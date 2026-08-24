using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using BusinessLayer.Interfaces;
using Microsoft.Extensions.Logging;

namespace BusinessLayer.Services.AiAssistant.Mcp;

/// <summary>
/// Runs OpenAI chat completions with MCP-style tool_calls until the model
/// returns a final text answer (or the round limit is hit).
/// </summary>
public sealed class AiAssistantMcpToolLoop(
    IAiAssistantToolsService toolsService,
    ILogger<AiAssistantMcpToolLoop> logger) : IAiAssistantMcpToolLoop
{
    private const int MaxToolRounds = 12;
    /// Soft cap: several account edits (price/qty, pause/active, sold-out, delete)
    /// may run in one user turn — e.g. "delete all ads except …".
    private const int MaxSuccessfulAccountMutationsPerTurn = 25;

    private static readonly HashSet<string> MutatingToolNames = new(StringComparer.Ordinal)
    {
        "update_ad_price_quantity",
        "set_ad_listing_status",
        "mark_ad_sold_out",
        "delete_ad",
        "create_request_ad",
        "create_booking_ad",
        "create_offer_ad",
        "create_retail_ad",
        "create_category_ad",
        "create_shipping_ad",
        "submit_feedback"
    };

    private static readonly HashSet<string> AccountMutationTools = new(StringComparer.Ordinal)
    {
        "update_ad_price_quantity",
        "set_ad_listing_status",
        "mark_ad_sold_out",
        "delete_ad",
    };

    private static readonly HashSet<string> AdCreationToolNames = new(StringComparer.Ordinal)
    {
        "create_request_ad",
        "create_booking_ad",
        "create_offer_ad",
        "create_retail_ad",
        "create_category_ad",
        "create_shipping_ad"
    };

    public async Task<AiMcpLoopResult> CompleteWithToolsAsync(
        HttpClient httpClient,
        string apiKey,
        string chatModel,
        IList<object> messages,
        Guid? userId,
        string responseLanguage = "en",
        Func<string, CancellationToken, Task>? onThinkingStep = null,
        CancellationToken cancellationToken = default)
    {
        var isArabic = responseLanguage.StartsWith("ar", StringComparison.OrdinalIgnoreCase);
        var tools = toolsService.GetToolDefinitions();
        var successfulMutations = 0;
        string? successfulAdCreationPayload = null;
        var listings = new List<AiProductListingDto>();

        AiMcpLoopResult Complete(string answer) =>
            new(answer, DeduplicateListings(listings));

        for (var round = 0; round < MaxToolRounds; round++)
        {
            using var httpRequest = new HttpRequestMessage(
                HttpMethod.Post,
                "https://api.openai.com/v1/chat/completions");
            httpRequest.Headers.Authorization = new AuthenticationHeaderValue("Bearer", apiKey);

            var payload = new Dictionary<string, object?>
            {
                ["model"] = chatModel,
                ["temperature"] = 0.1,
                ["max_tokens"] = 700,
                ["messages"] = messages,
                ["tools"] = tools,
                ["tool_choice"] = "auto"
            };

            httpRequest.Content = new StringContent(
                JsonSerializer.Serialize(payload),
                Encoding.UTF8,
                "application/json");

            using var response = await httpClient.SendAsync(httpRequest, cancellationToken)
                .ConfigureAwait(false);
            var json = await response.Content.ReadAsStringAsync(cancellationToken).ConfigureAwait(false);
            if (!response.IsSuccessStatusCode)
            {
                throw new InvalidOperationException(
                    $"OpenAI assistant failed ({(int)response.StatusCode}): {json}");
            }

            using var doc = JsonDocument.Parse(json);
            var choice = doc.RootElement.GetProperty("choices")[0];
            var msg = choice.GetProperty("message");
            var finishReason = choice.TryGetProperty("finish_reason", out var fr)
                ? fr.GetString()
                : null;

            if (finishReason == "tool_calls" &&
                msg.TryGetProperty("tool_calls", out var toolCalls) &&
                toolCalls.ValueKind == JsonValueKind.Array &&
                toolCalls.GetArrayLength() > 0)
            {
                // Echo the assistant tool_calls message, then append each tool result.
                messages.Add(JsonSerializer.Deserialize<object>(msg.GetRawText())!);

                if (onThinkingStep is not null
                    && msg.TryGetProperty("content", out var thinkEl))
                {
                    var thinkText = thinkEl.ValueKind == JsonValueKind.String
                        ? thinkEl.GetString()
                        : null;
                    if (!string.IsNullOrWhiteSpace(thinkText))
                    {
                        foreach (var rawLine in thinkText.Split('\n', StringSplitOptions.RemoveEmptyEntries))
                        {
                            var line = rawLine.Trim().TrimStart('-', '*', '\u2022', '\u2013').Trim();
                            if (line.Length == 0) continue;
                            await onThinkingStep(line, cancellationToken).ConfigureAwait(false);
                        }
                    }
                }

                foreach (var tc in toolCalls.EnumerateArray())
                {
                    var id = tc.GetProperty("id").GetString() ?? Guid.NewGuid().ToString("N");
                    var fn = tc.GetProperty("function");
                    var name = fn.GetProperty("name").GetString() ?? "";
                    var args = fn.TryGetProperty("arguments", out var a)
                        ? a.GetString() ?? "{}"
                        : "{}";

                    if (onThinkingStep is not null)
                    {
                        await onThinkingStep(
                                DescribeToolCall(name, isArabic),
                                cancellationToken)
                            .ConfigureAwait(false);
                    }

                    if (AccountMutationTools.Contains(name)
                        && successfulMutations >= MaxSuccessfulAccountMutationsPerTurn)
                    {
                        logger.LogWarning(
                            "Blocked mutating tool {Tool} for user {UserId}; already applied {Count} mutation(s) this turn.",
                            name,
                            userId,
                            successfulMutations);
                        messages.Add(new
                        {
                            role = "tool",
                            tool_call_id = id,
                            content = JsonSerializer.Serialize(new
                            {
                                ok = false,
                                blocked_bulk_update = true,
                                error =
                                    "Too many account-changing actions in one message " +
                                    "(price/qty, pause/active, sold-out, or delete). " +
                                    "Tell the user what was already applied and ask them to continue in a new message."
                            })
                        });
                        continue;
                    }

                    var result = await toolsService.ExecuteAsync(
                            userId,
                            new AiToolCall(id, name, args),
                            cancellationToken)
                        .ConfigureAwait(false);

                    listings.AddRange(ParseListingCards(name, result.Content));
                    if (ListingToolNames.Contains(name)
                        && listings.Count == 0
                        && IsSuccessfulToolPayload(result.Content))
                    {
                        logger.LogWarning(
                            "AI tool {Tool} succeeded but returned no listing cards. Payload: {Payload}",
                            name,
                            TruncateForLog(result.Content));
                    }

                    if (AccountMutationTools.Contains(name)
                        && IsSuccessfulToolPayload(result.Content))
                    {
                        successfulMutations++;
                    }

                    if (AdCreationToolNames.Contains(name)
                        && IsSuccessfulToolPayload(result.Content))
                    {
                        successfulAdCreationPayload = result.Content;
                    }

                    if (onThinkingStep is not null
                        && !IsSuccessfulToolPayload(result.Content))
                    {
                        await onThinkingStep(
                                DescribeToolResult(name, result.Content, isArabic),
                                cancellationToken)
                            .ConfigureAwait(false);
                    }

                    messages.Add(new
                    {
                        role = "tool",
                        tool_call_id = result.CallId,
                        content = result.Content
                    });
                }

                if (successfulAdCreationPayload is not null)
                {
                    return Complete(FormatAdCreationSuccessMessage(successfulAdCreationPayload, isArabic));
                }

                continue;
            }

            var answer = msg.TryGetProperty("content", out var contentEl)
                ? contentEl.GetString()?.Trim()
                : null;

            if (!string.IsNullOrWhiteSpace(answer))
            {
                return Complete(answer);
            }

            if (successfulAdCreationPayload is not null)
            {
                return Complete(FormatAdCreationSuccessMessage(successfulAdCreationPayload, isArabic));
            }

            throw new InvalidOperationException("OpenAI returned an empty assistant answer.");
        }

        if (successfulAdCreationPayload is not null)
        {
            logger.LogWarning(
                "AI assistant hit the MCP tool-call limit ({MaxRounds}) after a successful ad create; returning success text.",
                MaxToolRounds);
            return Complete(FormatAdCreationSuccessMessage(successfulAdCreationPayload, isArabic));
        }

        logger.LogWarning("AI assistant exceeded the MCP tool-call limit ({MaxRounds}).", MaxToolRounds);
        throw new InvalidOperationException("AI assistant exceeded the tool-call limit.");
    }

    private static readonly HashSet<string> ListingToolNames = new(StringComparer.Ordinal)
    {
        "find_cheapest_product",
        "find_most_expensive_product",
        "search_products"
    };

    internal static IReadOnlyList<AiProductListingDto> ParseListingCards(string toolName, string content)
    {
        if (string.IsNullOrWhiteSpace(content))
        {
            return [];
        }

        if (!string.IsNullOrWhiteSpace(toolName) && !ListingToolNames.Contains(toolName))
        {
            return [];
        }

        try
        {
            using var doc = JsonDocument.Parse(content);
            var parsed = new List<AiProductListingDto>();
            if (doc.RootElement.TryGetProperty("listings", out var listingsEl)
                && listingsEl.ValueKind == JsonValueKind.Array)
            {
                foreach (var el in listingsEl.EnumerateArray())
                {
                    var card = TryReadListingCard(el);
                    if (card is not null && card.ProductId != Guid.Empty)
                    {
                        parsed.Add(card);
                    }
                }
            }

            if (parsed.Count == 0)
            {
                foreach (var key in new[] { "cheapest", "mostExpensive", "bestMatch", "alternatives" })
                {
                    if (!doc.RootElement.TryGetProperty(key, out var extra)) continue;
                    if (extra.ValueKind == JsonValueKind.Array)
                    {
                        foreach (var el in extra.EnumerateArray())
                        {
                            var card = TryReadListingCard(el);
                            if (card is not null && card.ProductId != Guid.Empty)
                            {
                                parsed.Add(card);
                            }
                        }
                    }
                    else if (extra.ValueKind == JsonValueKind.Object)
                    {
                        var card = TryReadListingCard(extra);
                        if (card is not null && card.ProductId != Guid.Empty)
                        {
                            parsed.Add(card);
                        }
                    }
                }
            }

            return parsed;
        }
        catch
        {
            return [];
        }
    }

    private static AiProductListingDto? TryReadListingCard(JsonElement el)
    {
        if (el.ValueKind != JsonValueKind.Object) return null;
        if ((!TryGetGuid(el, "productId", out var productId) && !TryGetGuid(el, "id", out productId))
            || productId == Guid.Empty)
        {
            return null;
        }

        var images = new List<string>();
        if (TryGetPropertyIgnoreCase(el, "images", out var imgs)
            && imgs.ValueKind == JsonValueKind.Array)
        {
            foreach (var img in imgs.EnumerateArray())
            {
                if (img.ValueKind != JsonValueKind.String) continue;
                var path = img.GetString();
                if (!string.IsNullOrWhiteSpace(path)) images.Add(path.Trim());
            }
        }

        return new AiProductListingDto(
            productId,
            GetJsonString(el, "productCode"),
            GetJsonString(el, "nameEn"),
            GetJsonString(el, "nameAr"),
            GetJsonDecimal(el, "price") ?? 0,
            GetJsonString(el, "currency"),
            GetJsonDecimal(el, "usdPrice") ?? GetJsonDecimal(el, "priceUsd"),
            GetJsonDecimal(el, "priceAed"),
            GetJsonInt64(el, "quantity") ?? 0,
            GetJsonString(el, "unitName"),
            GetJsonByte(el, "categoryId"),
            GetJsonByte(el, "productTypeId"),
            GetJsonString(el, "productTypeName"),
            GetJsonString(el, "searchListingChannel"),
            GetJsonBool(el, "hasRetailPricing"),
            images);
    }

    private static bool TryGetPropertyIgnoreCase(JsonElement el, string name, out JsonElement value)
    {
        if (el.TryGetProperty(name, out value)) return true;
        foreach (var prop in el.EnumerateObject())
        {
            if (string.Equals(prop.Name, name, StringComparison.OrdinalIgnoreCase))
            {
                value = prop.Value;
                return true;
            }
        }

        value = default;
        return false;
    }

    private static bool TryGetGuid(JsonElement el, string name, out Guid id)
    {
        id = Guid.Empty;
        if (!TryGetPropertyIgnoreCase(el, name, out var value)) return false;
        if (value.ValueKind == JsonValueKind.String)
        {
            return Guid.TryParse(value.GetString(), out id);
        }

        return false;
    }

    private static string? GetJsonString(JsonElement el, string name) =>
        TryGetPropertyIgnoreCase(el, name, out var value) && value.ValueKind == JsonValueKind.String
            ? value.GetString()
            : null;

    private static decimal? GetJsonDecimal(JsonElement el, string name)
    {
        if (!TryGetPropertyIgnoreCase(el, name, out var value)) return null;
        if (value.ValueKind == JsonValueKind.Number && value.TryGetDecimal(out var n)) return n;
        if (value.ValueKind == JsonValueKind.String
            && decimal.TryParse(value.GetString(), out var parsed))
        {
            return parsed;
        }

        return null;
    }

    private static long? GetJsonInt64(JsonElement el, string name)
    {
        if (!TryGetPropertyIgnoreCase(el, name, out var value)) return null;
        if (value.ValueKind == JsonValueKind.Number)
        {
            if (value.TryGetInt64(out var n)) return n;
            if (value.TryGetDecimal(out var d)) return (long)decimal.Truncate(d);
        }

        if (value.ValueKind == JsonValueKind.String
            && long.TryParse(value.GetString(), out var parsed))
        {
            return parsed;
        }

        return null;
    }

    private static byte? GetJsonByte(JsonElement el, string name)
    {
        var n = GetJsonInt64(el, name);
        if (n is < 0 or > 255) return null;
        return n is null ? null : (byte)n.Value;
    }

    private static bool GetJsonBool(JsonElement el, string name)
    {
        if (!TryGetPropertyIgnoreCase(el, name, out var value)) return false;
        return value.ValueKind switch
        {
            JsonValueKind.True => true,
            JsonValueKind.False => false,
            JsonValueKind.String when bool.TryParse(value.GetString(), out var b) => b,
            _ => false
        };
    }

    private static IReadOnlyList<AiProductListingDto> DeduplicateListings(
        IReadOnlyList<AiProductListingDto> listings)
    {
        var seen = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        var result = new List<AiProductListingDto>();
        foreach (var listing in listings)
        {
            var key = $"{listing.ProductId:D}:{listing.SearchListingChannel}";
            if (!seen.Add(key))
            {
                continue;
            }
            result.Add(listing);
        }
        return result;
    }

    private static string DescribeToolCall(string toolName, bool isArabic) =>
        isArabic
            ? DescribeToolCallAr(toolName)
            : DescribeToolCallEn(toolName);

    private static string DescribeToolCallAr(string toolName) =>
        toolName switch
        {
            "get_my_last_order" => "بشوف آخر طلب من طلباتك…",
            "get_my_purchase_summary" => "بجمّع مشترياتك…",
            "explain_my_order_delay" => "براجع ليه الطلب ممكن يتأخر…",
            "get_my_sales_count" => "بشوف مبيعاتك والطلبات على إعلاناتك…",
            "get_last_order_on_my_ads" => "بجيب آخر طلب على إعلاناتك…",
            "explain_order_delay_on_my_ads" => "براجع تأخير طلب على الإعلان…",
            "find_cheapest_product" => "بدوّر على أرخص سعر…",
            "find_most_expensive_product" => "بدوّر على أعلى سعر…",
            "search_products" => "بدوّر في الإعلانات…",
            "list_my_ads" => "بجيب قائمة إعلاناتك…",
            "get_my_last_ad" => "بجيب آخر إعلان نزلته…",
            "get_my_first_ad" => "بجيب أول إعلان نزلته…",
            "update_ad_price_quantity" => "بحدّث السعر أو الكمية…",
            "set_ad_listing_status" => "بحدّث حالة الإعلان…",
            "mark_ad_sold_out" => "بعلّم الكمية نافدة…",
            "delete_ad" => "بحذف الإعلان…",
            "lookup_create_ad_reference" => "براجع الوحدات والدول والموانئ…",
            "list_my_addresses" => "بجيب عناوين التسليم المحفوظة…",
            "create_request_ad" => "بنشر إعلان الطلب…",
            "create_booking_ad" => "بنشر إعلان الحجز…",
            "create_offer_ad" => "بنشر إعلان العرض…",
            "create_retail_ad" => "بنشر إعلان التجزئة…",
            "create_category_ad" => "بنشر إعلان الصنف…",
            "search_shipping_prices" => "بشوف أسعار الشحن…",
            "create_shipping_ad" => "بنشر إعلان الشحن…",
            _ => "بلمّ البيانات المطلوبة…"
        };

    private static string DescribeToolCallEn(string toolName) =>
        toolName switch
        {
            "get_my_last_order" => "Checking your latest order…",
            "get_my_purchase_summary" => "Summarizing your purchases…",
            "explain_my_order_delay" => "Checking why the order may be delayed…",
            "get_my_sales_count" => "Checking sales on your ads…",
            "get_last_order_on_my_ads" => "Fetching the latest order on your ads…",
            "explain_order_delay_on_my_ads" => "Checking a delay on an ad order…",
            "find_cheapest_product" => "Looking for the lowest price…",
            "find_most_expensive_product" => "Looking for the highest price…",
            "search_products" => "Searching listings…",
            "list_my_ads" => "Loading your ads…",
            "get_my_last_ad" => "Fetching your newest ad…",
            "get_my_first_ad" => "Fetching your oldest ad…",
            "update_ad_price_quantity" => "Updating price or quantity…",
            "set_ad_listing_status" => "Updating the listing status…",
            "mark_ad_sold_out" => "Marking it sold out…",
            "delete_ad" => "Deleting the ad…",
            "lookup_create_ad_reference" => "Checking units, countries, and ports…",
            "list_my_addresses" => "Loading saved delivery addresses…",
            "create_request_ad" => "Publishing the request ad…",
            "create_booking_ad" => "Publishing the booking ad…",
            "create_offer_ad" => "Publishing the offer ad…",
            "create_retail_ad" => "Publishing the retail ad…",
            "create_category_ad" => "Publishing the category ad…",
            "search_shipping_prices" => "Checking shipping rates…",
            "create_shipping_ad" => "Publishing the shipping ad…",
            _ => "Gathering what I need…"
        };

    private static string DescribeToolResult(string toolName, string content, bool isArabic)
    {
        try
        {
            using var doc = JsonDocument.Parse(content);
            if (doc.RootElement.TryGetProperty("ok", out var ok)
                && ok.ValueKind == JsonValueKind.False)
            {
                var err = doc.RootElement.TryGetProperty("error", out var e)
                    ? e.GetString()
                    : null;
                if (isArabic)
                {
                    return string.IsNullOrWhiteSpace(err)
                        ? $"الأداة {toolName} رجّعت خطأ."
                        : $"الأداة {toolName}: {err}";
                }

                return string.IsNullOrWhiteSpace(err)
                    ? $"Tool {toolName} returned an error."
                    : $"Tool {toolName}: {err}";
            }

            if (doc.RootElement.TryGetProperty("found", out var found)
                && found.ValueKind == JsonValueKind.False)
            {
                return isArabic
                    ? $"الأداة {toolName}: مفيش بيانات مطابقة."
                    : $"Tool {toolName}: no matching data.";
            }
        }
        catch (JsonException)
        {
            // Fall through.
        }

        if (toolName.StartsWith("create_", StringComparison.Ordinal) && toolName.EndsWith("_ad", StringComparison.Ordinal))
        {
            try
            {
                using var doc = JsonDocument.Parse(content);
                if (doc.RootElement.TryGetProperty("ok", out var ok)
                    && ok.ValueKind == JsonValueKind.True)
                {
                    var paths = new List<string>();
                    if (doc.RootElement.TryGetProperty("draftImagePaths", out var imgs)
                        && imgs.ValueKind == JsonValueKind.Array)
                    {
                        foreach (var p in imgs.EnumerateArray())
                        {
                            if (p.ValueKind == JsonValueKind.String)
                            {
                                var s = p.GetString();
                                if (!string.IsNullOrWhiteSpace(s)) paths.Add(s!);
                            }
                        }
                    }

                    if (doc.RootElement.TryGetProperty("draftVideoPath", out var vid)
                        && vid.ValueKind == JsonValueKind.String)
                    {
                        var s = vid.GetString();
                        if (!string.IsNullOrWhiteSpace(s)) paths.Add(s!);
                    }

                    if (paths.Count > 0)
                    {
                        return isArabic
                            ? "تم رفع الوسائط:\n" + string.Join("\n", paths)
                            : "Media uploaded:\n" + string.Join("\n", paths);
                    }

                    return isArabic
                        ? "تم إنشاء الإعلان وإرساله للمراجعة."
                        : "Ad created and submitted for review.";
                }
            }
            catch (JsonException)
            {
                // Fall through.
            }
        }

        return isArabic
            ? $"وصل نتيجة من {toolName}."
            : $"Received result from {toolName}.";
    }

    private static string FormatAdCreationSuccessMessage(string toolPayload, bool isArabic)
    {
        try
        {
            using var doc = JsonDocument.Parse(toolPayload);
            var root = doc.RootElement;
            var adType = root.TryGetProperty("adType", out var adTypeEl)
                ? adTypeEl.GetString()
                : null;
            var name = root.TryGetProperty("name", out var nameEl)
                ? nameEl.GetString()
                : null;
            var productCode = root.TryGetProperty("productCode", out var codeEl)
                ? codeEl.GetString()
                : null;
            var submitted = root.TryGetProperty("submittedForReview", out var submittedEl)
                            && submittedEl.ValueKind == JsonValueKind.True;

            if (isArabic)
            {
                var adLabel = string.IsNullOrWhiteSpace(adType) ? "الإعلان" : adType.Trim();
                var title = string.IsNullOrWhiteSpace(name) ? string.Empty : $" «{name.Trim()}»";
                var codeSuffix = string.IsNullOrWhiteSpace(productCode)
                    ? string.Empty
                    : $" رمز المنتج (ProductCode): {productCode.Trim()}.";

                if (submitted)
                {
                    return $"تم إنشاء إعلان {adLabel}{title} بنجاح وإرساله للمراجعة من الإدارة.{codeSuffix} "
                           + "ستتلقى إشعاراً عند الموافقة أو الرفض.";
                }

                return $"تم إنشاء إعلان {adLabel}{title} بنجاح.{codeSuffix}";
            }

            var adLabelEn = string.IsNullOrWhiteSpace(adType) ? "ad" : adType.Trim();
            var titleEn = string.IsNullOrWhiteSpace(name) ? string.Empty : $" \"{name.Trim()}\"";
            var codeSuffixEn = string.IsNullOrWhiteSpace(productCode)
                ? string.Empty
                : $" ProductCode: {productCode.Trim()}.";

            if (submitted)
            {
                return $"Your {adLabelEn} ad{titleEn} was created and submitted for admin review.{codeSuffixEn} "
                       + "You will be notified when it is approved or rejected.";
            }

            return $"Your {adLabelEn} ad{titleEn} was created successfully.{codeSuffixEn}";
        }
        catch (JsonException)
        {
            return isArabic
                ? "تم إنشاء الإعلان بنجاح وإرساله للمراجعة من الإدارة."
                : "Your ad was created and submitted for admin review.";
        }
    }

    private static string TruncateForLog(string value, int max = 500)
    {
        if (string.IsNullOrEmpty(value) || value.Length <= max) return value;
        return value[..max] + "…";
    }

    private static bool IsSuccessfulToolPayload(string content)
    {
        try
        {
            using var doc = JsonDocument.Parse(content);
            return doc.RootElement.TryGetProperty("ok", out var ok)
                   && ok.ValueKind == JsonValueKind.True;
        }
        catch (JsonException)
        {
            return false;
        }
    }
}
