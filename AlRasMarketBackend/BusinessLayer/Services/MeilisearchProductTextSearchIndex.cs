using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using System.Text.Json.Serialization;
using BusinessLayer.Interfaces;
using BusinessLayer.Options;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace BusinessLayer.Services;

public sealed class MeilisearchProductTextSearchIndex(
    HttpClient httpClient,
    IOptions<MeilisearchOptions> options,
    ILogger<MeilisearchProductTextSearchIndex> logger) : IProductTextSearchIndex
{
    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
        DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull
    };

    private readonly MeilisearchOptions _options = options.Value;
    private static readonly SemaphoreSlim EnsureLock = new(1, 1);
    // Shared across typed-HttpClient instances so every search does not re-PATCH settings.
    private static int _indexReadyFlag;

    public bool IsEnabled => _options.Enabled && !string.IsNullOrWhiteSpace(_options.Url);

    public async Task EnsureIndexAsync(CancellationToken cancellationToken = default)
    {
        if (!IsEnabled)
        {
            return;
        }

        if (Volatile.Read(ref _indexReadyFlag) == 1)
        {
            return;
        }

        await EnsureLock.WaitAsync(cancellationToken).ConfigureAwait(false);
        try
        {
            if (Volatile.Read(ref _indexReadyFlag) == 1)
            {
                return;
            }

            ApplyAuth();
            var uid = Uri.EscapeDataString(_options.IndexUid);

            using (var get = await httpClient.GetAsync($"indexes/{uid}", cancellationToken).ConfigureAwait(false))
            {
                if (!get.IsSuccessStatusCode)
                {
                    using var create = new HttpRequestMessage(HttpMethod.Post, "indexes")
                    {
                        Content = JsonContent(new { uid = _options.IndexUid, primaryKey = "id" })
                    };
                    using var createResponse =
                        await httpClient.SendAsync(create, cancellationToken).ConfigureAwait(false);
                    var createBody =
                        await createResponse.Content.ReadAsStringAsync(cancellationToken).ConfigureAwait(false);
                    if (!createResponse.IsSuccessStatusCode
                        && !createBody.Contains("index_already_exists", StringComparison.OrdinalIgnoreCase)
                        && !createBody.Contains("already exists", StringComparison.OrdinalIgnoreCase))
                    {
                        logger.LogError(
                            "Meilisearch create index failed: {Status} {Body}",
                            (int)createResponse.StatusCode,
                            createBody);
                        throw new InvalidOperationException(
                            $"Meilisearch create index failed: {createResponse.StatusCode}");
                    }
                }
            }

            var settings = new
            {
                searchableAttributes = new[]
                {
                    "nameEn",
                    "nameAr",
                    "productCode",
                    "suggestLabels",
                    "categoryNameEn",
                    "categoryNameAr",
                    "productTypeName",
                    "descriptionEn",
                    "descriptionAr",
                    "retailDescriptionEn",
                    "retailDescriptionAr",
                    "supplierNotesEn",
                    "supplierNotesAr",
                    "shippingDescriptionEn",
                    "shippingDescriptionAr"
                },
                filterableAttributes = new[] { "isPublic" },
                sortableAttributes = new[] { "createdAtUnix" },
                displayedAttributes = new[]
                {
                    "id",
                    "productId",
                    "productCode",
                    "nameEn",
                    "nameAr",
                    "suggestLabels",
                    "createdAtUnix",
                    "isPublic"
                },
                typoTolerance = new
                {
                    enabled = true,
                    minWordSizeForTypos = new { oneTypo = 5, twoTypos = 9 }
                },
                pagination = new { maxTotalHits = Math.Max(1000, _options.MaxSearchHits) },
                synonyms = new Dictionary<string, string[]>
                {
                    ["cocoa"] = ["coco", "kakao", "كاكو", "كوكو", "كاكاو", "كاكاوه", "كاكاوية"],
                    ["coco"] = ["cocoa", "kakao", "كاكو", "كوكو", "كاكاو"],
                    ["كاكاو"] = ["cocoa", "coco", "كاكو", "كوكو", "كاكاوه"],
                    ["كوكو"] = ["cocoa", "coco", "كاكاو", "كاكو"],
                    ["cardamom"] = ["cardamon", "هيل", "الهيل", "حب الهان"],
                    ["هيل"] = ["cardamom", "الهيل", "حب الهان"],
                    ["coffee"] = ["قهوة", "بن", "القهوة"],
                    ["قهوة"] = ["coffee", "بن", "القهوة"],
                    ["بن"] = ["coffee", "قهوة"],
                    ["tea"] = ["شاي", "الشاي"],
                    ["شاي"] = ["tea", "الشاي"]
                }
            };

            using var patch = new HttpRequestMessage(HttpMethod.Patch, $"indexes/{uid}/settings")
            {
                Content = JsonContent(settings)
            };
            using var patchResponse = await httpClient.SendAsync(patch, cancellationToken).ConfigureAwait(false);
            if (!patchResponse.IsSuccessStatusCode)
            {
                var body = await patchResponse.Content.ReadAsStringAsync(cancellationToken).ConfigureAwait(false);
                logger.LogWarning(
                    "Meilisearch settings update returned {Status}: {Body}",
                    (int)patchResponse.StatusCode,
                    body);
            }

            Volatile.Write(ref _indexReadyFlag, 1);
            logger.LogInformation("Meilisearch index ready: {Index}", _options.IndexUid);
        }
        finally
        {
            EnsureLock.Release();
        }
    }

    public Task UpsertAsync(ProductTextSearchDocument document, CancellationToken cancellationToken = default) =>
        UpsertManyAsync([document], cancellationToken);

    public async Task UpsertManyAsync(
        IReadOnlyList<ProductTextSearchDocument> documents,
        CancellationToken cancellationToken = default)
    {
        if (!IsEnabled || documents.Count == 0)
        {
            return;
        }

        await EnsureIndexAsync(cancellationToken).ConfigureAwait(false);
        ApplyAuth();

        var payload = documents.Select(ToMeiliDocument).ToList();
        var uid = Uri.EscapeDataString(_options.IndexUid);
        using var request = new HttpRequestMessage(HttpMethod.Post, $"indexes/{uid}/documents")
        {
            Content = JsonContent(payload)
        };
        using var response = await httpClient.SendAsync(request, cancellationToken).ConfigureAwait(false);
        if (!response.IsSuccessStatusCode)
        {
            var body = await response.Content.ReadAsStringAsync(cancellationToken).ConfigureAwait(false);
            logger.LogWarning(
                "Meilisearch upsert failed ({Count} docs): {Status} {Body}",
                documents.Count,
                (int)response.StatusCode,
                body);
        }
    }

    public async Task DeleteAsync(Guid productId, CancellationToken cancellationToken = default)
    {
        if (!IsEnabled)
        {
            return;
        }

        await EnsureIndexAsync(cancellationToken).ConfigureAwait(false);
        ApplyAuth();

        var uid = Uri.EscapeDataString(_options.IndexUid);
        var id = Uri.EscapeDataString(productId.ToString("D"));
        using var response = await httpClient
            .DeleteAsync($"indexes/{uid}/documents/{id}", cancellationToken)
            .ConfigureAwait(false);
        if (!response.IsSuccessStatusCode && response.StatusCode != System.Net.HttpStatusCode.NotFound)
        {
            var body = await response.Content.ReadAsStringAsync(cancellationToken).ConfigureAwait(false);
            logger.LogWarning(
                "Meilisearch delete failed for {ProductId}: {Status} {Body}",
                productId,
                (int)response.StatusCode,
                body);
        }
    }

    public async Task<ProductTextSearchPage> SearchAsync(
        string query,
        int limit,
        CancellationToken cancellationToken = default)
    {
        if (!IsEnabled || string.IsNullOrWhiteSpace(query))
        {
            return new ProductTextSearchPage();
        }

        // Hot path: skip EnsureIndex (settings PATCH). Bootstrap/sync owns index setup.
        ApplyAuth();

        var take = Math.Clamp(limit, 1, Math.Max(1, _options.MaxSearchHits));
        var uid = Uri.EscapeDataString(_options.IndexUid);
        var body = new
        {
            q = query.Trim(),
            filter = "isPublic = true",
            limit = take,
            offset = 0,
            sort = new[] { "createdAtUnix:desc" },
            attributesToRetrieve = new[] { "id", "productId", "createdAtUnix" },
            matchingStrategy = "last"
        };

        using var request = new HttpRequestMessage(HttpMethod.Post, $"indexes/{uid}/search")
        {
            Content = JsonContent(body)
        };
        using var response = await httpClient.SendAsync(request, cancellationToken).ConfigureAwait(false);
        var json = await response.Content.ReadAsStringAsync(cancellationToken).ConfigureAwait(false);
        if (!response.IsSuccessStatusCode)
        {
            logger.LogWarning(
                "Meilisearch search failed: {Status} {Body}",
                (int)response.StatusCode,
                json);
            return new ProductTextSearchPage();
        }

        using var doc = JsonDocument.Parse(json);
        var root = doc.RootElement;
        var estimated = root.TryGetProperty("estimatedTotalHits", out var eth)
            ? eth.GetInt32()
            : root.TryGetProperty("nbHits", out var nb)
                ? nb.GetInt32()
                : 0;

        var hits = new List<ProductTextSearchHit>();
        if (root.TryGetProperty("hits", out var hitsEl) && hitsEl.ValueKind == JsonValueKind.Array)
        {
            foreach (var hit in hitsEl.EnumerateArray())
            {
                var idText = hit.TryGetProperty("id", out var idProp)
                    ? idProp.GetString()
                    : hit.TryGetProperty("productId", out var pidProp)
                        ? pidProp.GetString()
                        : null;
                if (!Guid.TryParse(idText, out var productId))
                {
                    continue;
                }

                var created = hit.TryGetProperty("createdAtUnix", out var createdProp)
                    ? createdProp.GetInt64()
                    : 0L;
                hits.Add(new ProductTextSearchHit
                {
                    ProductId = productId,
                    CreatedAtUnix = created
                });
            }
        }

        return new ProductTextSearchPage
        {
            Hits = hits,
            EstimatedTotal = estimated > 0 ? estimated : hits.Count
        };
    }

    public async Task<IReadOnlyList<string>> SuggestAsync(
        string query,
        int limit,
        CancellationToken cancellationToken = default)
    {
        if (!IsEnabled || string.IsNullOrWhiteSpace(query))
        {
            return [];
        }

        // Hot path: skip EnsureIndex (settings PATCH). Bootstrap/sync owns index setup.
        ApplyAuth();

        var take = Math.Clamp(limit, 1, 20);
        var uid = Uri.EscapeDataString(_options.IndexUid);
        var body = new
        {
            q = query.Trim(),
            filter = "isPublic = true",
            limit = Math.Max(take * 3, 12),
            attributesToRetrieve = new[] { "suggestLabels", "nameEn", "nameAr", "productCode" },
            matchingStrategy = "last"
        };

        using var request = new HttpRequestMessage(HttpMethod.Post, $"indexes/{uid}/search")
        {
            Content = JsonContent(body)
        };
        using var response = await httpClient.SendAsync(request, cancellationToken).ConfigureAwait(false);
        var json = await response.Content.ReadAsStringAsync(cancellationToken).ConfigureAwait(false);
        if (!response.IsSuccessStatusCode)
        {
            logger.LogWarning(
                "Meilisearch suggest failed: {Status} {Body}",
                (int)response.StatusCode,
                json);
            return [];
        }

        var needle = query.Trim();
        var suggestions = new List<string>();
        var seen = new HashSet<string>(StringComparer.OrdinalIgnoreCase);

        using var doc = JsonDocument.Parse(json);
        if (!doc.RootElement.TryGetProperty("hits", out var hitsEl)
            || hitsEl.ValueKind != JsonValueKind.Array)
        {
            return [];
        }

        foreach (var hit in hitsEl.EnumerateArray())
        {
            void TryAdd(string? value)
            {
                var label = value?.Trim();
                if (string.IsNullOrWhiteSpace(label))
                {
                    return;
                }

                if (!label.Contains(needle, StringComparison.OrdinalIgnoreCase)
                    && !needle.Contains(label, StringComparison.OrdinalIgnoreCase)
                    && label.Length > needle.Length + 8)
                {
                    // Prefer labels that visually relate to the typed query.
                    // Still allow Meili typo hits that do not contain the exact substring.
                }

                if (seen.Add(label))
                {
                    suggestions.Add(label);
                }
            }

            if (hit.TryGetProperty("suggestLabels", out var labels)
                && labels.ValueKind == JsonValueKind.Array)
            {
                foreach (var label in labels.EnumerateArray())
                {
                    TryAdd(label.GetString());
                    if (suggestions.Count >= take)
                    {
                        return suggestions;
                    }
                }
            }

            TryAdd(hit.TryGetProperty("nameEn", out var ne) ? ne.GetString() : null);
            if (suggestions.Count >= take)
            {
                return suggestions;
            }

            TryAdd(hit.TryGetProperty("nameAr", out var na) ? na.GetString() : null);
            if (suggestions.Count >= take)
            {
                return suggestions;
            }

            TryAdd(hit.TryGetProperty("productCode", out var pc) ? pc.GetString() : null);
            if (suggestions.Count >= take)
            {
                return suggestions;
            }
        }

        return suggestions;
    }

    public async Task<long> GetDocumentCountAsync(CancellationToken cancellationToken = default)
    {
        if (!IsEnabled)
        {
            return 0;
        }

        await EnsureIndexAsync(cancellationToken).ConfigureAwait(false);
        ApplyAuth();

        var uid = Uri.EscapeDataString(_options.IndexUid);
        using var response = await httpClient
            .GetAsync($"indexes/{uid}/stats", cancellationToken)
            .ConfigureAwait(false);
        if (!response.IsSuccessStatusCode)
        {
            return 0;
        }

        var json = await response.Content.ReadAsStringAsync(cancellationToken).ConfigureAwait(false);
        using var doc = JsonDocument.Parse(json);
        if (doc.RootElement.TryGetProperty("numberOfDocuments", out var count))
        {
            return count.GetInt64();
        }

        return 0;
    }

    private static object ToMeiliDocument(ProductTextSearchDocument d) => new
    {
        id = d.ProductId.ToString("D"),
        productId = d.ProductId.ToString("D"),
        productCode = d.ProductCode,
        nameEn = d.NameEn,
        nameAr = d.NameAr,
        categoryNameEn = d.CategoryNameEn,
        categoryNameAr = d.CategoryNameAr,
        productTypeName = d.ProductTypeName,
        descriptionEn = d.DescriptionEn,
        descriptionAr = d.DescriptionAr,
        retailDescriptionEn = d.RetailDescriptionEn,
        retailDescriptionAr = d.RetailDescriptionAr,
        supplierNotesEn = d.SupplierNotesEn,
        supplierNotesAr = d.SupplierNotesAr,
        shippingDescriptionEn = d.ShippingDescriptionEn,
        shippingDescriptionAr = d.ShippingDescriptionAr,
        suggestLabels = d.SuggestLabels,
        createdAtUnix = d.CreatedAtUnix,
        isPublic = d.IsPublic
    };

    private void ApplyAuth()
    {
        httpClient.DefaultRequestHeaders.Remove("Authorization");
        if (!string.IsNullOrWhiteSpace(_options.ApiKey))
        {
            httpClient.DefaultRequestHeaders.Authorization =
                new AuthenticationHeaderValue("Bearer", _options.ApiKey.Trim());
        }
    }

    private static StringContent JsonContent(object value) =>
        new(JsonSerializer.Serialize(value, JsonOptions), Encoding.UTF8, "application/json");
}
