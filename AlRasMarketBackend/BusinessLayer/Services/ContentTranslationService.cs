using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using BusinessLayer.Interfaces;
using DataLayer.Interfaces;
using DataLayer.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;

namespace BusinessLayer.Services;

public class ContentTranslationService(
    IRasAlSouqDbContext dbContext,
    IHttpClientFactory httpClientFactory,
    IConfiguration configuration,
    ILogger<ContentTranslationService> logger) : IContentTranslationService
{
    public async Task UpsertProductFieldsAsync(
        Guid productId,
        string? name,
        string? description,
        string? retailDescription,
        string? supplierNotes = null,
        string? shippingDescription = null,
        CancellationToken cancellationToken = default)
    {
        // Same field set and per-field semantics as before; OpenAI calls run in parallel,
        // DB writes stay sequential (EF DbContext is not thread-safe).
        var fields = new (string Field, string? Text)[]
        {
            (ContentTranslationFields.Name, name),
            (ContentTranslationFields.Description, description),
            (ContentTranslationFields.RetailDescription, retailDescription),
            (ContentTranslationFields.SupplierNotes, supplierNotes),
            (ContentTranslationFields.ShippingDescription, shippingDescription)
        };

        var pending = new List<PendingFieldTranslation>(fields.Length);
        foreach (var (field, text) in fields)
        {
            var prepared = await PrepareFieldAsync(
                ContentTranslationScopes.Product,
                productId,
                orderId: null,
                field,
                text,
                cancellationToken);
            if (prepared is not null)
            {
                pending.Add(prepared);
            }
        }

        if (pending.Count == 0)
        {
            return;
        }

        await Task.WhenAll(pending.Select(async item =>
        {
            try
            {
                if (item.SourceLang == "ar")
                {
                    item.TextAr = item.Trimmed;
                    item.TextEn = await TranslateAsync(item.Trimmed, "ar", "en", cancellationToken);
                }
                else
                {
                    item.TextEn = item.Trimmed;
                    item.TextAr = await TranslateAsync(item.Trimmed, "en", "ar", cancellationToken);
                }
            }
            catch (Exception ex)
            {
                logger.LogWarning(
                    ex,
                    "AI translation failed for {Scope}/{Field}; storing source language only.",
                    item.Scope,
                    item.Field);
                item.TextAr = item.SourceLang == "ar" ? item.Trimmed : item.Existing?.TextAr;
                item.TextEn = item.SourceLang == "en" ? item.Trimmed : item.Existing?.TextEn;
            }
        }));

        foreach (var item in pending)
        {
            await PersistFieldAsync(item, cancellationToken);
        }
    }

    public async Task UpsertOrderOfferNotesAsync(
        long orderId,
        string? notes,
        CancellationToken cancellationToken = default)
    {
        await UpsertFieldAsync(
            ContentTranslationScopes.Order,
            productId: null,
            orderId,
            ContentTranslationFields.OfferNotes,
            notes,
            cancellationToken);
    }

    public async Task<IReadOnlyDictionary<Guid, ProductFieldTranslations>> GetProductTranslationsAsync(
        IEnumerable<Guid> productIds,
        CancellationToken cancellationToken = default)
    {
        var ids = productIds.Distinct().ToList();
        if (ids.Count == 0)
        {
            return new Dictionary<Guid, ProductFieldTranslations>();
        }

        var rows = await dbContext.ContentTranslations.AsNoTracking()
            .Where(x =>
                x.Scope == ContentTranslationScopes.Product
                && x.ProductId != null
                && ids.Contains(x.ProductId.Value)
                && (x.Field == ContentTranslationFields.Name
                    || x.Field == ContentTranslationFields.Description
                    || x.Field == ContentTranslationFields.RetailDescription
                    || x.Field == ContentTranslationFields.SupplierNotes
                    || x.Field == ContentTranslationFields.ShippingDescription))
            .ToListAsync(cancellationToken);

        var map = new Dictionary<Guid, ProductFieldTranslations>();
        foreach (var group in rows.GroupBy(x => x.ProductId!.Value))
        {
            string? nameAr = null, nameEn = null, descAr = null, descEn = null, retailAr = null, retailEn = null;
            string? supplierAr = null, supplierEn = null, shippingAr = null, shippingEn = null;
            foreach (var row in group)
            {
                switch (row.Field)
                {
                    case ContentTranslationFields.Name:
                        nameAr = row.TextAr;
                        nameEn = row.TextEn;
                        break;
                    case ContentTranslationFields.Description:
                        descAr = row.TextAr;
                        descEn = row.TextEn;
                        break;
                    case ContentTranslationFields.RetailDescription:
                        retailAr = row.TextAr;
                        retailEn = row.TextEn;
                        break;
                    case ContentTranslationFields.SupplierNotes:
                        supplierAr = row.TextAr;
                        supplierEn = row.TextEn;
                        break;
                    case ContentTranslationFields.ShippingDescription:
                        shippingAr = row.TextAr;
                        shippingEn = row.TextEn;
                        break;
                }
            }

            map[group.Key] = new ProductFieldTranslations
            {
                NameAr = nameAr,
                NameEn = nameEn,
                DescriptionAr = descAr,
                DescriptionEn = descEn,
                RetailDescriptionAr = retailAr,
                RetailDescriptionEn = retailEn,
                SupplierNotesAr = supplierAr,
                SupplierNotesEn = supplierEn,
                ShippingDescriptionAr = shippingAr,
                ShippingDescriptionEn = shippingEn
            };
        }

        return map;
    }

    private async Task UpsertFieldAsync(
        string scope,
        Guid? productId,
        long? orderId,
        string field,
        string? sourceText,
        CancellationToken cancellationToken)
    {
        var prepared = await PrepareFieldAsync(scope, productId, orderId, field, sourceText, cancellationToken);
        if (prepared is null)
        {
            return;
        }

        try
        {
            if (prepared.SourceLang == "ar")
            {
                prepared.TextAr = prepared.Trimmed;
                prepared.TextEn = await TranslateAsync(prepared.Trimmed, "ar", "en", cancellationToken);
            }
            else
            {
                prepared.TextEn = prepared.Trimmed;
                prepared.TextAr = await TranslateAsync(prepared.Trimmed, "en", "ar", cancellationToken);
            }
        }
        catch (Exception ex)
        {
            logger.LogWarning(
                ex,
                "AI translation failed for {Scope}/{Field}; storing source language only.",
                scope,
                field);
            prepared.TextAr = prepared.SourceLang == "ar" ? prepared.Trimmed : prepared.Existing?.TextAr;
            prepared.TextEn = prepared.SourceLang == "en" ? prepared.Trimmed : prepared.Existing?.TextEn;
        }

        await PersistFieldAsync(prepared, cancellationToken);
    }

    private async Task<PendingFieldTranslation?> PrepareFieldAsync(
        string scope,
        Guid? productId,
        long? orderId,
        string field,
        string? sourceText,
        CancellationToken cancellationToken)
    {
        var trimmed = string.IsNullOrWhiteSpace(sourceText) ? null : sourceText.Trim();
        if (trimmed is null)
        {
            // Clear stored translation when source is emptied.
            var existingEmpty = await FindRowAsync(scope, productId, orderId, field, cancellationToken);
            if (existingEmpty is not null)
            {
                dbContext.ContentTranslations.Remove(existingEmpty);
                await dbContext.SaveChangesAsync(cancellationToken);
            }

            return null;
        }

        var hash = ComputeHash(trimmed);
        var existing = await FindRowAsync(scope, productId, orderId, field, cancellationToken);
        if (existing is not null
            && string.Equals(existing.SourceHash, hash, StringComparison.OrdinalIgnoreCase))
        {
            return null;
        }

        return new PendingFieldTranslation
        {
            Scope = scope,
            ProductId = productId,
            OrderId = orderId,
            Field = field,
            Trimmed = trimmed,
            Hash = hash,
            SourceLang = DetectLanguage(trimmed),
            Existing = existing
        };
    }

    private async Task PersistFieldAsync(PendingFieldTranslation item, CancellationToken cancellationToken)
    {
        if (item.Existing is null)
        {
            dbContext.ContentTranslations.Add(new ContentTranslation
            {
                Id = Guid.NewGuid(),
                Scope = item.Scope,
                ProductId = item.ProductId,
                OrderId = item.OrderId,
                Field = item.Field,
                TextAr = item.TextAr,
                TextEn = item.TextEn,
                SourceLanguage = item.SourceLang,
                SourceHash = item.Hash,
                UpdatedAtUtc = DateTime.UtcNow
            });
        }
        else
        {
            item.Existing.TextAr = item.TextAr;
            item.Existing.TextEn = item.TextEn;
            item.Existing.SourceLanguage = item.SourceLang;
            item.Existing.SourceHash = item.Hash;
            item.Existing.UpdatedAtUtc = DateTime.UtcNow;
        }

        await dbContext.SaveChangesAsync(cancellationToken);
    }

    private async Task<ContentTranslation?> FindRowAsync(
        string scope,
        Guid? productId,
        long? orderId,
        string field,
        CancellationToken cancellationToken)
    {
        if (scope == ContentTranslationScopes.Product && productId.HasValue)
        {
            return await dbContext.ContentTranslations
                .FirstOrDefaultAsync(
                    x => x.Scope == scope && x.ProductId == productId && x.Field == field,
                    cancellationToken);
        }

        if (scope == ContentTranslationScopes.Order && orderId.HasValue)
        {
            return await dbContext.ContentTranslations
                .FirstOrDefaultAsync(
                    x => x.Scope == scope && x.OrderId == orderId && x.Field == field,
                    cancellationToken);
        }

        return null;
    }

    private static string DetectLanguage(string text)
    {
        var arabic = 0;
        var latin = 0;
        foreach (var ch in text)
        {
            if (ch is >= '\u0600' and <= '\u06FF'
                or >= '\u0750' and <= '\u077F'
                or >= '\u08A0' and <= '\u08FF'
                or >= '\uFB50' and <= '\uFDFF'
                or >= '\uFE70' and <= '\uFEFF')
            {
                arabic++;
            }
            else if (char.IsLetter(ch))
            {
                latin++;
            }
        }

        return arabic > latin ? "ar" : "en";
    }

    private static string ComputeHash(string text)
    {
        var bytes = SHA256.HashData(Encoding.UTF8.GetBytes(text));
        return Convert.ToHexString(bytes);
    }

    private async Task<string> TranslateAsync(
        string text,
        string fromLang,
        string toLang,
        CancellationToken cancellationToken)
    {
        var apiKey = configuration["OpenAI:ApiKey"];
        if (string.IsNullOrWhiteSpace(apiKey))
        {
            throw new InvalidOperationException("OpenAI ApiKey is not configured.");
        }

        var fromName = fromLang == "ar" ? "Arabic" : "English";
        var toName = toLang == "ar" ? "Arabic" : "English";
        var prompt =
            $"Translate the following marketplace product text from {fromName} to {toName}. " +
            "Keep product names, brand names, units, and numbers accurate. " +
            "Return ONLY JSON: {\"translation\":\"...\"}. No markdown.\n\n" +
            text;

        var payload = new
        {
            model = "gpt-4o-mini",
            temperature = 0.1,
            response_format = new { type = "json_object" },
            messages = new object[]
            {
                new { role = "user", content = prompt }
            }
        };

        using var request = new HttpRequestMessage(HttpMethod.Post, "https://api.openai.com/v1/chat/completions");
        request.Headers.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", apiKey);
        request.Content = new StringContent(JsonSerializer.Serialize(payload), Encoding.UTF8, "application/json");

        var httpClient = httpClientFactory.CreateClient(nameof(ContentTranslationService));
        using var response = await httpClient.SendAsync(request, cancellationToken);
        var body = await response.Content.ReadAsStringAsync(cancellationToken);
        if (!response.IsSuccessStatusCode)
        {
            throw new InvalidOperationException($"OpenAI translate failed: {(int)response.StatusCode} {body}");
        }

        using var doc = JsonDocument.Parse(body);
        var content = doc.RootElement
            .GetProperty("choices")[0]
            .GetProperty("message")
            .GetProperty("content")
            .GetString();

        if (string.IsNullOrWhiteSpace(content))
        {
            throw new InvalidOperationException("OpenAI returned empty translation.");
        }

        using var contentDoc = JsonDocument.Parse(content);
        if (!contentDoc.RootElement.TryGetProperty("translation", out var translationEl)
            || translationEl.ValueKind != JsonValueKind.String)
        {
            throw new InvalidOperationException("OpenAI translation JSON missing 'translation'.");
        }

        var translated = (translationEl.GetString() ?? string.Empty).Trim();
        if (string.IsNullOrWhiteSpace(translated))
        {
            throw new InvalidOperationException("OpenAI returned blank translation.");
        }

        return translated;
    }

    private sealed class PendingFieldTranslation
    {
        public required string Scope { get; init; }
        public Guid? ProductId { get; init; }
        public long? OrderId { get; init; }
        public required string Field { get; init; }
        public required string Trimmed { get; init; }
        public required string Hash { get; init; }
        public required string SourceLang { get; init; }
        public ContentTranslation? Existing { get; init; }
        public string? TextAr { get; set; }
        public string? TextEn { get; set; }
    }
}
