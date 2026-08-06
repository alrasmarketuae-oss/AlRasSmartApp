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
    /// per user turn (price/qty, pause/active, sold-out, delete, or withdrawal).
    /// </summary>
    private const int MaxSuccessfulMutationsPerTurn = 1;

    private static readonly HashSet<string> MutatingToolNames = new(StringComparer.Ordinal)
    {
        "update_ad_price_quantity",
        "set_ad_listing_status",
        "mark_ad_sold_out",
        "delete_ad",
        "create_withdrawal",
        "create_request_ad",
        "create_booking_ad",
        "create_offer_ad",
        "create_retail_ad",
        "create_category_ad",
        "create_shipping_ad"
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

    public async Task<string> CompleteWithToolsAsync(
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
                        await onThinkingStep(
                                PickMcpToolThinking(isArabic),
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
                                    "(update price/qty, pause/active, sold-out, delete, or withdrawal). " +
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
                    return FormatAdCreationSuccessMessage(successfulAdCreationPayload, isArabic);
                }

                continue;
            }

            var answer = msg.TryGetProperty("content", out var contentEl)
                ? contentEl.GetString()?.Trim()
                : null;

            if (!string.IsNullOrWhiteSpace(answer))
            {
                return answer;
            }

            if (successfulAdCreationPayload is not null)
            {
                return FormatAdCreationSuccessMessage(successfulAdCreationPayload, isArabic);
            }

            throw new InvalidOperationException("OpenAI returned an empty assistant answer.");
        }

        if (successfulAdCreationPayload is not null)
        {
            logger.LogWarning(
                "AI assistant hit the MCP tool-call limit ({MaxRounds}) after a successful ad create; returning success text.",
                MaxToolRounds);
            return FormatAdCreationSuccessMessage(successfulAdCreationPayload, isArabic);
        }

        logger.LogWarning("AI assistant exceeded the MCP tool-call limit ({MaxRounds}).", MaxToolRounds);
        throw new InvalidOperationException("AI assistant exceeded the tool-call limit.");
    }

    private static string DescribeToolCall(string toolName, bool isArabic) =>
        isArabic
            ? DescribeToolCallAr(toolName)
            : DescribeToolCallEn(toolName);

    private static string DescribeToolCallAr(string toolName) =>
        toolName switch
        {
            "get_my_last_order" => "بستدعي أداة: آخر طلب من طلباتي…",
            "get_my_purchase_summary" => "بستدعي أداة: ملخص مشترياتي / اشتريت بكام…",
            "explain_my_order_delay" => "بستدعي أداة: ليه الطلب متأخر (طلباتي)…",
            "get_my_sales_count" => "بستدعي أداة: المبيعات وطلبات الإعلانات…",
            "get_last_order_on_my_ads" => "بستدعي أداة: آخر طلب على إعلاناتي…",
            "explain_order_delay_on_my_ads" => "بستدعي أداة: تأخير طلب على الإعلان…",
            "find_cheapest_product" => "بستدعي أداة: أرخص منتج…",
            "find_most_expensive_product" => "بستدعي أداة: أغلى منتج…",
            "list_my_ads" => "بستدعي أداة: قائمة إعلاناتي…",
            "get_my_last_ad" => "بستدعي أداة: آخر إعلان نزلته…",
            "get_my_first_ad" => "بستدعي أداة: أول إعلان نزلته…",
            "update_ad_price_quantity" => "بستدعي أداة: تعديل السعر/الكمية…",
            "set_ad_listing_status" => "بستدعي أداة: إيقاف/تفعيل إعلان…",
            "mark_ad_sold_out" => "بستدعي أداة: تعليم نفاد الكمية…",
            "delete_ad" => "بستدعي أداة: حذف إعلان…",
            "list_my_ibans" => "بستدعي أداة: الآيبان والرصيد…",
            "create_withdrawal" => "بستدعي أداة: طلب سحب…",
            "lookup_create_ad_reference" => "بستدعي أداة: مراجع إنشاء الإعلان (وحدات/دول/موانئ)…",
            "list_my_addresses" => "بستدعي أداة: عناوين التسليم المحفوظة…",
            "create_request_ad" => "جاري إنشاء إعلان طلب على السحابة…",
            "create_booking_ad" => "جاري إنشاء إعلان Booking…",
            "create_offer_ad" => "جاري إنشاء إعلان Offer…",
            "create_retail_ad" => "جاري إنشاء إعلان Retail…",
            "create_category_ad" => "جاري إنشاء إعلان Category…",
            "search_shipping_prices" => "بستدعي أداة: أسعار الشحن بين الدول…",
            "create_shipping_ad" => "جاري نشر إعلان الشحن…",
            _ => $"بستدعي أداة: {toolName}…"
        };

    private static string DescribeToolCallEn(string toolName) =>
        toolName switch
        {
            "get_my_last_order" => "Calling tool: your latest purchase (My Orders)…",
            "get_my_purchase_summary" => "Calling tool: purchase summary / how much you spent…",
            "explain_my_order_delay" => "Calling tool: why your order may be delayed…",
            "get_my_sales_count" => "Calling tool: sales and orders on your ads…",
            "get_last_order_on_my_ads" => "Calling tool: latest order on your ads…",
            "explain_order_delay_on_my_ads" => "Calling tool: delay on an ad order…",
            "find_cheapest_product" => "Calling tool: cheapest product match…",
            "find_most_expensive_product" => "Calling tool: most expensive product match…",
            "list_my_ads" => "Calling tool: your ad catalog…",
            "get_my_last_ad" => "Calling tool: your most recent ad…",
            "get_my_first_ad" => "Calling tool: your earliest ad…",
            "update_ad_price_quantity" => "Calling tool: update price/quantity…",
            "set_ad_listing_status" => "Calling tool: pause or activate an ad…",
            "mark_ad_sold_out" => "Calling tool: mark sold out…",
            "delete_ad" => "Calling tool: delete an ad…",
            "list_my_ibans" => "Calling tool: balance and saved IBANs…",
            "create_withdrawal" => "Calling tool: create withdrawal request…",
            "lookup_create_ad_reference" => "Exploring ad requirements (units/countries/port)…",
            "list_my_addresses" => "Listing saved delivery addresses…",
            "create_request_ad" => "Creating the Request ad on the server…",
            "create_booking_ad" => "Creating the Booking ad…",
            "create_offer_ad" => "Creating the Offer ad…",
            "create_retail_ad" => "Creating the Retail ad…",
            "create_category_ad" => "Creating the Category ad…",
            "search_shipping_prices" => "Searching shipping prices between countries…",
            "create_shipping_ad" => "Publishing the shipping ad…",
            _ => $"Calling tool: {toolName}…"
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

    private static readonly string[] McpToolThinkingAr =
    [
        "الشبكة العصبية تراجع السياق الكامل للبيانات…",
        "أجري استدلالًا أعمق عبر التفاصيل المجمّعة…",
        "طبقة الذكاء تربط المعلومات الآن…",
        "أجري تحليلًا دلاليًا لفهم الإعلان بدقة أكبر…",
        "أراجع النتائج المستنتجة قبل تثبيت أي شيء…",
        "تحليل ذكاء اصطناعي أعمق يعمل في الخلفية…",
        "أتحقق كيف يؤثر كل تفصيل على بقية الإعلان…",
        "أمرّر البيانات عبر طبقة الفهم قبل الإنشاء…",
        "أطابق التفاصيل المجمّعة بذكاء قبل المتابعة…",
        "أراجع السياق الكامل قبل الخطوة التالية…",
        "النموذج يحلّل العلاقات وليس الكلمات فقط…",
        "أجري مرحلة الاستدلال النهائية قبل الحفظ…",
        "أبحث عن أي تعارضات محتملة قبل تأكيد البيانات…",
        "تحليل عميق يعمل — أربط التفاصيل معًا…",
        "أدع النموذج يتحقق أن الصورة الكاملة منطقية…",
        "أجري تحققًا دلاليًا قبل تحويل البيانات إلى إعلان…",
        "طبقة ذكاء تراجع النتيجة من زاوية أخرى…",
        "أختبر الاتساق عبر الحقول قبل التنفيذ…",
        "أراجع ما فهمه النموذج قبل اعتماده…",
        "النموذج يجمع إشارات دقيقة لبناء النتيجة النهائية…",
        "أجري تحليل ذكاء اصطناعي متعدد المراحل قبل النشر…",
        "أراجع البيانات بمستوى أعمق قبل الإرسال…",
        "الاستدلال يعمل الآن — لحظة قبل المتابعة…",
        "أربط المعنى بالسياق قبل الخطوة الأخيرة…",
        "أشغّل طبقة الذكاء النهائية الآن…",
        "أراجع النتيجة عبر إشارات متعددة قبل التأكيد…",
        "النموذج يقارن التفاصيل داخليًا قبل تثبيت الإعلان…",
        "أجري مراجعة أخيرة بمستوى الذكاء للصورة الكاملة…",
        "التحليل يصل لمرحلته النهائية — أجهّز القرار الأخير…",
        "الذكاء الاصطناعي أوشك على إنهاء التحليل — أثبّت النتيجة الآن…"
    ];

    private static readonly string[] McpToolThinkingEn =
    [
        "The neural network is reviewing the full context of the data…",
        "Running deeper reasoning across the collected details…",
        "The intelligence layer is connecting the information now…",
        "Running semantic analysis to understand the ad more precisely…",
        "Reviewing the inferred results before locking anything in…",
        "A deeper AI analysis is running in the background…",
        "Checking how each detail affects the rest of the ad…",
        "Passing the data through the understanding layer before creation…",
        "Matching the collected details intelligently before proceeding…",
        "Reviewing the full context before taking the next step…",
        "The model is analyzing relationships, not just individual words…",
        "Running the final inference stage before saving…",
        "Checking for possible inconsistencies before confirming the data…",
        "Deep analysis is running — connecting the details together…",
        "Letting the model verify that the complete picture makes sense…",
        "Running semantic validation before turning the data into an ad…",
        "An intelligence layer is reviewing the result from another angle…",
        "Testing consistency across the fields before execution…",
        "Reviewing what the model understood before committing it…",
        "The model is combining subtle signals to build the final result…",
        "Running multi-stage AI analysis before publishing…",
        "Reviewing the data at a deeper level before submission…",
        "Inference is running now — just a moment before we continue…",
        "Connecting meaning with context before the final step…",
        "Running the final intelligence layer now…",
        "Cross-checking the result using multiple signals before confirmation…",
        "The model is comparing the details internally before locking the ad…",
        "Performing one final AI-level review of the complete picture…",
        "The analysis is reaching its final stage — preparing the final decision…",
        "The AI has nearly completed its analysis — locking in the result now…"
    ];

    private static string PickMcpToolThinking(bool isArabic)
    {
        var pool = isArabic ? McpToolThinkingAr : McpToolThinkingEn;
        return pool[Random.Shared.Next(pool.Length)];
    }
}
