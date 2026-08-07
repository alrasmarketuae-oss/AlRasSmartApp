using System.Text;
using System.Text.Json;
using BusinessLayer.Dtos;
using BusinessLayer.Helpers;
using BusinessLayer.Interfaces;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;

namespace BusinessLayer.Services;

public class OpenAiVisionService(
    HttpClient httpClient,
    IConfiguration configuration,
    ILogger<OpenAiVisionService> logger) : IOpenAiVisionService
{
    private static readonly string[] AllowedCategories =
    {
        "Herbs", "Pulses", "Spices", "Nuts", "Coffee", "Cardamom", "Cocoa", "Acids",
        "Milk", "Dates", "Sugar", "Rice", "Sweets", "Canned", "Flour", "Beauty",
        "Poultry", "Frozen Foods"
    };

    public async Task<ImageProductVisionResult> SuggestProductNamesFromImageAsync(
        Stream imageStream,
        string fileName,
        CancellationToken cancellationToken = default)
    {
        var apiKey = configuration["OpenAI:ApiKey"];
        if (string.IsNullOrWhiteSpace(apiKey))
        {
            throw new InvalidOperationException("OpenAI ApiKey is not configured.");
        }

        byte[] jpegBytes;
        await using (var buffered = new MemoryStream())
        {
            await imageStream.CopyToAsync(buffered, cancellationToken).ConfigureAwait(false);
            buffered.Position = 0;
            try
            {
                jpegBytes = await ImageFileHelper.CompressToJpegBytesAsync(
                    buffered,
                    ImageCompressionOptions.SearchVision,
                    cancellationToken).ConfigureAwait(false);
            }
            catch (Exception ex)
            {
                logger.LogWarning(ex, "Image search: failed to compress upload; using raw bytes.");
                jpegBytes = buffered.ToArray();
            }
        }

        if (jpegBytes.Length == 0)
        {
            return new ImageProductVisionResult();
        }

        var dataUrl = $"data:image/jpeg;base64,{Convert.ToBase64String(jpegBytes)}";

        var prompt =
            "Identify the product in this image for a Middle East wholesale marketplace " +
            $"(categories: {string.Join(", ", AllowedCategories)}).\n" +
            "Return ONLY JSON (no markdown):\n" +
            "{\n" +
            "  \"detectedProductName\": \"\",\n" +
            "  \"detectedBrand\": \"\",\n" +
            "  \"products\":[\n" +
            "    {\"singular\":\"...\",\"plural\":\"...\"},\n" +
            "    {\"singular\":\"...\",\"plural\":\"...\"},\n" +
            "    {\"singular\":\"...\",\"plural\":\"...\"}\n" +
            "  ]\n" +
            "}\n" +
            "Rules:\n" +
            "- detectedProductName: exact product name printed on packaging/label if clearly readable; " +
            "otherwise empty string. Prefer English when bilingual; keep Arabic if only Arabic is printed.\n" +
            "- detectedBrand: brand/manufacturer logo or printed brand if clearly readable; otherwise empty.\n" +
            "- Do NOT invent a product name or brand that is not visible on the image.\n" +
            "- products: ALWAYS return exactly 3 category-style marketplace noun guesses " +
            "(singular + plural), even when detectedProductName is set (used as fallback).\n" +
            "- Prefer common marketplace nouns (e.g. Cardamom/Cardamoms), not slogans.\n" +
            "- No explanation, no extra keys.";

        var payload = new
        {
            model = "gpt-4o-mini",
            temperature = 0.1,
            response_format = new { type = "json_object" },
            messages = new object[]
            {
                new
                {
                    role = "user",
                    content = new object[]
                    {
                        new { type = "text", text = prompt },
                        new { type = "image_url", image_url = new { url = dataUrl, detail = "low" } }
                    }
                }
            }
        };

        using var request = new HttpRequestMessage(HttpMethod.Post, "https://api.openai.com/v1/chat/completions");
        request.Headers.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", apiKey);
        request.Content = new StringContent(JsonSerializer.Serialize(payload), Encoding.UTF8, "application/json");

        using var timeoutCts = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken);
        timeoutCts.CancelAfter(TimeSpan.FromSeconds(40));

        using var response = await httpClient.SendAsync(request, timeoutCts.Token).ConfigureAwait(false);
        var body = await response.Content.ReadAsStringAsync(timeoutCts.Token).ConfigureAwait(false);
        if (!response.IsSuccessStatusCode)
        {
            throw new InvalidOperationException($"OpenAI request failed: {(int)response.StatusCode} {body}");
        }

        using var doc = JsonDocument.Parse(body);
        var content = doc.RootElement
            .GetProperty("choices")[0]
            .GetProperty("message")
            .GetProperty("content")
            .GetString();

        if (string.IsNullOrWhiteSpace(content))
        {
            return new ImageProductVisionResult();
        }

        return ParseImageProductVisionResult(content);
    }

    private static ImageProductVisionResult ParseImageProductVisionResult(string content)
    {
        using var contentDoc = JsonDocument.Parse(content);
        var root = contentDoc.RootElement;

        var detectedName = (ReadJsonString(root, "detectedProductName")
            ?? ReadJsonString(root, "productName")
            ?? string.Empty).Trim();
        var detectedBrand = (ReadJsonString(root, "detectedBrand")
            ?? ReadJsonString(root, "brand")
            ?? string.Empty).Trim();

        var fallback = new List<string>();

        // Preferred: { "products": [ { "singular", "plural" }, ... ] }
        if (root.TryGetProperty("products", out var productsElement)
            && productsElement.ValueKind == JsonValueKind.Array)
        {
            foreach (var item in productsElement.EnumerateArray().Take(3))
            {
                if (item.ValueKind != JsonValueKind.Object)
                {
                    continue;
                }

                AddName(fallback, ReadJsonString(item, "singular"));
                AddName(fallback, ReadJsonString(item, "plural"));
            }
        }
        // Fallback: { "names": [ "a", "b", ... ] } or [{singular,plural}, ...]
        else if (root.TryGetProperty("names", out var namesElement)
                 && namesElement.ValueKind == JsonValueKind.Array)
        {
            foreach (var item in namesElement.EnumerateArray().Take(6))
            {
                if (item.ValueKind == JsonValueKind.String)
                {
                    AddName(fallback, item.GetString());
                }
                else if (item.ValueKind == JsonValueKind.Object)
                {
                    AddName(fallback, ReadJsonString(item, "singular"));
                    AddName(fallback, ReadJsonString(item, "plural"));
                }
            }
        }

        fallback = fallback
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .Take(6)
            .ToList();

        var searchNames = new List<string>();
        if (!string.IsNullOrWhiteSpace(detectedName))
        {
            AddName(searchNames, detectedName);
            if (!string.IsNullOrWhiteSpace(detectedBrand))
            {
                AddName(searchNames, detectedBrand);
                AddName(searchNames, $"{detectedBrand} {detectedName}");
            }
        }
        else
        {
            searchNames.AddRange(fallback);
        }

        return new ImageProductVisionResult
        {
            DetectedProductName = detectedName,
            DetectedBrand = detectedBrand,
            SearchNames = searchNames
                .Distinct(StringComparer.OrdinalIgnoreCase)
                .Take(8)
                .ToList(),
            FallbackNames = fallback
        };
    }

    private static string? ReadJsonString(JsonElement obj, string propertyName) =>
        obj.TryGetProperty(propertyName, out var el) && el.ValueKind == JsonValueKind.String
            ? el.GetString()
            : null;

    private static void AddName(List<string> target, string? value)
    {
        var trimmed = (value ?? string.Empty).Trim();
        if (trimmed.Length == 0)
        {
            return;
        }

        target.Add(trimmed);
    }

    public async Task<ProductSearchSpellCheckResult> CheckProductSearchSpellingAsync(
        string query,
        CancellationToken cancellationToken = default)
    {
        var apiKey = configuration["OpenAI:ApiKey"];
        if (string.IsNullOrWhiteSpace(apiKey))
        {
            throw new InvalidOperationException("OpenAI ApiKey is not configured.");
        }

        var trimmed = (query ?? string.Empty).Trim();
        if (trimmed.Length < 2)
        {
            return new ProductSearchSpellCheckResult { IsMisspelled = false };
        }

        var prompt =
            "You check product search queries for a Middle East wholesale marketplace " +
            $"(categories include: {string.Join(", ", AllowedCategories)}). " +
            "Decide if the query is ONLY a misspelled / mistyped product name (typo / near-miss). " +
            "Return ONLY JSON: {\"misspelled\":true|false,\"correctedName\":\"...\"}. " +
            "Rules:\n" +
            "- misspelled=true ONLY for typos of the same intended word (extra/missing/swapped letters).\n" +
            "- correctedName must stay in the same language/script as the query when possible.\n" +
            "- Examples OK: هيلل→هيل, cardammom→cardamom, قهوه→قهوة.\n" +
            "- Examples NOT OK (misspelled=false): شاي, كوكو as unknown products, or replacing شاي with هيل, " +
            "or replacing كوكو with Cardamom. Do NOT invent a different product that exists in the catalog.\n" +
            "- If the query is a valid unknown product name, misspelled=false and correctedName=\"\".\n" +
            "No explanation, no markdown.\n" +
            $"Query: {trimmed}";

        var payload = new
        {
            model = "gpt-4o-mini",
            temperature = 0,
            response_format = new { type = "json_object" },
            messages = new object[]
            {
                new { role = "user", content = prompt }
            }
        };

        using var request = new HttpRequestMessage(HttpMethod.Post, "https://api.openai.com/v1/chat/completions");
        request.Headers.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", apiKey);
        request.Content = new StringContent(JsonSerializer.Serialize(payload), Encoding.UTF8, "application/json");

        using var response = await httpClient.SendAsync(request, cancellationToken);
        var body = await response.Content.ReadAsStringAsync(cancellationToken);
        if (!response.IsSuccessStatusCode)
        {
            throw new InvalidOperationException($"OpenAI request failed: {(int)response.StatusCode} {body}");
        }

        using var doc = JsonDocument.Parse(body);
        var content = doc.RootElement
            .GetProperty("choices")[0]
            .GetProperty("message")
            .GetProperty("content")
            .GetString();

        if (string.IsNullOrWhiteSpace(content))
        {
            return new ProductSearchSpellCheckResult { IsMisspelled = false };
        }

        using var contentDoc = JsonDocument.Parse(content);
        var root = contentDoc.RootElement;
        var misspelled = root.TryGetProperty("misspelled", out var misspelledEl)
            && misspelledEl.ValueKind is JsonValueKind.True or JsonValueKind.False
            && misspelledEl.GetBoolean();

        string? corrected = null;
        if (root.TryGetProperty("correctedName", out var correctedEl)
            && correctedEl.ValueKind == JsonValueKind.String)
        {
            corrected = (correctedEl.GetString() ?? string.Empty).Trim();
        }

        if (!misspelled || string.IsNullOrWhiteSpace(corrected))
        {
            return new ProductSearchSpellCheckResult { IsMisspelled = false };
        }

        if (string.Equals(corrected, trimmed, StringComparison.OrdinalIgnoreCase))
        {
            return new ProductSearchSpellCheckResult { IsMisspelled = false };
        }

        return new ProductSearchSpellCheckResult
        {
            IsMisspelled = true,
            CorrectedName = corrected
        };
    }

    public async Task<IReadOnlyDictionary<int, string>> TranslatePortNamesToArabicAsync(
        IReadOnlyList<PortNameTranslationItem> ports,
        CancellationToken cancellationToken = default)
    {
        if (ports is null || ports.Count == 0)
        {
            return new Dictionary<int, string>();
        }

        var apiKey = configuration["OpenAI:ApiKey"];
        if (string.IsNullOrWhiteSpace(apiKey))
        {
            throw new InvalidOperationException("OpenAI ApiKey is not configured.");
        }

        var listJson = JsonSerializer.Serialize(ports.Select(p => new
        {
            id = p.Id,
            nameEn = p.NameEn,
            unLocode = p.UnLocode
        }));

        var prompt =
            "Translate seaport / place names to Arabic for a shipping marketplace in the Middle East. " +
            "Return ONLY JSON in this exact shape: " +
            "{\"translations\":[{\"id\":123,\"nameAr\":\"...\"}]}. " +
            "Rules: use Modern Standard Arabic; keep well-known Arabic forms for major ports " +
            "(e.g. Dubai→دبي, Hamburg→هامبورغ, Shanghai→شنغهاي); " +
            "transliterate unfamiliar names clearly; never invent English text; " +
            "include every id from the input; no markdown, no explanation.\n" +
            $"Ports: {listJson}";

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

        using var response = await httpClient.SendAsync(request, cancellationToken);
        var body = await response.Content.ReadAsStringAsync(cancellationToken);
        if (!response.IsSuccessStatusCode)
        {
            throw new InvalidOperationException($"OpenAI request failed: {(int)response.StatusCode} {body}");
        }

        using var doc = JsonDocument.Parse(body);
        var content = doc.RootElement
            .GetProperty("choices")[0]
            .GetProperty("message")
            .GetProperty("content")
            .GetString();

        var result = new Dictionary<int, string>();
        if (string.IsNullOrWhiteSpace(content))
        {
            return result;
        }

        using var contentDoc = JsonDocument.Parse(content);
        if (!contentDoc.RootElement.TryGetProperty("translations", out var translations)
            || translations.ValueKind != JsonValueKind.Array)
        {
            return result;
        }

        foreach (var item in translations.EnumerateArray())
        {
            if (!item.TryGetProperty("id", out var idEl) || !idEl.TryGetInt32(out var id))
            {
                continue;
            }

            if (!item.TryGetProperty("nameAr", out var nameEl) || nameEl.ValueKind != JsonValueKind.String)
            {
                continue;
            }

            var nameAr = (nameEl.GetString() ?? string.Empty).Trim();
            if (string.IsNullOrWhiteSpace(nameAr) || !ContainsArabic(nameAr))
            {
                continue;
            }

            result[id] = nameAr;
        }

        return result;
    }

    public async Task<(string TitleEn, string BodyEn, string TitleAr, string BodyAr)> EnsureBilingualNotificationAsync(
        string title,
        string body,
        CancellationToken cancellationToken = default)
    {
        title = (title ?? string.Empty).Trim();
        body = (body ?? string.Empty).Trim();
        var isArabic = ContainsArabic(title) || ContainsArabic(body);

        try
        {
            var apiKey = configuration["OpenAI:ApiKey"];
            if (string.IsNullOrWhiteSpace(apiKey))
            {
                return DuplicateNotificationFallback(title, body);
            }

            var sourceLang = isArabic ? "Arabic" : "English";
            var prompt =
                "You prepare bilingual push notification text for a Middle East marketplace admin panel. " +
                $"The admin entered title and body in {sourceLang}. " +
                "Return ONLY JSON: {\"titleEn\":\"...\",\"bodyEn\":\"...\",\"titleAr\":\"...\",\"bodyAr\":\"...\"}. " +
                "Rules:\n" +
                (isArabic
                    ? "- Keep the given Arabic title/body exactly as titleAr/bodyAr.\n- Translate naturally to English for titleEn/bodyEn.\n"
                    : "- Keep the given English title/body exactly as titleEn/bodyEn.\n- Translate naturally to Modern Standard Arabic for titleAr/bodyAr.\n") +
                "- Preserve meaning; concise push-notification tone.\n" +
                "- No markdown, no extra keys.\n" +
                $"Title: {title}\nBody: {body}";

            var content = await RequestJsonCompletionAsync(apiKey, prompt, cancellationToken);
            if (string.IsNullOrWhiteSpace(content))
            {
                return DuplicateNotificationFallback(title, body);
            }

            using var contentDoc = JsonDocument.Parse(content);
            var root = contentDoc.RootElement;
            var titleEn = ReadJsonString(root, "titleEn") ?? string.Empty;
            var bodyEn = ReadJsonString(root, "bodyEn") ?? string.Empty;
            var titleAr = ReadJsonString(root, "titleAr") ?? string.Empty;
            var bodyAr = ReadJsonString(root, "bodyAr") ?? string.Empty;

            if (isArabic)
            {
                titleAr = string.IsNullOrWhiteSpace(titleAr) ? title : titleAr;
                bodyAr = string.IsNullOrWhiteSpace(bodyAr) ? body : bodyAr;
                titleEn = string.IsNullOrWhiteSpace(titleEn) ? title : titleEn;
                bodyEn = string.IsNullOrWhiteSpace(bodyEn) ? body : bodyEn;
            }
            else
            {
                titleEn = string.IsNullOrWhiteSpace(titleEn) ? title : titleEn;
                bodyEn = string.IsNullOrWhiteSpace(bodyEn) ? body : bodyEn;
                titleAr = string.IsNullOrWhiteSpace(titleAr) ? title : titleAr;
                bodyAr = string.IsNullOrWhiteSpace(bodyAr) ? body : bodyAr;
            }

            return (titleEn.Trim(), bodyEn.Trim(), titleAr.Trim(), bodyAr.Trim());
        }
        catch (Exception ex)
        {
            logger.LogWarning(ex, "EnsureBilingualNotificationAsync failed; using input fallback.");
            return DuplicateNotificationFallback(title, body);
        }
    }

    public async Task<(string NameEn, string NameAr)> EnsureBilingualStatusNameAsync(
        string statusName,
        CancellationToken cancellationToken = default)
    {
        statusName = (statusName ?? string.Empty).Trim();
        if (string.IsNullOrWhiteSpace(statusName))
        {
            return (string.Empty, string.Empty);
        }

        var isArabic = ContainsArabic(statusName);

        try
        {
            var apiKey = configuration["OpenAI:ApiKey"];
            if (string.IsNullOrWhiteSpace(apiKey))
            {
                return DuplicateStatusFallback(statusName);
            }

            var sourceLang = isArabic ? "Arabic" : "English";
            var prompt =
                "You prepare bilingual order status labels for a Middle East marketplace admin panel. " +
                $"The admin entered a status phrase in {sourceLang}. " +
                "Return ONLY JSON: {\"nameEn\":\"...\",\"nameAr\":\"...\"}. " +
                "Rules:\n" +
                (isArabic
                    ? "- Keep the given phrase exactly as nameAr.\n- Translate naturally to English for nameEn.\n"
                    : "- Keep the given phrase exactly as nameEn.\n- Translate naturally to Modern Standard Arabic for nameAr.\n") +
                "- Short status label suitable for order tracking.\n" +
                "- No markdown, no extra keys.\n" +
                $"Status: {statusName}";

            var content = await RequestJsonCompletionAsync(apiKey, prompt, cancellationToken);
            if (string.IsNullOrWhiteSpace(content))
            {
                return DuplicateStatusFallback(statusName);
            }

            using var contentDoc = JsonDocument.Parse(content);
            var root = contentDoc.RootElement;
            var nameEn = ReadJsonString(root, "nameEn") ?? string.Empty;
            var nameAr = ReadJsonString(root, "nameAr") ?? string.Empty;

            if (isArabic)
            {
                nameAr = string.IsNullOrWhiteSpace(nameAr) ? statusName : nameAr;
                nameEn = string.IsNullOrWhiteSpace(nameEn) ? statusName : nameEn;
            }
            else
            {
                nameEn = string.IsNullOrWhiteSpace(nameEn) ? statusName : nameEn;
                nameAr = string.IsNullOrWhiteSpace(nameAr) ? statusName : nameAr;
            }

            return (nameEn.Trim(), nameAr.Trim());
        }
        catch (Exception ex)
        {
            logger.LogWarning(ex, "EnsureBilingualStatusNameAsync failed; using input fallback.");
            return DuplicateStatusFallback(statusName);
        }
    }

    private async Task<string?> RequestJsonCompletionAsync(
        string apiKey,
        string prompt,
        CancellationToken cancellationToken)
    {
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

        using var response = await httpClient.SendAsync(request, cancellationToken);
        var body = await response.Content.ReadAsStringAsync(cancellationToken);
        if (!response.IsSuccessStatusCode)
        {
            throw new InvalidOperationException($"OpenAI request failed: {(int)response.StatusCode} {body}");
        }

        using var doc = JsonDocument.Parse(body);
        return doc.RootElement
            .GetProperty("choices")[0]
            .GetProperty("message")
            .GetProperty("content")
            .GetString();
    }

    private static (string TitleEn, string BodyEn, string TitleAr, string BodyAr) DuplicateNotificationFallback(
        string title,
        string body) =>
        (title, body, title, body);

    private static (string NameEn, string NameAr) DuplicateStatusFallback(string statusName) =>
        (statusName, statusName);

    private static bool ContainsArabic(string value)
    {
        foreach (var c in value)
        {
            if (c is >= '\u0600' and <= '\u06FF'
                or >= '\u0750' and <= '\u077F'
                or >= '\u08A0' and <= '\u08FF'
                or >= '\uFB50' and <= '\uFDFF'
                or >= '\uFE70' and <= '\uFEFF')
            {
                return true;
            }
        }

        return false;
    }

    private static string GetMimeType(string fileName)
    {
        var ext = Path.GetExtension(fileName).ToLowerInvariant();
        return ext switch
        {
            ".jpg" or ".jpeg" => "image/jpeg",
            ".png" => "image/png",
            ".webp" => "image/webp",
            _ => "image/jpeg"
        };
    }

    public async Task<AdImagePolicyScanResult> ScanAdImageForPolicyViolationsAsync(
        Stream imageStream,
        string fileName,
        CancellationToken cancellationToken = default)
    {
        var apiKey = configuration["OpenAI:ApiKey"];
        if (string.IsNullOrWhiteSpace(apiKey))
        {
            logger.LogWarning("OpenAI ApiKey missing — skipping ad image policy scan.");
            return new AdImagePolicyScanResult();
        }

        byte[] jpegBytes;
        await using (var buffered = new MemoryStream())
        {
            await imageStream.CopyToAsync(buffered, cancellationToken).ConfigureAwait(false);
            buffered.Position = 0;
            try
            {
                jpegBytes = await ImageFileHelper.CompressToJpegBytesAsync(
                    buffered,
                    ImageCompressionOptions.SearchVision,
                    cancellationToken).ConfigureAwait(false);
            }
            catch (Exception ex)
            {
                logger.LogWarning(ex, "Ad moderation: failed to compress image; using raw bytes.");
                jpegBytes = buffered.ToArray();
            }
        }

        if (jpegBytes.Length == 0)
        {
            return new AdImagePolicyScanResult();
        }

        var dataUrl = $"data:image/jpeg;base64,{Convert.ToBase64String(jpegBytes)}";
        var prompt =
            "You moderate marketplace product photos for Al Ras Smart (B2B food wholesale).\n" +
            "REJECT the image only if ANY of these are clearly visible:\n" +
            "- phone numbers, WhatsApp, emails, social handles, websites, QR codes for contact\n" +
            "- seller company logos or watermarks overlaid on the photo\n" +
            "- commercial product brand logos/trademarks (e.g. Nestle, Almarai, MDH, Everest)\n" +
            "ALLOWED (do NOT reject for these):\n" +
            "- origin country or region (Sudanese peanuts, Indian cardamom, Egyptian rice, Product of Sudan)\n" +
            "- product type, grade, size, color, packing type, weight, and other commodity specs\n" +
            "- plain commodity photos without a commercial brand mark\n" +
            "Return ONLY JSON:\n" +
            "{\n" +
            "  \"hasViolation\": false,\n" +
            "  \"violationKinds\": [],\n" +
            "  \"summary\": \"\"\n" +
            "}\n" +
            "violationKinds examples: phone, whatsapp, email, url, social, seller_logo, watermark, " +
            "qr_contact, product_brand, brand_logo.\n" +
            "Origin country text is NOT a brand. If unsure whether a mark is a commercial brand vs origin/spec text, " +
            "prefer hasViolation=false unless a clear commercial logo is visible. No markdown.";

        var payload = new
        {
            model = "gpt-4o-mini",
            temperature = 0,
            response_format = new { type = "json_object" },
            messages = new object[]
            {
                new
                {
                    role = "user",
                    content = new object[]
                    {
                        new { type = "text", text = prompt },
                        new { type = "image_url", image_url = new { url = dataUrl, detail = "low" } }
                    }
                }
            }
        };

        using var request = new HttpRequestMessage(HttpMethod.Post, "https://api.openai.com/v1/chat/completions");
        request.Headers.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", apiKey);
        request.Content = new StringContent(JsonSerializer.Serialize(payload), Encoding.UTF8, "application/json");

        using var timeoutCts = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken);
        timeoutCts.CancelAfter(TimeSpan.FromSeconds(35));

        using var response = await httpClient.SendAsync(request, timeoutCts.Token).ConfigureAwait(false);
        var body = await response.Content.ReadAsStringAsync(timeoutCts.Token).ConfigureAwait(false);
        if (!response.IsSuccessStatusCode)
        {
            return new AdImagePolicyScanResult();
        }

        using var doc = JsonDocument.Parse(body);
        var content = doc.RootElement
            .GetProperty("choices")[0]
            .GetProperty("message")
            .GetProperty("content")
            .GetString();

        if (string.IsNullOrWhiteSpace(content))
        {
            return new AdImagePolicyScanResult();
        }

        using var parsed = JsonDocument.Parse(content);
        var root = parsed.RootElement;
        var hasViolation = root.TryGetProperty("hasViolation", out var hv) && hv.ValueKind == JsonValueKind.True;
        var kinds = new List<string>();
        if (root.TryGetProperty("violationKinds", out var vk) && vk.ValueKind == JsonValueKind.Array)
        {
            foreach (var item in vk.EnumerateArray())
            {
                var value = item.GetString();
                if (!string.IsNullOrWhiteSpace(value))
                {
                    kinds.Add(value.Trim());
                }
            }
        }

        var summary = root.TryGetProperty("summary", out var s) ? s.GetString() : null;
        return new AdImagePolicyScanResult
        {
            HasViolation = hasViolation,
            ViolationKinds = kinds,
            Summary = summary
        };
    }

    public async Task<AdTextPolicyScanResult> ScanAdTextForPolicyViolationsAsync(
        string combinedText,
        CancellationToken cancellationToken = default)
    {
        var text = combinedText?.Trim() ?? string.Empty;
        if (string.IsNullOrWhiteSpace(text))
        {
            return new AdTextPolicyScanResult();
        }

        var apiKey = configuration["OpenAI:ApiKey"];
        if (string.IsNullOrWhiteSpace(apiKey))
        {
            logger.LogWarning("OpenAI ApiKey missing — skipping ad text policy scan.");
            return new AdTextPolicyScanResult();
        }

        // Cap payload size for cost/latency.
        if (text.Length > 4000)
        {
            text = text[..4000];
        }

        var prompt =
            "You moderate marketplace ad TEXT for Al Ras Smart (B2B food wholesale).\n" +
            "The text is labeled. ALWAYS inspect the Ad title fields first, then specifications.\n" +
            "This applies on first publish AND when the seller edits/resubmits the ad.\n" +
            "REJECT (hasViolation=true) if ANY field (especially Ad title) contains:\n" +
            "- insults, swear words, hate speech, sexual harassment, or abusive language " +
            "(Arabic or English, including disguised/leet forms)\n" +
            "- phone numbers, WhatsApp, emails, social handles, websites meant for off-platform contact\n" +
            "- seller company name, trade name, or branding used as contact/promotion " +
            "(not a commodity/product type name)\n" +
            "ALLOWED (hasViolation=false):\n" +
            "- normal product title/type and origin (e.g. Sudanese peanuts, Indian cardamom, vanilla, saffron, Grade A)\n" +
            "- common food ingredients, spices, and commodities even with spelling mistakes (e.g. vanillia, cinamon)\n" +
            "- buyer request titles like \"i need vanilla\" or \"need cardamom\" when naming a commodity only\n" +
            "- packing, weight, grade, and other commodity specs\n" +
            "- polite commercial language\n" +
            "IMPORTANT: ingredient and commodity names (vanilla, vanillia, rice, sugar, etc.) are NOT brand names " +
            "and are NOT seller company names. Do NOT reject for commodity names alone.\n" +
            "Return ONLY JSON:\n" +
            "{\n" +
            "  \"hasViolation\": false,\n" +
            "  \"violationKinds\": [],\n" +
            "  \"summary\": \"\"\n" +
            "}\n" +
            "violationKinds examples: insult, profanity, hate, phone, whatsapp, email, url, social, " +
            "seller_company_name, brand_name.\n" +
            "If insult/profanity OR real contact details OR seller company/trade name is present, hasViolation MUST be true. " +
            "Commodity-only titles (including typos and \"i need X\" requests) MUST be hasViolation=false. No markdown.\n\n" +
            "Ad text:\n" + text;

        var payload = new
        {
            model = "gpt-4o-mini",
            temperature = 0,
            response_format = new { type = "json_object" },
            messages = new object[]
            {
                new { role = "user", content = prompt }
            }
        };

        using var request = new HttpRequestMessage(HttpMethod.Post, "https://api.openai.com/v1/chat/completions");
        request.Headers.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", apiKey);
        request.Content = new StringContent(JsonSerializer.Serialize(payload), Encoding.UTF8, "application/json");

        using var timeoutCts = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken);
        timeoutCts.CancelAfter(TimeSpan.FromSeconds(25));

        using var response = await httpClient.SendAsync(request, timeoutCts.Token).ConfigureAwait(false);
        var body = await response.Content.ReadAsStringAsync(timeoutCts.Token).ConfigureAwait(false);
        if (!response.IsSuccessStatusCode)
        {
            logger.LogWarning("Ad text policy scan failed: {Status} {Body}", (int)response.StatusCode, body);
            // Fail closed: treat API failure as needing human review (caller checks ScanFailed).
            return new AdTextPolicyScanResult { HasViolation = false, Summary = "scan_failed" };
        }

        using var doc = JsonDocument.Parse(body);
        var content = doc.RootElement
            .GetProperty("choices")[0]
            .GetProperty("message")
            .GetProperty("content")
            .GetString();

        if (string.IsNullOrWhiteSpace(content))
        {
            return new AdTextPolicyScanResult { Summary = "scan_failed" };
        }

        using var parsed = JsonDocument.Parse(content);
        var root = parsed.RootElement;
        var hasViolation = root.TryGetProperty("hasViolation", out var hv) && hv.ValueKind == JsonValueKind.True;
        var kinds = new List<string>();
        if (root.TryGetProperty("violationKinds", out var vk) && vk.ValueKind == JsonValueKind.Array)
        {
            foreach (var item in vk.EnumerateArray())
            {
                var value = item.GetString();
                if (!string.IsNullOrWhiteSpace(value))
                {
                    kinds.Add(value.Trim());
                }
            }
        }

        var summary = root.TryGetProperty("summary", out var s) ? s.GetString() : null;
        return new AdTextPolicyScanResult
        {
            HasViolation = hasViolation,
            ViolationKinds = kinds,
            Summary = summary
        };
    }
}
