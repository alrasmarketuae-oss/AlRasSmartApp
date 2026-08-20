using System.Text.Json;
using BusinessLayer.Caching;
using BusinessLayer.Helpers;
using BusinessLayer.Interfaces;
using BusinessLayer.Services;
using DataLayer.Interfaces;
using DataLayer.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;

namespace BusinessLayer.Services.AiAssistant.Mcp;

/// <summary>
/// MCP-style backend tools the OpenAI model can request. Our API executes them (not the model).
/// Flow: model returns tool_calls JSON → this service runs →
/// tool JSON is sent back to the model → model writes the final user answer.
/// </summary>
public sealed partial class AiAssistantMcpToolsService(
    IRasAlSouqDbContext dbContext,
    IServiceScopeFactory scopeFactory,
    ProductCacheVersions productCacheVersions,
    ICommissionSettingsProvider commissionSettingsProvider,
    ICategoryCommissionProvider categoryCommissionProvider,
    IConfiguration configuration,
    ILogger<AiAssistantMcpToolsService> logger) : IAiAssistantToolsService
{
    public IReadOnlyList<object> GetToolDefinitions() =>
    [
        new
        {
            type = "function",
            function = new
            {
                name = "update_ad_price_quantity",
                description =
                    "Update price and/or quantity of EXACTLY ONE of the signed-in seller's own ads per turn. " +
                    "NEVER update all ads, every ad, or multiple ads — even if the user asks. " +
                    "If the user says change all / كل إعلاناتي / جميع الإعلانات, refuse and ask them to name ONE specific ad (or ProductCode). " +
                    "MOST ads have a SINGLE price. Call this tool immediately — do NOT ask جملة/تجزئة and do NOT tell the user whether the ad is hybrid. " +
                    "Omit channel unless the user clearly said جملة/wholesale or تجزئة/retail. " +
                    "ONLY if this tool returns needs_channel_clarification=true, then ask جملة ولا تجزئة؟ and call again with channel. " +
                    "Never mention هجين / wholesale / retail / جملة / تجزئة in the user reply unless that clarification was required. " +
                    "Use the SELLER ADS CATALOG / list_my_ads names. If the spoken/typed name is a unique exact match, update immediately. " +
                    "If the name is a slight typo or matches several ads, the tool returns needs_clarification with suggestions — " +
                    "ask the user in their language: did you mean ad A or ad B? When they pick one, call again with that exact product_name or product_code.",
                parameters = new
                {
                    type = "object",
                    properties = new
                    {
                        product_name = new
                        {
                            type = "string",
                            description = "Ad/product name as the seller knows it (Arabic or English)."
                        },
                        product_code = new
                        {
                            type = "string",
                            description =
                                "Exact ProductCode (wholesale) or RetailCode (retail) when the user picked a specific ad."
                        },
                        channel = new
                        {
                            type = "string",
                            description =
                                "Pass ONLY if the user clearly said جملة/wholesale or تجزئة/retail. " +
                                "Otherwise omit. The tool asks for a channel only when the ad is actually hybrid."
                        },
                        price = new
                        {
                            type = "number",
                            description = "New price for the selected channel only. Omit to leave unchanged."
                        },
                        quantity = new
                        {
                            type = "integer",
                            description =
                                "New stock quantity for the selected channel only (ad unit; not grams unless unit is Gram). Omit to leave unchanged."
                        }
                    },
                    additionalProperties = false
                }
            }
        },
        new
        {
            type = "function",
            function = new
            {
                name = "list_my_ads",
                description =
                    "List all ads owned by the signed-in seller (names Arabic/English, ProductCode, price, quantity). " +
                    "Call this when helping the seller pick which ad to update, or when the catalog may be incomplete.",
                parameters = new
                {
                    type = "object",
                    properties = new { },
                    additionalProperties = false
                }
            }
        },
        new
        {
            type = "function",
            function = new
            {
                name = "get_my_last_ad",
                description =
                    "Return the signed-in seller's MOST RECENTLY created ad (آخر إعلان نزلته / نشرته / أضفته / last ad I posted). " +
                    "Ordered by Product.CreatedAt descending. Use for 'هات آخر إعلان' — NOT for last order/sale.",
                parameters = new
                {
                    type = "object",
                    properties = new { },
                    additionalProperties = false
                }
            }
        },
        new
        {
            type = "function",
            function = new
            {
                name = "get_my_first_ad",
                description =
                    "Return the signed-in seller's EARLIEST created ad (أول إعلان نزلته / نشرته / أضفته / first ad I posted). " +
                    "Ordered by Product.CreatedAt ascending. Use for 'هات أول إعلان' — NOT for first order.",
                parameters = new
                {
                    type = "object",
                    properties = new { },
                    additionalProperties = false
                }
            }
        },
        new
        {
            type = "function",
            function = new
            {
                name = "find_cheapest_product",
                description =
                    "Find the cheapest publicly active approved marketplace listing matching a product name " +
                    "(Arabic or English; synonyms like هيل/cardamom are matched). " +
                    "Compares BOTH wholesale/category and retail channels on hybrid ads as separate candidates. " +
                    "Ranks by buyer-facing price AFTER commission markup. " +
                    "Always report productCode from the winning channel (RetailCode for retail, ProductCode for wholesale), " +
                    "customerPrice with currency, channel, and quantity with unitName (do not invent grams/kg).",
                parameters = new
                {
                    type = "object",
                    properties = new
                    {
                        product_name = new
                        {
                            type = "string",
                            description = "Product name to search for (Arabic or English)."
                        }
                    },
                    required = new[] { "product_name" },
                    additionalProperties = false
                }
            }
        },
        new
        {
            type = "function",
            function = new
            {
                name = "find_most_expensive_product",
                description =
                    "Find the most expensive publicly active approved marketplace listing matching a product name " +
                    "(Arabic or English; synonyms matched). " +
                    "Compares BOTH wholesale/category and retail channels on hybrid ads as separate candidates. " +
                    "Ranks by buyer-facing price AFTER commission markup. " +
                    "Always report productCode from the winning channel (RetailCode for retail, ProductCode for wholesale), " +
                    "customerPrice with currency, channel, and quantity with unitName.",
                parameters = new
                {
                    type = "object",
                    properties = new
                    {
                        product_name = new
                        {
                            type = "string",
                            description = "Product name to search for (Arabic or English)."
                        }
                    },
                    required = new[] { "product_name" },
                    additionalProperties = false
                }
            }
        },
        new
        {
            type = "function",
            function = new
            {
                name = "search_products",
                description =
                    "Search publicly active approved marketplace ads by product name or type " +
                    "(Arabic or English; synonyms like هيل/cardamom). " +
                    "Use when the user wants ads, listings, product cards, or examples of a product — " +
                    "not specifically the cheapest/most expensive. " +
                    "Returns listing cards the app shows in chat. Compare BOTH wholesale/category and retail channels.",
                parameters = new
                {
                    type = "object",
                    properties = new
                    {
                        product_name = new
                        {
                            type = "string",
                            description = "Product name or type to search for (Arabic or English)."
                        }
                    },
                    required = new[] { "product_name" },
                    additionalProperties = false
                }
            }
        },
        new
        {
            type = "function",
            function = new
            {
                name = "get_my_sales_count",
                description =
                    "SELLER ONLY — summary of customer orders ON THIS USER'S ADS (الطلبات على إعلاناتي / مبيعاتي): " +
                    "completed received/delivered sales count AND earnings, plus pending/open orders grouped by product name. " +
                    "NEVER use for My Orders / طلباتي (purchases this user made as a buyer). " +
                    "Use when they ask about sales, orders on my ads, طلبات على إعلاناتي, مبيعاتي.",
                parameters = new
                {
                    type = "object",
                    properties = new { },
                    additionalProperties = false
                }
            }
        },
        new
        {
            type = "function",
            function = new
            {
                name = "get_last_order_on_my_ads",
                description =
                    "SELLER ONLY — the latest customer order placed ON this user's ads (آخر طلب على إعلاناتي). " +
                    "NEVER use for My Orders / طلباتي. For the user's own purchase use get_my_last_order instead.",
                parameters = new
                {
                    type = "object",
                    properties = new { },
                    additionalProperties = false
                }
            }
        },
        new
        {
            type = "function",
            function = new
            {
                name = "explain_order_delay_on_my_ads",
                description =
                    "SELLER ONLY — explain why a customer order on this user's ads may be delayed. " +
                    "Defaults to the latest incoming ad order; pass order_id for a specific one. " +
                    "NEVER use for the user's own purchases (use explain_my_order_delay for طلباتي).",
                parameters = new
                {
                    type = "object",
                    properties = new
                    {
                        order_id = new
                        {
                            type = "string",
                            description = "Optional numeric order id on the seller's ads."
                        }
                    },
                    additionalProperties = false
                }
            }
        },
        new
        {
            type = "function",
            function = new
            {
                name = "set_ad_listing_status",
                description =
                    "Pause or reactivate EXACTLY ONE of the seller's own approved ads. " +
                    "action must be \"pause\" or \"active\". Never change multiple ads in one turn. " +
                    "Resolve the ad by product_code or unique product_name first.",
                parameters = new
                {
                    type = "object",
                    properties = new
                    {
                        action = new
                        {
                            type = "string",
                            description = "\"pause\" or \"active\"."
                        },
                        product_name = new { type = "string", description = "Ad name." },
                        product_code = new { type = "string", description = "ProductCode or RetailCode." }
                    },
                    required = new[] { "action" },
                    additionalProperties = false
                }
            }
        },
        new
        {
            type = "function",
            function = new
            {
                name = "mark_ad_sold_out",
                description =
                    "Mark EXACTLY ONE owned ad as sold out (quantity = 0). Call immediately. " +
                    "Do NOT ask جملة/تجزئة unless this tool returns needs_channel_clarification=true. " +
                    "Most ads have a single stock quantity. Never mention hybrid/wholesale/retail unless that clarification was required.",
                parameters = new
                {
                    type = "object",
                    properties = new
                    {
                        product_name = new { type = "string" },
                        product_code = new { type = "string" },
                        channel = new
                        {
                            type = "string",
                            description = "\"wholesale\" or \"retail\" for hybrid ads."
                        }
                    },
                    additionalProperties = false
                }
            }
        },
        new
        {
            type = "function",
            function = new
            {
                name = "delete_ad",
                description =
                    "Permanently delete EXACTLY ONE of the seller's ads. " +
                    "First call without confirm (or confirm=false) to preview; after the user explicitly agrees, call again with confirm=true. " +
                    "Never delete without confirm=true.",
                parameters = new
                {
                    type = "object",
                    properties = new
                    {
                        product_name = new { type = "string" },
                        product_code = new { type = "string" },
                        confirm = new
                        {
                            type = "boolean",
                            description = "Must be true to actually delete after user confirmation."
                        }
                    },
                    additionalProperties = false
                }
            }
        },
        new
        {
            type = "function",
            function = new
            {
                name = "get_my_purchase_summary",
                description =
                    "AS BUYER — how much THIS USER spent on purchases they placed (My Orders / طلباتي / اشتريت بكام). " +
                    "Works for suppliers too: suppliers can buy. " +
                    "NEVER use for sales or orders customers placed on this user's ads (use get_my_sales_count).",
                parameters = new
                {
                    type = "object",
                    properties = new { },
                    additionalProperties = false
                }
            }
        },
        new
        {
            type = "function",
            function = new
            {
                name = "get_my_last_order",
                description =
                    "AS BUYER — THIS USER's most recent purchase in My Orders (طلباتي / هاتلي آخر اوردر). " +
                    "Works for suppliers too: suppliers can place orders and track them here. " +
                    "NEVER use for orders on the seller's ads (use get_last_order_on_my_ads).",
                parameters = new
                {
                    type = "object",
                    properties = new { },
                    additionalProperties = false
                }
            }
        },
        new
        {
            type = "function",
            function = new
            {
                name = "explain_my_order_delay",
                description =
                    "AS BUYER — why THIS USER's purchase in My Orders may be delayed (آخر اوردر متأخر ليه in طلباتي). " +
                    "Works for suppliers too when asking about an order they bought. " +
                    "Defaults to latest buyer order; pass order_id if specified. " +
                    "NEVER use for delays on ads (use explain_order_delay_on_my_ads).",
                parameters = new
                {
                    type = "object",
                    properties = new
                    {
                        order_id = new
                        {
                            type = "string",
                            description = "Optional numeric order id from My Orders."
                        }
                    },
                    additionalProperties = false
                }
            }
        },
        new
        {
            type = "function",
            function = new
            {
                name = "lookup_create_ad_reference",
                description =
                    "Lookup static create-ad reference data: units, product_types, categories, request_types (Local/Reexport), " +
                    "countries, or ports (requires country_name). Use while collecting ad fields from the user.",
                parameters = new
                {
                    type = "object",
                    properties = new
                    {
                        lookup = new
                        {
                            type = "string",
                            description = "units | product_types | categories | request_types | countries | ports | booking_price_types"
                        },
                        query = new
                        {
                            type = "string",
                            description = "Optional filter text (country/port/category name)."
                        },
                        country_name = new
                        {
                            type = "string",
                            description = "Required when lookup=ports. Arabic or English country name."
                        }
                    },
                    required = new[] { "lookup" },
                    additionalProperties = false
                }
            }
        },
        new
        {
            type = "function",
            function = new
            {
                name = "list_my_addresses",
                description =
                    "List the signed-in user's saved delivery addresses (id + label/city/lines). " +
                    "REQUIRED before create_request_ad for company_customer: pick address_id from this list. " +
                    "If empty, tell the user to add an address in Profile / Create Order first — never invent a GUID.",
                parameters = new
                {
                    type = "object",
                    properties = new { },
                    additionalProperties = false
                }
            }
        },
        new
        {
            type = "function",
            function = new
            {
                name = "create_request_ad",
                description =
                    "Create ONE Request ad (طلب / Request) using the same backend API as mobile Create Ad / Create Order. " +
                    "Allowed audiences: supplier OR company_customer only. " +
                    "Collect required fields first: name, specifications, negotiable, request_type Local/Reexport, packaging (ALWAYS ask). " +
                    "OPTIONAL: target price, quantity, unit_name, currency — omit any the user did not provide. " +
                    "If target price is provided, also collect currency (USD/AED) and unit_name. " +
                    "request_type_name Local or Reexport (محلي / إعادة تصدير) — ALWAYS ask, " +
                    "address_id from list_my_addresses (REQUIRED for company_customer; recommended for supplier), " +
                    "specifications, packaging kg (ALWAYS ask; user may say none), " +
                    "optional delivery_date (YYYY-MM-DD), optional media. " +
                    "Never publish without Local/Reexport. Never invent address_id. " +
                    "After the user confirms, call once with submit_for_review=true (default). " +
                    "Only ONE ad per user message.",
                parameters = new
                {
                    type = "object",
                    properties = new
                    {
                        name = new { type = "string", description = "Product/ad name." },
                        price = new { type = "number", description = "Target price." },
                        quantity = new { type = "integer", description = "Required quantity." },
                        unit_name = new
                        {
                            type = "string",
                            description = "Ton, Kilogram, Carton, Bag, Box, Piece, Gram, Dozen (Arabic ok). For 5 tons use quantity=5 and unit_name=Ton."
                        },
                        unit_id = new
                        {
                            type = "integer",
                            description = "1=Ton, 2=Gram, 3=Kg, 4=Carton, 5=Bag, 6=Dozen, 7=Box, 8=Piece — NOT product type ids."
                        },
                        quantity_with_unit = new
                        {
                            type = "string",
                            description = "Optional combined text like '5 ton' or '5 طن'."
                        },
                        currency = new { type = "string", description = "USD or AED." },
                        negotiable = new { type = "boolean", description = "Is price negotiable?" },
                        request_type_name = new
                        {
                            type = "string",
                            description = "REQUIRED: Local or Reexport (محلي / إعادة تصدير)."
                        },
                        request_type_id = new { type = "integer", description = "1=Local, 2=Reexport" },
                        address_id = new
                        {
                            type = "string",
                            description =
                                "Saved delivery address GUID from list_my_addresses. " +
                                "Required for company_customer; recommended for supplier Request ads."
                        },
                        delivery_date = new
                        {
                            type = "string",
                            description = "Optional required-delivery date YYYY-MM-DD."
                        },
                        specifications = new { type = "string", description = "Product specifications." },
                        packaging = new { type = "integer", description = "Optional packing kg 1-255." },
                        draft_image_paths = new
                        {
                            type = "array",
                            items = new { type = "string" },
                            description = "R2 draft image paths already uploaded (product-images/drafts/…)."
                        },
                        draft_video_path = new
                        {
                            type = "string",
                            description = "Optional R2 draft video path (product-videos/drafts/…)."
                        },
                        draft_video_duration_seconds = new
                        {
                            type = "integer",
                            description = "Required when draft_video_path is set."
                        },
                        created_language = new { type = "string", description = "ar or en." },
                        submit_for_review = new
                        {
                            type = "boolean",
                            description = "Default true — submit to admin review after create."
                        }
                    },
                    required = new[]
                    {
                        "name", "price", "quantity", "unit_name", "request_type_name", "specifications"
                    },
                    additionalProperties = false
                }
            }
        },
        CreateAdToolDefinition(
            "create_booking_ad",
            "Create ONE Booking ad (supplier only). Currency is always USD. Ask FOB/CNF/CIF first. FOB: exporting country (الدولة المصدرة) ONLY — never destination or ports. CNF/CIF: MUST collect exporting country + loading port + destination country + arrival port before calling. Also: name, price, qty, unit, shipping days, negotiable, specs, packaging (ALWAYS ask), media.",
            ["name", "price", "quantity", "unit_name", "origin_country_name", "booking_price_type_name", "shipping_duration_days", "specifications"]),
        CreateAdToolDefinition(
            "create_offer_ad",
            "Create ONE Offer ad (supplier only). Collect BEFORE calling: product name, media, price_before, price_after, offer_duration_days, quantity, unit_name, currency, negotiable, Local/Reexport, specifications, packaging kg (ALWAYS ask; user may say none).",
            ["name", "price_before", "price_after", "offer_duration_days", "quantity", "unit_name", "currency", "request_type_name", "specifications"]),
        CreateAdToolDefinition(
            "create_retail_ad",
            "Create ONE Retail ad (supplier only). Currency is always AED. Collect BEFORE calling: product name, media, price, quantity, unit_name, delivery_days, negotiable, specifications, packaging kg (ALWAYS ask; user may say none).",
            ["name", "price", "quantity", "unit_name", "delivery_days", "specifications"]),
        CreateAdToolDefinition(
            "create_category_ad",
            "Create ONE Category ad (supplier only). Collect BEFORE calling: product name, category_id/name, media, wholesale price, quantity, unit_name, currency, negotiable, Local/Reexport, wholesale specifications, packaging kg (ALWAYS ask; user may say none). "
            + "HYBRID (enable_retail_pricing=true): you MUST also ask and collect SEPARATE retail fields BEFORE calling the tool: retail_price (AED), retail_quantity, retail_unit_name, retail_specifications (مواصفات التجزئة — never skip; do NOT copy wholesale specs unless user says same), optional retail_packaging. "
            + "Never call create_category_ad with enable_retail_pricing=true until retail_specifications is present.",
            ["name", "price", "quantity", "unit_name", "category_id", "request_type_name", "specifications"]),
        new
        {
            type = "function",
            function = new
            {
                name = "search_shipping_prices",
                description =
                    "Search approved international shipping ads (أسعار الشحن) from one country to another. " +
                    "Pass from_country_name and to_country_name (Arabic or English). Ports are optional. " +
                    "Returns company names, 20ft/40ft USD prices (buyer-facing with markup), duration days, and route. " +
                    "Use when the user asks shipping cost / سعر شحن / من دولة إلى دولة.",
                parameters = new
                {
                    type = "object",
                    properties = new
                    {
                        from_country_name = new
                        {
                            type = "string",
                            description = "Origin/export country (e.g. Egypt / مصر / UAE / الإمارات)."
                        },
                        to_country_name = new
                        {
                            type = "string",
                            description = "Destination country (e.g. UAE / الإمارات / Saudi Arabia)."
                        },
                        from_port_name = new
                        {
                            type = "string",
                            description = "Optional loading port filter."
                        },
                        to_port_name = new
                        {
                            type = "string",
                            description = "Optional arrival port filter."
                        }
                    },
                    required = new[] { "from_country_name", "to_country_name" },
                    additionalProperties = false
                }
            }
        },
        CreateAdToolDefinition(
            "create_shipping_ad",
            "Create ONE shipping company ad (shipping audience only). Collect: from/to country + port, min/max shipping duration days, optional container 20ft and/or 40ft USD prices, specifications/details. Uses profile phone if phone_number omitted.",
            ["from_country_name", "from_port_name", "to_country_name", "to_port_name", "min_duration_days", "max_duration_days", "specifications"]),
        SubmitFeedbackToolDefinition
    ];

    public async Task<AiToolResult> ExecuteAsync(
        Guid? userId,
        AiToolCall call,
        CancellationToken cancellationToken = default)
    {
        try
        {
            var content = call.Name switch
            {
                "update_ad_price_quantity" => await UpdateAdPriceQuantityAsync(
                    userId, call.ArgumentsJson, cancellationToken).ConfigureAwait(false),
                "list_my_ads" => await ListMyAdsAsync(userId, cancellationToken).ConfigureAwait(false),
                "get_my_last_ad" => await GetMyLastAdAsync(userId, cancellationToken).ConfigureAwait(false),
                "get_my_first_ad" => await GetMyFirstAdAsync(userId, cancellationToken).ConfigureAwait(false),
                "find_cheapest_product" => await FindCheapestProductAsync(
                    call.ArgumentsJson, cancellationToken).ConfigureAwait(false),
                "find_most_expensive_product" => await FindMostExpensiveProductAsync(
                    call.ArgumentsJson, cancellationToken).ConfigureAwait(false),
                "search_products" => await SearchProductsAsync(
                    call.ArgumentsJson, cancellationToken).ConfigureAwait(false),
                "get_my_sales_count" => await GetMySalesCountAsync(
                    userId, cancellationToken).ConfigureAwait(false),
                "get_last_order_on_my_ads" => await GetLastOrderOnMyAdsAsync(
                    userId, cancellationToken).ConfigureAwait(false),
                "explain_order_delay_on_my_ads" => await ExplainOrderDelayOnMyAdsAsync(
                    userId, call.ArgumentsJson, cancellationToken).ConfigureAwait(false),
                "set_ad_listing_status" => await SetAdListingStatusAsync(
                    userId, call.ArgumentsJson, cancellationToken).ConfigureAwait(false),
                "mark_ad_sold_out" => await MarkAdSoldOutAsync(
                    userId, call.ArgumentsJson, cancellationToken).ConfigureAwait(false),
                "delete_ad" => await DeleteAdAsync(
                    userId, call.ArgumentsJson, cancellationToken).ConfigureAwait(false),
                "get_my_purchase_summary" => await GetMyPurchaseSummaryAsync(
                    userId, cancellationToken).ConfigureAwait(false),
                "get_my_last_order" => await GetMyLastOrderAsync(
                    userId, cancellationToken).ConfigureAwait(false),
                "explain_my_order_delay" => await ExplainMyOrderDelayAsync(
                    userId, call.ArgumentsJson, cancellationToken).ConfigureAwait(false),
                "lookup_create_ad_reference" => await LookupCreateAdReferenceAsync(
                    call.ArgumentsJson, cancellationToken).ConfigureAwait(false),
                "list_my_addresses" => await ListMyAddressesAsync(
                    userId, cancellationToken).ConfigureAwait(false),
                "create_request_ad" => await CreateRequestAdAsync(
                    userId, call.ArgumentsJson, cancellationToken).ConfigureAwait(false),
                "create_booking_ad" => await CreateBookingAdAsync(
                    userId, call.ArgumentsJson, cancellationToken).ConfigureAwait(false),
                "create_offer_ad" => await CreateOfferAdAsync(
                    userId, call.ArgumentsJson, cancellationToken).ConfigureAwait(false),
                "create_retail_ad" => await CreateRetailAdAsync(
                    userId, call.ArgumentsJson, cancellationToken).ConfigureAwait(false),
                "create_category_ad" => await CreateCategoryAdAsync(
                    userId, call.ArgumentsJson, cancellationToken).ConfigureAwait(false),
                "search_shipping_prices" => await SearchShippingPricesAsync(
                    call.ArgumentsJson, cancellationToken).ConfigureAwait(false),
                "create_shipping_ad" => await CreateShippingAdAsync(
                    userId, call.ArgumentsJson, cancellationToken).ConfigureAwait(false),
                "submit_feedback" => await SubmitFeedbackAsync(
                    userId, call.ArgumentsJson, cancellationToken).ConfigureAwait(false),
                _ => Json(new { ok = false, error = $"Unknown tool: {call.Name}" })
            };
            return new AiToolResult(call.Id, call.Name, content);
        }
        catch (Exception ex) when (ex is not OperationCanceledException)
        {
            logger.LogWarning(ex, "AI tool {Tool} failed", call.Name);
            return new AiToolResult(
                call.Id,
                call.Name,
                Json(new { ok = false, error = ex.Message }));
        }
    }

    private async Task<string> UpdateAdPriceQuantityAsync(
        Guid? userId,
        string argumentsJson,
        CancellationToken cancellationToken)
    {
        if (!userId.HasValue)
        {
            return Json(new
            {
                ok = false,
                error = "Sign in as the ad owner to update price or quantity."
            });
        }

        using var args = JsonDocument.Parse(string.IsNullOrWhiteSpace(argumentsJson) ? "{}" : argumentsJson);
        var root = args.RootElement;
        var productCode = GetString(root, "product_code");
        var productName = GetString(root, "product_name");
        var channel = NormalizeUpdateChannel(GetString(root, "channel"))
                      ?? InferUpdateChannelFromText(productName);
        decimal? price = GetDecimal(root, "price");
        long? quantity = GetLong(root, "quantity");

        if (!price.HasValue && !quantity.HasValue)
        {
            return Json(new { ok = false, error = "Provide at least price or quantity to update." });
        }

        if (price is <= 0)
        {
            return Json(new { ok = false, error = "Price must be greater than zero." });
        }

        if (quantity is < 0)
        {
            return Json(new { ok = false, error = "Quantity cannot be negative." });
        }

        var owned = dbContext.Products.Where(p => p.OwnerId == userId.Value);

        if (!string.IsNullOrWhiteSpace(productCode))
        {
            var code = productCode.Trim();
            var product = await owned
                .Include(p => p.Unit)
                .Include(p => p.RetailUnit)
                .FirstOrDefaultAsync(
                    p => (p.ProductCode != null && p.ProductCode.ToLower() == code.ToLower())
                         || (p.RetailCode != null && p.RetailCode.ToLower() == code.ToLower()),
                    cancellationToken)
                .ConfigureAwait(false);

            if (product is null)
            {
                return Json(new
                {
                    ok = false,
                    error = $"No ad with ProductCode '{code}' was found on your account."
                });
            }

            channel ??= InferChannelFromProductCode(product, code);
            return await ApplyPriceQuantityUpdateAsync(product, price, quantity, channel, cancellationToken)
                .ConfigureAwait(false);
        }

        if (string.IsNullOrWhiteSpace(productName))
        {
            return Json(new
            {
                ok = false,
                error = "Provide product_code or product_name."
            });
        }

        if (LooksLikeBulkUpdateRequest(productName))
        {
            return Json(new
            {
                ok = false,
                blocked_bulk_update = true,
                error =
                    "Bulk updates are not allowed. Update only one specific ad. " +
                    "Ask the user which single ad (name or ProductCode) they want to change."
            });
        }

        var candidates = await LoadOwnerNameCandidatesAsync(userId.Value, cancellationToken)
            .ConfigureAwait(false);
        var ranked = RankOwnerAdsByName(productName, candidates);

        if (ranked.Count == 0)
        {
            return Json(new
            {
                ok = false,
                needs_clarification = true,
                error = $"No ads named like '{productName.Trim()}' were found on your account.",
                message =
                    "Tell the user no close match was found. Ask which ad they meant using the SELLER ADS CATALOG / suggestions below by name.",
                suggestions = candidates
                    .OrderBy(x => x.NameEn)
                    .Take(20)
                    .Select(ToAdSuggestion)
                    .ToList()
            });
        }

        var best = ranked[0];
        var secondScore = ranked.Count > 1 ? ranked[1].Score : 0;
        var uniqueStrong =
            best.Score >= 85
            && (ranked.Count == 1 || best.Score - secondScore >= 12);

        // Unique strong lexical match → resolve channel then update (or ask).
        if (uniqueStrong && best.Score >= 85)
        {
            var strongPeers = ranked.Where(x => x.Score == best.Score).ToList();
            if (strongPeers.Count == 1)
        {
            var tracked = await dbContext.Products
                .Include(p => p.Unit)
                    .Include(p => p.RetailUnit)
                    .FirstAsync(p => p.ProductId == best.ProductId, cancellationToken)
                .ConfigureAwait(false);

                return await ApplyPriceQuantityUpdateAsync(
                        tracked, price, quantity, channel, cancellationToken)
                .ConfigureAwait(false);
            }
        }

        // Typo / several close names → ask: did you mean this ad or that ad?
        var suggestions = ranked.Take(5).Select(ToAdSuggestion).ToList();
        return Json(new
        {
            ok = false,
            needs_clarification = true,
            message =
                "Ask the user which ad they meant, listing each suggestion by display name " +
                "(prefer Arabic name when speaking Arabic). Example: هل تقصد «X» أم «Y»؟ " +
                "When they choose, call update_ad_price_quantity again with that product_code or exact product_name. Do not invent ads.",
            query = productName.Trim(),
            suggestions
        });
    }

    private async Task<string> ApplyPriceQuantityUpdateAsync(
        Product product,
        decimal? price,
        long? quantity,
        string? channel,
        CancellationToken cancellationToken)
    {
        var isHybrid = ProductTypeCodes.HasRetailStockConfigured(product);
        var resolvedChannel = NormalizeUpdateChannel(channel);

        if (!isHybrid)
        {
            // Single-price listing: ignore any wholesale/retail guess and update the only price.
            resolvedChannel = "listing";
        }
        else if (resolvedChannel is null)
        {
            return Json(new
            {
                ok = false,
                needs_channel_clarification = true,
                isHybrid = true,
                productCode = product.ProductCode,
                retailCode = product.RetailCode,
                nameEn = product.NameEn,
                wholesalePrice = product.USDPrice,
                wholesaleQuantity = product.Quantity,
                wholesaleUnit = product.Unit?.UnitNameEn,
                retailPrice = product.RetailPrice,
                retailQuantity = product.RetailQuantity,
                retailUnit = product.RetailUnit?.UnitNameEn,
                message =
                    "This ONE ad has two prices (جملة + تجزئة). Do NOT update yet. " +
                    "Ask ONLY: جملة ولا تجزئة؟ / wholesale or retail? " +
                    "Do not explain hybrid theory. Then call again with channel=wholesale or channel=retail " +
                    "(and the same product_code/name). Never update both channels in one request."
            });
        }

        if (resolvedChannel == "retail")
        {
            var beforeRetailPrice = product.RetailPrice;
            var beforeRetailQty = product.RetailQuantity;
            var retailUnitName = product.RetailUnit?.UnitNameEn;

            if (price.HasValue) product.RetailPrice = price.Value;
            if (quantity.HasValue) product.RetailQuantity = quantity.Value;
            product.UpdatedAt = DateTime.UtcNow;

            await dbContext.SaveChangesAsync(cancellationToken).ConfigureAwait(false);

            ProductsAppService.InvalidateProductListCaches(product.OwnerId);
            productCacheVersions.BumpDetail();
            QueueTextSearchSync(product.ProductId);
            QueueOwnerUpdatedNotification(
                product,
                beforeRetailPrice ?? 0,
                beforeRetailQty ?? 0,
                price,
                quantity);

            return Json(new
            {
                ok = true,
                isHybrid = true,
                channel = "retail",
                productCode = product.RetailCode ?? product.ProductCode,
                wholesaleProductCode = product.ProductCode,
                retailCode = product.RetailCode,
                name = product.NameEn,
                previousPrice = beforeRetailPrice,
                previousQuantity = beforeRetailQty,
                price = product.RetailPrice,
                quantity = product.RetailQuantity,
                unitName = retailUnitName,
                message =
                    "Retail channel updated only. Wholesale price/quantity were NOT changed. " +
                    "Always report quantity with unitName (do not convert units)."
            });
        }

        var beforePrice = product.USDPrice;
        var beforeQty = product.Quantity;
        var unitName = product.Unit?.UnitNameEn;

        if (price.HasValue) product.USDPrice = price.Value;
        if (quantity.HasValue) product.Quantity = quantity.Value;
        product.UpdatedAt = DateTime.UtcNow;

        await dbContext.SaveChangesAsync(cancellationToken).ConfigureAwait(false);

        ProductsAppService.InvalidateProductListCaches(product.OwnerId);
        productCacheVersions.BumpDetail();
        QueueTextSearchSync(product.ProductId);
        QueueOwnerUpdatedNotification(product, beforePrice, beforeQty, price, quantity);

        if (!isHybrid)
        {
        return Json(new
        {
            ok = true,
                isHybrid = false,
            productCode = product.ProductCode,
            name = product.NameEn,
            previousPrice = beforePrice,
            previousQuantity = beforeQty,
            price = product.USDPrice,
            quantity = product.Quantity,
            unitName,
            message =
                    "Ad updated successfully. This listing has a SINGLE price — not hybrid. " +
                    "Tell the user the new price/quantity with unitName. " +
                    "Do NOT mention هجين, جملة, تجزئة, wholesale, or retail."
            });
        }

        return Json(new
        {
            ok = true,
            isHybrid = true,
            channel = "wholesale",
            productCode = product.ProductCode,
            retailCode = product.RetailCode,
            name = product.NameEn,
            previousPrice = beforePrice,
            previousQuantity = beforeQty,
            price = product.USDPrice,
            quantity = product.Quantity,
            unitName,
            message =
                "Wholesale/category channel updated only. Retail price/quantity were NOT changed. Always report quantity with unitName."
        });
    }

    private static string? NormalizeUpdateChannel(string? channel)
    {
        if (string.IsNullOrWhiteSpace(channel)) return null;
        var c = channel.Trim().ToLowerInvariant();
        if (c is "wholesale" or "category" or "ton" or "جملة" or "الجملة") return "wholesale";
        if (c is "retail" or "تجزئة" or "التجزئة") return "retail";
        return null;
    }

    private static string? InferUpdateChannelFromText(string? text)
    {
        if (string.IsNullOrWhiteSpace(text)) return null;
        var t = text.Trim().ToLowerInvariant();
        var hasRetail = t.Contains("retail", StringComparison.Ordinal)
                        || t.Contains("تجزئه", StringComparison.Ordinal)
                        || t.Contains("تجزئة", StringComparison.Ordinal);
        var hasWholesale = t.Contains("wholesale", StringComparison.Ordinal)
                           || t.Contains("category", StringComparison.Ordinal)
                           || t.Contains("جمله", StringComparison.Ordinal)
                           || t.Contains("جملة", StringComparison.Ordinal)
                           || t.Contains("طن", StringComparison.Ordinal);
        if (hasRetail && !hasWholesale) return "retail";
        if (hasWholesale && !hasRetail) return "wholesale";
        return null;
    }

    private static string? InferChannelFromProductCode(Product product, string code)
    {
        var matchesRetail = !string.IsNullOrWhiteSpace(product.RetailCode)
            && string.Equals(product.RetailCode, code, StringComparison.OrdinalIgnoreCase);
        var matchesWholesale = !string.IsNullOrWhiteSpace(product.ProductCode)
            && string.Equals(product.ProductCode, code, StringComparison.OrdinalIgnoreCase);

        if (matchesRetail && !matchesWholesale) return "retail";
        if (matchesWholesale && !matchesRetail) return "wholesale";
        return null;
    }

    private async Task<string> ListMyAdsAsync(Guid? userId, CancellationToken cancellationToken)
    {
        if (!userId.HasValue)
        {
            return Json(new
            {
                ok = false,
                error = "Sign in as a seller to list your ads."
            });
        }

        var ads = await LoadOwnerHybridCatalogAsync(userId.Value, cancellationToken)
            .ConfigureAwait(false);
        return Json(new
        {
            ok = true,
            count = ads.Count,
            ads = ads
                .OrderBy(x => x.NameEn)
                .Select(a => new
                {
                    productCode = a.ProductCode,
                    retailCode = a.HasRetail ? a.RetailCode : null,
                    nameEn = a.NameEn,
                    nameAr = a.NameAr,
                    isHybrid = a.HasRetail,
                    price = a.USDPrice,
                    quantity = a.Quantity,
                    unitName = a.UnitName,
                    wholesalePrice = a.HasRetail ? a.USDPrice : (decimal?)null,
                    retailPrice = a.HasRetail ? a.RetailPrice : null
                })
                .ToList(),
            instruction =
                "Use these exact names when the seller wants to update an ad. " +
                "Call update_ad_price_quantity immediately. Ask جملة ولا تجزئة ONLY if that tool returns needs_channel_clarification. " +
                "Ads with isHybrid=false have one price — never mention hybrid/wholesale/retail to the user. " +
                "If their wording is slightly wrong, ask: did you mean ad A or ad B?"
        });
    }

    public async Task<string?> BuildSellerAdsCatalogAsync(
        Guid userId,
        CancellationToken cancellationToken = default)
    {
        var ads = await LoadOwnerHybridCatalogAsync(userId, cancellationToken)
            .ConfigureAwait(false);
        if (ads.Count == 0) return null;

        var lines = ads
            .OrderBy(x => x.NameEn)
            .Take(150)
            .Select(a =>
            {
                var name = string.IsNullOrWhiteSpace(a.NameAr)
                    ? (a.NameEn ?? "")
                    : $"{a.NameEn} | {a.NameAr}";
                if (a.HasRetail)
                {
                    return
                        $"- {name} | hybrid | wholesaleCode={a.ProductCode} wholesalePrice={a.USDPrice} " +
                        $"wholesaleQty={FormatQuantity(a.Quantity, a.UnitName)} | " +
                        $"retailCode={a.RetailCode} retailPrice={a.RetailPrice} " +
                        $"retailQty={FormatQuantity(a.RetailQuantity ?? 0, a.RetailUnitName)}";
                }

                return $"- {name} | code={a.ProductCode} | price={a.USDPrice} | qty={FormatQuantity(a.Quantity, a.UnitName)}";
            });

        return
            $"SELLER ADS CATALOG ({Math.Min(ads.Count, 150)} of {ads.Count}):\n" +
            string.Join("\n", lines) +
            "\nUse this list when the seller asks to update an ad. " +
            "Ads without the word 'hybrid' have ONE price — update immediately and never mention جملة/تجزئة/هجين. " +
            "Ask جملة ولا تجزئة ONLY after update_ad_price_quantity returns needs_channel_clarification. " +
            "If their name has a slight typo, ask which catalog ad they meant before calling update.";
    }

    private static object ToAdSuggestion(NameCandidate m) => new
    {
        productCode = m.ProductCode,
        nameEn = m.NameEn,
        nameAr = m.NameAr,
        price = m.USDPrice,
        quantity = m.Quantity,
        unitName = m.UnitName,
        matchScore = m.Score
    };

    private Task<string> FindCheapestProductAsync(
        string argumentsJson,
        CancellationToken cancellationToken) =>
        FindPricedProductAsync(argumentsJson, ProductMatchSort.Cheapest, 5, cancellationToken);

    private Task<string> FindMostExpensiveProductAsync(
        string argumentsJson,
        CancellationToken cancellationToken) =>
        FindPricedProductAsync(argumentsJson, ProductMatchSort.MostExpensive, 5, cancellationToken);

    private Task<string> SearchProductsAsync(
        string argumentsJson,
        CancellationToken cancellationToken) =>
        FindPricedProductAsync(argumentsJson, ProductMatchSort.BestMatch, 8, cancellationToken);

    private enum ProductMatchSort
    {
        Cheapest,
        MostExpensive,
        BestMatch
    }

    private async Task<string> FindPricedProductAsync(
        string argumentsJson,
        ProductMatchSort sort,
        int take,
        CancellationToken cancellationToken)
    {
        using var args = JsonDocument.Parse(string.IsNullOrWhiteSpace(argumentsJson) ? "{}" : argumentsJson);
        var productName = GetString(args.RootElement, "product_name");
        if (string.IsNullOrWhiteSpace(productName))
        {
            return Json(new { ok = false, error = "product_name is required." });
        }

        var commissionSettings = await commissionSettingsProvider.GetAsync(cancellationToken)
            .ConfigureAwait(false);
        var categoryCommissions = await categoryCommissionProvider.GetAsync(cancellationToken)
            .ConfigureAwait(false);
        var usdToAedRate = CurrencyConversionHelper.GetUsdToAedRate(configuration);

        var rowsRaw = await (
                from p in dbContext.Products.AsNoTracking()
                join t in dbContext.ContentTranslations.AsNoTracking()
                        .Where(x =>
                            x.Scope == ContentTranslationScopes.Product &&
                            x.Field == ContentTranslationFields.Name)
                    on p.ProductId equals t.ProductId into tj
                from t in tj.DefaultIfEmpty()
                where p.IsApproved == true
                      && (
                          (p.USDPrice > 0 && p.Quantity > 0)
                          || (p.CategoryId != null
                              && p.RetailPrice != null
                              && p.RetailPrice > 0
                              && p.RetailUnitId != null
                              && p.RetailQuantity != null
                              && p.RetailQuantity > 0))
                select new
                {
                    p.ProductId,
                    p.ProductCode,
                    p.RetailCode,
                    p.NameEn,
                    NameAr = t != null ? t.TextAr : null,
                    p.USDPrice,
                    p.Quantity,
                    UnitName = p.Unit != null ? p.Unit.UnitNameEn : null,
                    p.RetailPrice,
                    p.RetailUnitId,
                    p.RetailQuantity,
                    RetailUnitName = p.RetailUnit != null ? p.RetailUnit.UnitNameEn : null,
                    p.Currency,
                    p.Status,
                    p.IsApproved,
                    p.CategoryId,
                    p.ProductTypeId,
                    SellerCompany = p.Owner != null ? p.Owner.CompanyName : null
                })
            .ToListAsync(cancellationToken)
            .ConfigureAwait(false);

        var channelRows = new List<NameCandidate>();
        foreach (var r in rowsRaw)
        {
            if (r.USDPrice > 0 && r.Quantity > 0)
            {
                var commissionTypeId = ProductTypeCodes.WholesaleCommissionProductTypeId(
                    r.CategoryId, r.ProductTypeId);
                var commissionPercent = CustomerPriceCalculator.ResolveCommissionPercent(
                    commissionTypeId, r.CategoryId, commissionSettings, categoryCommissions);
                var markedUp = CustomerPriceCalculator.ApplyProductMarkup(
                    r.USDPrice, commissionTypeId, r.CategoryId, commissionSettings, categoryCommissions);
                var priced = ProductPricePresenter.Present(
                    markedUp, commissionTypeId ?? r.ProductTypeId, r.Currency, usdToAedRate);

                channelRows.Add(new NameCandidate(
            r.ProductId,
            r.ProductCode,
            r.NameEn,
            r.NameAr,
            r.USDPrice,
                    priced.Price,
                    priced.Currency,
                    priced.PriceUsd,
                    priced.PriceAed,
                    commissionPercent,
            r.Quantity,
            r.UnitName,
            r.Currency,
            r.Status,
            r.IsApproved,
                    r.CategoryId,
                    r.ProductTypeId,
                    r.SellerCompany,
                    Channel: "wholesale"));
            }

            if (ProductTypeCodes.HasRetailPricing(
                    r.CategoryId,
                    r.ProductTypeId,
                    r.RetailPrice,
                    r.RetailUnitId,
                    r.RetailQuantity)
                && r.RetailPrice is > 0
                && r.RetailQuantity is > 0)
            {
                var retailPrice = r.RetailPrice.Value;
                var commissionPercent = CustomerPriceCalculator.ResolveCommissionPercent(
                    ProductTypeCodes.Retail, categoryId: null, commissionSettings, categoryCommissions);
                var markedUp = CustomerPriceCalculator.ApplyProductMarkup(
                    retailPrice,
                    ProductTypeCodes.Retail,
                    categoryId: null,
                    commissionSettings,
                    categoryCommissions);
                var priced = ProductPricePresenter.Present(
                    markedUp, ProductTypeCodes.Retail, "AED", usdToAedRate);

                channelRows.Add(new NameCandidate(
                    r.ProductId,
                    string.IsNullOrWhiteSpace(r.RetailCode) ? r.ProductCode : r.RetailCode,
                    r.NameEn,
                    r.NameAr,
                    retailPrice,
                    priced.Price,
                    priced.Currency,
                    priced.PriceUsd,
                    priced.PriceAed,
                    commissionPercent,
                    r.RetailQuantity.Value,
                    r.RetailUnitName,
                    "AED",
                    r.Status,
                    r.IsApproved,
                    r.CategoryId,
                    ProductTypeCodes.Retail,
                    r.SellerCompany,
                    Channel: "retail"));
            }
        }

        var publicRows = channelRows
            .Where(r => ProductStatusCodes.IsPubliclyVisible(r.Status, r.IsApproved))
            .ToList();

        var rankedQuery = RankByName(productName, publicRows)
            .Where(x => x.Score >= 50);

        var ranked = sort switch
        {
            ProductMatchSort.MostExpensive => rankedQuery
                .OrderByDescending(x => x.CustomerPrice)
                .ThenByDescending(x => x.Score)
                .ThenBy(x => x.NameEn)
                .ToList(),
            ProductMatchSort.Cheapest => rankedQuery
                .OrderBy(x => x.CustomerPrice)
                .ThenByDescending(x => x.Score)
                .ThenBy(x => x.NameEn)
                .ToList(),
            _ => rankedQuery
            .OrderByDescending(x => x.Score)
                .ThenBy(x => x.CustomerPrice)
                .ThenBy(x => x.NameEn)
                .ToList()
        };

        if (ranked.Count == 0)
        {
            return Json(new
            {
                ok = false,
                error = $"No approved in-stock products found matching '{productName.Trim()}'."
            });
        }

        var topMatches = ranked.Take(Math.Clamp(take, 1, 12)).ToList();
        var listings = await BuildListingCardsAsync(topMatches, cancellationToken).ConfigureAwait(false);
        var winner = topMatches[0];
        var winnerKey = sort switch
        {
            ProductMatchSort.MostExpensive => "mostExpensive",
            ProductMatchSort.Cheapest => "cheapest",
            _ => "bestMatch"
        };

        return Json(new Dictionary<string, object?>
        {
            ["ok"] = true,
            [winnerKey] = new
            {
                productId = winner.ProductId,
                productCode = winner.ProductCode,
                channel = winner.Channel,
                nameEn = winner.NameEn,
                nameAr = winner.NameAr,
                basePrice = winner.USDPrice,
                customerPrice = winner.CustomerPrice,
                price = winner.CustomerPrice,
                currency = winner.CustomerCurrency,
                priceUsd = winner.CustomerPriceUsd,
                priceAed = winner.CustomerPriceAed,
                commissionPercent = winner.CommissionPercent,
                quantity = winner.Quantity,
                unitName = winner.UnitName,
                quantityDisplay = FormatQuantity(winner.Quantity, winner.UnitName),
                seller = winner.SellerCompany,
                matchScore = winner.Score
            },
            ["alternatives"] = topMatches.Skip(1).Select(m => new
            {
                productId = m.ProductId,
                productCode = m.ProductCode,
                channel = m.Channel,
                nameEn = m.NameEn,
                nameAr = m.NameAr,
                basePrice = m.USDPrice,
                customerPrice = m.CustomerPrice,
                price = m.CustomerPrice,
                currency = m.CustomerCurrency,
                commissionPercent = m.CommissionPercent,
                quantity = m.Quantity,
                unitName = m.UnitName,
                quantityDisplay = FormatQuantity(m.Quantity, m.UnitName)
            }).ToList(),
            ["listings"] = listings,
            ["instruction"] =
                "The mobile app shows listing cards under your reply. Keep the spoken answer short: name, customerPrice with currency, channel, quantity with unitName. " +
                "Tell the user they can tap a card to open the ad details. Never invent prices. Never dump every field. Never say grams unless unitName is Gram."
        });
    }

    private async Task<List<object>> BuildListingCardsAsync(
        IReadOnlyList<NameCandidate> matches,
        CancellationToken cancellationToken)
    {
        var ids = matches.Select(m => m.ProductId).Distinct().ToList();
        var imagesByProduct = new Dictionary<Guid, IReadOnlyList<string>>();
        if (ids.Count > 0)
        {
            var imageRows = await dbContext.ProductImages.AsNoTracking()
                .Where(i => ids.Contains(i.ProductId))
                .OrderBy(i => i.Id)
                .Select(i => new { i.ProductId, i.ImagePath })
                .ToListAsync(cancellationToken)
                .ConfigureAwait(false);

            imagesByProduct = imageRows
                .GroupBy(i => i.ProductId)
                .ToDictionary(
                    g => g.Key,
                    g => (IReadOnlyList<string>)g
                        .Select(x => x.ImagePath)
                        .Where(path => !string.IsNullOrWhiteSpace(path))
                        .Take(5)
                        .ToList());
        }

        return matches.Select(m =>
        {
            var isRetail = string.Equals(m.Channel, "retail", StringComparison.OrdinalIgnoreCase);
            var searchChannel = isRetail
                ? "retail"
                : (m.CategoryId is > 0 ? "category" : (string?)null);
            imagesByProduct.TryGetValue(m.ProductId, out var images);
            return (object)new
            {
                productId = m.ProductId,
                productCode = m.ProductCode,
                nameEn = m.NameEn,
                nameAr = m.NameAr,
                price = m.CustomerPrice,
                currency = m.CustomerCurrency,
                usdPrice = m.CustomerPriceUsd,
                priceAed = m.CustomerPriceAed,
                quantity = m.Quantity,
                unitName = m.UnitName,
                categoryId = m.CategoryId,
                productTypeId = m.ProductTypeId,
                productTypeName = isRetail ? "Retail" : (string?)null,
                searchListingChannel = searchChannel,
                hasRetailPricing = isRetail,
                images = images ?? Array.Empty<string>()
            };
        }).ToList();
    }

    private async Task<string> GetMySalesCountAsync(
        Guid? userId,
        CancellationToken cancellationToken)
    {
        if (!userId.HasValue)
        {
            return Json(new
            {
                ok = false,
                error = "Sign in as a seller to view your sales count."
            });
        }

        var sellerId = userId.Value;
        var cancelled = OrderStatusCodes.Cancelled;
        var returnApproved = OrderStatusCodes.ReturnApproved;

        var orders = await (
                from o in dbContext.Orders.AsNoTracking()
                join p in dbContext.Products.AsNoTracking() on o.ProductId equals p.ProductId into pj
                from p in pj.DefaultIfEmpty()
                join t in dbContext.ContentTranslations.AsNoTracking()
                        .Where(x =>
                            x.Scope == ContentTranslationScopes.Product &&
                            x.Field == ContentTranslationFields.Name)
                    on p.ProductId equals t.ProductId into tj
                from t in tj.DefaultIfEmpty()
                where o.ToUserId == sellerId
                select new
                {
                    o.StatusId,
                    o.TotalPrice,
                    ProductCode = p != null ? p.ProductCode : null,
                    NameEn = p != null ? p.NameEn : null,
                    NameAr = t != null ? t.TextAr : null,
                    StatusEn = o.CustomStatusNameEn,
                    StatusAr = o.CustomStatusNameAr
                })
            .ToListAsync(cancellationToken)
            .ConfigureAwait(false);

        var completed = orders
            .Where(o => OrderStatusCodes.CountsAsDeliveredSale(o.StatusId))
            .ToList();

        var pending = orders
            .Where(o =>
                o.StatusId != cancelled
                && o.StatusId != returnApproved
                && !OrderStatusCodes.CountsAsDeliveredSale(o.StatusId))
            .ToList();

        var pendingByProduct = pending
            .GroupBy(o => new
            {
                Code = o.ProductCode ?? "",
                NameEn = string.IsNullOrWhiteSpace(o.NameEn) ? "Unknown product" : o.NameEn!.Trim(),
                NameAr = string.IsNullOrWhiteSpace(o.NameAr) ? null : o.NameAr!.Trim()
            })
            .Select(g => new
            {
                productCode = string.IsNullOrWhiteSpace(g.Key.Code) ? null : g.Key.Code,
                productNameEn = g.Key.NameEn,
                productNameAr = g.Key.NameAr,
                pendingOrderCount = g.Count(),
                pendingOrdersValue = g.Sum(x => x.TotalPrice),
                statuses = g
                    .GroupBy(x => x.StatusId)
                    .Select(sg => new
                    {
                        statusId = sg.Key,
                        statusEn = sg.Select(x => x.StatusEn).FirstOrDefault(x => !string.IsNullOrWhiteSpace(x))
                                   ?? OrderStatusCodes.GetNameEn(sg.Key),
                        statusAr = sg.Select(x => x.StatusAr).FirstOrDefault(x => !string.IsNullOrWhiteSpace(x))
                                   ?? OrderStatusCodes.GetNameAr(sg.Key),
                        count = sg.Count()
                    })
                    .ToList()
            })
            .OrderByDescending(x => x.pendingOrderCount)
            .ThenBy(x => x.productNameEn)
            .ToList();

        return Json(new
        {
            ok = true,
            perspective = "as_seller",
            meaning =
                "Customer orders ON this user's ads (الطلبات على إعلاناتي / مبيعاتي). " +
                "Not this user's purchases in My Orders (طلباتي).",
            completedSalesCount = completed.Count,
            completedSalesEarnings = completed.Sum(x => x.TotalPrice),
            pendingOrdersCount = pending.Count,
            pendingOrdersValue = pending.Sum(x => x.TotalPrice),
            pendingByProduct,
            statusLabelAr = "تم الاستلام",
            statusLabelEn = "Received",
            instruction =
                "Speak as SELLER about orders on THEIR ads. Tell: (1) completed sales count + earnings, " +
                "and (2) pending orders per product name if pendingByProduct is not empty. " +
                "Never call these طلباتي / My Orders."
        });
    }

    private async Task<List<OwnerCatalogAd>> LoadOwnerHybridCatalogAsync(
        Guid ownerId,
        CancellationToken cancellationToken)
    {
        var rows = await (
                from p in dbContext.Products.AsNoTracking()
                join t in dbContext.ContentTranslations.AsNoTracking()
                        .Where(x =>
                            x.Scope == ContentTranslationScopes.Product &&
                            x.Field == ContentTranslationFields.Name)
                    on p.ProductId equals t.ProductId into tj
                from t in tj.DefaultIfEmpty()
                where p.OwnerId == ownerId
                select new OwnerCatalogAd(
                    p.ProductId,
                    p.ProductCode,
                    p.RetailCode,
                    p.NameEn,
                    t != null ? t.TextAr : null,
                    p.USDPrice,
                    p.Quantity,
                    p.Unit != null ? p.Unit.UnitNameEn : null,
                    p.RetailPrice,
                    p.RetailQuantity,
                    p.RetailUnit != null ? p.RetailUnit.UnitNameEn : null,
                    p.CategoryId,
                    p.ProductTypeId,
                    p.RetailUnitId))
            .ToListAsync(cancellationToken)
            .ConfigureAwait(false);

        return rows
            .GroupBy(r => r.ProductId)
            .Select(g => g.First())
            .ToList();
    }

    private async Task<List<NameCandidate>> LoadOwnerNameCandidatesAsync(
        Guid ownerId,
        CancellationToken cancellationToken)
    {
        var rowsRaw = await (
                from p in dbContext.Products.AsNoTracking()
                join t in dbContext.ContentTranslations.AsNoTracking()
                        .Where(x =>
                            x.Scope == ContentTranslationScopes.Product &&
                            x.Field == ContentTranslationFields.Name)
                    on p.ProductId equals t.ProductId into tj
                from t in tj.DefaultIfEmpty()
                where p.OwnerId == ownerId
                select new
                {
                    p.ProductId,
                    p.ProductCode,
                    p.NameEn,
                    NameAr = t != null ? t.TextAr : null,
                    p.USDPrice,
                    p.Quantity,
                    UnitName = p.Unit != null ? p.Unit.UnitNameEn : null,
                    p.Currency,
                    p.Status,
                    p.IsApproved
                })
            .ToListAsync(cancellationToken)
            .ConfigureAwait(false);

        return rowsRaw
            .Select(r => new NameCandidate(
                r.ProductId,
                r.ProductCode,
                r.NameEn,
                r.NameAr,
                r.USDPrice,
                CustomerPrice: r.USDPrice,
                CustomerCurrency: r.Currency,
                CustomerPriceUsd: r.USDPrice,
                CustomerPriceAed: null,
                CommissionPercent: 0,
                r.Quantity,
                r.UnitName,
                r.Currency,
                r.Status,
                r.IsApproved,
                CategoryId: null,
                ProductTypeId: null,
                null))
            .GroupBy(r => r.ProductId)
            .Select(g => g.First())
            .ToList();
    }

    private static List<NameCandidate> RankByName(string query, IEnumerable<NameCandidate> candidates)
    {
        var terms = ExpandSearchTerms(query);
        if (terms.Count == 0) return [];

        return candidates
            .Select(c => c with { Score = terms.Max(t => ScoreNameMatch(t, c.NameEn, c.NameAr)) })
            .Where(c => c.Score > 0)
            .OrderByDescending(c => c.Score)
            .ThenBy(c => c.NameEn)
            .ToList();
    }

    /// <summary>
    /// Owner-ad matching: lexical + slight-typo fuzzy so "safron" can suggest "saffron".
    /// </summary>
    private static List<NameCandidate> RankOwnerAdsByName(string query, IEnumerable<NameCandidate> candidates)
    {
        var q = NormalizeName(query);
        if (string.IsNullOrEmpty(q)) return [];

        var terms = ExpandSearchTerms(query);
        return candidates
            .Select(c =>
            {
                var lexical = terms.Count == 0
                    ? 0
                    : terms.Max(t => ScoreNameMatch(t, c.NameEn, c.NameAr));
                var fuzzy = ScoreFuzzyName(q, c.NameEn, c.NameAr);
                return c with { Score = Math.Max(lexical, fuzzy) };
            })
            .Where(c => c.Score > 0)
            .OrderByDescending(c => c.Score)
            .ThenBy(c => c.NameEn)
            .ToList();
    }

    private static int ScoreFuzzyName(string queryNorm, string? nameEn, string? nameAr)
    {
        var best = 0;
        foreach (var name in new[] { NormalizeName(nameEn), NormalizeName(nameAr) })
        {
            if (string.IsNullOrEmpty(name)) continue;
            var dist = LevenshteinDistance(queryNorm, name);
            var maxLen = Math.Max(queryNorm.Length, name.Length);
            if (maxLen == 0) continue;

            // Allow ~1 typo on short names, ~25% edits on longer ones.
            var maxDist = Math.Max(1, Math.Min(3, maxLen / 4));
            if (dist == 0) best = Math.Max(best, 100);
            else if (dist <= maxDist)
            {
                // Below strong lexical tier (85) so unique exact/prefix still auto-updates,
                // while typos go through clarification.
                best = Math.Max(best, 72 - dist * 4);
            }
            else
            {
                // Also compare against individual tokens (e.g. query vs "cardamom myq").
                foreach (var token in name.Split(
                             [' ', '-', '_'],
                             StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries))
                {
                    if (token.Length < 3) continue;
                    var td = LevenshteinDistance(queryNorm, token);
                    var tMax = Math.Max(1, Math.Min(2, token.Length / 4));
                    if (td > 0 && td <= tMax)
                    {
                        best = Math.Max(best, 68 - td * 4);
                    }
                }
            }
        }

        return best;
    }

    private static int LevenshteinDistance(string a, string b)
    {
        if (a.Length == 0) return b.Length;
        if (b.Length == 0) return a.Length;

        var prev = new int[b.Length + 1];
        var curr = new int[b.Length + 1];
        for (var j = 0; j <= b.Length; j++) prev[j] = j;

        for (var i = 1; i <= a.Length; i++)
        {
            curr[0] = i;
            for (var j = 1; j <= b.Length; j++)
            {
                var cost = a[i - 1] == b[j - 1] ? 0 : 1;
                curr[j] = Math.Min(
                    Math.Min(curr[j - 1] + 1, prev[j] + 1),
                    prev[j - 1] + cost);
            }

            (prev, curr) = (curr, prev);
        }

        return prev[b.Length];
    }

    /// <summary>
    /// Expand Arabic/English marketplace synonyms so "هيل" also matches "Cardamom".
    /// </summary>
    private static List<string> ExpandSearchTerms(string query)
    {
        var q = NormalizeName(query);
        if (string.IsNullOrEmpty(q)) return [];

        var terms = new HashSet<string>(StringComparer.Ordinal) { q };
        foreach (var group in ProductNameSynonymGroups)
        {
            var normalizedGroup = group.Select(NormalizeName).Where(x => x.Length > 0).ToList();
            if (normalizedGroup.Any(t =>
                    t == q
                    || t.StartsWith(q, StringComparison.Ordinal)
                    || q.StartsWith(t, StringComparison.Ordinal)
                    || t.Contains(q, StringComparison.Ordinal)
                    || q.Contains(t, StringComparison.Ordinal)))
            {
                foreach (var t in normalizedGroup) terms.Add(t);
            }
        }

        return terms.ToList();
    }

    private static readonly string[][] ProductNameSynonymGroups =
    [
        ["هيل", "حبهان", "cardamom", "cardamum", "elaichi"],
        ["زعفران", "saffron"],
        ["قرفه", "قرفة", "دارسين", "cinnamon"],
        ["كمون", "cumin"],
        ["كزبره", "كزبرة", "coriander", "cilantro"],
        ["فلفل اسود", "black pepper"],
        ["زنجبيل", "ginger"],
        ["كركم", "turmeric"],
        ["قرنفل", "clove", "cloves"],
        ["يانسون", "anise", "aniseed"],
        ["شمر", "fennel"],
        ["فستق", "pistachio", "pistachios"],
        ["لوز", "almond", "almonds"],
        ["كسبر", "كسبرة"]
    ];

    private static int ScoreNameMatch(string queryNorm, string? nameEn, string? nameAr)
    {
        var en = NormalizeName(nameEn);
        var ar = NormalizeName(nameAr);
        var best = 0;

        foreach (var name in new[] { en, ar })
        {
            if (string.IsNullOrEmpty(name)) continue;
            if (name == queryNorm) best = Math.Max(best, 100);
            else if (name.StartsWith(queryNorm, StringComparison.Ordinal) ||
                     queryNorm.StartsWith(name, StringComparison.Ordinal))
            {
                best = Math.Max(best, 85);
            }
            else if (HasWordToken(name, queryNorm))
            {
                best = Math.Max(best, 80);
            }
            else if (name.Contains(queryNorm, StringComparison.Ordinal))
            {
                // Prefer shorter names for contains (closer to the query).
                var penalty = Math.Min(30, Math.Abs(name.Length - queryNorm.Length));
                best = Math.Max(best, 60 - penalty / 3);
            }
        }

        return best;
    }

    private static bool HasWordToken(string nameNorm, string queryNorm)
    {
        if (queryNorm.Length < 2) return false;
        foreach (var part in nameNorm.Split(
                     [' ', '-', '_', '/', ',', '.', '(', ')'],
                     StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries))
        {
            if (part == queryNorm) return true;
            if (part.StartsWith(queryNorm, StringComparison.Ordinal) && queryNorm.Length >= 3)
            {
                return true;
            }
        }

        return false;
    }

    private static string NormalizeName(string? value)
    {
        if (string.IsNullOrWhiteSpace(value)) return string.Empty;
        var s = value.Trim().ToLowerInvariant();
        s = s
            .Replace('أ', 'ا')
            .Replace('إ', 'ا')
            .Replace('آ', 'ا')
            .Replace('ة', 'ه')
            .Replace('ى', 'ي')
            .Replace('ؤ', 'و')
            .Replace('ئ', 'ي');
        while (s.Contains("  ", StringComparison.Ordinal))
        {
            s = s.Replace("  ", " ", StringComparison.Ordinal);
        }

        return s;
    }

    private static string FormatQuantity(long quantity, string? unitName) =>
        string.IsNullOrWhiteSpace(unitName)
            ? quantity.ToString()
            : $"{quantity} {unitName}";

    private void QueueTextSearchSync(Guid productId)
    {
        _ = Task.Run(async () =>
        {
            try
            {
                await using var scope = scopeFactory.CreateAsyncScope();
                var sync = scope.ServiceProvider.GetRequiredService<ProductTextSearchSyncService>();
                await sync.UpsertProductAsync(productId).ConfigureAwait(false);
            }
            catch (Exception ex)
            {
                logger.LogWarning(ex, "AI tool Meilisearch sync failed for {ProductId}", productId);
            }
        });
    }

    private void QueueOwnerUpdatedNotification(
        Product product,
        decimal beforePrice,
        long beforeQty,
        decimal? newPrice,
        long? newQty)
    {
        var productId = product.ProductId;
        if (!product.OwnerId.HasValue) return;
        var ownerId = product.OwnerId.Value;
        var productName = string.IsNullOrWhiteSpace(product.NameEn) ? "Your ad" : product.NameEn.Trim();
        var unitName = product.Unit?.UnitNameEn;
        var priceText = newPrice?.ToString("0.##") ?? product.USDPrice.ToString("0.##");
        var qtyText = FormatQuantity(newQty ?? product.Quantity, unitName);

        _ = Task.Run(async () =>
        {
            try
            {
                await using var scope = scopeFactory.CreateAsyncScope();
                var db = scope.ServiceProvider.GetRequiredService<IRasAlSouqDbContext>();
                var fcm = scope.ServiceProvider.GetRequiredService<IFcmNotificationService>();
                var productData = scope.ServiceProvider.GetRequiredService<IProductDataAccess>();

                var owner = await db.Users.AsNoTracking()
                    .Where(u => u.Id == ownerId)
                    .Select(u => new { u.Id, u.FcmToken, u.PreferredLanguage })
                    .FirstOrDefaultAsync()
                    .ConfigureAwait(false);
                if (owner is null) return;

                var titleEn = "Ad updated";
                var bodyEn = $"\"{productName}\" was updated. Price: {priceText}. Quantity: {qtyText}.";
                var titleAr = "تم تحديث الإعلان";
                var bodyAr = $"تم تحديث \"{productName}\". السعر: {priceText}. الكمية: {qtyText}.";

                var routeId = await productData.GetOrCreateNotificationRouteIdAsync(
                    "product-detail", CancellationToken.None).ConfigureAwait(false);
                var typeId = await productData.GetOrCreateNotificationTypeIdAsync(
                    "ad_updated", CancellationToken.None).ConfigureAwait(false);

                await productData.AddInboxNotificationAsync(new Notification
                {
                    Id = Guid.NewGuid(),
                    Title = titleEn,
                    TitleAr = titleAr,
                    Body = bodyEn,
                    BodyAr = bodyAr,
                    FromUserId = ownerId,
                    ToUserId = ownerId,
                    TypeId = typeId,
                    RouteId = routeId,
                    ReferenceId = productId.ToString(),
                    IsRead = false,
                    CreatedAt = DateTime.UtcNow
                }).ConfigureAwait(false);
                NotificationCacheVersions.Bump(ownerId);

                if (!string.IsNullOrWhiteSpace(owner.FcmToken))
                {
                    var (pushTitle, pushBody) = NotificationMessages.PickOptional(
                        owner.PreferredLanguage,
                        titleEn,
                        bodyEn,
                        titleAr,
                        bodyAr);
                    await fcm.SendNotificationAsync(
                        owner.FcmToken,
                        new FcmNotificationPayload
                        {
                            Title = pushTitle,
                            Body = pushBody,
                            Type = "ad_updated",
                            RouteId = "product-detail",
                            ReferenceId = productId.ToString()
                        }).ConfigureAwait(false);
                }
            }
            catch (Exception ex)
            {
                logger.LogWarning(ex, "AI tool FCM/inbox notify failed for {ProductId}", productId);
            }
        });
    }

    private static bool LooksLikeBulkUpdateRequest(string productName)
    {
        var n = productName.Trim().ToLowerInvariant();
        if (n.Length == 0) return false;

        // Arabic / English phrasing that means "all my ads" rather than a product name.
        string[] markers =
        [
            "كل اعلان", "كل إعلان", "كل الاعلان", "كل الإعلان",
            "جميع اعلان", "جميع إعلان", "جميع الاعلان", "جميع الإعلان",
            "كل حاجه", "كل حاجة", "كلها", "جميعها",
            "all ads", "all my ads", "every ad", "all products", "all my products",
            "update all", "change all", "set all"
        ];

        foreach (var marker in markers)
        {
            if (n.Contains(marker, StringComparison.Ordinal))
            {
                return true;
            }
        }

        return n is "all" or "كل" or "جميع" or "الكل";
    }

    private static string? GetString(JsonElement root, string name) =>
        root.TryGetProperty(name, out var el) && el.ValueKind == JsonValueKind.String
            ? el.GetString()
            : null;

    private static decimal? GetDecimal(JsonElement root, string name)
    {
        if (!root.TryGetProperty(name, out var el)) return null;
        if (el.ValueKind == JsonValueKind.Number && el.TryGetDecimal(out var d)) return d;
        if (el.ValueKind == JsonValueKind.String &&
            decimal.TryParse(el.GetString(), out var parsed))
        {
            return parsed;
        }

        return null;
    }

    private static long? GetLong(JsonElement root, string name)
    {
        if (!root.TryGetProperty(name, out var el)) return null;
        if (el.ValueKind == JsonValueKind.Number && el.TryGetInt64(out var n)) return n;
        if (el.ValueKind == JsonValueKind.String &&
            long.TryParse(el.GetString(), out var parsed))
        {
            return parsed;
        }

        return null;
    }

    private static string Json(object value) =>
        JsonSerializer.Serialize(value, new JsonSerializerOptions
        {
            PropertyNamingPolicy = JsonNamingPolicy.CamelCase
        });

    private sealed record NameCandidate(
        Guid ProductId,
        string? ProductCode,
        string? NameEn,
        string? NameAr,
        decimal USDPrice,
        decimal CustomerPrice,
        string? CustomerCurrency,
        decimal CustomerPriceUsd,
        decimal? CustomerPriceAed,
        decimal CommissionPercent,
        long Quantity,
        string? UnitName,
        string? Currency,
        byte? Status,
        bool? IsApproved,
        byte? CategoryId,
        byte? ProductTypeId,
        string? SellerCompany,
        string? Channel = null,
        int Score = 0);

    private sealed record OwnerCatalogAd(
        Guid ProductId,
        string? ProductCode,
        string? RetailCode,
        string? NameEn,
        string? NameAr,
        decimal USDPrice,
        long Quantity,
        string? UnitName,
        decimal? RetailPrice,
        long? RetailQuantity,
        string? RetailUnitName,
        byte? CategoryId,
        byte? ProductTypeId,
        byte? RetailUnitId)
    {
        public bool HasRetail =>
            ProductTypeCodes.HasRetailStockConfigured(
                CategoryId, ProductTypeId, RetailPrice, RetailUnitId);
    }
}
