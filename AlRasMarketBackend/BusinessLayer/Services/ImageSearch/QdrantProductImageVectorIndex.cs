using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using BusinessLayer.Constants;
using BusinessLayer.Interfaces;
using BusinessLayer.Options;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace BusinessLayer.Services.ImageSearch;

public sealed class QdrantProductImageVectorIndex(
    HttpClient httpClient,
    IOptions<QdrantOptions> options,
    ILogger<QdrantProductImageVectorIndex> logger) : IProductImageVectorIndex
{
    private readonly QdrantOptions _options = options.Value;
    private readonly SemaphoreSlim _ensureLock = new(1, 1);
    private bool _collectionReady;

    public async Task EnsureCollectionAsync(CancellationToken cancellationToken = default)
    {
        if (_collectionReady)
        {
            return;
        }

        await _ensureLock.WaitAsync(cancellationToken).ConfigureAwait(false);
        try
        {
            if (_collectionReady)
            {
                return;
            }

            ApplyAuth();
            var collection = Uri.EscapeDataString(_options.Collection);
            using (var get = await httpClient.GetAsync($"/collections/{collection}", cancellationToken)
                       .ConfigureAwait(false))
            {
                if (get.IsSuccessStatusCode)
                {
                    _collectionReady = true;
                    return;
                }
            }

            var createBody = new
            {
                vectors = new
                {
                    size = _options.VectorSize,
                    distance = "Cosine"
                },
                hnsw_config = new
                {
                    m = _options.HnswM,
                    ef_construct = _options.HnswEfConstruct
                }
            };

            using var create = new HttpRequestMessage(HttpMethod.Put, $"/collections/{collection}")
            {
                Content = JsonContent(createBody)
            };
            using var createResponse = await httpClient.SendAsync(create, cancellationToken).ConfigureAwait(false);
            var createText = await createResponse.Content.ReadAsStringAsync(cancellationToken).ConfigureAwait(false);
            if (!createResponse.IsSuccessStatusCode
                && !createText.Contains("already exists", StringComparison.OrdinalIgnoreCase))
            {
                logger.LogError(
                    "Failed creating Qdrant collection {Collection}: {Status} {Body}",
                    _options.Collection,
                    (int)createResponse.StatusCode,
                    createText);
                throw new InvalidOperationException($"Qdrant collection create failed: {createResponse.StatusCode}");
            }

            _collectionReady = true;
            logger.LogInformation("Qdrant collection ready: {Collection} (HNSW)", _options.Collection);
        }
        finally
        {
            _ensureLock.Release();
        }
    }


    public async Task<long> GetPointsCountAsync(CancellationToken cancellationToken = default)
    {
        try
        {
            await EnsureCollectionAsync(cancellationToken).ConfigureAwait(false);
            ApplyAuth();
            var collection = Uri.EscapeDataString(_options.Collection);
            using var response = await httpClient.GetAsync($"/collections/{collection}", cancellationToken)
                .ConfigureAwait(false);
            if (!response.IsSuccessStatusCode)
            {
                return -1;
            }

            await using var stream = await response.Content.ReadAsStreamAsync(cancellationToken).ConfigureAwait(false);
            using var doc = await JsonDocument.ParseAsync(stream, cancellationToken: cancellationToken)
                .ConfigureAwait(false);
            if (doc.RootElement.TryGetProperty("result", out var result)
                && result.TryGetProperty("points_count", out var count)
                && count.TryGetInt64(out var n))
            {
                return n;
            }

            return -1;
        }
        catch (Exception ex)
        {
            logger.LogWarning(ex, "Failed reading Qdrant points_count for {Collection}.", _options.Collection);
            return -1;
        }
    }
    public async Task UpsertAsync(ProductImageVectorPoint point, CancellationToken cancellationToken = default)
    {
        if (point.Vector.Length == 0)
        {
            return;
        }

        await EnsureCollectionAsync(cancellationToken).ConfigureAwait(false);
        ApplyAuth();

        var collection = Uri.EscapeDataString(_options.Collection);
        var payload = new
        {
            points = new[]
            {
                new
                {
                    id = point.ProductImageId,
                    vector = point.Vector,
                    payload = new
                    {
                        productId = point.ProductId.ToString("D"),
                        productImageId = point.ProductImageId,
                        productCode = point.ProductCode ?? string.Empty,
                        productName = point.ProductName ?? string.Empty,
                        imagePath = point.ImagePath ?? string.Empty,
                        isReference = point.IsReference,
                        referenceImageId = point.ReferenceImageId,
                    }
                }
            }
        };

        using var request = new HttpRequestMessage(HttpMethod.Put, $"/collections/{collection}/points?wait=true")
        {
            Content = JsonContent(payload)
        };
        using var response = await httpClient.SendAsync(request, cancellationToken).ConfigureAwait(false);
        if (!response.IsSuccessStatusCode)
        {
            var body = await response.Content.ReadAsStringAsync(cancellationToken).ConfigureAwait(false);
            logger.LogWarning(
                "Qdrant upsert failed for image {ImageId}: {Status} {Body}",
                point.ProductImageId,
                (int)response.StatusCode,
                body);
        }
    }

    public async Task DeleteByProductImageIdAsync(long productImageId, CancellationToken cancellationToken = default)
    {
        await EnsureCollectionAsync(cancellationToken).ConfigureAwait(false);
        ApplyAuth();
        var collection = Uri.EscapeDataString(_options.Collection);
        var payload = new { points = new object[] { productImageId } };
        using var request = new HttpRequestMessage(HttpMethod.Post, $"/collections/{collection}/points/delete?wait=true")
        {
            Content = JsonContent(payload)
        };
        using var response = await httpClient.SendAsync(request, cancellationToken).ConfigureAwait(false);
        if (!response.IsSuccessStatusCode)
        {
            var body = await response.Content.ReadAsStringAsync(cancellationToken).ConfigureAwait(false);
            logger.LogWarning(
                "Qdrant delete image {ImageId} failed: {Status} {Body}",
                productImageId,
                (int)response.StatusCode,
                body);
        }
    }

    public async Task DeleteByProductIdAsync(Guid productId, CancellationToken cancellationToken = default)
    {
        await EnsureCollectionAsync(cancellationToken).ConfigureAwait(false);
        ApplyAuth();
        var collection = Uri.EscapeDataString(_options.Collection);
        var payload = new
        {
            filter = new
            {
                must = new object[]
                {
                    new
                    {
                        key = "productId",
                        match = new { value = productId.ToString("D") }
                    }
                }
            }
        };
        using var request = new HttpRequestMessage(HttpMethod.Post, $"/collections/{collection}/points/delete?wait=true")
        {
            Content = JsonContent(payload)
        };
        using var response = await httpClient.SendAsync(request, cancellationToken).ConfigureAwait(false);
        if (!response.IsSuccessStatusCode)
        {
            var body = await response.Content.ReadAsStringAsync(cancellationToken).ConfigureAwait(false);
            logger.LogWarning(
                "Qdrant delete product {ProductId} failed: {Status} {Body}",
                productId,
                (int)response.StatusCode,
                body);
        }
    }

    public async Task<IReadOnlyList<ProductImageVectorHit>> SearchSimilarAsync(
        float[] queryVector,
        CancellationToken cancellationToken = default)
    {
        if (queryVector.Length == 0)
        {
            return [];
        }

        await EnsureCollectionAsync(cancellationToken).ConfigureAwait(false);
        ApplyAuth();
        var collection = Uri.EscapeDataString(_options.Collection);

        var payload = new Dictionary<string, object?>
        {
            ["vector"] = queryVector,
            ["limit"] = Math.Clamp(_options.MaxResults, 1, 100),
            ["with_payload"] = true,
            ["score_threshold"] = _options.MinScore,
            ["params"] = new Dictionary<string, object>
            {
                ["hnsw_ef"] = _options.SearchEf
            }
        };

        using var request = new HttpRequestMessage(HttpMethod.Post, $"/collections/{collection}/points/search")
        {
            Content = JsonContent(payload)
        };
        using var response = await httpClient.SendAsync(request, cancellationToken).ConfigureAwait(false);
        var body = await response.Content.ReadAsStringAsync(cancellationToken).ConfigureAwait(false);
        if (!response.IsSuccessStatusCode)
        {
            logger.LogWarning("Qdrant search failed: {Status} {Body}", (int)response.StatusCode, body);
            return [];
        }

        var hits = ParseHits(body);
        if (hits.Count == 0)
        {
            return hits;
        }

        // Keep only a tight cluster around the best match (very similar results).
        var best = hits[0].Score;
        if (best < _options.MinScore)
        {
            return [];
        }

        var floor = Math.Max(_options.MinScore, best - _options.ScoreClusterWindow);
        return hits.Where(h => h.Score >= floor).ToList();
    }

    private List<ProductImageVectorHit> ParseHits(string body)
    {
        var list = new List<ProductImageVectorHit>();
        try
        {
            using var doc = JsonDocument.Parse(body);
            if (!doc.RootElement.TryGetProperty("result", out var result)
                || result.ValueKind != JsonValueKind.Array)
            {
                return list;
            }

            foreach (var item in result.EnumerateArray())
            {
                var score = item.TryGetProperty("score", out var scoreEl) ? scoreEl.GetSingle() : 0f;
                var payload = item.TryGetProperty("payload", out var p) ? p : default;
                var isReference = ReadPayloadBool(payload, "isReference");

                long imageId = 0;
                if (payload.ValueKind == JsonValueKind.Object
                    && payload.TryGetProperty("productImageId", out var imgEl))
                {
                    if (imgEl.ValueKind == JsonValueKind.Number)
                    {
                        imageId = imgEl.GetInt64();
                    }
                    else
                    {
                        _ = long.TryParse(imgEl.GetString(), out imageId);
                    }
                }

                long referenceImageId = 0;
                if (isReference)
                {
                    referenceImageId = ReadPayloadLong(payload, "referenceImageId");
                    if (referenceImageId <= 0 && ClipVectorIds.IsReferencePointId(imageId))
                    {
                        referenceImageId = ClipVectorIds.ToReferenceImageId(imageId);
                    }
                }

                Guid productId;
                if (isReference)
                {
                    productId = ClipVectorIds.ReferenceProductId;
                }
                else
                {
                    var productIdRaw = ReadPayloadString(payload, "productId");
                    if (!Guid.TryParse(productIdRaw, out productId))
                    {
                        continue;
                    }
                }

                list.Add(new ProductImageVectorHit
                {
                    ProductId = productId,
                    ProductImageId = imageId,
                    ProductCode = ReadPayloadString(payload, "productCode"),
                    ProductName = ReadPayloadString(payload, "productName"),
                    ImagePath = ReadPayloadString(payload, "imagePath"),
                    Score = score,
                    IsReference = isReference,
                    ReferenceImageId = referenceImageId,
                });
            }
        }
        catch (Exception ex)
        {
            logger.LogWarning(ex, "Failed parsing Qdrant search response");
        }

        return list;
    }

    private static string ReadPayloadString(JsonElement payload, string key)
    {
        if (payload.ValueKind != JsonValueKind.Object || !payload.TryGetProperty(key, out var el))
        {
            return string.Empty;
        }

        return el.ValueKind switch
        {
            JsonValueKind.String => el.GetString()?.Trim() ?? string.Empty,
            JsonValueKind.Number => el.ToString(),
            JsonValueKind.True => "true",
            JsonValueKind.False => "false",
            _ => string.Empty
        };
    }

    private static bool ReadPayloadBool(JsonElement payload, string key)
    {
        if (payload.ValueKind != JsonValueKind.Object || !payload.TryGetProperty(key, out var el))
        {
            return false;
        }

        return el.ValueKind switch
        {
            JsonValueKind.True => true,
            JsonValueKind.False => false,
            JsonValueKind.String => bool.TryParse(el.GetString(), out var b) && b,
            JsonValueKind.Number => el.TryGetInt32(out var n) && n != 0,
            _ => false
        };
    }

    private static long ReadPayloadLong(JsonElement payload, string key)
    {
        if (payload.ValueKind != JsonValueKind.Object || !payload.TryGetProperty(key, out var el))
        {
            return 0;
        }

        if (el.ValueKind == JsonValueKind.Number && el.TryGetInt64(out var n))
        {
            return n;
        }

        return long.TryParse(el.GetString(), out var parsed) ? parsed : 0;
    }

    private void ApplyAuth()
    {
        httpClient.DefaultRequestHeaders.Remove("api-key");
        if (!string.IsNullOrWhiteSpace(_options.ApiKey))
        {
            httpClient.DefaultRequestHeaders.TryAddWithoutValidation("api-key", _options.ApiKey);
        }
    }

    private static StringContent JsonContent(object value) =>
        new(JsonSerializer.Serialize(value), Encoding.UTF8, "application/json");
}
