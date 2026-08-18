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
    private const int MaxToolRounds = 6;
    /// <summary>
    /// Hard cap: never apply more than one successful mutating account action
    /// per user turn (price/qty, pause/active, sold-out, or delete).
    /// </summary>
    private const int MaxSuccessfulMutationsPerTurn = 1;

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
                            var line = rawLine.Trim().TrimStart('-', '*', 'â€¢', 'â€“').Trim();
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

                    if (MutatingToolNames.Contains(name)
                        && !AdCreationToolNames.Contains(name)
                        && successfulMutations >= MaxSuccessfulMutationsPerTurn)
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
                                    "Only ONE account-changing action is allowed per user message " +
                                    "(update price/qty, pause/active, sold-out, or delete). " +
                                    "Tell the user to send another message for the next change."
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

                    if (MutatingToolNames.Contains(name)
                        && IsSuccessfulToolPayload(result.Content))
                    {
                        successfulMutations++;
                    }

                    if (AdCreationToolNames.Contains(name)
                        && IsSuccessfulToolPayload(result.Content))
                    {
                        successfulAdCreationPayload = result.Content;
                    }

                    if (onThinkingStep is not null)
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

    private static IReadOnlyList<AiProductListingDto> ParseListingCards(string toolName, string content)
    {
        if (!ListingToolNames.Contains(toolName) || string.IsNullOrWhiteSpace(content))
        {
            return [];
        }

        try
        {
            using var doc = JsonDocument.Parse(content);
            if (!doc.RootElement.TryGetProperty("listings", out var listingsEl)
                || listingsEl.ValueKind != JsonValueKind.Array)
            {
                return [];
            }

            var parsed = JsonSerializer.Deserialize<List<AiProductListingDto>>(
                listingsEl.GetRawText(),
                new JsonSerializerOptions { PropertyNameCaseInsensitive = true });
            return parsed?
                .Where(x => x.ProductId != Guid.Empty)
                .ToList()
                ?? [];
        }
        catch
        {
            return [];
        }
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
            "get_my_last_order" => "Ø¨Ø³ØªØ¯Ø¹ÙŠ Ø£Ø¯Ø§Ø©: Ø¢Ø®Ø± Ø·Ù„Ø¨ Ù…Ù† Ø·Ù„Ø¨Ø§ØªÙŠâ€¦",
            "get_my_purchase_summary" => "Ø¨Ø³ØªØ¯Ø¹ÙŠ Ø£Ø¯Ø§Ø©: Ù…Ù„Ø®Øµ Ù…Ø´ØªØ±ÙŠØ§ØªÙŠ / Ø§Ø´ØªØ±ÙŠØª Ø¨ÙƒØ§Ù…â€¦",
            "explain_my_order_delay" => "Ø¨Ø³ØªØ¯Ø¹ÙŠ Ø£Ø¯Ø§Ø©: Ù„ÙŠÙ‡ Ø§Ù„Ø·Ù„Ø¨ Ù…ØªØ£Ø®Ø± (Ø·Ù„Ø¨Ø§ØªÙŠ)â€¦",
            "get_my_sales_count" => "Ø¨Ø³ØªØ¯Ø¹ÙŠ Ø£Ø¯Ø§Ø©: Ø§Ù„Ù…Ø¨ÙŠØ¹Ø§Øª ÙˆØ·Ù„Ø¨Ø§Øª Ø§Ù„Ø¥Ø¹Ù„Ø§Ù†Ø§Øªâ€¦",
            "get_last_order_on_my_ads" => "Ø¨Ø³ØªØ¯Ø¹ÙŠ Ø£Ø¯Ø§Ø©: Ø¢Ø®Ø± Ø·Ù„Ø¨ Ø¹Ù„Ù‰ Ø¥Ø¹Ù„Ø§Ù†Ø§ØªÙŠâ€¦",
            "explain_order_delay_on_my_ads" => "Ø¨Ø³ØªØ¯Ø¹ÙŠ Ø£Ø¯Ø§Ø©: ØªØ£Ø®ÙŠØ± Ø·Ù„Ø¨ Ø¹Ù„Ù‰ Ø§Ù„Ø¥Ø¹Ù„Ø§Ù†â€¦",
            "find_cheapest_product" => "Ø¨Ø³ØªØ¯Ø¹ÙŠ Ø£Ø¯Ø§Ø©: Ø£Ø±Ø®Øµ Ù…Ù†ØªØ¬â€¦",
            "find_most_expensive_product" => "Ø¨Ø³ØªØ¯Ø¹ÙŠ Ø£Ø¯Ø§Ø©: Ø£ØºÙ„Ù‰ Ù…Ù†ØªØ¬â€¦",
            "search_products" => "Ø¨Ø³ØªØ¯Ø¹ÙŠ Ø£Ø¯Ø§Ø©: Ø¥Ø¹Ù„Ø§Ù†Ø§Øª Ø§Ù„Ù…Ù†ØªØ¬â€¦",
            "list_my_ads" => "Ø¨Ø³ØªØ¯Ø¹ÙŠ Ø£Ø¯Ø§Ø©: Ù‚Ø§Ø¦Ù…Ø© Ø¥Ø¹Ù„Ø§Ù†Ø§ØªÙŠâ€¦",
            "get_my_last_ad" => "Ø¨Ø³ØªØ¯Ø¹ÙŠ Ø£Ø¯Ø§Ø©: Ø¢Ø®Ø± Ø¥Ø¹Ù„Ø§Ù† Ù†Ø²Ù„ØªÙ‡â€¦",
            "get_my_first_ad" => "Ø¨Ø³ØªØ¯Ø¹ÙŠ Ø£Ø¯Ø§Ø©: Ø£ÙˆÙ„ Ø¥Ø¹Ù„Ø§Ù† Ù†Ø²Ù„ØªÙ‡â€¦",
            "update_ad_price_quantity" => "Ø¨Ø³ØªØ¯Ø¹ÙŠ Ø£Ø¯Ø§Ø©: ØªØ¹Ø¯ÙŠÙ„ Ø§Ù„Ø³Ø¹Ø±/Ø§Ù„ÙƒÙ…ÙŠØ©â€¦",
            "set_ad_listing_status" => "Ø¨Ø³ØªØ¯Ø¹ÙŠ Ø£Ø¯Ø§Ø©: Ø¥ÙŠÙ‚Ø§Ù/ØªÙØ¹ÙŠÙ„ Ø¥Ø¹Ù„Ø§Ù†â€¦",
            "mark_ad_sold_out" => "Ø¨Ø³ØªØ¯Ø¹ÙŠ Ø£Ø¯Ø§Ø©: ØªØ¹Ù„ÙŠÙ… Ù†ÙØ§Ø¯ Ø§Ù„ÙƒÙ…ÙŠØ©â€¦",
            "delete_ad" => "Ø¨Ø³ØªØ¯Ø¹ÙŠ Ø£Ø¯Ø§Ø©: Ø­Ø°Ù Ø¥Ø¹Ù„Ø§Ù†â€¦",
            "lookup_create_ad_reference" => "Ø¨Ø³ØªØ¯Ø¹ÙŠ Ø£Ø¯Ø§Ø©: Ù…Ø±Ø§Ø¬Ø¹ Ø¥Ù†Ø´Ø§Ø¡ Ø§Ù„Ø¥Ø¹Ù„Ø§Ù† (ÙˆØ­Ø¯Ø§Øª/Ø¯ÙˆÙ„/Ù…ÙˆØ§Ù†Ø¦)â€¦",
            "list_my_addresses" => "Ø¨Ø³ØªØ¯Ø¹ÙŠ Ø£Ø¯Ø§Ø©: Ø¹Ù†Ø§ÙˆÙŠÙ† Ø§Ù„ØªØ³Ù„ÙŠÙ… Ø§Ù„Ù…Ø­ÙÙˆØ¸Ø©â€¦",
            "create_request_ad" => "Ø¬Ø§Ø±ÙŠ Ø¥Ù†Ø´Ø§Ø¡ Ø¥Ø¹Ù„Ø§Ù† Ø·Ù„Ø¨ Ø¹Ù„Ù‰ Ø§Ù„Ø³Ø­Ø§Ø¨Ø©â€¦",
            "create_booking_ad" => "Ø¬Ø§Ø±ÙŠ Ø¥Ù†Ø´Ø§Ø¡ Ø¥Ø¹Ù„Ø§Ù† Bookingâ€¦",
            "create_offer_ad" => "Ø¬Ø§Ø±ÙŠ Ø¥Ù†Ø´Ø§Ø¡ Ø¥Ø¹Ù„Ø§Ù† Offerâ€¦",
            "create_retail_ad" => "Ø¬Ø§Ø±ÙŠ Ø¥Ù†Ø´Ø§Ø¡ Ø¥Ø¹Ù„Ø§Ù† Retailâ€¦",
            "create_category_ad" => "Ø¬Ø§Ø±ÙŠ Ø¥Ù†Ø´Ø§Ø¡ Ø¥Ø¹Ù„Ø§Ù† Categoryâ€¦",
            "search_shipping_prices" => "Ø¨Ø³ØªØ¯Ø¹ÙŠ Ø£Ø¯Ø§Ø©: Ø£Ø³Ø¹Ø§Ø± Ø§Ù„Ø´Ø­Ù† Ø¨ÙŠÙ† Ø§Ù„Ø¯ÙˆÙ„â€¦",
            "create_shipping_ad" => "Ø¬Ø§Ø±ÙŠ Ù†Ø´Ø± Ø¥Ø¹Ù„Ø§Ù† Ø§Ù„Ø´Ø­Ù†â€¦",
            _ => $"Ø¨Ø³ØªØ¯Ø¹ÙŠ Ø£Ø¯Ø§Ø©: {toolName}â€¦"
        };

    private static string DescribeToolCallEn(string toolName) =>
        toolName switch
        {
            "get_my_last_order" => "Calling tool: your latest purchase (My Orders)â€¦",
            "get_my_purchase_summary" => "Calling tool: purchase summary / how much you spentâ€¦",
            "explain_my_order_delay" => "Calling tool: why your order may be delayedâ€¦",
            "get_my_sales_count" => "Calling tool: sales and orders on your adsâ€¦",
            "get_last_order_on_my_ads" => "Calling tool: latest order on your adsâ€¦",
            "explain_order_delay_on_my_ads" => "Calling tool: delay on an ad orderâ€¦",
            "find_cheapest_product" => "Calling tool: cheapest product matchâ€¦",
            "find_most_expensive_product" => "Calling tool: most expensive product matchâ€¦",
            "search_products" => "Calling tool: matching product adsâ€¦",
            "list_my_ads" => "Calling tool: your ad catalogâ€¦",
            "get_my_last_ad" => "Calling tool: your most recent adâ€¦",
            "get_my_first_ad" => "Calling tool: your earliest adâ€¦",
            "update_ad_price_quantity" => "Calling tool: update price/quantityâ€¦",
            "set_ad_listing_status" => "Calling tool: pause or activate an adâ€¦",
            "mark_ad_sold_out" => "Calling tool: mark sold outâ€¦",
            "delete_ad" => "Calling tool: delete an adâ€¦",
            "lookup_create_ad_reference" => "Exploring ad requirements (units/countries/port)â€¦",
            "list_my_addresses" => "Listing saved delivery addressesâ€¦",
            "create_request_ad" => "Creating the Request ad on the serverâ€¦",
            "create_booking_ad" => "Creating the Booking adâ€¦",
            "create_offer_ad" => "Creating the Offer adâ€¦",
            "create_retail_ad" => "Creating the Retail adâ€¦",
            "create_category_ad" => "Creating the Category adâ€¦",
            "search_shipping_prices" => "Searching shipping prices between countriesâ€¦",
            "create_shipping_ad" => "Publishing the shipping adâ€¦",
            _ => $"Calling tool: {toolName}â€¦"
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
                        ? $"Ø§Ù„Ø£Ø¯Ø§Ø© {toolName} Ø±Ø¬Ù‘Ø¹Øª Ø®Ø·Ø£."
                        : $"Ø§Ù„Ø£Ø¯Ø§Ø© {toolName}: {err}";
                }

                return string.IsNullOrWhiteSpace(err)
                    ? $"Tool {toolName} returned an error."
                    : $"Tool {toolName}: {err}";
            }

            if (doc.RootElement.TryGetProperty("found", out var found)
                && found.ValueKind == JsonValueKind.False)
            {
                return isArabic
                    ? $"Ø§Ù„Ø£Ø¯Ø§Ø© {toolName}: Ù…ÙÙŠØ´ Ø¨ÙŠØ§Ù†Ø§Øª Ù…Ø·Ø§Ø¨Ù‚Ø©."
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
                            ? "ØªÙ… Ø±ÙØ¹ Ø§Ù„ÙˆØ³Ø§Ø¦Ø·:\n" + string.Join("\n", paths)
                            : "Media uploaded:\n" + string.Join("\n", paths);
                    }

                    return isArabic
                        ? "ØªÙ… Ø¥Ù†Ø´Ø§Ø¡ Ø§Ù„Ø¥Ø¹Ù„Ø§Ù† ÙˆØ¥Ø±Ø³Ø§Ù„Ù‡ Ù„Ù„Ù…Ø±Ø§Ø¬Ø¹Ø©."
                        : "Ad created and submitted for review.";
                }
            }
            catch (JsonException)
            {
                // Fall through.
            }
        }

        return isArabic
            ? $"ÙˆØµÙ„ Ù†ØªÙŠØ¬Ø© Ù…Ù† {toolName}."
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
                var adLabel = string.IsNullOrWhiteSpace(adType) ? "Ø§Ù„Ø¥Ø¹Ù„Ø§Ù†" : adType.Trim();
                var title = string.IsNullOrWhiteSpace(name) ? string.Empty : $" Â«{name.Trim()}Â»";
                var codeSuffix = string.IsNullOrWhiteSpace(productCode)
                    ? string.Empty
                    : $" Ø±Ù…Ø² Ø§Ù„Ù…Ù†ØªØ¬ (ProductCode): {productCode.Trim()}.";

                if (submitted)
                {
                    return $"ØªÙ… Ø¥Ù†Ø´Ø§Ø¡ Ø¥Ø¹Ù„Ø§Ù† {adLabel}{title} Ø¨Ù†Ø¬Ø§Ø­ ÙˆØ¥Ø±Ø³Ø§Ù„Ù‡ Ù„Ù„Ù…Ø±Ø§Ø¬Ø¹Ø© Ù…Ù† Ø§Ù„Ø¥Ø¯Ø§Ø±Ø©.{codeSuffix} "
                           + "Ø³ØªØªÙ„Ù‚Ù‰ Ø¥Ø´Ø¹Ø§Ø±Ø§Ù‹ Ø¹Ù†Ø¯ Ø§Ù„Ù…ÙˆØ§ÙÙ‚Ø© Ø£Ùˆ Ø§Ù„Ø±ÙØ¶.";
                }

                return $"ØªÙ… Ø¥Ù†Ø´Ø§Ø¡ Ø¥Ø¹Ù„Ø§Ù† {adLabel}{title} Ø¨Ù†Ø¬Ø§Ø­.{codeSuffix}";
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
                ? "ØªÙ… Ø¥Ù†Ø´Ø§Ø¡ Ø§Ù„Ø¥Ø¹Ù„Ø§Ù† Ø¨Ù†Ø¬Ø§Ø­ ÙˆØ¥Ø±Ø³Ø§Ù„Ù‡ Ù„Ù„Ù…Ø±Ø§Ø¬Ø¹Ø© Ù…Ù† Ø§Ù„Ø¥Ø¯Ø§Ø±Ø©."
                : "Your ad was created and submitted for admin review.";
        }
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
