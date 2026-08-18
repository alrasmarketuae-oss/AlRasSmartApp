using System.Collections.Concurrent;
using System.Diagnostics;
using System.Net.WebSockets;
using System.Text;
using System.Text.Json;
using System.Text.Json.Nodes;
using BusinessLayer.Interfaces;
using BusinessLayer.Options;
using DataLayer.Interfaces;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace BusinessLayer.Services.AiAssistant.Voice;

public sealed class AiVoiceAgentSession : IAsyncDisposable
{
    private readonly ClientWebSocket _socket = new();
    private readonly SemaphoreSlim _sendLock = new(1, 1);
    private readonly CancellationTokenSource _lifetime = new();
    private readonly IServiceScopeFactory _scopeFactory;
    private readonly AiVoiceAgentOptions _options;
    private readonly IConfiguration _configuration;
    private readonly AiVoiceProgressSpeechService _progressSpeech;
    private readonly ILogger _logger;
    private readonly Func<string, object, CancellationToken, Task> _sendToClient;
    private readonly string _connectionId;
    private readonly Guid? _userId;
    private readonly string _language;
    private readonly string _voice;
    private readonly Stopwatch _sessionWatch = Stopwatch.StartNew();
    private Task? _receiveLoop;
    private int _disposed;
    private int _progressPhraseIndex;
    private volatile bool _agentSpeaking;
    private DateTime _turnSpeechStartedUtc;
    private DateTime _turnCompletedUtc;
    private DateTime _requestSentUtc;
    private DateTime? _firstAudioUtc;
    private long _lastSpeechStartedMs;
    private readonly ConcurrentDictionary<string, byte> _handledCallIds = new(StringComparer.Ordinal);

    public AiVoiceAgentSession(
        IServiceScopeFactory scopeFactory,
        IOptions<AiVoiceAgentOptions> options,
        IConfiguration configuration,
        AiVoiceProgressSpeechService progressSpeech,
        ILogger logger,
        Func<string, object, CancellationToken, Task> sendToClient,
        string connectionId,
        Guid? userId,
        string language,
        string voiceGender)
    {
        _scopeFactory = scopeFactory;
        _options = options.Value;
        _configuration = configuration;
        _progressSpeech = progressSpeech;
        _logger = logger;
        _sendToClient = sendToClient;
        _connectionId = connectionId;
        _userId = userId;
        _language = string.Equals(language, "en", StringComparison.OrdinalIgnoreCase) ? "en" : "ar";
        _voice = string.Equals(voiceGender, "male", StringComparison.OrdinalIgnoreCase)
            ? (_options.MaleVoice ?? "ash")
            : (_options.FemaleVoice ?? "coral");
    }

    public async Task StartAsync(CancellationToken cancellationToken)
    {
        var apiKey = _configuration["OpenAI:ApiKey"];
        if (string.IsNullOrWhiteSpace(apiKey))
        {
            throw new InvalidOperationException("OpenAI ApiKey is not configured.");
        }

        using var linked = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken, _lifetime.Token);
        _socket.Options.SetRequestHeader("Authorization", "Bearer " + apiKey);
        _socket.Options.SetRequestHeader("OpenAI-Beta", "realtime=v1");
        _socket.Options.KeepAliveInterval = TimeSpan.FromSeconds(20);

        var model = string.IsNullOrWhiteSpace(_options.RealtimeModel)
            ? "gpt-4o-realtime-preview"
            : _options.RealtimeModel.Trim();
        var uri = new Uri($"wss://api.openai.com/v1/realtime?model={Uri.EscapeDataString(model)}");
        await _socket.ConnectAsync(uri, linked.Token).ConfigureAwait(false);

        _logger.LogInformation(
            "Voice session started connectionId={ConnectionId} userId={UserId} model={Model} voice={Voice} vad={Vad}",
            _connectionId,
            _userId,
            model,
            _voice,
            _options.TurnDetection);

        await SendJsonAsync(await BuildSessionUpdateAsync(linked.Token).ConfigureAwait(false), linked.Token)
            .ConfigureAwait(false);
        _receiveLoop = Task.Run(() => ReceiveLoopAsync(_lifetime.Token), CancellationToken.None);
        await NotifyStatusAsync("listening", CancellationToken.None).ConfigureAwait(false);
    }

    public async Task SendAudioBase64Async(string pcmBase64, CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(pcmBase64) || _socket.State != WebSocketState.Open)
        {
            return;
        }

        using var linked = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken, _lifetime.Token);
        await SendJsonAsync(new JsonObject
        {
            ["type"] = "input_audio_buffer.append",
            ["audio"] = pcmBase64
        }, linked.Token).ConfigureAwait(false);
    }

    public async Task InterruptAsync(CancellationToken cancellationToken)
    {
        if (_socket.State != WebSocketState.Open)
        {
            return;
        }

        _logger.LogInformation(
            "Voice user interrupted agent connectionId={ConnectionId} sessionMs={Ms}",
            _connectionId,
            _sessionWatch.ElapsedMilliseconds);
        _agentSpeaking = false;
        using var linked = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken, _lifetime.Token);
        try
        {
            await SendJsonAsync(new JsonObject { ["type"] = "response.cancel" }, linked.Token)
                .ConfigureAwait(false);
        }
        catch (Exception ex) when (ex is not OperationCanceledException)
        {
            _logger.LogDebug(ex, "Voice response.cancel failed (may already be idle)");
        }

        await _sendToClient("voiceInterrupted", new { reason = "user" }, linked.Token).ConfigureAwait(false);
        await NotifyStatusAsync("listening", linked.Token).ConfigureAwait(false);
    }

    public async ValueTask DisposeAsync()
    {
        if (Interlocked.Exchange(ref _disposed, 1) == 1)
        {
            return;
        }

        try
        {
            _lifetime.Cancel();
        }
        catch
        {
            // ignore
        }

        try
        {
            if (_receiveLoop is not null)
            {
                await _receiveLoop.ConfigureAwait(false);
            }
        }
        catch
        {
            // ignore
        }

        try
        {
            if (_socket.State is WebSocketState.Open or WebSocketState.CloseReceived)
            {
                await _socket.CloseAsync(
                    WebSocketCloseStatus.NormalClosure,
                    "done",
                    CancellationToken.None).ConfigureAwait(false);
            }
        }
        catch
        {
            // ignore
        }

        _socket.Dispose();
        _sendLock.Dispose();
        _lifetime.Dispose();
        _logger.LogInformation(
            "Voice session ended connectionId={ConnectionId} durationMs={Ms}",
            _connectionId,
            _sessionWatch.ElapsedMilliseconds);
    }

    private async Task ReceiveLoopAsync(CancellationToken cancellationToken)
    {
        var buffer = new byte[64 * 1024];
        var message = new MemoryStream();
        try
        {
            while (!cancellationToken.IsCancellationRequested && _socket.State == WebSocketState.Open)
            {
                message.SetLength(0);
                WebSocketReceiveResult result;
                do
                {
                    result = await _socket.ReceiveAsync(buffer, cancellationToken).ConfigureAwait(false);
                    if (result.MessageType == WebSocketMessageType.Close)
                    {
                        _logger.LogWarning(
                            "Voice OpenAI socket closed connectionId={ConnectionId} status={Status}",
                            _connectionId,
                            result.CloseStatus);
                        await NotifyErrorAsync("انقطع الاتصال بالصوت. جاري إعادة المحاولة.", cancellationToken)
                            .ConfigureAwait(false);
                        return;
                    }

                    message.Write(buffer, 0, result.Count);
                }
                while (!result.EndOfMessage);

                var json = Encoding.UTF8.GetString(message.GetBuffer(), 0, (int)message.Length);
                await HandleOpenAiEventAsync(json, cancellationToken).ConfigureAwait(false);
            }
        }
        catch (OperationCanceledException)
        {
            // session stopped
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Voice receive loop failed connectionId={ConnectionId}", _connectionId);
            try
            {
                await NotifyErrorAsync("حصلت مشكلة في الاتصال الصوتي، ممكن نجرب تاني؟", CancellationToken.None)
                    .ConfigureAwait(false);
            }
            catch
            {
                // ignore
            }
        }
    }

    private async Task HandleOpenAiEventAsync(string json, CancellationToken cancellationToken)
    {
        using var doc = JsonDocument.Parse(json);
        var root = doc.RootElement;
        var type = root.TryGetProperty("type", out var typeEl) ? typeEl.GetString() : null;
        if (string.IsNullOrWhiteSpace(type))
        {
            return;
        }

        switch (type)
        {
            case "error":
                var errorMessage = ReadErrorMessage(root);
                _logger.LogWarning(
                    "Voice OpenAI error connectionId={ConnectionId} message={Message}",
                    _connectionId,
                    errorMessage);
                if (errorMessage.Contains("turn_detection", StringComparison.OrdinalIgnoreCase)
                    && _options.TurnDetection.Contains("semantic", StringComparison.OrdinalIgnoreCase))
                {
                    await SendJsonAsync(BuildServerVadSessionPatch(), cancellationToken).ConfigureAwait(false);
                    return;
                }

                await NotifyErrorAsync(
                    "حصلت مشكلة وأنا بحاول أسمعك، ممكن تقول الطلب مرة تانية؟",
                    cancellationToken).ConfigureAwait(false);
                break;

            case "input_audio_buffer.speech_started":
                _lastSpeechStartedMs = _sessionWatch.ElapsedMilliseconds;
                _turnSpeechStartedUtc = DateTime.UtcNow;
                _logger.LogInformation(
                    "Voice user speech detected connectionId={ConnectionId} sessionMs={Ms}",
                    _connectionId,
                    _lastSpeechStartedMs);
                if (_agentSpeaking)
                {
                    _logger.LogInformation(
                        "Voice barge-in connectionId={ConnectionId}",
                        _connectionId);
                    _agentSpeaking = false;
                    try
                    {
                        await SendJsonAsync(new JsonObject { ["type"] = "response.cancel" }, cancellationToken)
                            .ConfigureAwait(false);
                    }
                    catch
                    {
                        // ignore
                    }

                    await _sendToClient("voiceInterrupted", new { reason = "speech_started" }, cancellationToken)
                        .ConfigureAwait(false);
                }

                await NotifyStatusAsync("listening", cancellationToken).ConfigureAwait(false);
                break;

            case "input_audio_buffer.speech_stopped":
                _turnCompletedUtc = DateTime.UtcNow;
                var vadMs = (_turnCompletedUtc - _turnSpeechStartedUtc).TotalMilliseconds;
                _logger.LogInformation(
                    "Voice user turn completed connectionId={ConnectionId} vadDurationMs={VadMs}",
                    _connectionId,
                    Math.Round(vadMs));
                _requestSentUtc = DateTime.UtcNow;
                _firstAudioUtc = null;
                await NotifyStatusAsync("processing", cancellationToken).ConfigureAwait(false);
                break;

            case "response.created":
                break;

            case "response.audio.delta":
            case "response.output_audio.delta":
                if (root.TryGetProperty("delta", out var audioDelta)
                    && audioDelta.ValueKind == JsonValueKind.String)
                {
                    if (_firstAudioUtc is null)
                    {
                        _firstAudioUtc = DateTime.UtcNow;
                        var ttfa = (_firstAudioUtc.Value - _requestSentUtc).TotalMilliseconds;
                        if (_requestSentUtc == default)
                        {
                            ttfa = 0;
                        }

                        _logger.LogInformation(
                            "Voice first audio connectionId={ConnectionId} timeToFirstAudioMs={Ttfa} responseStarted=true",
                            _connectionId,
                            Math.Round(Math.Max(0, ttfa)));
                        await _sendToClient(
                            "voiceMetrics",
                            new
                            {
                                eventName = "first_audio",
                                timeToFirstAudioMs = Math.Round(Math.Max(0, ttfa)),
                                vadDurationMs = Math.Round((_turnCompletedUtc - _turnSpeechStartedUtc).TotalMilliseconds)
                            },
                            cancellationToken).ConfigureAwait(false);
                    }

                    if (!_agentSpeaking)
                    {
                        _agentSpeaking = true;
                        _logger.LogInformation(
                            "Voice audio playback started connectionId={ConnectionId}",
                            _connectionId);
                        await NotifyStatusAsync("speaking", cancellationToken).ConfigureAwait(false);
                    }

                    await _sendToClient(
                        "voiceAudio",
                        new { pcmBase64 = audioDelta.GetString(), kind = "response" },
                        cancellationToken).ConfigureAwait(false);
                }

                break;

            case "response.audio.done":
            case "response.output_audio.done":
                _agentSpeaking = false;
                break;

            case "response.audio_transcript.delta":
            case "response.output_audio_transcript.delta":
                if (root.TryGetProperty("delta", out var textDelta)
                    && textDelta.ValueKind == JsonValueKind.String)
                {
                    await _sendToClient(
                        "voiceTranscript",
                        new { role = "assistant", text = textDelta.GetString(), final = false },
                        cancellationToken).ConfigureAwait(false);
                }

                break;

            case "conversation.item.input_audio_transcription.completed":
                if (root.TryGetProperty("transcript", out var userText)
                    && userText.ValueKind == JsonValueKind.String)
                {
                    var spoken = userText.GetString() ?? "";
                    if (spoken.Length > 0)
                    {
                        await _sendToClient(
                            "voiceTranscript",
                            new { role = "user", text = spoken, final = true },
                            cancellationToken).ConfigureAwait(false);
                    }
                }

                break;

            case "response.function_call_arguments.done":
                await HandleFunctionCallAsync(root, cancellationToken).ConfigureAwait(false);
                break;

            case "response.output_item.done":
                if (root.TryGetProperty("item", out var item)
                    && item.ValueKind == JsonValueKind.Object
                    && item.TryGetProperty("type", out var itemType)
                    && itemType.GetString() == "function_call")
                {
                    await HandleFunctionCallAsync(item, cancellationToken).ConfigureAwait(false);
                }

                break;

            case "response.done":
                var totalMs = _firstAudioUtc is null
                    ? 0
                    : (DateTime.UtcNow - _requestSentUtc).TotalMilliseconds;
                _logger.LogInformation(
                    "Voice response done connectionId={ConnectionId} totalResponseMs={Ms}",
                    _connectionId,
                    Math.Round(totalMs));
                _agentSpeaking = false;
                await NotifyStatusAsync("listening", cancellationToken).ConfigureAwait(false);
                break;
        }
    }

    private async Task HandleFunctionCallAsync(JsonElement payload, CancellationToken cancellationToken)
    {
        var callId = payload.TryGetProperty("call_id", out var callIdEl)
            ? callIdEl.GetString()
            : null;
        var name = payload.TryGetProperty("name", out var nameEl) ? nameEl.GetString() : null;
        var args = payload.TryGetProperty("arguments", out var argsEl) && argsEl.ValueKind == JsonValueKind.String
            ? argsEl.GetString()
            : payload.TryGetProperty("arguments", out var argsObj)
                ? argsObj.GetRawText()
                : "{}";
        if (string.IsNullOrWhiteSpace(callId) || string.IsNullOrWhiteSpace(name))
        {
            return;
        }

        if (!_handledCallIds.TryAdd(callId, 0))
        {
            return;
        }

        _logger.LogInformation(
            "Voice tool started connectionId={ConnectionId} tool={Tool}",
            _connectionId,
            name);
        await NotifyStatusAsync("processing", cancellationToken).ConfigureAwait(false);

        using var progressCts = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken);
        var progressTask = RunProgressSpeechAsync(name!, progressCts.Token);
        var toolWatch = Stopwatch.StartNew();
        string output;
        try
        {
            await using var scope = _scopeFactory.CreateAsyncScope();
            if (string.Equals(name, "search_help_knowledge", StringComparison.Ordinal))
            {
                output = await SearchHelpKnowledgeAsync(
                    scope.ServiceProvider,
                    string.IsNullOrWhiteSpace(args) ? "{}" : args!,
                    cancellationToken).ConfigureAwait(false);
            }
            else
            {
                var tools = scope.ServiceProvider.GetRequiredService<IAiAssistantToolsService>();
                var result = await tools.ExecuteAsync(
                    _userId,
                    new AiToolCall(callId, name!, string.IsNullOrWhiteSpace(args) ? "{}" : args!),
                    cancellationToken).ConfigureAwait(false);
                output = result.Content;
            }
        }
        catch (Exception ex) when (ex is not OperationCanceledException)
        {
            _logger.LogWarning(ex, "Voice tool failed connectionId={ConnectionId} tool={Tool}", _connectionId, name);
            output = JsonSerializer.Serialize(new
            {
                ok = false,
                error = "tool_failed",
                message = "The backend could not complete this action. Ask the user to try again."
            });
        }
        finally
        {
            progressCts.Cancel();
            try
            {
                await progressTask.ConfigureAwait(false);
            }
            catch (OperationCanceledException)
            {
                // expected
            }
        }

        toolWatch.Stop();
        _logger.LogInformation(
            "Voice tool completed connectionId={ConnectionId} tool={Tool} durationMs={Ms}",
            _connectionId,
            name,
            toolWatch.ElapsedMilliseconds);

        await SendJsonAsync(new JsonObject
        {
            ["type"] = "conversation.item.create",
            ["item"] = new JsonObject
            {
                ["type"] = "function_call_output",
                ["call_id"] = callId,
                ["output"] = output
            }
        }, cancellationToken).ConfigureAwait(false);
        await SendJsonAsync(new JsonObject { ["type"] = "response.create" }, cancellationToken)
            .ConfigureAwait(false);
    }

    private async Task RunProgressSpeechAsync(string toolName, CancellationToken cancellationToken)
    {
        var delay = Math.Max(400, _options.ProgressSpeechDelayMs);
        var repeat = Math.Max(delay + 500, _options.ProgressSpeechRepeatMs);
        var phrases = _options.ProgressPhrases is { Length: > 0 }
            ? _options.ProgressPhrases
            : ["ثواني يا فندم، براجع البيانات."];

        try
        {
            await Task.Delay(delay, cancellationToken).ConfigureAwait(false);
            var first = phrases[_progressPhraseIndex % phrases.Length];
            _progressPhraseIndex++;
            await SendProgressPhraseAsync(first, cancellationToken).ConfigureAwait(false);

            while (!cancellationToken.IsCancellationRequested)
            {
                await Task.Delay(repeat, cancellationToken).ConfigureAwait(false);
                var next = phrases[_progressPhraseIndex % phrases.Length];
                _progressPhraseIndex++;
                await SendProgressPhraseAsync(next, cancellationToken).ConfigureAwait(false);
            }
        }
        catch (OperationCanceledException)
        {
            // tool finished before/during progress — do not delay the real answer
        }
    }

    private async Task SendProgressPhraseAsync(string phrase, CancellationToken cancellationToken)
    {
        if (_agentSpeaking)
        {
            return;
        }

        var pcm = await _progressSpeech.SynthesizePcmAsync(phrase, _voice, cancellationToken)
            .ConfigureAwait(false);
        if (pcm is null || pcm.Length == 0 || cancellationToken.IsCancellationRequested || _agentSpeaking)
        {
            return;
        }

        _logger.LogInformation(
            "Voice progress speech connectionId={ConnectionId} chars={Chars}",
            _connectionId,
            phrase.Length);
        await _sendToClient(
            "voiceAudio",
            new { pcmBase64 = Convert.ToBase64String(pcm), kind = "progress" },
            cancellationToken).ConfigureAwait(false);
    }

    private async Task<JsonObject> BuildSessionUpdateAsync(CancellationToken cancellationToken)
    {
        string audience = "guest";
        string? displayName = null;
        string? catalog = null;
        await using (var scope = _scopeFactory.CreateAsyncScope())
        {
            var tools = scope.ServiceProvider.GetRequiredService<IAiAssistantToolsService>();
            if (_userId is Guid userId)
            {
                var db = scope.ServiceProvider.GetRequiredService<IRasAlSouqDbContext>();
                var user = await db.Users
                    .AsNoTracking()
                    .Where(x => x.Id == userId)
                    .Select(x => new { x.RoleId, x.IsCustomer, x.FullName, x.CompanyName })
                    .FirstOrDefaultAsync(cancellationToken)
                    .ConfigureAwait(false);
                if (user is not null)
                {
                    audience = user.RoleId switch
                    {
                        5 => "shipping",
                        3 => "personal",
                        2 when user.IsCustomer == true => "company_customer",
                        2 => "supplier",
                        _ => "public"
                    };
                    displayName = audience is "supplier" or "company_customer" or "shipping"
                        ? FirstNonEmpty(user.CompanyName, user.FullName)
                        : FirstNonEmpty(user.FullName, user.CompanyName);
                }

                try
                {
                    catalog = await tools.BuildSellerAdsCatalogAsync(userId, cancellationToken)
                        .ConfigureAwait(false);
                }
                catch (Exception ex)
                {
                    _logger.LogDebug(ex, "Voice seller catalog skipped");
                }
            }

            var toolsJson = AiVoiceRealtimeToolSchema.ToRealtimeTools(tools.GetToolDefinitions());
            toolsJson.Add(new JsonObject
            {
                ["type"] = "function",
                ["name"] = "search_help_knowledge",
                ["description"] =
                    "Search AlRas platform help/policy knowledge for how-to, commissions, permissions, and support questions. Do not use for live product prices or the user's own ads.",
                ["parameters"] = new JsonObject
                {
                    ["type"] = "object",
                    ["properties"] = new JsonObject
                    {
                        ["query"] = new JsonObject
                        {
                            ["type"] = "string",
                            ["description"] = "The user question in Arabic or English."
                        }
                    },
                    ["required"] = new JsonArray("query")
                }
            });
            var instructions = AiVoiceAgentInstructions.Build(_language, audience, displayName, catalog);
            var session = new JsonObject
            {
                ["modalities"] = new JsonArray("text", "audio"),
                ["instructions"] = instructions,
                ["voice"] = _voice,
                ["input_audio_format"] = "pcm16",
                ["output_audio_format"] = "pcm16",
                ["input_audio_transcription"] = new JsonObject
                {
                    ["model"] = "gpt-4o-mini-transcribe"
                },
                ["turn_detection"] = BuildTurnDetectionNode(),
                ["tools"] = toolsJson,
                ["tool_choice"] = "auto",
                ["temperature"] = _options.Temperature
            };
            return new JsonObject
            {
                ["type"] = "session.update",
                ["session"] = session
            };
        }
    }

    private async Task<string> SearchHelpKnowledgeAsync(
        IServiceProvider services,
        string argumentsJson,
        CancellationToken cancellationToken)
    {
        try
        {
            using var argsDoc = JsonDocument.Parse(string.IsNullOrWhiteSpace(argumentsJson) ? "{}" : argumentsJson);
            var query = argsDoc.RootElement.TryGetProperty("query", out var q)
                ? q.GetString()
                : null;
            if (string.IsNullOrWhiteSpace(query))
            {
                return JsonSerializer.Serialize(new { ok = false, error = "missing_query" });
            }

            var embedding = services.GetRequiredService<IAiTextEmbeddingService>();
            var index = services.GetRequiredService<IAiKnowledgeIndex>();
            var aiOptions = services.GetRequiredService<IOptions<AiAssistantOptions>>().Value;
            var vector = await embedding.EmbedAsync(query, cancellationToken).ConfigureAwait(false);
            var hits = await index.SearchAsync(
                vector,
                "public",
                Math.Max(3, Math.Min(8, aiOptions.RetrievalLimit)),
                cancellationToken).ConfigureAwait(false);
            return JsonSerializer.Serialize(new
            {
                ok = true,
                hits = hits.Select(h => new { h.Title, content = h.Content.Length > 1200 ? h.Content[..1200] : h.Content })
            });
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Voice help knowledge search failed");
            return JsonSerializer.Serialize(new { ok = false, error = "knowledge_unavailable" });
        }
    }

    private JsonObject BuildServerVadSessionPatch() =>
        new()
        {
            ["type"] = "session.update",
            ["session"] = new JsonObject
            {
                ["turn_detection"] = BuildServerVadNode()
            }
        };

    private JsonNode BuildTurnDetectionNode()
    {
        if (string.Equals(_options.TurnDetection, "server_vad", StringComparison.OrdinalIgnoreCase))
        {
            return BuildServerVadNode();
        }

        return new JsonObject
        {
            ["type"] = "semantic_vad",
            ["eagerness"] = string.IsNullOrWhiteSpace(_options.SemanticEagerness)
                ? "medium"
                : _options.SemanticEagerness,
            ["create_response"] = true,
            ["interrupt_response"] = true
        };
    }

    private JsonObject BuildServerVadNode() =>
        new()
        {
            ["type"] = "server_vad",
            ["threshold"] = _options.VadThreshold,
            ["prefix_padding_ms"] = _options.PrefixPaddingMs,
            ["silence_duration_ms"] = _options.SilenceDurationMs,
            ["create_response"] = true,
            ["interrupt_response"] = true
        };

    private async Task SendJsonAsync(JsonNode payload, CancellationToken cancellationToken)
    {
        var bytes = Encoding.UTF8.GetBytes(payload.ToJsonString());
        await _sendLock.WaitAsync(cancellationToken).ConfigureAwait(false);
        try
        {
            if (_socket.State != WebSocketState.Open)
            {
                return;
            }

            await _socket.SendAsync(bytes, WebSocketMessageType.Text, true, cancellationToken)
                .ConfigureAwait(false);
        }
        finally
        {
            _sendLock.Release();
        }
    }

    private Task NotifyStatusAsync(string phase, CancellationToken cancellationToken) =>
        _sendToClient("voiceStatus", new { phase }, cancellationToken);

    private Task NotifyErrorAsync(string message, CancellationToken cancellationToken) =>
        _sendToClient("voiceError", new { message }, cancellationToken);

    private static string ReadErrorMessage(JsonElement root)
    {
        if (root.TryGetProperty("error", out var error) && error.ValueKind == JsonValueKind.Object)
        {
            if (error.TryGetProperty("message", out var message) && message.ValueKind == JsonValueKind.String)
            {
                return message.GetString() ?? "error";
            }
        }

        return "error";
    }

    private static string? FirstNonEmpty(params string?[] values) =>
        values.FirstOrDefault(x => !string.IsNullOrWhiteSpace(x))?.Trim();
}

public sealed class AiVoiceAgentSessionManager(IServiceProvider services) : IAsyncDisposable
{
    private readonly ConcurrentDictionary<string, AiVoiceAgentSession> _sessions = new(StringComparer.Ordinal);

    public async Task<AiVoiceAgentSession> StartAsync(
        string connectionId,
        Guid? userId,
        string language,
        string? voiceGender,
        Func<string, object, CancellationToken, Task> sendToClient,
        CancellationToken cancellationToken)
    {
        await StopAsync(connectionId).ConfigureAwait(false);
        var session = new AiVoiceAgentSession(
            services.GetRequiredService<IServiceScopeFactory>(),
            services.GetRequiredService<IOptions<AiVoiceAgentOptions>>(),
            services.GetRequiredService<IConfiguration>(),
            services.GetRequiredService<AiVoiceProgressSpeechService>(),
            services.GetRequiredService<ILogger<AiVoiceAgentSession>>(),
            sendToClient,
            connectionId,
            userId,
            language ?? "ar",
            voiceGender ?? "female");
        if (!_sessions.TryAdd(connectionId, session))
        {
            await session.DisposeAsync().ConfigureAwait(false);
            throw new InvalidOperationException("Voice session already exists.");
        }

        try
        {
            await session.StartAsync(cancellationToken).ConfigureAwait(false);
            return session;
        }
        catch
        {
            _sessions.TryRemove(connectionId, out _);
            await session.DisposeAsync().ConfigureAwait(false);
            throw;
        }
    }

    public bool TryGet(string connectionId, out AiVoiceAgentSession session) =>
        _sessions.TryGetValue(connectionId, out session!);

    public async Task StopAsync(string connectionId)
    {
        if (_sessions.TryRemove(connectionId, out var session))
        {
            await session.DisposeAsync().ConfigureAwait(false);
        }
    }

    public async ValueTask DisposeAsync()
    {
        foreach (var id in _sessions.Keys.ToArray())
        {
            await StopAsync(id).ConfigureAwait(false);
        }
    }
}
