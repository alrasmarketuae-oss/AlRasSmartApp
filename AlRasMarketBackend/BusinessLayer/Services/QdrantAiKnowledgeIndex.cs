using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using BusinessLayer.Interfaces;
using BusinessLayer.Options;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace BusinessLayer.Services;

public sealed class QdrantAiKnowledgeIndex(
    HttpClient httpClient,
    IOptions<AiAssistantOptions> options,
    ILogger<QdrantAiKnowledgeIndex> logger) : IAiKnowledgeIndex
{
    private readonly AiAssistantOptions _options = options.Value;
    private readonly SemaphoreSlim _ensureLock = new(1, 1);
    private bool _ready;

    public async Task EnsureCollectionAsync(CancellationToken cancellationToken = default)
    {
        if (_ready || !_options.Enabled) return;

        await _ensureLock.WaitAsync(cancellationToken).ConfigureAwait(false);
        try
        {
            if (_ready) return;
            ApplyAuth();
            var collection = Uri.EscapeDataString(_options.Collection);
            using var get = await httpClient.GetAsync(
                $"collections/{collection}",
                cancellationToken).ConfigureAwait(false);
            if (!get.IsSuccessStatusCode)
            {
                using var create = new HttpRequestMessage(HttpMethod.Put, $"collections/{collection}")
                {
                    Content = JsonContent(new
                    {
                        vectors = new
                        {
                            size = _options.EmbeddingDimensions,
                            distance = "Cosine"
                        },
                        hnsw_config = new { m = 16, ef_construct = 128 }
                    })
                };
                using var response = await httpClient.SendAsync(create, cancellationToken)
                    .ConfigureAwait(false);
                var body = await response.Content.ReadAsStringAsync(cancellationToken)
                    .ConfigureAwait(false);
                if (!response.IsSuccessStatusCode
                    && !body.Contains("already exists", StringComparison.OrdinalIgnoreCase))
                {
                    throw new InvalidOperationException(
                        $"Qdrant AI collection create failed: {response.StatusCode} {body}");
                }
            }

            _ready = true;
            logger.LogInformation(
                "AI knowledge collection ready: {Collection} ({Dimensions} dims)",
                _options.Collection,
                _options.EmbeddingDimensions);
        }
        finally
        {
            _ensureLock.Release();
        }
    }

    public async Task<long> GetCountAsync(CancellationToken cancellationToken = default)
    {
        await EnsureCollectionAsync(cancellationToken).ConfigureAwait(false);
        ApplyAuth();
        var collection = Uri.EscapeDataString(_options.Collection);
        using var response = await httpClient.GetAsync(
            $"collections/{collection}",
            cancellationToken).ConfigureAwait(false);
        if (!response.IsSuccessStatusCode) return 0;

        using var doc = JsonDocument.Parse(
            await response.Content.ReadAsStringAsync(cancellationToken).ConfigureAwait(false));
        return doc.RootElement.GetProperty("result").TryGetProperty("points_count", out var count)
            ? count.GetInt64()
            : 0;
    }

    public async Task UpsertAsync(
        IReadOnlyList<(AiKnowledgeChunk Chunk, float[] Vector)> chunks,
        CancellationToken cancellationToken = default)
    {
        if (chunks.Count == 0) return;
        await EnsureCollectionAsync(cancellationToken).ConfigureAwait(false);
        ApplyAuth();
        var collection = Uri.EscapeDataString(_options.Collection);
        var points = chunks.Select(x => new
        {
            id = x.Chunk.Id,
            vector = x.Vector,
            payload = new
            {
                source = x.Chunk.Source,
                title = x.Chunk.Title,
                language = x.Chunk.Language,
                audiences = x.Chunk.Audiences,
                content = x.Chunk.Content
            }
        });

        using var request = new HttpRequestMessage(
            HttpMethod.Put,
            $"collections/{collection}/points?wait=true")
        {
            Content = JsonContent(new { points })
        };
        using var response = await httpClient.SendAsync(request, cancellationToken)
            .ConfigureAwait(false);
        var body = await response.Content.ReadAsStringAsync(cancellationToken).ConfigureAwait(false);
        if (!response.IsSuccessStatusCode)
        {
            throw new InvalidOperationException(
                $"Qdrant AI upsert failed: {response.StatusCode} {body}");
        }
    }

    public async Task<IReadOnlyList<AiKnowledgeHit>> SearchAsync(
        float[] vector,
        string audience,
        int limit,
        CancellationToken cancellationToken = default,
        double? minScore = null)
    {
        await EnsureCollectionAsync(cancellationToken).ConfigureAwait(false);
        ApplyAuth();
        var collection = Uri.EscapeDataString(_options.Collection);
        var payload = new
        {
            query = vector,
            filter = new
            {
                should = new object[]
                {
                    new { key = "audiences", match = new { value = "public" } },
                    new { key = "audiences", match = new { value = audience } }
                }
            },
            limit = Math.Clamp(limit, 1, 12),
            with_payload = true,
            score_threshold = minScore ?? _options.MinScore
        };

        using var request = new HttpRequestMessage(
            HttpMethod.Post,
            $"collections/{collection}/points/query")
        {
            Content = JsonContent(payload)
        };
        using var response = await httpClient.SendAsync(request, cancellationToken)
            .ConfigureAwait(false);
        var body = await response.Content.ReadAsStringAsync(cancellationToken).ConfigureAwait(false);
        if (!response.IsSuccessStatusCode)
        {
            throw new InvalidOperationException(
                $"Qdrant AI query failed: {response.StatusCode} {body}");
        }

        using var doc = JsonDocument.Parse(body);
        if (!doc.RootElement.GetProperty("result").TryGetProperty("points", out var points))
        {
            return [];
        }

        var hits = new List<AiKnowledgeHit>();
        foreach (var point in points.EnumerateArray())
        {
            if (!point.TryGetProperty("payload", out var item)) continue;
            hits.Add(new AiKnowledgeHit(
                item.TryGetProperty("source", out var source) ? source.GetString() ?? "" : "",
                item.TryGetProperty("title", out var title) ? title.GetString() ?? "" : "",
                item.TryGetProperty("content", out var content) ? content.GetString() ?? "" : "",
                point.TryGetProperty("score", out var score) ? score.GetDouble() : 0));
        }

        return hits;
    }

    private void ApplyAuth()
    {
        if (!string.IsNullOrWhiteSpace(_options.QdrantApiKey))
        {
            httpClient.DefaultRequestHeaders.Remove("api-key");
            httpClient.DefaultRequestHeaders.TryAddWithoutValidation("api-key", _options.QdrantApiKey);
        }
    }

    private static StringContent JsonContent(object value) =>
        new(JsonSerializer.Serialize(value), Encoding.UTF8, "application/json");
}
