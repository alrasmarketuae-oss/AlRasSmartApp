using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using BusinessLayer.Dtos;
using BusinessLayer.Interfaces;
using BusinessLayer.Interfaces.AiAssistant;
using BusinessLayer.Options;
using Microsoft.Extensions.Options;

namespace BusinessLayer.Services.AiAssistant.Shopping;

public sealed class AiShoppingToolsService(
    IProductsAppService productsAppService,
    ICartAppService cartAppService,
    IOrdersAppService ordersAppService,
    ICategoriesAppService categoriesAppService,
    IAiShoppingIdempotencyStore idempotencyStore,
    IAiAsyncToolJobRegistry asyncJobs,
    IOptions<AiShoppingAgentOptions> options) : IAiShoppingToolsService
{
    private readonly AiShoppingAgentOptions _options = options.Value;

    private static readonly HashSet<string> AsyncTools = new(StringComparer.Ordinal)
    {
        "SearchProducts",
        "GetProductDetails",
        "GetProductAlternatives",
        "GetMyOrders",
        "GetOrderDetails",
        "LookupRefundById",
        "GetCategories",
        "GetOffers"
    };

    private static readonly HashSet<string> MutatingTools = new(StringComparer.Ordinal)
    {
        "AddToCart",
        "UpdateCartQuantity",
        "RemoveFromCart"
    };

    public IReadOnlyList<object> GetToolDefinitions(bool enableAsyncTools)
    {
        object Fn(string name, string description, object parameters, bool async) => new
        {
            type = "function",
            name,
            description,
            parameters,
            async = enableAsyncTools && async
        };

        var str = new { type = "string" };
        var num = new { type = "number" };
        var integer = new { type = "integer" };

        return
        [
            Fn(
                "SearchProducts",
                "Search Al Ras catalog for products matching a query. Never invent products.",
                new
                {
                    type = "object",
                    properties = new
                    {
                        query = str,
                        page = integer
                    },
                    required = new[] { "query" }
                },
                async: true),
            Fn(
                "GetProductDetails",
                "Get current product details and live price from Al Ras by productId.",
                new
                {
                    type = "object",
                    properties = new { productId = str },
                    required = new[] { "productId" }
                },
                async: true),
            Fn(
                "GetProductAlternatives",
                "Find cheaper or similar alternatives for a product query.",
                new
                {
                    type = "object",
                    properties = new
                    {
                        query = str,
                        preferCheaper = new { type = "boolean" }
                    },
                    required = new[] { "query" }
                },
                async: true),
            Fn(
                "GetCategories",
                "List visible product categories.",
                new { type = "object", properties = new { } },
                async: true),
            Fn(
                "GetOffers",
                "List current offer/discount listings.",
                new
                {
                    type = "object",
                    properties = new { page = integer },
                    required = Array.Empty<string>()
                },
                async: true),
            Fn(
                "GetCart",
                "Get the signed-in user's cart totals and items.",
                new { type = "object", properties = new { } },
                async: false),
            Fn(
                "AddToCart",
                "Add a catalog product to the user's cart.",
                new
                {
                    type = "object",
                    properties = new
                    {
                        productId = str,
                        quantity = num,
                        unitName = str
                    },
                    required = new[] { "productId", "quantity" }
                },
                async: false),
            Fn(
                "UpdateCartQuantity",
                "Reduce cart item quantity by a delta using cartItemId.",
                new
                {
                    type = "object",
                    properties = new
                    {
                        cartItemId = integer,
                        reduceBy = num
                    },
                    required = new[] { "cartItemId", "reduceBy" }
                },
                async: false),
            Fn(
                "RemoveFromCart",
                "Remove a cart line by cartItemId.",
                new
                {
                    type = "object",
                    properties = new { cartItemId = integer },
                    required = new[] { "cartItemId" }
                },
                async: false),
            Fn(
                "GetMyOrders",
                "List the signed-in user's orders (purchases).",
                new
                {
                    type = "object",
                    properties = new { page = integer },
                    required = Array.Empty<string>()
                },
                async: true),
            Fn(
                "GetOrderDetails",
                "Get one order the signed-in user owns by orderId.",
                new
                {
                    type = "object",
                    properties = new { orderId = integer },
                    required = new[] { "orderId" }
                },
                async: true),
            Fn(
                "LookupRefundById",
                "Look up the signed-in user's refund by Stripe refund ID (re_...).",
                new
                {
                    type = "object",
                    properties = new { refundId = str },
                    required = new[] { "refundId" }
                },
                async: true)
        ];
    }

    public async Task<AiShoppingToolExecutionResult> ExecuteAsync(
        Guid userId,
        string sessionKey,
        string turnId,
        string callId,
        string toolName,
        string argumentsJson,
        bool asyncPreferred,
        CancellationToken cancellationToken)
    {
        if (MutatingTools.Contains(toolName))
        {
            var idemKey = BuildIdempotencyKey(userId, sessionKey, turnId, toolName, argumentsJson);
            if (!idempotencyStore.TryBegin(idemKey, out var existing))
            {
                return WrapExisting(existing);
            }

            try
            {
                var result = await ExecuteCoreAsync(
                        userId,
                        sessionKey,
                        turnId,
                        callId,
                        toolName,
                        argumentsJson,
                        asyncPreferred: false,
                        cancellationToken)
                    .ConfigureAwait(false);
                idempotencyStore.Complete(idemKey, JsonSerializer.Deserialize<object>(result.PayloadJson) ?? result.PayloadJson);
                return result;
            }
            catch
            {
                idempotencyStore.Complete(idemKey, new { ok = false, error = "failed" });
                throw;
            }
        }

        return await ExecuteCoreAsync(
                userId,
                sessionKey,
                turnId,
                callId,
                toolName,
                argumentsJson,
                asyncPreferred,
                cancellationToken)
            .ConfigureAwait(false);
    }

    private async Task<AiShoppingToolExecutionResult> ExecuteCoreAsync(
        Guid userId,
        string sessionKey,
        string turnId,
        string callId,
        string toolName,
        string argumentsJson,
        bool asyncPreferred,
        CancellationToken cancellationToken)
    {
        using var doc = JsonDocument.Parse(string.IsNullOrWhiteSpace(argumentsJson) ? "{}" : argumentsJson);
        var args = doc.RootElement;

        async Task<string> Run() => toolName switch
        {
            "SearchProducts" => await SearchProductsAsync(userId, args, cancellationToken).ConfigureAwait(false),
            "GetProductDetails" => await GetProductDetailsAsync(userId, args, cancellationToken).ConfigureAwait(false),
            "GetProductAlternatives" => await GetAlternativesAsync(userId, args, cancellationToken).ConfigureAwait(false),
            "GetCategories" => await GetCategoriesAsync(cancellationToken).ConfigureAwait(false),
            "GetOffers" => await GetOffersAsync(userId, args, cancellationToken).ConfigureAwait(false),
            "GetCart" => await GetCartAsync(userId, cancellationToken).ConfigureAwait(false),
            "AddToCart" => await AddToCartAsync(userId, args, cancellationToken).ConfigureAwait(false),
            "UpdateCartQuantity" => await UpdateCartAsync(userId, args, cancellationToken).ConfigureAwait(false),
            "RemoveFromCart" => await RemoveFromCartAsync(userId, args, cancellationToken).ConfigureAwait(false),
            "GetMyOrders" => await GetMyOrdersAsync(userId, args, cancellationToken).ConfigureAwait(false),
            "GetOrderDetails" => await GetOrderDetailsAsync(userId, args, cancellationToken).ConfigureAwait(false),
            "LookupRefundById" => await LookupRefundByIdAsync(userId, args, cancellationToken).ConfigureAwait(false),
            _ => """{"ok":false,"error":"unknown_tool"}"""
        };

        var useAsync = asyncPreferred && _options.EnableAsyncTools && AsyncTools.Contains(toolName);
        string payload;
        if (useAsync)
        {
            payload = await asyncJobs.StartAsync(
                    sessionKey,
                    turnId,
                    callId,
                    toolName,
                    async ct => await Run().ConfigureAwait(false),
                    cancellationToken)
                .ConfigureAwait(false);
        }
        else
        {
            using var toolCts = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken);
            toolCts.CancelAfter(TimeSpan.FromSeconds(Math.Max(5, _options.ToolTimeoutSeconds)));
            payload = await Run().ConfigureAwait(false);
        }

        var listings = TryExtractListings(payload);
        return new AiShoppingToolExecutionResult
        {
            Ok = !payload.Contains("\"ok\":false", StringComparison.Ordinal),
            PayloadJson = AiShoppingResultShaper.EnsureValidJsonWithinLimit(payload, _options.MaxResultBytes),
            StartedAsync = useAsync,
            Listings = listings
        };
    }

    private async Task<string> SearchProductsAsync(Guid userId, JsonElement args, CancellationToken ct)
    {
        var query = args.TryGetProperty("query", out var q) ? q.GetString()?.Trim() ?? "" : "";
        if (query.Length < 1)
        {
            return """{"ok":false,"error":"missing_query"}""";
        }

        var page = args.TryGetProperty("page", out var p) && p.TryGetInt32(out var pageVal) ? Math.Max(1, pageVal) : 1;
        var raw = await productsAppService.SearchAsync(
                new SearchProductsInput
                {
                    Query = query,
                    Page = page,
                    PageSize = _options.MaxSearchItems,
                    SearcherUserId = userId.ToString("D")
                },
                ct)
            .ConfigureAwait(false);

        return AiShoppingResultShaper.ShapeSearch(raw, _options.MaxSearchItems, _options.MaxTextFieldChars);
    }

    private async Task<string> GetProductDetailsAsync(Guid userId, JsonElement args, CancellationToken ct)
    {
        var productId = args.TryGetProperty("productId", out var id) ? id.GetString()?.Trim() : null;
        if (string.IsNullOrWhiteSpace(productId))
        {
            return """{"ok":false,"error":"missing_productId"}""";
        }

        var raw = await productsAppService.GetByIdAsync(productId, asRetail: false, ct)
            .ConfigureAwait(false);
        return AiShoppingResultShaper.ShapeProduct(raw, _options.MaxTextFieldChars);
    }

    private async Task<string> GetAlternativesAsync(Guid userId, JsonElement args, CancellationToken ct)
    {
        var query = args.TryGetProperty("query", out var q) ? q.GetString()?.Trim() ?? "" : "";
        if (query.Length < 1)
        {
            return """{"ok":false,"error":"missing_query"}""";
        }

        var raw = await productsAppService.SearchAsync(
                new SearchProductsInput
                {
                    Query = query,
                    Page = 1,
                    PageSize = _options.MaxSearchItems,
                    SearcherUserId = userId.ToString("D")
                },
                ct)
            .ConfigureAwait(false);
        return AiShoppingResultShaper.ShapeSearch(raw, _options.MaxSearchItems, _options.MaxTextFieldChars, preferCheaper: true);
    }

    private async Task<string> GetCategoriesAsync(CancellationToken ct)
    {
        var raw = await categoriesAppService.GetAllAsync(ct).ConfigureAwait(false);
        return AiShoppingResultShaper.ShapeCategories(raw, _options.MaxTextFieldChars);
    }

    private async Task<string> GetOffersAsync(Guid userId, JsonElement args, CancellationToken ct)
    {
        var raw = await productsAppService.GetByTypeAsync(
                new GetProductsByTypeInput
                {
                    ProductTypeName = "Offers",
                    Page = 1,
                    PageSize = _options.MaxSearchItems
                },
                ct)
            .ConfigureAwait(false);
        return AiShoppingResultShaper.ShapeSearch(raw, _options.MaxSearchItems, _options.MaxTextFieldChars);
    }

    private async Task<string> GetCartAsync(Guid userId, CancellationToken ct)
    {
        var raw = await cartAppService.GetMyCartAsync(userId.ToString("D"), ct).ConfigureAwait(false);
        return AiShoppingResultShaper.ShapeCart(raw, _options.MaxTextFieldChars);
    }

    private async Task<string> AddToCartAsync(Guid userId, JsonElement args, CancellationToken ct)
    {
        var productId = args.TryGetProperty("productId", out var id) ? id.GetString()?.Trim() : null;
        var qty = args.TryGetProperty("quantity", out var q) && q.TryGetDecimal(out var qd) ? qd : 0m;
        var unit = args.TryGetProperty("unitName", out var u) ? u.GetString() : null;
        if (string.IsNullOrWhiteSpace(productId) || qty <= 0)
        {
            return """{"ok":false,"error":"invalid_args"}""";
        }

        var raw = await cartAppService.AddItemAsync(
                new AddCartItemInput
                {
                    UserId = userId.ToString("D"),
                    ProductId = productId!,
                    Quantity = qty,
                    UnitName = unit ?? string.Empty
                },
                ct)
            .ConfigureAwait(false);
        return AiShoppingResultShaper.ShapeGenericOk(raw);
    }

    private async Task<string> UpdateCartAsync(Guid userId, JsonElement args, CancellationToken ct)
    {
        var cartItemId = args.TryGetProperty("cartItemId", out var id) && id.TryGetInt64(out var cid) ? cid : 0;
        var reduceBy = args.TryGetProperty("reduceBy", out var r) && r.TryGetDecimal(out var rd) ? rd : 0m;
        if (cartItemId <= 0 || reduceBy <= 0)
        {
            return """{"ok":false,"error":"invalid_args"}""";
        }

        var raw = await cartAppService.ReduceItemQuantityAsync(
                new ReduceCartItemInput
                {
                    UserId = userId.ToString("D"),
                    CartItemId = cartItemId,
                    Quantity = reduceBy
                },
                ct)
            .ConfigureAwait(false);
        return AiShoppingResultShaper.ShapeGenericOk(raw);
    }

    private async Task<string> RemoveFromCartAsync(Guid userId, JsonElement args, CancellationToken ct)
    {
        var cartItemId = args.TryGetProperty("cartItemId", out var id) && id.TryGetInt64(out var cid) ? cid : 0;
        if (cartItemId <= 0)
        {
            return """{"ok":false,"error":"invalid_args"}""";
        }

        var raw = await cartAppService.RemoveItemAsync(
                new RemoveCartItemInput
                {
                    UserId = userId.ToString("D"),
                    CartItemId = cartItemId
                },
                ct)
            .ConfigureAwait(false);
        return AiShoppingResultShaper.ShapeGenericOk(raw);
    }

    private async Task<string> GetMyOrdersAsync(Guid userId, JsonElement args, CancellationToken ct)
    {
        var page = args.TryGetProperty("page", out var p) && p.TryGetInt32(out var pv) ? Math.Max(1, pv) : 1;
        var raw = await ordersAppService.GetMyOrdersAsync(
                userId.ToString("D"),
                page,
                10,
                statusId: null,
                search: null,
                ct)
            .ConfigureAwait(false);
        return AiShoppingResultShaper.ShapeOrders(raw, _options.MaxSearchItems, _options.MaxTextFieldChars);
    }

    private async Task<string> GetOrderDetailsAsync(Guid userId, JsonElement args, CancellationToken ct)
    {
        var orderId = args.TryGetProperty("orderId", out var id) && id.TryGetInt64(out var oid) ? oid : 0L;
        if (orderId <= 0)
        {
            return """{"ok":false,"error":"invalid_orderId"}""";
        }

        var raw = await ordersAppService.GetOrderByIdAsync(userId.ToString("D"), orderId, ct).ConfigureAwait(false);
        return AiShoppingResultShaper.ShapeOrderDetail(raw, _options.MaxTextFieldChars);
    }

    private async Task<string> LookupRefundByIdAsync(Guid userId, JsonElement args, CancellationToken ct)
    {
        var refundId = args.TryGetProperty("refundId", out var idEl)
            ? idEl.GetString()
            : null;
        if (string.IsNullOrWhiteSpace(refundId)
            && args.TryGetProperty("refund_id", out var snakeEl))
        {
            refundId = snakeEl.GetString();
        }

        if (string.IsNullOrWhiteSpace(refundId))
        {
            return """{"ok":false,"error":"invalid_refundId"}""";
        }

        try
        {
            var raw = await ordersAppService
                .GetOrderByRefundIdAsync(userId.ToString("D"), refundId, ct)
                .ConfigureAwait(false);
            return AiShoppingResultShaper.ShapeOrderDetail(raw, _options.MaxTextFieldChars);
        }
        catch (KeyNotFoundException)
        {
            return """{"ok":true,"found":false,"error":"refund_not_found"}""";
        }
    }

    private static string BuildIdempotencyKey(
        Guid userId,
        string sessionKey,
        string turnId,
        string toolName,
        string argsJson)
    {
        var material = $"{userId:D}|{sessionKey}|{turnId}|{toolName}|{argsJson}";
        var hash = SHA256.HashData(Encoding.UTF8.GetBytes(material));
        return Convert.ToHexString(hash);
    }

    private static AiShoppingToolExecutionResult WrapExisting(object? existing)
    {
        var json = existing is null
            ? """{"ok":false,"error":"duplicate"}"""
            : JsonSerializer.Serialize(existing);
        return new AiShoppingToolExecutionResult
        {
            Ok = false,
            PayloadJson = json,
            ErrorCode = "duplicate"
        };
    }

    private static IReadOnlyList<AiProductListingDto>? TryExtractListings(string payload)
    {
        try
        {
            using var doc = JsonDocument.Parse(payload);
            if (!doc.RootElement.TryGetProperty("items", out var items)
                || items.ValueKind != JsonValueKind.Array)
            {
                return null;
            }

            var list = new List<AiProductListingDto>();
            foreach (var el in items.EnumerateArray())
            {
                if (!el.TryGetProperty("productId", out var idEl))
                {
                    continue;
                }

                if (!Guid.TryParse(idEl.GetString(), out var productId) || productId == Guid.Empty)
                {
                    continue;
                }

                var name = el.TryGetProperty("name", out var n) ? n.GetString() : null;
                name ??= el.TryGetProperty("nameEn", out var ne) ? ne.GetString() : null;
                name ??= el.TryGetProperty("productName", out var pn) ? pn.GetString() : null;
                var nameAr = el.TryGetProperty("nameAr", out var na) ? na.GetString() : null;
                var price = el.TryGetProperty("price", out var pr) && pr.TryGetDecimal(out var pd) ? pd : 0m;
                if (price == 0m
                    && el.TryGetProperty("displayPrice", out var dpr)
                    && dpr.TryGetDecimal(out var dpd))
                {
                    price = dpd;
                }

                var currency = el.TryGetProperty("currency", out var c) ? c.GetString() : null;
                var qty = el.TryGetProperty("quantity", out var q) && q.TryGetInt64(out var ql) ? ql : 0;
                var unit = el.TryGetProperty("unitName", out var u) ? u.GetString() : null;
                var descriptionEn = el.TryGetProperty("descriptionEn", out var de) ? de.GetString() : null;
                descriptionEn ??= el.TryGetProperty("description", out var d) ? d.GetString() : null;
                var descriptionAr = el.TryGetProperty("descriptionAr", out var da) ? da.GetString() : null;
                byte? productTypeId = el.TryGetProperty("productTypeId", out var pti) && pti.TryGetByte(out var ptiv)
                    ? ptiv
                    : null;
                var productTypeName = el.TryGetProperty("productTypeName", out var ptn) ? ptn.GetString() : null;
                byte? requestTypeId = el.TryGetProperty("requestTypeId", out var rti) && rti.TryGetByte(out var rtiv)
                    ? rtiv
                    : null;
                var requestTypeName = el.TryGetProperty("requestTypeName", out var rtn) ? rtn.GetString() : null;
                byte? bookingPriceTypeId = el.TryGetProperty("bookingPriceTypeId", out var bti) && bti.TryGetByte(out var btiv)
                    ? btiv
                    : null;
                var bookingPriceTypeName = el.TryGetProperty("bookingPriceTypeName", out var btn)
                    ? btn.GetString()
                    : null;
                var shippingDescriptionEn = el.TryGetProperty("shippingDescriptionEn", out var sde)
                    ? sde.GetString()
                    : null;
                DateTime? createdAt = null;
                if (el.TryGetProperty("createdAt", out var ca) && ca.ValueKind == JsonValueKind.String
                    && DateTime.TryParse(ca.GetString(), out var parsedCreatedAt))
                {
                    createdAt = parsedCreatedAt;
                }

                byte? discountPercentage = el.TryGetProperty("discountPercentage", out var dp)
                    && dp.TryGetByte(out var dpv)
                        ? dpv
                        : null;
                short? discountDays = el.TryGetProperty("discountDays", out var dd) && dd.TryGetInt16(out var ddv)
                    ? ddv
                    : null;

                var images = new List<string>();
                if (el.TryGetProperty("images", out var imgs) && imgs.ValueKind == JsonValueKind.Array)
                {
                    foreach (var img in imgs.EnumerateArray())
                    {
                        if (img.ValueKind == JsonValueKind.String
                            && !string.IsNullOrWhiteSpace(img.GetString()))
                        {
                            images.Add(img.GetString()!.Trim());
                        }
                    }
                }
                else if (el.TryGetProperty("image", out var oneImg)
                    && oneImg.ValueKind == JsonValueKind.String
                    && !string.IsNullOrWhiteSpace(oneImg.GetString()))
                {
                    images.Add(oneImg.GetString()!.Trim());
                }

                list.Add(new AiProductListingDto(
                    productId,
                    null,
                    name,
                    nameAr,
                    price,
                    currency,
                    null,
                    null,
                    qty,
                    unit,
                    null,
                    productTypeId,
                    productTypeName,
                    el.TryGetProperty("searchListingChannel", out var ch) ? ch.GetString() : null,
                    el.TryGetProperty("hasRetailPricing", out var hrp) && hrp.ValueKind == JsonValueKind.True,
                    images.Count == 0 ? null : images,
                    descriptionEn,
                    descriptionAr,
                    createdAt,
                    discountPercentage,
                    discountDays,
                    requestTypeId,
                    requestTypeName,
                    bookingPriceTypeId,
                    bookingPriceTypeName,
                    shippingDescriptionEn));
            }

            return list.Count == 0 ? null : list;
        }
        catch
        {
            return null;
        }
    }
}
