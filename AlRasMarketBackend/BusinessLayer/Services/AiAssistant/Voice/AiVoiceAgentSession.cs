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
    private volatile bool _suppressCancelledOutput;
    private DateTime _turnSpeechStartedUtc;
    private DateTime _turnCompletedUtc;
    private DateTime _requestSentUtc;
    private DateTime? _firstAudioUtc;
    private long _lastSpeechStartedMs;
    private volatile bool _sessionReady;
    private int _appendedBytesWithoutSpeech;
    private readonly TaskCompletionSource _sessionCreated = new(TaskCreationOptions.RunContinuationsAsynchronously);
    private readonly TaskCompletionSource _sessionUpdated = new(TaskCreationOptions.RunContinuationsAsynchronously);
    private readonly ConcurrentDictionary<string, byte> _handledCallIds = new(StringComparer.Ordinal);
    private const int MaxBufferedBytesWithoutSpeech = 24_000 * 2 * 8;

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
        try
        {
            var apiKey = _configuration["OpenAI:ApiKey"];
            if (string.IsNullOrWhiteSpace(apiKey))
            {
                throw new InvalidOperationException("OpenAI ApiKey is not configured.");
            }

            using var linked = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken, _lifetime.Token);
            _socket.Options.SetRequestHeader("Authorization", "Bearer " + apiKey);
            _socket.Options.KeepAliveInterval = TimeSpan.FromSeconds(15);
            var model = ResolveRealtimeModel();
            if (NeedsRealtimeBetaHeader(model))
            {
                _socket.Options.SetRequestHeader("OpenAI-Beta", "realtime=v1");
            }

            var uri = new Uri($"wss://api.openai.com/v1/realtime?model={Uri.EscapeDataString(model)}");
            await _socket.ConnectAsync(uri, linked.Token).ConfigureAwait(false);

            _logger.LogInformation(
                "Voice session started connectionId={ConnectionId} userId={UserId} model={Model} voice={Voice} vad={Vad}",
                _connectionId,
                _userId,
                model,
                _voice,
                _options.TurnDetection);

            _receiveLoop = Task.Run(() => ReceiveLoopAsync(_lifetime.Token), CancellationToken.None);
            await WaitForSignalAsync(_sessionCreated, TimeSpan.FromSeconds(5), "session.created", linked.Token)
                .ConfigureAwait(false);
            await SendJsonAsync(await BuildSessionUpdateAsync(linked.Token).ConfigureAwait(false), linked.Token)
                .ConfigureAwait(false);
            await WaitForSignalAsync(_sessionUpdated, TimeSpan.FromSeconds(8), "session.updated", linked.Token)
                .ConfigureAwait(false);
            _sessionReady = true;
            await NotifyStatusAsync("listening", CancellationToken.None).ConfigureAwait(false);
        }
        catch (OperationCanceledException)
        {
            throw;
        }
        catch (Exception ex)
        {
            _sessionReady = false;
            _logger.LogError(
                ex,
                "Voice session start failed connectionId={ConnectionId} userId={UserId}",
                _connectionId,
                _userId);
            throw;
        }
    }

    public async Task SendAudioBase64Async(string pcmBase64, CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(pcmBase64)
            || !_sessionReady
            || _socket.State != WebSocketState.Open)
        {
            return;
        }

        var byteCount = (pcmBase64.Length * 3) / 4;
        var pending = Interlocked.Add(ref _appendedBytesWithoutSpeech, byteCount);
        if (pending >= MaxBufferedBytesWithoutSpeech)
        {
            Interlocked.Exchange(ref _appendedBytesWithoutSpeech, 0);
            using var clearLinked = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken, _lifetime.Token);
            await SendJsonAsync(new JsonObject { ["type"] = "input_audio_buffer.clear" }, clearLinked.Token)
                .ConfigureAwait(false);
            _logger.LogInformation(
                "Voice cleared silent input buffer connectionId={ConnectionId} pendingBytes={Bytes}",
                _connectionId,
                pending);
        }

        using var linked = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken, _lifetime.Token);
        try
        {
            await SendJsonAsync(new JsonObject
            {
                ["type"] = "input_audio_buffer.append",
                ["audio"] = pcmBase64
            }, linked.Token).ConfigureAwait(false);
        }
        catch (OperationCanceledException)
        {
            throw;
        }
        catch (Exception ex)
        {
            _logger.LogWarning(
                ex,
                "Voice send audio failed connectionId={ConnectionId} approxBytes={Bytes}",
                _connectionId,
                byteCount);
        }
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
        _suppressCancelledOutput = true;
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

        await SafeSendToClientAsync("voiceInterrupted", new { reason = "user" }, linked.Token)
            .ConfigureAwait(false);
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
                            "Voice OpenAI socket closed connectionId={ConnectionId} status={Status} description={Description}",
                            _connectionId,
                            result.CloseStatus,
                            result.CloseStatusDescription);
                        _sessionReady = false;
                        await NotifyErrorAsync(
                            "انقطع الاتصال بالصوت. جاري إعادة المحاولة.",
                            cancellationToken,
                            recoverable: true).ConfigureAwait(false);
                        return;
                    }

                    message.Write(buffer, 0, result.Count);
                }
                while (!result.EndOfMessage);

                var json = Encoding.UTF8.GetString(message.GetBuffer(), 0, (int)message.Length);
                try
                {
                    await HandleOpenAiEventAsync(json, cancellationToken).ConfigureAwait(false);
                }
                catch (Exception ex) when (ex is not OperationCanceledException)
                {
                    _logger.LogWarning(
                        ex,
                        "Voice OpenAI event handling failed connectionId={ConnectionId}",
                        _connectionId);
                }
            }
        }
        catch (OperationCanceledException)
        {
            // session stopped
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Voice receive loop failed connectionId={ConnectionId}", _connectionId);
            _sessionReady = false;
            try
            {
                await NotifyErrorAsync(
                    "حصلت مشكلة في الاتصال الصوتي، ممكن نجرب تاني؟",
                    CancellationToken.None,
                    recoverable: true).ConfigureAwait(false);
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
            case "session.created":
                _sessionCreated.TrySetResult();
                break;

            case "session.updated":
                _sessionReady = true;
                _sessionUpdated.TrySetResult();
                _logger.LogInformation("Voice session updated connectionId={ConnectionId}", _connectionId);
                break;

            case "error":
                var errorMessage = ReadErrorMessage(root);
                var errorCode = ReadErrorField(root, "code");
                var errorParam = ReadErrorField(root, "param");
                _logger.LogWarning(
                    "Voice OpenAI error connectionId={ConnectionId} code={Code} param={Param} message={Message}",
                    _connectionId,
                    errorCode,
                    errorParam,
                    errorMessage);
                if (IsIgnorableAudioBufferError(errorMessage, errorCode))
                {
                    return;
                }

                if (IsAudioBufferOverflow(errorMessage, errorCode))
                {
                    Interlocked.Exchange(ref _appendedBytesWithoutSpeech, 0);
                    await SendJsonAsync(
                        new JsonObject { ["type"] = "input_audio_buffer.clear" },
                        cancellationToken).ConfigureAwait(false);
                    return;
                }

                if (IsTurnDetectionConfigError(errorMessage, errorParam)
                    && _options.TurnDetection.Contains("semantic", StringComparison.OrdinalIgnoreCase))
                {
                    await SendJsonAsync(BuildServerVadSessionPatch(), cancellationToken).ConfigureAwait(false);
                    return;
                }

                if (IsUnknownSessionFieldError(errorMessage, errorParam))
                {
                    _logger.LogWarning(
                        "Voice session field rejected connectionId={ConnectionId} param={Param}",
                        _connectionId,
                        errorParam);
                    return;
                }

                await NotifyErrorAsync(
                    "الصوت مش واضح عندي دلوقتي، ممكن تقول الطلب مرة تانية؟",
                    cancellationToken).ConfigureAwait(false);
                break;

            case "input_audio_buffer.speech_started":
                _lastSpeechStartedMs = _sessionWatch.ElapsedMilliseconds;
                _turnSpeechStartedUtc = DateTime.UtcNow;
                Interlocked.Exchange(ref _appendedBytesWithoutSpeech, 0);
                _logger.LogInformation(
                    "Voice user speech detected connectionId={ConnectionId} sessionMs={Ms} agentSpeaking={AgentSpeaking}",
                    _connectionId,
                    _lastSpeechStartedMs,
                    _agentSpeaking);
                if (_agentSpeaking)
                {
                    // Do not barge-in on distant/quiet VAD hits — the mobile client
                    // interrupts only when mic amplitude shows the user is close.
                    _logger.LogDebug(
                        "Voice ignoring distant speech while agent speaks connectionId={ConnectionId}",
                        _connectionId);
                    break;
                }

                await NotifyStatusAsync("listening", cancellationToken).ConfigureAwait(false);
                break;

            case "input_audio_buffer.speech_stopped":
                if (_agentSpeaking)
                {
                    _logger.LogDebug(
                        "Voice ignoring speech_stopped while agent speaks connectionId={ConnectionId}",
                        _connectionId);
                    break;
                }

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
                _suppressCancelledOutput = false;
                break;

            case "response.audio.delta":
            case "response.output_audio.delta":
                if (_suppressCancelledOutput)
                {
                    break;
                }

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
                        await SafeSendToClientAsync(
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

                    await SafeSendToClientAsync(
                        "voiceAudio",
                        new { pcmBase64 = audioDelta.GetString(), kind = "response" },
                        cancellationToken).ConfigureAwait(false);
                }

                break;

            case "response.audio.done":
            case "response.output_audio.done":
                // Keep _agentSpeaking until response.done so stray VAD events
                // do not flip the client to processing while PCM is still playing.
                break;

            case "response.audio_transcript.delta":
            case "response.output_audio_transcript.delta":
                if (_suppressCancelledOutput)
                {
                    break;
                }

                if (root.TryGetProperty("delta", out var textDelta)
                    && textDelta.ValueKind == JsonValueKind.String)
                {
                    await SafeSendToClientAsync(
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
                        await SafeSendToClientAsync(
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
                var cancelled = IsCancelledResponse(root);
                var totalMs = _firstAudioUtc is null
                    ? 0
                    : (DateTime.UtcNow - _requestSentUtc).TotalMilliseconds;
                _logger.LogInformation(
                    "Voice response done connectionId={ConnectionId} totalResponseMs={Ms} cancelled={Cancelled}",
                    _connectionId,
                    Math.Round(totalMs),
                    cancelled);
                if (cancelled)
                {
                    break;
                }

                _agentSpeaking = false;
                // Let the client finish playing buffered PCM before switching to listening.
                await NotifyStatusAsync("response_complete", cancellationToken).ConfigureAwait(false);
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

        try
        {
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
        catch (Exception ex) when (ex is not OperationCanceledException)
        {
            _logger.LogError(
                ex,
                "Voice tool response send failed connectionId={ConnectionId} tool={Tool}",
                _connectionId,
                name);
            await NotifyErrorAsync(
                "حصلت مشكلة وأنا بحاول أجيب البيانات، ممكن نجرب تاني؟",
                cancellationToken,
                recoverable: true).ConfigureAwait(false);
        }
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
        await SafeSendToClientAsync(
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
                ["type"] = "realtime",
                ["model"] = ResolveRealtimeModel(),
                ["output_modalities"] = new JsonArray("audio"),
                ["instructions"] = instructions,
                ["audio"] = new JsonObject
                {
                    ["input"] = new JsonObject
                    {
                        ["format"] = new JsonObject
                        {
                            ["type"] = "audio/pcm",
                            ["rate"] = _options.SampleRate > 0 ? _options.SampleRate : 24000
                        },
                        ["noise_reduction"] = new JsonObject { ["type"] = "near_field" },
                        ["transcription"] = new JsonObject
                        {
                            ["model"] = "gpt-4o-mini-transcribe"
                        },
                        ["turn_detection"] = BuildTurnDetectionNode()
                    },
                    ["output"] = new JsonObject
                    {
                        ["format"] = new JsonObject
                        {
                            ["type"] = "audio/pcm",
                            ["rate"] = _options.SampleRate > 0 ? _options.SampleRate : 24000
                        },
                        ["voice"] = _voice
                    }
                },
                ["tools"] = toolsJson,
                ["tool_choice"] = "auto"
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
                ["type"] = "realtime",
                ["audio"] = new JsonObject
                {
                    ["input"] = new JsonObject
                    {
                        ["turn_detection"] = BuildServerVadNode()
                    }
                }
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
            ["interrupt_response"] = _options.InterruptResponse
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
            ["interrupt_response"] = _options.InterruptResponse
        };

    private async Task SendJsonAsync(JsonNode payload, CancellationToken cancellationToken)
    {
        var payloadType = payload["type"]?.ToString() ?? "unknown";
        try
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
        catch (OperationCanceledException)
        {
            throw;
        }
        catch (Exception ex)
        {
            _logger.LogWarning(
                ex,
                "Voice OpenAI send failed connectionId={ConnectionId} payloadType={PayloadType}",
                _connectionId,
                payloadType);
            throw;
        }
    }

    private Task NotifyStatusAsync(string phase, CancellationToken cancellationToken) =>
        SafeSendToClientAsync("voiceStatus", new { phase }, cancellationToken);

    private Task NotifyErrorAsync(string message, CancellationToken cancellationToken, bool recoverable = false) =>
        SafeSendToClientAsync("voiceError", new { message, recoverable }, cancellationToken);

    private async Task SafeSendToClientAsync(
        string eventName,
        object payload,
        CancellationToken cancellationToken)
    {
        try
        {
            await _sendToClient(eventName, payload, cancellationToken).ConfigureAwait(false);
        }
        catch (OperationCanceledException)
        {
            // client disconnected
        }
        catch (Exception ex)
        {
            _logger.LogWarning(
                ex,
                "Voice client notify failed connectionId={ConnectionId} event={Event}",
                _connectionId,
                eventName);
        }
    }

    private async Task WaitForSignalAsync(
        TaskCompletionSource source,
        TimeSpan timeout,
        string label,
        CancellationToken cancellationToken)
    {
        using var timeoutCts = new CancellationTokenSource(timeout);
        using var linked = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken, timeoutCts.Token);
        try
        {
            await source.Task.WaitAsync(linked.Token).ConfigureAwait(false);
        }
        catch (OperationCanceledException) when (timeoutCts.IsCancellationRequested)
        {
            _logger.LogWarning(
                "Voice waited for {Label} timed out connectionId={ConnectionId}",
                label,
                _connectionId);
        }
    }

    private string ResolveRealtimeModel()
    {
        var model = _options.RealtimeModel?.Trim();
        return string.IsNullOrWhiteSpace(model) ? "gpt-realtime" : model;
    }

    private static bool NeedsRealtimeBetaHeader(string model) =>
        model.Contains("gpt-4o-realtime", StringComparison.OrdinalIgnoreCase)
        || model.Contains("preview", StringComparison.OrdinalIgnoreCase);

    private static bool IsCancelledResponse(JsonElement root)
    {
        if (root.TryGetProperty("response", out var response)
            && response.ValueKind == JsonValueKind.Object
            && response.TryGetProperty("status", out var status))
        {
            var value = status.GetString();
            return string.Equals(value, "cancelled", StringComparison.OrdinalIgnoreCase)
                || string.Equals(value, "incomplete", StringComparison.OrdinalIgnoreCase)
                    && response.TryGetProperty("status_details", out var details)
                    && details.ValueKind == JsonValueKind.Object
                    && details.TryGetProperty("reason", out var reason)
                    && string.Equals(reason.GetString(), "cancelled", StringComparison.OrdinalIgnoreCase);
        }

        return false;
    }

    private static bool IsIgnorableAudioBufferError(string message, string? code) =>
        ContainsAny(message, "buffer too small", "buffer has 0", "expected at least")
        || ContainsAny(code, "input_audio_buffer_commit_empty");

    private static bool IsAudioBufferOverflow(string message, string? code) =>
        ContainsAny(message, "buffer too large", "too many audio", "input audio buffer is too")
        || ContainsAny(code, "input_audio_buffer_overflow", "buffer_too_large");

    private static bool IsTurnDetectionConfigError(string message, string? param) =>
        ContainsAny(message, "turn_detection", "semantic_vad")
        || ContainsAny(param, "turn_detection", "semantic_vad");

    private static bool IsUnknownSessionFieldError(string message, string? param) =>
        ContainsAny(message, "unknown parameter", "unknown field", "unsupported")
        && !string.IsNullOrWhiteSpace(param);

    private static bool ContainsAny(string? value, params string[] parts)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            return false;
        }

        foreach (var part in parts)
        {
            if (value.Contains(part, StringComparison.OrdinalIgnoreCase))
            {
                return true;
            }
        }

        return false;
    }

    private static string ReadErrorField(JsonElement root, string field)
    {
        if (root.TryGetProperty("error", out var error)
            && error.ValueKind == JsonValueKind.Object
            && error.TryGetProperty(field, out var value)
            && value.ValueKind == JsonValueKind.String)
        {
            return value.GetString() ?? "";
        }

        return "";
    }

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
        catch (Exception ex)
        {
            services.GetRequiredService<ILogger<AiVoiceAgentSessionManager>>()
                .LogError(ex, "Voice session manager start failed connectionId={ConnectionId}", connectionId);
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
