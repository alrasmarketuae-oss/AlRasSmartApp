using System.Text.Json;
using BusinessLayer.Dtos;
using BusinessLayer.Interfaces;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;

namespace BusinessLayer.Services.AiAssistant.Mcp;

public sealed partial class AiAssistantMcpToolsService
{
    private async Task<string> CreateBookingAdAsync(
        Guid? userId,
        string argumentsJson,
        CancellationToken cancellationToken)
    {
        if (!userId.HasValue)
        {
            return Json(new { ok = false, error = "Sign in to create a Booking ad." });
        }

        var audience = await ResolveAudienceAsync(userId.Value, cancellationToken).ConfigureAwait(false);
        if (audience is not "supplier")
        {
            return Json(new { ok = false, error = "Only suppliers can create Booking ads." });
        }

        using var args = JsonDocument.Parse(string.IsNullOrWhiteSpace(argumentsJson) ? "{}" : argumentsJson);
        var root = args.RootElement;

        var name = RequireName(root);
        if (name.Error is not null) return name.Error;

        var price = GetDecimal(root, "price");
        if (price is null or <= 0)
        {
            return Json(new { ok = false, error = "price must be greater than zero." });
        }

        var quantityUnit = ResolveQuantityAndUnit(root);
        if (quantityUnit.Error is not null)
        {
            return quantityUnit.Error;
        }

        if (quantityUnit.Quantity is null or <= 0)
        {
            return Json(new { ok = false, error = "quantity must be greater than zero." });
        }

        if (string.IsNullOrWhiteSpace(quantityUnit.UnitName))
        {
            return Json(new { ok = false, error = "unit_name or unit_id is required." });
        }

        var originCountry = GetString(root, "origin_country_name") ?? GetString(root, "origin_country");
        var loadingPort = GetString(root, "loading_port_name") ?? GetString(root, "loading_port");
        var destinationCountry = GetString(root, "destination_country_name")
                                 ?? GetString(root, "destination_country");
        var arrivalPort = GetString(root, "arrival_port_name")
                          ?? GetString(root, "destination_port_name")
                          ?? GetString(root, "destination_port");

        var bookingPriceType = NormalizeBookingPriceType(
            GetString(root, "booking_price_type_name") ?? GetString(root, "incoterm"));
        if (string.IsNullOrWhiteSpace(bookingPriceType))
        {
            return Json(new { ok = false, error = "booking_price_type_name is required: FOB, CNF, or CIF." });
        }

        var isFob = string.Equals(bookingPriceType, "FOB", StringComparison.OrdinalIgnoreCase);
        var missingGeo = new List<string>();
        if (string.IsNullOrWhiteSpace(originCountry))
        {
            missingGeo.Add("origin_country_name (الدولة المصدرة)");
        }

        if (!isFob)
        {
            if (string.IsNullOrWhiteSpace(loadingPort))
            {
                missingGeo.Add("loading_port_name (ميناء التحميل)");
            }

            if (string.IsNullOrWhiteSpace(destinationCountry))
            {
                missingGeo.Add("destination_country_name (بلد الوجهة)");
            }

            if (string.IsNullOrWhiteSpace(arrivalPort))
            {
                missingGeo.Add("arrival_port_name (ميناء الوصول)");
            }
        }

        if (missingGeo.Count > 0)
        {
            return Json(new
            {
                ok = false,
                error = isFob
                    ? "origin_country_name (الدولة المصدرة) is required for FOB. Do not ask for or send destination_country_name, loading_port_name, or arrival_port_name."
                    : $"For {bookingPriceType}, still missing: {string.Join(", ", missingGeo)}. CNF/CIF requires origin country, loading port, destination country, and arrival port."
            });
        }

        var shippingDays = GetString(root, "shipping_duration_days")
                           ?? GetString(root, "shipping_duration");
        if (string.IsNullOrWhiteSpace(shippingDays))
        {
            return Json(new { ok = false, error = "shipping_duration_days is required." });
        }

        var specifications = (GetString(root, "specifications") ?? GetString(root, "description") ?? "").Trim();
        if (string.IsNullOrWhiteSpace(specifications))
        {
            return Json(new { ok = false, error = "specifications are required." });
        }

        var media = ParseCreateAdMedia(root);
        if (media.Error is not null) return media.Error!;

        var input = new CreateProductInput
        {
            OwnerId = userId.Value.ToString("D"),
            NameEn = name.Value!,
            CreatedLanguage = NormalizeCreatedLanguage(GetString(root, "created_language")),
            ProductTypeName = "Booking",
            USDPrice = price.Value,
            Currency = "USD",
            Quantity = quantityUnit.Quantity.Value,
            UnitName = quantityUnit.UnitName,
            DescriptionEn = specifications,
            OriginCountryName = originCountry.Trim(),
            LoadingPortName = isFob ? null : loadingPort!.Trim(),
            DestinationCountryName = isFob ? null : destinationCountry!.Trim(),
            ArrivalPortName = isFob ? null : arrivalPort!.Trim(),
            BookingPriceTypeName = bookingPriceType,
            ShippingDuration = shippingDays.Trim(),
            Negotiable = GetBool(root, "negotiable") ?? false,
            Packaging = ParsePackaging(root),
            DraftImagePaths = media.DraftImagePaths,
            DraftVideoPath = media.DraftVideoPath,
            DraftVideoDurationSeconds = media.DraftVideoDurationSeconds
        };

        return await ExecuteProductCreateAsync(
                userId.Value,
                input,
                "Booking",
                GetBool(root, "submit_for_review") ?? true,
                cancellationToken)
            .ConfigureAwait(false);
    }

    private async Task<string> CreateOfferAdAsync(
        Guid? userId,
        string argumentsJson,
        CancellationToken cancellationToken)
    {
        if (!userId.HasValue)
        {
            return Json(new { ok = false, error = "Sign in to create an Offer ad." });
        }

        var audience = await ResolveAudienceAsync(userId.Value, cancellationToken).ConfigureAwait(false);
        if (audience is not "supplier")
        {
            return Json(new { ok = false, error = "Only suppliers can create Offer ads." });
        }

        using var args = JsonDocument.Parse(string.IsNullOrWhiteSpace(argumentsJson) ? "{}" : argumentsJson);
        var root = args.RootElement;

        var name = RequireName(root);
        if (name.Error is not null) return name.Error;

        var beforePrice = GetDecimal(root, "price_before")
                          ?? GetDecimal(root, "before_discount_price");
        var afterPrice = GetDecimal(root, "price_after")
                         ?? GetDecimal(root, "after_discount_price")
                         ?? GetDecimal(root, "price");
        if (beforePrice is null or <= 0 || afterPrice is null or <= 0)
        {
            return Json(new { ok = false, error = "price_before and price_after must be greater than zero." });
        }

        if (afterPrice >= beforePrice)
        {
            return Json(new { ok = false, error = "price_after must be less than price_before." });
        }

        var offerDays = GetLong(root, "offer_duration_days") ?? GetLong(root, "discount_days");
        if (offerDays is null or <= 0)
        {
            return Json(new { ok = false, error = "offer_duration_days is required." });
        }

        var quantityUnit = ResolveQuantityAndUnit(root);
        if (quantityUnit.Error is not null)
        {
            return quantityUnit.Error;
        }

        if (quantityUnit.Quantity is null or <= 0)
        {
            return Json(new { ok = false, error = "quantity must be greater than zero." });
        }

        if (string.IsNullOrWhiteSpace(quantityUnit.UnitName))
        {
            return Json(new { ok = false, error = "unit_name or unit_id is required." });
        }

        var requestTypeName = NormalizeRequestTypeForCreate(
            GetString(root, "request_type_name"),
            GetLong(root, "request_type_id"));
        if (string.IsNullOrWhiteSpace(requestTypeName))
        {
            return Json(new
            {
                ok = false,
                error = "request_type_name is required: Local or Reexport."
            });
        }

        var currency = NormalizeCurrency(GetString(root, "currency")) ?? "USD";
        var specifications = (GetString(root, "specifications") ?? GetString(root, "description") ?? "").Trim();
        if (string.IsNullOrWhiteSpace(specifications))
        {
            return Json(new { ok = false, error = "specifications are required." });
        }

        var media = ParseCreateAdMedia(root);
        if (media.Error is not null) return media.Error!;

        var discountPercent = (byte)Math.Clamp(
            (int)Math.Round(((beforePrice.Value - afterPrice.Value) / beforePrice.Value) * 100m),
            1,
            99);

        var input = new CreateProductInput
        {
            OwnerId = userId.Value.ToString("D"),
            NameEn = name.Value!,
            CreatedLanguage = NormalizeCreatedLanguage(GetString(root, "created_language")),
            ProductTypeName = "Offers",
            USDPrice = afterPrice.Value,
            Currency = currency,
            Quantity = quantityUnit.Quantity.Value,
            UnitName = quantityUnit.UnitName,
            DescriptionEn = specifications,
            Negotiable = GetBool(root, "negotiable") ?? false,
            RequestTypeName = requestTypeName,
            DiscountPercentage = discountPercent,
            DiscountDays = (short)offerDays.Value,
            OfferDuration = offerDays.Value.ToString(),
            Packaging = ParsePackaging(root),
            DraftImagePaths = media.DraftImagePaths,
            DraftVideoPath = media.DraftVideoPath,
            DraftVideoDurationSeconds = media.DraftVideoDurationSeconds
        };

        return await ExecuteProductCreateAsync(
                userId.Value,
                input,
                "Offers",
                GetBool(root, "submit_for_review") ?? true,
                cancellationToken)
            .ConfigureAwait(false);
    }

    private async Task<string> CreateRetailAdAsync(
        Guid? userId,
        string argumentsJson,
        CancellationToken cancellationToken)
    {
        if (!userId.HasValue)
        {
            return Json(new { ok = false, error = "Sign in to create a Retail ad." });
        }

        var audience = await ResolveAudienceAsync(userId.Value, cancellationToken).ConfigureAwait(false);
        if (audience is not "supplier")
        {
            return Json(new { ok = false, error = "Only suppliers can create Retail ads." });
        }

        using var args = JsonDocument.Parse(string.IsNullOrWhiteSpace(argumentsJson) ? "{}" : argumentsJson);
        var root = args.RootElement;

        var name = RequireName(root);
        if (name.Error is not null) return name.Error;

        var price = GetDecimal(root, "price");
        if (price is null or <= 0)
        {
            return Json(new { ok = false, error = "price must be greater than zero." });
        }

        var quantityUnit = ResolveQuantityAndUnit(root);
        if (quantityUnit.Error is not null)
        {
            return quantityUnit.Error;
        }

        if (quantityUnit.Quantity is null or <= 0)
        {
            return Json(new { ok = false, error = "quantity must be greater than zero." });
        }

        if (string.IsNullOrWhiteSpace(quantityUnit.UnitName))
        {
            return Json(new { ok = false, error = "unit_name or unit_id is required." });
        }

        var deliveryDays = GetString(root, "delivery_days")
                           ?? GetString(root, "shipping_duration_days")
                           ?? GetString(root, "shipping_duration");
        if (string.IsNullOrWhiteSpace(deliveryDays))
        {
            return Json(new { ok = false, error = "delivery_days is required." });
        }

        var specifications = (GetString(root, "specifications") ?? GetString(root, "description") ?? "").Trim();
        if (string.IsNullOrWhiteSpace(specifications))
        {
            return Json(new { ok = false, error = "specifications are required." });
        }

        var media = ParseCreateAdMedia(root);
        if (media.Error is not null) return media.Error!;

        var input = new CreateProductInput
        {
            OwnerId = userId.Value.ToString("D"),
            NameEn = name.Value!,
            CreatedLanguage = NormalizeCreatedLanguage(GetString(root, "created_language")),
            ProductTypeName = "Retail",
            USDPrice = price.Value,
            Currency = "AED",
            Quantity = quantityUnit.Quantity.Value,
            UnitName = quantityUnit.UnitName,
            DescriptionEn = specifications,
            Negotiable = GetBool(root, "negotiable") ?? false,
            ShippingDuration = deliveryDays.Trim(),
            Packaging = ParsePackaging(root),
            DraftImagePaths = media.DraftImagePaths,
            DraftVideoPath = media.DraftVideoPath,
            DraftVideoDurationSeconds = media.DraftVideoDurationSeconds
        };

        return await ExecuteProductCreateAsync(
                userId.Value,
                input,
                "Retail",
                GetBool(root, "submit_for_review") ?? true,
                cancellationToken)
            .ConfigureAwait(false);
    }

    private async Task<string> CreateCategoryAdAsync(
        Guid? userId,
        string argumentsJson,
        CancellationToken cancellationToken)
    {
        if (!userId.HasValue)
        {
            return Json(new { ok = false, error = "Sign in to create a Category ad." });
        }

        var audience = await ResolveAudienceAsync(userId.Value, cancellationToken).ConfigureAwait(false);
        if (audience is not "supplier")
        {
            return Json(new { ok = false, error = "Only suppliers can create Category ads." });
        }

        using var args = JsonDocument.Parse(string.IsNullOrWhiteSpace(argumentsJson) ? "{}" : argumentsJson);
        var root = args.RootElement;

        var name = RequireName(root);
        if (name.Error is not null) return name.Error;

        var price = GetDecimal(root, "price");
        if (price is null or <= 0)
        {
            return Json(new { ok = false, error = "price must be greater than zero." });
        }

        var quantityUnit = ResolveQuantityAndUnit(root);
        if (quantityUnit.Error is not null)
        {
            return quantityUnit.Error;
        }

        if (quantityUnit.Quantity is null or <= 0)
        {
            return Json(new { ok = false, error = "quantity must be greater than zero." });
        }

        if (string.IsNullOrWhiteSpace(quantityUnit.UnitName))
        {
            return Json(new { ok = false, error = "unit_name or unit_id is required." });
        }

        var categoryId = ResolveCategoryId(root);
        if (categoryId is null)
        {
            return Json(new { ok = false, error = "category_id or category_name is required." });
        }

        var requestTypeName = NormalizeRequestTypeForCreate(
            GetString(root, "request_type_name"),
            GetLong(root, "request_type_id"));
        if (string.IsNullOrWhiteSpace(requestTypeName))
        {
            return Json(new
            {
                ok = false,
                error = "request_type_name is required: Local or Reexport."
            });
        }

        var specifications = (GetString(root, "specifications") ?? GetString(root, "description") ?? "").Trim();
        if (string.IsNullOrWhiteSpace(specifications))
        {
            return Json(new { ok = false, error = "specifications are required." });
        }

        var media = ParseCreateAdMedia(root);
        if (media.Error is not null) return media.Error!;

        var enableRetail = GetBool(root, "enable_retail_pricing") ?? false;
        decimal? retailPrice = null;
        string? retailUnitName = null;
        long? retailQuantity = null;
        string? retailSpecs = null;
        if (enableRetail)
        {
            retailPrice = GetDecimal(root, "retail_price");
            retailQuantity = GetLong(root, "retail_quantity");
            retailUnitName = ResolveUnitName(root, "retail_unit_name", "retail_unit_id");
            retailSpecs = (GetString(root, "retail_specifications")
                          ?? GetString(root, "retail_description_en")
                          ?? "").Trim();

            var missingRetail = new List<string>();
            if (retailPrice is null or <= 0) missingRetail.Add("retail_price (AED)");
            if (retailQuantity is null or <= 0) missingRetail.Add("retail_quantity");
            if (string.IsNullOrWhiteSpace(retailUnitName)) missingRetail.Add("retail_unit_name");
            if (string.IsNullOrWhiteSpace(retailSpecs)) missingRetail.Add("retail_specifications");

            if (missingRetail.Count > 0)
            {
                return Json(new
                {
                    ok = false,
                    error =
                        "Hybrid Category+Retail ad is incomplete. Ask the user for these retail fields BEFORE calling again: "
                        + string.Join(", ", missingRetail)
                        + ". Do not reuse wholesale specifications as retail_specifications unless the user explicitly said they are the same.",
                    missing_retail_fields = missingRetail,
                    hint_ar =
                        "الإعلان هجين (جملة + تجزئة). اسأل عن مواصفات التجزئة وسعر/كمية/وحدة التجزئة قبل إعادة المحاولة. لا تنسخ مواصفات الجملة تلقائياً."
                });
            }
        }

        var currency = NormalizeCurrency(GetString(root, "currency")) ?? "USD";

        var retailDescriptionEn = enableRetail ? retailSpecs : null;

        var input = new CreateProductInput
        {
            OwnerId = userId.Value.ToString("D"),
            NameEn = name.Value!,
            CreatedLanguage = NormalizeCreatedLanguage(GetString(root, "created_language")),
            CategoryId = categoryId,
            USDPrice = price.Value,
            Currency = currency,
            Quantity = quantityUnit.Quantity.Value,
            UnitName = quantityUnit.UnitName,
            DescriptionEn = specifications,
            Negotiable = GetBool(root, "negotiable") ?? false,
            RequestTypeName = requestTypeName,
            Packaging = ParsePackaging(root),
            EnableRetailPricing = enableRetail ? true : false,
            RetailPrice = retailPrice,
            RetailQuantity = retailQuantity,
            RetailUnitName = retailUnitName,
            RetailDescriptionEn = retailDescriptionEn,
            RetailPackaging = enableRetail ? ParsePackaging(root, "retail_packaging") : null,
            DraftImagePaths = media.DraftImagePaths,
            DraftVideoPath = media.DraftVideoPath,
            DraftVideoDurationSeconds = media.DraftVideoDurationSeconds
        };

        return await ExecuteProductCreateAsync(
                userId.Value,
                input,
                "Category",
                GetBool(root, "submit_for_review") ?? true,
                cancellationToken)
            .ConfigureAwait(false);
    }

    private async Task<string> SearchShippingPricesAsync(
        string argumentsJson,
        CancellationToken cancellationToken)
    {
        using var args = JsonDocument.Parse(string.IsNullOrWhiteSpace(argumentsJson) ? "{}" : argumentsJson);
        var root = args.RootElement;

        var fromCountry = GetString(root, "from_country_name")
                          ?? GetString(root, "origin_country_name")
                          ?? GetString(root, "from_country");
        var toCountry = GetString(root, "to_country_name")
                        ?? GetString(root, "destination_country_name")
                        ?? GetString(root, "to_country");
        if (string.IsNullOrWhiteSpace(fromCountry) || string.IsNullOrWhiteSpace(toCountry))
        {
            return Json(new
            {
                ok = false,
                error = "from_country_name and to_country_name are required."
            });
        }

        var fromPort = GetString(root, "from_port_name") ?? GetString(root, "loading_port_name");
        var toPort = GetString(root, "to_port_name")
                     ?? GetString(root, "arrival_port_name")
                     ?? GetString(root, "destination_port_name");

        try
        {
            await using var scope = scopeFactory.CreateAsyncScope();
            var shipping = scope.ServiceProvider.GetRequiredService<IInternationalShippingAppService>();
            var raw = await shipping.SearchAsync(
                    new SearchInternationalShippingInput
                    {
                        FromCountryName = fromCountry.Trim(),
                        FromPortName = string.IsNullOrWhiteSpace(fromPort) ? null : fromPort.Trim(),
                        ToCountryName = toCountry.Trim(),
                        ToPortName = string.IsNullOrWhiteSpace(toPort) ? null : toPort.Trim()
                    },
                    cancellationToken)
                .ConfigureAwait(false);

            var compact = CompactShippingSearchResults(raw);
            return Json(new
            {
                ok = true,
                fromCountry = fromCountry.Trim(),
                toCountry = toCountry.Trim(),
                fromPort = string.IsNullOrWhiteSpace(fromPort) ? null : fromPort.Trim(),
                toPort = string.IsNullOrWhiteSpace(toPort) ? null : toPort.Trim(),
                count = compact.Count,
                offers = compact,
                message = compact.Count == 0
                    ? "No approved shipping offers found for this route."
                    : $"Found {compact.Count} shipping offer(s). Prices are buyer-facing USD."
            });
        }
        catch (Exception ex) when (ex is not OperationCanceledException)
        {
            return Json(new { ok = false, error = ex.Message });
        }
    }

    private static List<object> CompactShippingSearchResults(object raw)
    {
        var list = new List<object>();
        try
        {
            var json = JsonSerializer.Serialize(raw);
            using var doc = JsonDocument.Parse(json);
            if (doc.RootElement.ValueKind != JsonValueKind.Array)
            {
                return list;
            }

            foreach (var item in doc.RootElement.EnumerateArray().Take(12))
            {
                list.Add(new
                {
                    companyName = item.TryGetProperty("publisherName", out var nameEl)
                        ? nameEl.GetString()
                        : null,
                    fromCountry = item.TryGetProperty("fromCountry", out var fc) ? fc.GetString() : null,
                    fromPort = item.TryGetProperty("fromPort", out var fp) ? fp.GetString() : null,
                    toCountry = item.TryGetProperty("toCountry", out var tc) ? tc.GetString() : null,
                    toPort = item.TryGetProperty("toPort", out var tp) ? tp.GetString() : null,
                    container20ftPriceUsd = item.TryGetProperty("container20ftPriceUsd", out var p20)
                        ? p20.GetDecimal()
                        : (decimal?)null,
                    container40ftPriceUsd = item.TryGetProperty("container40ftPriceUsd", out var p40)
                        ? p40.GetDecimal()
                        : (decimal?)null,
                    minDurationDays = item.TryGetProperty("minDurationDays", out var minD)
                        ? minD.ValueKind == JsonValueKind.Null ? null : minD.GetInt32()
                        : (int?)null,
                    maxDurationDays = item.TryGetProperty("maxDurationDays", out var maxD)
                        ? maxD.ValueKind == JsonValueKind.Null ? null : maxD.GetInt32()
                        : (int?)null
                });
            }
        }
        catch (JsonException)
        {
            // Fall through with empty list.
        }

        return list;
    }

    private async Task<string> CreateShippingAdAsync(
        Guid? userId,
        string argumentsJson,
        CancellationToken cancellationToken)
    {
        if (!userId.HasValue)
        {
            return Json(new { ok = false, error = "Sign in to create a shipping ad." });
        }

        var audience = await ResolveAudienceAsync(userId.Value, cancellationToken).ConfigureAwait(false);
        if (audience is not "shipping")
        {
            return Json(new { ok = false, error = "Only shipping company accounts can create shipping ads." });
        }

        using var args = JsonDocument.Parse(string.IsNullOrWhiteSpace(argumentsJson) ? "{}" : argumentsJson);
        var root = args.RootElement;

        var fromCountry = GetString(root, "from_country_name") ?? GetString(root, "origin_country_name");
        var fromPort = GetString(root, "from_port_name") ?? GetString(root, "loading_port_name");
        var toCountry = GetString(root, "to_country_name") ?? GetString(root, "destination_country_name");
        var toPort = GetString(root, "to_port_name") ?? GetString(root, "destination_port_name");
        if (string.IsNullOrWhiteSpace(fromCountry)
            || string.IsNullOrWhiteSpace(fromPort)
            || string.IsNullOrWhiteSpace(toCountry)
            || string.IsNullOrWhiteSpace(toPort))
        {
            return Json(new
            {
                ok = false,
                error = "from_country_name, from_port_name, to_country_name, and to_port_name are required."
            });
        }

        var price20 = GetDecimal(root, "container_20ft_price_usd")
                      ?? GetDecimal(root, "price_20ft");
        var price40 = GetDecimal(root, "container_40ft_price_usd")
                      ?? GetDecimal(root, "price_40ft");
        if (price20 is null or <= 0 || price40 is null or <= 0)
        {
            return Json(new { ok = false, error = "container_20ft_price_usd and container_40ft_price_usd are required." });
        }

        var minDays = GetLong(root, "min_duration_days") ?? GetLong(root, "shipping_duration_min_days");
        var maxDays = GetLong(root, "max_duration_days") ?? GetLong(root, "shipping_duration_max_days");
        if (minDays is null or <= 0 || maxDays is null or <= 0 || minDays > maxDays)
        {
            return Json(new
            {
                ok = false,
                error = "min_duration_days and max_duration_days are required (min <= max)."
            });
        }

        var details = (GetString(root, "specifications") ?? GetString(root, "details") ?? "").Trim();
        if (string.IsNullOrWhiteSpace(details))
        {
            return Json(new { ok = false, error = "specifications/details are required." });
        }

        var phone = GetString(root, "phone_number");
        if (string.IsNullOrWhiteSpace(phone))
        {
            phone = await dbContext.Users.AsNoTracking()
                .Where(u => u.Id == userId.Value)
                .Select(u => u.PhoneNumber)
                .FirstOrDefaultAsync(cancellationToken)
                .ConfigureAwait(false);
        }

        if (string.IsNullOrWhiteSpace(phone))
        {
            return Json(new { ok = false, error = "phone_number is required on the shipping company profile." });
        }

        var input = new CreateInternationalShippingPostInput
        {
            PublisherUserId = userId.Value.ToString("D"),
            FromCountryName = fromCountry.Trim(),
            FromPortName = fromPort.Trim(),
            ToCountryName = toCountry.Trim(),
            ToPortName = toPort.Trim(),
            PhoneNumber = phone.Trim(),
            Container20ftPriceUsd = price20.Value,
            Container40ftPriceUsd = price40.Value,
            MinDurationDays = (int)minDays.Value,
            MaxDurationDays = (int)maxDays.Value,
            Details = details
        };

        try
        {
            await using var scope = scopeFactory.CreateAsyncScope();
            var shipping = scope.ServiceProvider.GetRequiredService<IShippingCompanyAppService>();
            var result = await shipping.CreatePostAsync(
                    userId.Value.ToString("D"),
                    input,
                    cancellationToken)
                .ConfigureAwait(false);

            return Json(new
            {
                ok = true,
                adType = "Shipping",
                post = result,
                message = "Shipping ad created and submitted for admin review."
            });
        }
        catch (Exception ex) when (ex is not OperationCanceledException)
        {
            return Json(new { ok = false, error = ex.Message });
        }
    }

    private async Task<string> ExecuteProductCreateAsync(
        Guid userId,
        CreateProductInput input,
        string adType,
        bool submitForReview,
        CancellationToken cancellationToken)
    {
        try
        {
            await using var scope = scopeFactory.CreateAsyncScope();
            var products = scope.ServiceProvider.GetRequiredService<IProductsAppService>();
            var createResult = await products.CreateAsync(input, cancellationToken).ConfigureAwait(false);

            var productId = ExtractProductId(createResult);
            if (productId is null)
            {
                return Json(new
                {
                    ok = false,
                    error = "Ad was created but product id could not be read from the API response."
                });
            }

            object? submitResult = null;
            var submitted = false;
            if (submitForReview)
            {
                submitResult = await products.SubmitForAdminReviewAsync(
                        productId,
                        userId.ToString("D"),
                        cancellationToken)
                    .ConfigureAwait(false);
                submitted = true;
            }

            return Json(new
            {
                ok = true,
                adType,
                productId,
                productCode = ExtractStringProperty(createResult, "productCode"),
                name = input.NameEn,
                price = input.USDPrice,
                currency = input.Currency,
                quantity = input.Quantity,
                unitName = input.UnitName,
                submittedForReview = submitted,
                submitResult,
                draftImagePaths = input.DraftImagePaths,
                draftVideoPath = input.DraftVideoPath,
                message =
                    $"{adType} ad created using the same API as mobile Create Ad. " +
                    "Tell the user it is pending admin review when submittedForReview is true."
            });
        }
        catch (Exception ex) when (ex is not OperationCanceledException)
        {
            return Json(new { ok = false, error = ex.Message });
        }
    }

    private static (string? Value, string? Error) RequireName(JsonElement root)
    {
        var name = (GetString(root, "name") ?? GetString(root, "name_en") ?? GetString(root, "product_name") ?? "")
            .Trim();
        if (string.IsNullOrWhiteSpace(name))
        {
            return (null, Json(new { ok = false, error = "name (product name) is required — ask the user first." }));
        }

        return (name, null);
    }

    private static byte? ParsePackaging(JsonElement root, string propertyName = "packaging")
    {
        if (!root.TryGetProperty(propertyName, out var packagingEl)) return null;
        if (packagingEl.ValueKind == JsonValueKind.Number && packagingEl.TryGetByte(out var pkg)) return pkg;
        if (packagingEl.ValueKind == JsonValueKind.String
            && byte.TryParse(packagingEl.GetString(), out var parsedPkg))
        {
            return parsedPkg;
        }

        return null;
    }

    private static string? ResolveCategoryId(JsonElement root)
    {
        var idText = GetString(root, "category_id");
        if (!string.IsNullOrWhiteSpace(idText) && byte.TryParse(idText.Trim(), out var parsedId))
        {
            return KnownCategories.Any(c => c.Id == parsedId) ? parsedId.ToString() : null;
        }

        var catId = GetLong(root, "category_id");
        if (catId is >= 1 and <= 255)
        {
            var match = KnownCategories.FirstOrDefault(c => c.Id == catId);
            if (match.NameEn is not null) return match.Id.ToString();
        }

        var name = GetString(root, "category_name") ?? GetString(root, "category");
        if (string.IsNullOrWhiteSpace(name)) return null;

        var normalized = name.Trim();
        var byName = KnownCategories.FirstOrDefault(c =>
            c.NameEn.Equals(normalized, StringComparison.OrdinalIgnoreCase)
            || c.NameAr.Equals(normalized, StringComparison.OrdinalIgnoreCase));
        return byName.NameEn is null ? null : byName.Id.ToString();
    }

    private static string? ResolveUnitName(
        JsonElement root,
        string unitNameProperty = "unit_name",
        string unitIdProperty = "unit_id")
    {
        var unitName = GetString(root, unitNameProperty) ?? GetString(root, "unit");
        if (!string.IsNullOrWhiteSpace(unitName))
        {
            if (TryParseQuantityUnit(unitName, out _, out var parsedUnit))
            {
                return parsedUnit;
            }

            if (long.TryParse(unitName.Trim(), out _))
            {
                unitName = null;
            }
            else
            {
                var normalized = NormalizeUnitAlias(unitName.Trim());
                if (!string.IsNullOrWhiteSpace(normalized))
                {
                    return normalized;
                }

                var match = KnownUnits.FirstOrDefault(x =>
                    x.NameEn.Equals(unitName.Trim(), StringComparison.OrdinalIgnoreCase)
                    || x.NameAr.Equals(unitName.Trim(), StringComparison.OrdinalIgnoreCase));
                return match.NameEn ?? unitName.Trim();
            }
        }

        var unitId = GetLong(root, unitIdProperty);
        if (unitId is >= 1 and <= 255)
        {
            var match = KnownUnits.FirstOrDefault(x => x.Id == unitId);
            if (match.NameEn is not null) return match.NameEn;
        }

        return null;
    }

    private static string? NormalizeBookingPriceType(string? name)
    {
        if (string.IsNullOrWhiteSpace(name)) return null;
        var normalized = name.Trim().ToUpperInvariant();
        return normalized switch
        {
            "C&F" or "C AND F" or "CANDF" => "CNF",
            "FOB" or "CNF" or "CIF" => normalized,
            _ => null
        };
    }

    private sealed record ParsedCreateAdMedia(
        List<string>? DraftImagePaths,
        string? DraftVideoPath,
        byte? DraftVideoDurationSeconds,
        string? Error);

    private static ParsedCreateAdMedia ParseCreateAdMedia(JsonElement root)
    {
        var draftImagePaths = GetStringList(root, "draft_image_paths");
        var draftVideoPath = GetString(root, "draft_video_path");
        var draftVideoDuration = GetByte(root, "draft_video_duration_seconds");

        if (!string.IsNullOrWhiteSpace(draftVideoPath) && draftVideoDuration is null)
        {
            return new ParsedCreateAdMedia(
                null,
                null,
                null,
                Json(new
                {
                    ok = false,
                    error = "draft_video_duration_seconds is required when draft_video_path is set."
                }));
        }

        return new ParsedCreateAdMedia(draftImagePaths, draftVideoPath, draftVideoDuration, null);
    }
}
