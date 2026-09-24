using System.Text;
using System.Text.Json;

namespace BusinessLayer.Services.AiAssistant.Shopping;

/// <summary>
/// Builds valid, field-limited JSON for Astra. Never mid-truncates JSON blobs.
/// </summary>
public static class AiShoppingResultShaper
{
    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase
    };

    public static string EnsureValidJsonWithinLimit(string json, int maxBytes)
    {
        if (string.IsNullOrWhiteSpace(json))
        {
            return """{"ok":false,"error":"empty","items":[],"hasMore":false}""";
        }

        try
        {
            using var _ = JsonDocument.Parse(json);
        }
        catch
        {
            return """{"ok":false,"error":"invalid_json","items":[],"hasMore":false}""";
        }

        if (Encoding.UTF8.GetByteCount(json) <= maxBytes)
        {
            return json;
        }

        // Replace with a valid compact indication instead of cutting mid-JSON.
        return """{"ok":true,"items":[],"hasMore":true,"truncated":true,"message":"Result too large; ask a more specific query."}""";
    }

    public static string ShapeSearch(object raw, int maxItems, int maxTextChars, bool preferCheaper = false)
    {
        var items = ExtractArray(raw, "items", "Items", "data", "Data", "products", "Products");
        var shaped = new List<Dictionary<string, object?>>();
        foreach (var item in items)
        {
            var card = ShapeItem(item, maxTextChars);
            if (card is not null)
            {
                shaped.Add(card);
            }
        }

        if (preferCheaper)
        {
            shaped = shaped
                .OrderBy(x => x.TryGetValue("price", out var p) && p is decimal d ? d : decimal.MaxValue)
                .ToList();
        }

        var hasMore = shaped.Count > maxItems;
        if (hasMore)
        {
            shaped = shaped.Take(maxItems).ToList();
        }

        return JsonSerializer.Serialize(new
        {
            ok = true,
            items = shaped,
            hasMore,
            count = shaped.Count
        }, JsonOptions);
    }

    public static string ShapeProduct(object raw, int maxTextChars)
    {
        var map = ToMap(raw);
        if (map is null)
        {
            return """{"ok":false,"error":"not_found","priceAvailable":false}""";
        }

        // Unwrap common { data: {...} } envelopes.
        if (map.TryGetValue("data", out var data) || map.TryGetValue("Data", out data))
        {
            map = ToMap(data) ?? map;
        }

        var card = ShapeItem(map, maxTextChars);
        if (card is null)
        {
            return """{"ok":false,"error":"not_found","priceAvailable":false}""";
        }

        card["priceAvailable"] = card.TryGetValue("showPrice", out var showPriceFlag)
            && showPriceFlag is true
            && card.ContainsKey("price")
            && card["price"] is not null;
        return JsonSerializer.Serialize(new { ok = true, item = card }, JsonOptions);
    }

    public static string ShapeCategories(object raw, int maxTextChars)
    {
        var items = ExtractArray(raw, "items", "Items", "data", "Data");
        if (items.Count == 0 && raw is IEnumerable<object> enumerable)
        {
            items = enumerable.Select(ToMap).Where(x => x is not null).Cast<Dictionary<string, object?>>().ToList();
        }

        var shaped = items
            .Select(x => new Dictionary<string, object?>
            {
                ["categoryId"] = Pick(x, "categoryId", "CategoryId"),
                ["name"] = Clip(PickString(x, "nameEn", "NameEn", "name", "Name", "nameAr", "NameAr"), maxTextChars)
            })
            .Where(x => x["categoryId"] is not null)
            .Take(50)
            .ToList();

        return JsonSerializer.Serialize(new { ok = true, items = shaped, hasMore = false }, JsonOptions);
    }

    public static string ShapeCart(object raw, int maxTextChars)
    {
        var map = ToMap(raw) ?? new Dictionary<string, object?>();
        if (map.TryGetValue("data", out var data) || map.TryGetValue("Data", out data))
        {
            map = ToMap(data) ?? map;
        }

        var itemsRaw = ExtractArray(map, "items", "Items");
        var items = itemsRaw
            .Select(x => new Dictionary<string, object?>
            {
                ["cartItemId"] = Pick(x, "id", "Id", "cartItemId"),
                ["productId"] = Pick(x, "productId", "ProductId"),
                ["name"] = Clip(PickString(x, "productName", "ProductName", "name"), maxTextChars),
                ["quantity"] = Pick(x, "quantity", "Quantity"),
                ["unit"] = Pick(x, "unit", "Unit", "unitName"),
                ["unitPriceAed"] = Pick(x, "unitPriceAed", "UnitPriceAed"),
                ["totalPriceAed"] = Pick(x, "totalPriceAed", "TotalPriceAed")
            })
            .Take(30)
            .ToList();

        return JsonSerializer.Serialize(new
        {
            ok = true,
            cartId = Pick(map, "cartId", "CartId"),
            subtotalAed = Pick(map, "subtotalAed", "SubtotalAed"),
            vatAed = Pick(map, "vatAed", "VatAed"),
            totalAed = Pick(map, "totalAed", "TotalAed"),
            items,
            hasMore = itemsRaw.Count > items.Count
        }, JsonOptions);
    }

    public static string ShapeOrders(object raw, int maxItems, int maxTextChars)
    {
        var items = ExtractArray(raw, "items", "Items", "data", "Data", "orders", "Orders");
        var shaped = new List<Dictionary<string, object?>>();
        foreach (var item in items.Take(maxItems))
        {
            shaped.Add(new Dictionary<string, object?>
            {
                ["orderId"] = Pick(item, "id", "Id", "orderId", "OrderId"),
                ["status"] = Clip(PickString(item, "statusName", "StatusName", "status", "Status"), maxTextChars),
                ["total"] = Pick(item, "totalPrice", "TotalPrice", "customerTotal", "CustomerTotal"),
                ["currency"] = Pick(item, "currency", "Currency"),
                ["createdAt"] = Pick(item, "createdAt", "CreatedAt", "createdAtUtc")
            });
        }

        return JsonSerializer.Serialize(new
        {
            ok = true,
            items = shaped,
            hasMore = items.Count > shaped.Count
        }, JsonOptions);
    }

    public static string ShapeOrderDetail(object raw, int maxTextChars)
    {
        var map = ToMap(raw);
        if (map is null)
        {
            return """{"ok":false,"error":"not_found"}""";
        }

        if (map.TryGetValue("data", out var data) || map.TryGetValue("Data", out data))
        {
            map = ToMap(data) ?? map;
        }

        // Strip supplier internals for the model-facing payload.
        var safe = new Dictionary<string, object?>
        {
            ["orderId"] = Pick(map, "id", "Id", "orderId"),
            ["status"] = Clip(PickString(map, "statusName", "StatusName", "status"), maxTextChars),
            ["productName"] = Clip(PickString(map, "productName", "ProductName"), maxTextChars),
            ["quantity"] = Pick(map, "quantity", "Quantity"),
            ["total"] = Pick(map, "totalPrice", "TotalPrice", "customerTotal"),
            ["currency"] = Pick(map, "currency", "Currency"),
            ["createdAt"] = Pick(map, "createdAt", "CreatedAt"),
            ["refundId"] = Pick(map, "stripeRefundId", "StripeRefundId", "refundId", "RefundId"),
            ["isRefunded"] = Pick(map, "isRefunded", "IsRefunded"),
            ["refundedAtUtc"] = Pick(map, "refundedAtUtc", "RefundedAtUtc")
        };

        return JsonSerializer.Serialize(new { ok = true, item = safe }, JsonOptions);
    }

    public static string ShapeGenericOk(object raw)
    {
        var map = ToMap(raw) ?? new Dictionary<string, object?> { ["ok"] = true };
        if (!map.ContainsKey("ok") && !map.ContainsKey("Ok"))
        {
            map["ok"] = true;
        }

        // Never forward supplier/admin blobs.
        map.Remove("supplierName");
        map.Remove("SupplierName");
        map.Remove("supplierPhone");
        map.Remove("SupplierPhone");
        map.Remove("supplierEmail");
        map.Remove("SupplierEmail");
        map.Remove("ownerPrice");
        map.Remove("OwnerPrice");
        map.Remove("commissionPercent");
        map.Remove("CommissionPercent");
        return EnsureValidJsonWithinLimit(JsonSerializer.Serialize(map, JsonOptions), 8_192);
    }

    private static Dictionary<string, object?>? ShapeItem(Dictionary<string, object?> item, int maxTextChars)
    {
        var productId = PickString(item, "productId", "ProductId", "id", "Id");
        if (string.IsNullOrWhiteSpace(productId))
        {
            return null;
        }

        var price = PickDecimal(item, "price", "Price", "displayPrice", "DisplayPrice", "priceAed", "PriceAed");
        var showPrice = PickBool(item, "showPrice", "ShowPrice") ?? true;
        if (!showPrice)
        {
            price = null;
        }
        var description = Clip(
            PickString(item, "descriptionEn", "DescriptionEn", "description", "Description", "descriptionAr", "DescriptionAr"),
            maxTextChars);
        var images = new List<string>();
        var firstImage = FirstImage(item);
        if (!string.IsNullOrWhiteSpace(firstImage))
        {
            images.Add(firstImage);
        }

        return new Dictionary<string, object?>
        {
            ["productId"] = productId,
            ["name"] = Clip(
                PickString(item, "productName", "ProductName", "nameEn", "NameEn", "name", "Name", "nameAr", "NameAr"),
                maxTextChars),
            ["nameEn"] = Clip(PickString(item, "nameEn", "NameEn", "productName", "ProductName"), maxTextChars),
            ["nameAr"] = Clip(PickString(item, "nameAr", "NameAr"), maxTextChars),
            ["description"] = description,
            ["descriptionEn"] = Clip(PickString(item, "descriptionEn", "DescriptionEn", "description", "Description"), maxTextChars),
            ["descriptionAr"] = Clip(PickString(item, "descriptionAr", "DescriptionAr"), maxTextChars),
            ["price"] = price,
            ["displayPrice"] = price,
            ["showPrice"] = showPrice,
            ["priceAvailable"] = showPrice && price is not null,
            ["currency"] = PickString(item, "currency", "Currency") ?? "AED",
            ["quantity"] = Pick(item, "quantity", "Quantity"),
            ["unitName"] = Clip(PickString(item, "unitName", "UnitName"), 40),
            ["productTypeId"] = Pick(item, "productTypeId", "ProductTypeId"),
            ["productTypeName"] = Clip(PickString(item, "productTypeName", "ProductTypeName"), 40),
            ["requestTypeId"] = Pick(item, "requestTypeId", "RequestTypeId"),
            ["requestTypeName"] = Clip(PickString(item, "requestTypeName", "RequestTypeName"), 40),
            ["bookingPriceTypeId"] = Pick(item, "bookingPriceTypeId", "BookingPriceTypeId"),
            ["bookingPriceTypeName"] = Clip(PickString(item, "bookingPriceTypeName", "BookingPriceTypeName"), 40),
            ["shippingDescriptionEn"] = Clip(PickString(item, "shippingDescriptionEn", "ShippingDescriptionEn"), 80),
            ["createdAt"] = Pick(item, "createdAt", "CreatedAt"),
            ["discountPercentage"] = Pick(item, "discountPercentage", "DiscountPercentage"),
            ["discountDays"] = Pick(item, "discountDays", "DiscountDays"),
            ["searchListingChannel"] = PickString(item, "searchListingChannel", "SearchListingChannel"),
            ["hasRetailPricing"] = Pick(item, "hasRetailPricing", "HasRetailPricing") ?? false,
            ["image"] = firstImage,
            ["images"] = images
        };
    }

    private static string? FirstImage(Dictionary<string, object?> item)
    {
        var images = Pick(item, "images", "Images");
        if (images is JsonElement el && el.ValueKind == JsonValueKind.Array && el.GetArrayLength() > 0)
        {
            return el[0].GetString();
        }

        if (images is IEnumerable<object> list)
        {
            return list.Select(x => x?.ToString()).FirstOrDefault(x => !string.IsNullOrWhiteSpace(x));
        }

        return PickString(item, "imageUrl", "ImageUrl", "primaryImage");
    }

    private static List<Dictionary<string, object?>> ExtractArray(object raw, params string[] keys)
    {
        var map = ToMap(raw);
        if (map is not null)
        {
            foreach (var key in keys)
            {
                if (!map.TryGetValue(key, out var value) || value is null)
                {
                    continue;
                }

                return EnumerateMaps(value);
            }
        }

        return EnumerateMaps(raw);
    }

    private static List<Dictionary<string, object?>> EnumerateMaps(object value)
    {
        var list = new List<Dictionary<string, object?>>();
        if (value is JsonElement el && el.ValueKind == JsonValueKind.Array)
        {
            foreach (var item in el.EnumerateArray())
            {
                var map = ToMap(item);
                if (map is not null)
                {
                    list.Add(map);
                }
            }

            return list;
        }

        if (value is IEnumerable<object> objects)
        {
            foreach (var item in objects)
            {
                var map = ToMap(item);
                if (map is not null)
                {
                    list.Add(map);
                }
            }
        }

        return list;
    }

    private static Dictionary<string, object?>? ToMap(object? raw)
    {
        if (raw is null)
        {
            return null;
        }

        if (raw is Dictionary<string, object?> typed)
        {
            return typed;
        }

        if (raw is JsonElement el)
        {
            if (el.ValueKind != JsonValueKind.Object)
            {
                return null;
            }

            var map = new Dictionary<string, object?>(StringComparer.OrdinalIgnoreCase);
            foreach (var prop in el.EnumerateObject())
            {
                map[prop.Name] = prop.Value.ValueKind switch
                {
                    JsonValueKind.String => prop.Value.GetString(),
                    JsonValueKind.Number => prop.Value.TryGetDecimal(out var d) ? d : prop.Value.GetDouble(),
                    JsonValueKind.True => true,
                    JsonValueKind.False => false,
                    JsonValueKind.Null => null,
                    _ => prop.Value.Clone()
                };
            }

            return map;
        }

        try
        {
            var json = JsonSerializer.Serialize(raw);
            using var doc = JsonDocument.Parse(json);
            return ToMap(doc.RootElement.Clone());
        }
        catch
        {
            return null;
        }
    }

    private static object? Pick(Dictionary<string, object?> map, params string[] keys)
    {
        foreach (var key in keys)
        {
            if (map.TryGetValue(key, out var value) && value is not null)
            {
                return value;
            }
        }

        return null;
    }

    private static string? PickString(Dictionary<string, object?> map, params string[] keys) =>
        Pick(map, keys)?.ToString();

    private static decimal? PickDecimal(Dictionary<string, object?> map, params string[] keys)
    {
        var value = Pick(map, keys);
        return value switch
        {
            null => null,
            decimal d => d,
            double db => (decimal)db,
            float f => (decimal)f,
            int i => i,
            long l => l,
            string s when decimal.TryParse(s, out var parsed) => parsed,
            JsonElement el when el.TryGetDecimal(out var d) => d,
            _ => null
        };
    }

    private static bool? PickBool(Dictionary<string, object?> map, params string[] keys)
    {
        var value = Pick(map, keys);
        return value switch
        {
            null => null,
            bool b => b,
            string s when bool.TryParse(s, out var parsed) => parsed,
            string s when s == "1" => true,
            string s when s == "0" => false,
            int i => i != 0,
            long l => l != 0,
            JsonElement el when el.ValueKind == JsonValueKind.True => true,
            JsonElement el when el.ValueKind == JsonValueKind.False => false,
            JsonElement el when el.ValueKind == JsonValueKind.String
                && bool.TryParse(el.GetString(), out var parsed) => parsed,
            _ => null
        };
    }

    private static string? Clip(string? value, int max)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            return value;
        }

        var trimmed = value.Trim();
        return trimmed.Length <= max ? trimmed : trimmed[..max];
    }
}
