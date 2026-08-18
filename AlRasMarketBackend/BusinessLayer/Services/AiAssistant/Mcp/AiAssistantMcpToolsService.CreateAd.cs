using System.Globalization;
using System.Text.RegularExpressions;
using System.Text.Json;
using BusinessLayer.Caching;
using BusinessLayer.Dtos;
using BusinessLayer.Helpers;
using BusinessLayer.Interfaces;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;

namespace BusinessLayer.Services.AiAssistant.Mcp;

public sealed partial class AiAssistantMcpToolsService
{
    private static readonly (byte Id, string NameEn, string NameAr)[] KnownUnits =
    [
        (1, "Ton", "طن"),
        (2, "Gram", "جرام"),
        (3, "Kilogram", "كيلو"),
        (4, "Carton", "كرتون"),
        (5, "Bag", "كيس"),
        (6, "Dozen", "درزن"),
        (7, "Box", "صندوق"),
        (8, "Piece", "قطعة"),
        (9, "Packet", "عبوة"),
        (10, "Bundle", "حزمة"),
        (11, "Drum", "برميل"),
        (12, "Bottle", "زجاجة"),
        (13, "Tin", "علبة معدنية"),
        (14, "Sack", "شوال"),
        (15, "Case", "كرتونة"),
        (16, "Pallet", "طبلية"),
        (17, "Liter", "لتر"),
        (18, "Ml", "ملليلتر"),
        (19, "Jar", "برطمان")
    ];

    private static readonly (byte Id, string NameEn, string NameAr)[] KnownProductTypes =
    [
        (1, "Retail", "تجزئة"),
        (2, "Booking", "بوكينج"),
        (3, "Offers", "عروض"),
        (4, "Requests", "طلبات")
    ];

    private static readonly Dictionary<string, string> UnitAliasMap = new(StringComparer.OrdinalIgnoreCase)
    {
        ["ton"] = "Ton",
        ["tons"] = "Ton",
        ["tonne"] = "Ton",
        ["tonnes"] = "Ton",
        ["طن"] = "Ton",
        ["طنات"] = "Ton",
        ["تن"] = "Ton",
        ["gram"] = "Gram",
        ["grams"] = "Gram",
        ["g"] = "Gram",
        ["جرام"] = "Gram",
        ["kilogram"] = "Kilogram",
        ["kilograms"] = "Kilogram",
        ["kg"] = "Kilogram",
        ["kilo"] = "Kilogram",
        ["كيلو"] = "Kilogram",
        ["كجم"] = "Kilogram",
        ["كيلوجرام"] = "Kilogram",
        ["carton"] = "Carton",
        ["cartons"] = "Carton",
        ["كرتون"] = "Carton",
        ["كراتين"] = "Carton",
        ["bag"] = "Bag",
        ["bags"] = "Bag",
        ["كيس"] = "Bag",
        ["اكياس"] = "Bag",
        ["dozen"] = "Dozen",
        ["dz"] = "Dozen",
        ["درزن"] = "Dozen",
        ["box"] = "Box",
        ["boxes"] = "Box",
        ["صندوق"] = "Box",
        ["صناديق"] = "Box",
        ["piece"] = "Piece",
        ["pieces"] = "Piece",
        ["pc"] = "Piece",
        ["pcs"] = "Piece",
        ["قطعة"] = "Piece",
        ["قطع"] = "Piece",
        ["حبة"] = "Piece",
        ["packet"] = "Packet",
        ["packets"] = "Packet",
        ["عبوة"] = "Packet",
        ["باكيت"] = "Packet",
        ["bundle"] = "Bundle",
        ["bundles"] = "Bundle",
        ["حزمة"] = "Bundle",
        ["drum"] = "Drum",
        ["drums"] = "Drum",
        ["برميل"] = "Drum",
        ["bottle"] = "Bottle",
        ["bottles"] = "Bottle",
        ["زجاجة"] = "Bottle",
        ["tin"] = "Tin",
        ["tins"] = "Tin",
        ["علبة معدنية"] = "Tin",
        ["sack"] = "Sack",
        ["sacks"] = "Sack",
        ["شوال"] = "Sack",
        ["case"] = "Case",
        ["cases"] = "Case",
        ["كرتونة"] = "Case",
        ["pallet"] = "Pallet",
        ["pallets"] = "Pallet",
        ["طبلية"] = "Pallet",
        ["liter"] = "Liter",
        ["liters"] = "Liter",
        ["litre"] = "Liter",
        ["لتر"] = "Liter",
        ["ml"] = "Ml",
        ["milliliter"] = "Ml",
        ["ملليلتر"] = "Ml",
        ["jar"] = "Jar",
        ["jars"] = "Jar",
        ["برطمان"] = "Jar"
    };

    private static readonly (byte Id, string NameEn, string NameAr)[] KnownCategories =
    [
        (1, "Dry Fruits", "فواكه مجمده"),
        (2, "Coconut", "جوز الهند"),
        (3, "Cusmatic", "تجميل"),
        (5, "Canned", "معلبات"),
        (6, "Sweets", "حلويات"),
        (7, "Rice", "أرز"),
        (8, "Sugar", "سكر"),
        (9, "Dates", "تمور"),
        (10, "Milk", "حليب"),
        (11, "Acids", "أحماض"),
        (12, "Cocoa", "كاكو"),
        (13, "Cardamom", "الهيل"),
        (14, "Coffee", "قهوة"),
        (15, "Nuts", "مكسرات"),
        (16, "Spices", "توابل"),
        (17, "Pulses", "بقوليات"),
        (18, "Herbs", "أعشاب"),
        (59, "Arabic Gum", "صمغ عربى"),
        (60, "Sesame Seeds", "سمسم"),
        (61, "Seeds", "بذور"),
        (66, "Spice Powder", "بهارات مطحونة")
    ];

    private async Task<string> LookupCreateAdReferenceAsync(
        string argumentsJson,
        CancellationToken cancellationToken)
    {
        using var args = JsonDocument.Parse(string.IsNullOrWhiteSpace(argumentsJson) ? "{}" : argumentsJson);
        var root = args.RootElement;
        var lookup = (GetString(root, "lookup") ?? "").Trim().ToLowerInvariant();
        var query = (GetString(root, "query") ?? "").Trim();
        var countryName = GetString(root, "country_name");

        return lookup switch
        {
            "units" => Json(new
            {
                ok = true,
                lookup = "units",
                units = FilterReferenceRows(
                        KnownUnits.Select(x => new { id = x.Id, nameEn = x.NameEn, nameAr = x.NameAr }),
                        query)
                    .ToList()
            }),
            "categories" => Json(new
            {
                ok = true,
                lookup = "categories",
                categories = FilterReferenceRows(
                        KnownCategories.Select(x => new { id = x.Id, nameEn = x.NameEn, nameAr = x.NameAr }),
                        query)
                    .ToList()
            }),
            "request_types" => Json(new
            {
                ok = true,
                lookup = "request_types",
                requestTypes = new[]
                {
                    new { id = 1, nameEn = "Local", nameAr = "محلي", aliases = new[] { "local", "محلي" } },
                    new
                    {
                        id = 2,
                        nameEn = "Reexport",
                        nameAr = "إعادة تصدير",
                        aliases = new[] { "reexport", "rexport", "re-export", "export", "إعادة تصدير", "اعادة تصدير" }
                    }
                }
            }),
            "countries" => await LookupCountriesAsync(query, cancellationToken).ConfigureAwait(false),
            "ports" => await LookupPortsAsync(countryName, query, cancellationToken).ConfigureAwait(false),
            "booking_price_types" => Json(new
            {
                ok = true,
                lookup = "booking_price_types",
                bookingPriceTypes = new[]
                {
                    new { nameEn = "FOB", nameAr = "FOB" },
                    new { nameEn = "CNF", nameAr = "CNF" },
                    new { nameEn = "CIF", nameAr = "CIF" }
                }
            }),
            "product_types" => Json(new
            {
                ok = true,
                lookup = "product_types",
                note =
                    "Product type ids are NOT unit ids. For quantity '5 tons' use quantity=5 and unit_name=Ton (unit id 1), NOT unit_id=5.",
                productTypes = KnownProductTypes
                    .Select(x => new { id = x.Id, nameEn = x.NameEn, nameAr = x.NameAr })
                    .ToList()
            }),
            _ => Json(new
            {
                ok = false,
                error =
                    "lookup must be one of: units, product_types, categories, request_types, booking_price_types, countries, ports. " +
                    "For ports also pass country_name."
            })
        };
    }

    private async Task<string> LookupCountriesAsync(string query, CancellationToken cancellationToken)
    {
        await using var scope = scopeFactory.CreateAsyncScope();
        var cache = scope.ServiceProvider.GetRequiredService<IStaticReferenceCache>();
        await cache.EnsureLoadedAsync(cancellationToken).ConfigureAwait(false);

        var rows = cache.GetCountries()
            .Select(x => new
            {
                id = x.Id,
                nameEn = x.CountryNameEn,
                nameAr = x.CountryNameAr,
                iso2 = x.Iso2Code
            })
            .Where(x => MatchesQuery(query, x.nameEn, x.nameAr, x.iso2))
            .OrderBy(x => x.nameEn)
            .Take(40)
            .ToList();

        return Json(new
        {
            ok = true,
            lookup = "countries",
            count = rows.Count,
            resolved = string.IsNullOrWhiteSpace(query)
                ? null
                : cache.FindCountryByName(query)?.CountryNameEn,
            countries = rows
        });
    }

    private async Task<string> LookupPortsAsync(
        string? countryName,
        string query,
        CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(countryName))
        {
            return Json(new { ok = false, error = "country_name is required when lookup=ports." });
        }

        await using var scope = scopeFactory.CreateAsyncScope();
        var cache = scope.ServiceProvider.GetRequiredService<IStaticReferenceCache>();
        await cache.EnsureLoadedAsync(cancellationToken).ConfigureAwait(false);

        var country = cache.FindCountryByName(countryName);
        if (country is null)
        {
            var suggestions = cache.SuggestCountries(countryName)
                .Select(x => x.CountryNameEn)
                .Take(5)
                .ToList();
            return Json(new
            {
                ok = false,
                error = $"Country '{countryName.Trim()}' was not found. Use the exact English name from the catalog.",
                suggestions,
                hint = "Arabic names and aliases like United Arab Emirates → UAE are supported — try lookup=countries."
            });
        }

        var ports = cache.GetPortsByCountryId(country.Id)
            .Select(x => new
            {
                id = x.Id,
                nameEn = x.PortNameEn,
                nameAr = x.PortNameAr,
                countryId = country.Id,
                countryNameEn = country.CountryNameEn
            })
            .Where(x => MatchesQuery(query, x.nameEn, x.nameAr))
            .OrderBy(x => x.nameEn)
            .Take(60)
            .ToList();

        return Json(new
        {
            ok = true,
            lookup = "ports",
            country = new { id = country.Id, nameEn = country.CountryNameEn, nameAr = country.CountryNameAr },
            resolvedPort = string.IsNullOrWhiteSpace(query)
                ? null
                : cache.FindPortByName(query, country.Id)?.PortNameEn,
            count = ports.Count,
            ports
        });
    }

    private async Task<string> CreateRequestAdAsync(
        Guid? userId,
        string argumentsJson,
        CancellationToken cancellationToken)
    {
        if (!userId.HasValue)
        {
            return Json(new { ok = false, error = "Sign in to create a Request ad." });
        }

        var audience = await ResolveAudienceAsync(userId.Value, cancellationToken).ConfigureAwait(false);
        if (audience is not ("supplier" or "company_customer"))
        {
            return Json(new
            {
                ok = false,
                error =
                    audience switch
                    {
                        "shipping" => "Shipping companies cannot create Request ads.",
                        "personal" => "Personal customer accounts cannot create ads.",
                        "guest" => "Sign in to create a Request ad.",
                        _ => "This account type cannot create Request ads."
                    }
            });
        }

        using var args = JsonDocument.Parse(string.IsNullOrWhiteSpace(argumentsJson) ? "{}" : argumentsJson);
        var root = args.RootElement;

        var name = RequireName(root);
        if (name.Error is not null) return name.Error;

        var price = GetDecimal(root, "price") ?? GetDecimal(root, "target_price");
        if (price is < 0)
        {
            return Json(new { ok = false, error = "price (target price) cannot be negative." });
        }

        var quantityUnit = ResolveQuantityAndUnit(root);
        if (quantityUnit.Error is not null)
        {
            return quantityUnit.Error;
        }

        if (quantityUnit.Quantity is < 0)
        {
            return Json(new { ok = false, error = "quantity cannot be negative." });
        }

        if (quantityUnit.Quantity is > 0 && string.IsNullOrWhiteSpace(quantityUnit.UnitName))
        {
            return Json(new
            {
                ok = false,
                error =
                    "When quantity is provided, unit_name or unit_id is required (Ton, Kilogram, Carton, …)."
            });
        }

        if (price is > 0 && string.IsNullOrWhiteSpace(quantityUnit.UnitName))
        {
            return Json(new
            {
                ok = false,
                error = "When target price is provided, unit_name or unit_id is required."
            });
        }

        var requestTypeName = NormalizeRequestTypeForCreate(
            GetString(root, "request_type_name"),
            GetLong(root, "request_type_id"));
        if (string.IsNullOrWhiteSpace(requestTypeName))
        {
            return Json(new
            {
                ok = false,
                error = "request_type_name is required: Local or Reexport (محلي / إعادة تصدير)."
            });
        }

        var currency = NormalizeCurrency(GetString(root, "currency"));
        if (price is > 0 && currency is null)
        {
            return Json(new { ok = false, error = "currency must be USD or AED when target price is provided." });
        }

        var deliveryDate = NormalizeDeliveryDate(
            GetString(root, "delivery_date") ?? GetString(root, "required_delivery_date"));

        var addressId = (GetString(root, "address_id") ?? GetString(root, "AddressId") ?? "").Trim();
        if (audience == "company_customer" && string.IsNullOrWhiteSpace(addressId))
        {
            return Json(new
            {
                ok = false,
                error =
                    "address_id is required for company_customer Request ads. " +
                    "Call list_my_addresses first and pass a saved address GUID. " +
                    "If the list is empty, ask the user to add an address in Profile / Create Order."
            });
        }

        if (!string.IsNullOrWhiteSpace(addressId) && !Guid.TryParse(addressId, out _))
        {
            return Json(new
            {
                ok = false,
                error = "address_id must be a valid GUID from list_my_addresses."
            });
        }

        var specifications = (GetString(root, "specifications") ?? GetString(root, "description") ?? "").Trim();
        if (string.IsNullOrWhiteSpace(specifications))
        {
            return Json(new { ok = false, error = "specifications are required." });
        }

        byte? packaging = ParsePackaging(root);

        var negotiable = GetBool(root, "negotiable") ?? false;
        var submitForReview = GetBool(root, "submit_for_review") ?? true;
        var createdLanguage = NormalizeCreatedLanguage(GetString(root, "created_language"));
        var media = ParseCreateAdMedia(root);
        if (media.Error is not null) return media.Error!;

        var input = new CreateProductInput
        {
            OwnerId = userId.Value.ToString("D"),
            NameEn = name.Value!,
            CreatedLanguage = createdLanguage,
            ProductTypeName = "Requests",
            USDPrice = price ?? 0,
            Currency = price is > 0 ? currency : null,
            Quantity = quantityUnit.Quantity ?? 0,
            UnitName = quantityUnit.UnitName ?? string.Empty,
            DescriptionEn = specifications,
            Negotiable = negotiable,
            RequestTypeName = requestTypeName,
            ShippingDuration = deliveryDate,
            AddressId = string.IsNullOrWhiteSpace(addressId) ? null : addressId,
            Packaging = packaging,
            DraftImagePaths = media.DraftImagePaths,
            DraftVideoPath = media.DraftVideoPath,
            DraftVideoDurationSeconds = media.DraftVideoDurationSeconds
        };

        return await ExecuteProductCreateAsync(
                userId.Value,
                input,
                "Requests",
                submitForReview,
                cancellationToken)
            .ConfigureAwait(false);
    }

    private async Task<string> ListMyAddressesAsync(Guid? userId, CancellationToken cancellationToken)
    {
        if (!userId.HasValue)
        {
            return Json(new { ok = false, error = "Sign in to list saved addresses." });
        }

        using var scope = scopeFactory.CreateScope();
        var addressesApp = scope.ServiceProvider.GetRequiredService<IAddressesAppService>();
        var result = await addressesApp
            .GetByUserAsync(userId.Value.ToString("D"), cancellationToken)
            .ConfigureAwait(false);

        IReadOnlyList<AddressListItemDto> items = [];
        if (result is not null)
        {
            var type = result.GetType();
            var itemsProp = type.GetProperty("items") ?? type.GetProperty("Items");
            if (itemsProp?.GetValue(result) is System.Collections.IEnumerable raw)
            {
                items = raw.OfType<AddressListItemDto>().ToList();
            }
        }

        var mapped = items.Select(a => new
        {
            address_id = a.AddressId.ToString("D"),
            label = string.Join(
                ", ",
                new[] { a.AddressLine1, a.AddressLine2, a.CityName, a.CountryNameAr ?? a.CountryNameEn }
                    .Where(x => !string.IsNullOrWhiteSpace(x))),
            address_line1 = a.AddressLine1,
            address_line2 = a.AddressLine2,
            city_name = a.CityName,
            country_name_en = a.CountryNameEn,
            country_name_ar = a.CountryNameAr
        }).ToList();

        return Json(new
        {
            ok = true,
            count = mapped.Count,
            addresses = mapped,
            hint = mapped.Count == 0
                ? "No saved addresses. Ask the user to add one in Profile or Create Order before publishing a Request."
                : "Ask the user which address to use, then pass that address_id to create_request_ad."
        });
    }

    private async Task<string> ResolveAudienceAsync(Guid userId, CancellationToken cancellationToken)
    {
        var user = await dbContext.Users
            .AsNoTracking()
            .Where(x => x.Id == userId)
            .Select(x => new { x.RoleId, x.IsCustomer })
            .FirstOrDefaultAsync(cancellationToken)
            .ConfigureAwait(false);

        if (user is null) return "guest";

        return user.RoleId switch
        {
            5 => "shipping",
            3 => "personal",
            2 when user.IsCustomer == true => "company_customer",
            2 => "supplier",
            _ => "public"
        };
    }

    private static string? NormalizeRequestTypeForCreate(string? name, long? id)
    {
        if (id is 1) return "Local";
        if (id is 2) return "Reexport";

        if (string.IsNullOrWhiteSpace(name)) return null;

        var normalized = name.Trim().ToLowerInvariant();
        return normalized switch
        {
            "local" or "محلي" => "Local",
            "reexport" or "rexport" or "re-export" or "re_export" or "export"
                or "إعادة تصدير" or "اعادة تصدير" or "booking" => "Reexport",
            _ => char.IsUpper(name[0]) ? name.Trim() : null
        };
    }

    private static string? NormalizeCurrency(string? currency)
    {
        if (string.IsNullOrWhiteSpace(currency)) return "USD";
        var c = currency.Trim().ToUpperInvariant();
        return c is "USD" or "AED" ? c : null;
    }

    private static string? NormalizeDeliveryDate(string? value)
    {
        if (string.IsNullOrWhiteSpace(value)) return null;
        var trimmed = value.Trim();
        if (DateTime.TryParseExact(
                trimmed,
                ["yyyy-MM-dd", "yyyy/M/d", "dd/MM/yyyy", "d/M/yyyy"],
                CultureInfo.InvariantCulture,
                DateTimeStyles.None,
                out var parsed))
        {
            return parsed.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture);
        }

        return null;
    }

    private static string NormalizeCreatedLanguage(string? language) =>
        (language ?? "").Trim().StartsWith("ar", StringComparison.OrdinalIgnoreCase) ? "ar" : "en";

    private static string? ExtractProductId(object createResult)
    {
        if (createResult is JsonElement el)
        {
            if (el.TryGetProperty("productId", out var idEl)) return idEl.GetString();
            if (el.TryGetProperty("ProductId", out var idEl2)) return idEl2.GetString();
        }

        var type = createResult.GetType();
        var prop = type.GetProperty("productId") ?? type.GetProperty("ProductId");
        return prop?.GetValue(createResult)?.ToString();
    }

    private static string? ExtractStringProperty(object result, string propertyName)
    {
        if (result is JsonElement el && el.TryGetProperty(propertyName, out var valueEl))
        {
            return valueEl.GetString();
        }

        var prop = result.GetType().GetProperty(propertyName);
        return prop?.GetValue(result)?.ToString();
    }

    private static byte? GetByte(JsonElement root, string name)
    {
        if (!root.TryGetProperty(name, out var el)) return null;
        if (el.ValueKind == JsonValueKind.Number && el.TryGetByte(out var b)) return b;
        if (el.ValueKind == JsonValueKind.String && byte.TryParse(el.GetString(), out var parsed))
        {
            return parsed;
        }

        return null;
    }

    private static List<string>? GetStringList(JsonElement root, string name)
    {
        if (!root.TryGetProperty(name, out var el) || el.ValueKind != JsonValueKind.Array)
        {
            return null;
        }

        var list = new List<string>();
        foreach (var item in el.EnumerateArray())
        {
            if (item.ValueKind == JsonValueKind.String)
            {
                var value = item.GetString()?.Trim();
                if (!string.IsNullOrWhiteSpace(value))
                {
                    list.Add(value);
                }
            }
        }

        return list.Count == 0 ? null : list;
    }

    private sealed record ResolvedQuantityUnit(long? Quantity, string? UnitName, string? Error);

    private static ResolvedQuantityUnit ResolveQuantityAndUnit(JsonElement root)
    {
        var quantity = GetLong(root, "quantity");
        var unitName = ResolveUnitName(root);

        foreach (var key in new[] { "quantity_with_unit", "quantity_unit", "qty_with_unit" })
        {
            if (TryParseQuantityUnit(GetString(root, key), out var parsedQty, out var parsedUnit))
            {
                quantity ??= parsedQty;
                unitName ??= parsedUnit;
            }
        }

        var rawUnitField = GetString(root, "unit_name") ?? GetString(root, "unit");
        if (TryParseQuantityUnit(rawUnitField, out var inlineQty, out var inlineUnit))
        {
            quantity ??= inlineQty;
            unitName ??= inlineUnit;
        }

        if (quantity is > 0
            && string.Equals(unitName, "Piece", StringComparison.OrdinalIgnoreCase)
            && ContainsTonHint(rawUnitField))
        {
            unitName = "Ton";
        }

        if (quantity is > 0
            && unitName is "Bag" or "Gram"
            && ContainsTonHint(rawUnitField))
        {
            return new ResolvedQuantityUnit(
                quantity,
                "Ton",
                null);
        }

        var unitId = GetLong(root, "unit_id");
        if (quantity is > 0
            && unitId == 5
            && ContainsTonHint(rawUnitField)
            && string.IsNullOrWhiteSpace(GetString(root, "unit_name")))
        {
            return new ResolvedQuantityUnit(
                null,
                null,
                Json(new
                {
                    ok = false,
                    error =
                        "unit_id=5 means Bag, not '5 tons'. Use quantity=5 and unit_name=Ton (unit id 1)."
                }));
        }

        return new ResolvedQuantityUnit(quantity, unitName, null);
    }

    private static bool ContainsTonHint(string? text)
    {
        if (string.IsNullOrWhiteSpace(text)) return false;
        var value = text.Trim();
        return value.Contains("ton", StringComparison.OrdinalIgnoreCase)
               || value.Contains("tonne", StringComparison.OrdinalIgnoreCase)
               || value.Contains("طن", StringComparison.OrdinalIgnoreCase)
               || value.Contains("تن", StringComparison.OrdinalIgnoreCase);
    }

    private static bool TryParseQuantityUnit(string? text, out long? quantity, out string? unitName)
    {
        quantity = null;
        unitName = null;
        if (string.IsNullOrWhiteSpace(text)) return false;

        var trimmed = text.Trim();
        var match = Regex.Match(
            trimmed,
            @"^(?<qty>\d+(?:[.,]\d+)?)\s*(?<unit>.+)$",
            RegexOptions.CultureInvariant);
        if (match.Success)
        {
            var qtyText = match.Groups["qty"].Value.Replace(',', '.');
            if (decimal.TryParse(qtyText, NumberStyles.Number, CultureInfo.InvariantCulture, out var qtyDecimal))
            {
                quantity = (long)Math.Round(qtyDecimal, MidpointRounding.AwayFromZero);
            }

            unitName = NormalizeUnitAlias(match.Groups["unit"].Value.Trim());
            return unitName is not null;
        }

        unitName = NormalizeUnitAlias(trimmed);
        return unitName is not null;
    }

    private static string? NormalizeUnitAlias(string text)
    {
        var trimmed = text.Trim();
        if (UnitAliasMap.TryGetValue(trimmed, out var alias))
        {
            return alias;
        }

        var match = KnownUnits.FirstOrDefault(x =>
            x.NameEn.Equals(trimmed, StringComparison.OrdinalIgnoreCase)
            || x.NameAr.Equals(trimmed, StringComparison.OrdinalIgnoreCase));
        return match.NameEn;
    }

    private static IEnumerable<T> FilterReferenceRows<T>(
        IEnumerable<T> rows,
        string query)
        where T : class
    {
        if (string.IsNullOrWhiteSpace(query)) return rows;

        var q = query.Trim();
        return rows.Where(row =>
        {
            var json = JsonSerializer.Serialize(row).ToLowerInvariant();
            return json.Contains(q.ToLowerInvariant(), StringComparison.Ordinal);
        });
    }

    private static bool MatchesQuery(string query, params string?[] values) =>
        GeoNameResolver.MatchesQuery(query, values);

    private static object CreateAdToolDefinition(string name, string description, string[] required)
    {
        return new
        {
            type = "function",
            function = new
            {
                name,
                description = description + " Call lookup_create_ad_reference for countries/ports/units/categories. After user confirms, submit_for_review defaults true. ONE ad per turn.",
                parameters = new
                {
                    type = "object",
                    properties = new Dictionary<string, object>
                    {
                        ["name"] = new { type = "string", description = "Product/ad name — always ask the user." },
                        ["product_name"] = new { type = "string", description = "Alias for name." },
                        ["price"] = new { type = "number" },
                        ["price_before"] = new { type = "number" },
                        ["price_after"] = new { type = "number" },
                        ["target_price"] = new { type = "number" },
                        ["quantity"] = new { type = "integer" },
                        ["quantity_with_unit"] = new
                        {
                            type = "string",
                            description = "Optional combined text like '5 ton' or '5 طن' — parsed into quantity + unit."
                        },
                        ["unit_name"] = new
                        {
                            type = "string",
                            description =
                                "Ton, Kilogram, Carton, Bag, Box, Piece, Gram, Dozen (Arabic ok). " +
                                "NOT product type id. For 5 tons use quantity=5 and unit_name=Ton."
                        },
                        ["unit_id"] = new
                        {
                            type = "integer",
                            description =
                                "Unit id ONLY: 1=Ton, 2=Gram, 3=Kg, 4=Carton, 5=Bag, 6=Dozen, 7=Box, 8=Piece. " +
                                "Do NOT confuse with product type ids (2=Booking)."
                        },
                        ["currency"] = new { type = "string", description = "USD or AED where applicable." },
                        ["negotiable"] = new { type = "boolean" },
                        ["request_type_name"] = new
                        {
                            type = "string",
                            description = "Local or Reexport (محلي / إعادة تصدير). Required for Request/Offer/Category."
                        },
                        ["request_type_id"] = new { type = "integer", description = "1=Local, 2=Reexport." },
                        ["address_id"] = new
                        {
                            type = "string",
                            description = "Saved address GUID from list_my_addresses (Request ads)."
                        },
                        ["delivery_date"] = new { type = "string", description = "Optional YYYY-MM-DD for Requests." },
                        ["delivery_days"] = new { type = "string" },
                        ["offer_duration_days"] = new { type = "integer" },
                        ["origin_country_name"] = new
                        {
                            type = "string",
                            description =
                                "Booking exporting country (الدولة المصدرة). Arabic or English country name."
                        },
                        ["loading_port_name"] = new
                        {
                            type = "string",
                            description = "Loading port — required for CNF/CIF only. Omit entirely when booking_price_type_name is FOB."
                        },
                        ["destination_country_name"] = new
                        {
                            type = "string",
                            description =
                                "Destination country — required for CNF/CIF only. Omit entirely when booking_price_type_name is FOB."
                        },
                        ["arrival_port_name"] = new
                        {
                            type = "string",
                            description = "Arrival/destination port — required for CNF/CIF only. Omit entirely when booking_price_type_name is FOB."
                        },
                        ["from_country_name"] = new { type = "string" },
                        ["from_port_name"] = new { type = "string" },
                        ["to_country_name"] = new { type = "string" },
                        ["to_port_name"] = new { type = "string" },
                        ["booking_price_type_name"] = new { type = "string", description = "FOB, CNF, or CIF." },
                        ["shipping_duration_days"] = new { type = "string" },
                        ["min_duration_days"] = new { type = "integer" },
                        ["max_duration_days"] = new { type = "integer" },
                        ["container_20ft_price_usd"] = new { type = "number" },
                        ["container_40ft_price_usd"] = new { type = "number" },
                        ["category_id"] = new { type = "integer" },
                        ["category_name"] = new { type = "string" },
                        ["enable_retail_pricing"] = new
                        {
                            type = "boolean",
                            description =
                                "true = hybrid wholesale+retail. When true you MUST collect retail_price, retail_quantity, retail_unit_name, and retail_specifications before calling."
                        },
                        ["retail_price"] = new { type = "number", description = "Retail channel price in AED when hybrid." },
                        ["retail_quantity"] = new { type = "integer" },
                        ["retail_unit_name"] = new { type = "string" },
                        ["retail_specifications"] = new
                        {
                            type = "string",
                            description =
                                "REQUIRED when enable_retail_pricing=true. Retail-channel specs (مواصفات التجزئة). Do not omit; do not silently copy wholesale specs."
                        },
                        ["retail_packaging"] = new { type = "integer", description = "Retail packing kg 1-255; ask when hybrid." },
                        ["specifications"] = new { type = "string" },
                        ["details"] = new { type = "string" },
                        ["packaging"] = new
                        {
                            type = "integer",
                            description =
                                "Packaging weight kg (1-255). ALWAYS ask the user for every ad type before create; omit only if they explicitly say none/لا/بدون."
                        },
                        ["phone_number"] = new { type = "string" },
                        ["draft_image_paths"] = new
                        {
                            type = "array",
                            items = new { type = "string" },
                            description = "R2 draft image paths from mobile upload."
                        },
                        ["draft_video_path"] = new { type = "string" },
                        ["draft_video_duration_seconds"] = new { type = "integer" },
                        ["created_language"] = new { type = "string" },
                        ["submit_for_review"] = new { type = "boolean" }
                    },
                    required,
                    additionalProperties = false
                }
            }
        };
    }
}
