using System.Text.Json;
using System.Text.Json.Serialization;
using DataLayer.Models;

namespace BusinessLayer.Helpers;

/// <summary>
/// Snapshot of an approved (or pre-edit) product taken before the seller's proposed edit
/// overwrites the live row. Live product = proposed; this JSON = previous.
/// </summary>
public sealed class PendingProductEditSnapshot
{
    public string? NameEn { get; set; }
    public string? DescriptionEn { get; set; }
    public decimal USDPrice { get; set; }
    public string? Currency { get; set; }
    public long Quantity { get; set; }
    public byte? CategoryId { get; set; }
    public byte? ProductTypeId { get; set; }
    public byte? UnitId { get; set; }
    public int? MinimumOrderQuantity { get; set; }
    public int? MaximumOrderQuantity { get; set; }
    public byte? DiscountPercentage { get; set; }
    public short? DiscountDays { get; set; }
    public string? ShippingDescriptionEn { get; set; }
    public byte? Packaging { get; set; }
    public string? PackagingDetails { get; set; }
    public byte? RetailPackaging { get; set; }
    public string? RetailPackagingDetails { get; set; }
    public string? RetailDescriptionEn { get; set; }
    public short? OriginCountryId { get; set; }
    public short? DestinationCountryId { get; set; }
    public int? LoadingPortId { get; set; }
    public int? ArrivalPortId { get; set; }
    public string? VideoPath { get; set; }
    public byte? VideoDurationSeconds { get; set; }
    public bool IsVideoMuted { get; set; }
    public string? ShippingDuration { get; set; }
    public string? OfferDuration { get; set; }
    public Guid? AddressId { get; set; }
    public bool? Negotiable { get; set; }
    public decimal? RetailPrice { get; set; }
    public byte? RetailUnitId { get; set; }
    public long? RetailQuantity { get; set; }
    public byte? RequestTypeId { get; set; }
    public byte? BookingPriceTypeId { get; set; }
    public byte? Status { get; set; }
    public bool? IsApproved { get; set; }

    public List<string> ImagePaths { get; set; } = [];
    public List<string> DocumentPaths { get; set; } = [];
    public List<string> ExtraVideoPaths { get; set; } = [];
}

public static class PendingProductChangeHelper
{
    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
        PropertyNameCaseInsensitive = true,
        DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull,
        WriteIndented = false
    };

    public static string Serialize(PendingProductEditSnapshot snapshot) =>
        JsonSerializer.Serialize(snapshot, JsonOptions);

    public static PendingProductEditSnapshot? TryParse(string? raw)
    {
        if (string.IsNullOrWhiteSpace(raw))
        {
            return null;
        }

        try
        {
            return JsonSerializer.Deserialize<PendingProductEditSnapshot>(raw, JsonOptions);
        }
        catch
        {
            return null;
        }
    }

    /// <summary>
    /// True when PendingProductChanges was taken from a previously approved live ad
    /// (real seller edit), not from first-create media uploads.
    /// </summary>
    public static bool IndicatesPreviouslyApprovedEdit(string? raw)
    {
        var snapshot = TryParse(raw);
        return snapshot?.IsApproved == true;
    }

    public static PendingProductEditSnapshot Capture(
        Product product,
        IEnumerable<string> imagePaths,
        IEnumerable<string> documentPaths,
        IEnumerable<string> extraVideoPaths)
    {
        return new PendingProductEditSnapshot
        {
            NameEn = product.NameEn,
            DescriptionEn = product.DescriptionEn,
            USDPrice = product.USDPrice,
            Currency = product.Currency,
            Quantity = product.Quantity,
            CategoryId = product.CategoryId,
            ProductTypeId = product.ProductTypeId,
            UnitId = product.UnitId,
            MinimumOrderQuantity = product.MinimumOrderQuantity,
            MaximumOrderQuantity = product.MaximumOrderQuantity,
            DiscountPercentage = product.DiscountPercentage,
            DiscountDays = product.DiscountDays,
            ShippingDescriptionEn = product.ShippingDescriptionEn,
            Packaging = product.Packaging,
            PackagingDetails = product.PackagingDetails,
            OriginCountryId = product.OriginCountryId,
            DestinationCountryId = product.DestinationCountryId,
            LoadingPortId = product.LoadingPortId,
            ArrivalPortId = product.ArrivalPortId,
            VideoPath = product.VideoPath,
            VideoDurationSeconds = product.VideoDurationSeconds,
            IsVideoMuted = product.IsVideoMuted,
            ShippingDuration = product.ShippingDuration,
            OfferDuration = product.OfferDuration,
            AddressId = product.AddressId,
            Negotiable = product.Negotiable,
            RetailPrice = product.RetailPrice,
            RetailUnitId = product.RetailUnitId,
            RetailQuantity = product.RetailQuantity,
            RetailPackaging = product.RetailPackaging,
            RetailPackagingDetails = product.RetailPackagingDetails,
            RetailDescriptionEn = product.RetailDescriptionEn,
            RequestTypeId = product.RequestTypeId,
            BookingPriceTypeId = product.BookingPriceTypeId,
            Status = product.Status,
            IsApproved = product.IsApproved,
            ImagePaths = imagePaths
                .Where(p => !string.IsNullOrWhiteSpace(p))
                .Select(NormalizePath)
                .Distinct(StringComparer.OrdinalIgnoreCase)
                .ToList(),
            DocumentPaths = documentPaths
                .Where(p => !string.IsNullOrWhiteSpace(p))
                .Select(NormalizePath)
                .Distinct(StringComparer.OrdinalIgnoreCase)
                .ToList(),
            ExtraVideoPaths = extraVideoPaths
                .Where(p => !string.IsNullOrWhiteSpace(p))
                .Select(NormalizePath)
                .Distinct(StringComparer.OrdinalIgnoreCase)
                .ToList()
        };
    }

    public static void ApplySnapshotToProduct(Product product, PendingProductEditSnapshot snapshot)
    {
        product.NameEn = snapshot.NameEn;
        product.DescriptionEn = snapshot.DescriptionEn;
        product.USDPrice = snapshot.USDPrice;
        product.Currency = string.IsNullOrWhiteSpace(snapshot.Currency) ? product.Currency : snapshot.Currency;
        product.Quantity = snapshot.Quantity;
        product.CategoryId = snapshot.CategoryId;
        product.ProductTypeId = snapshot.ProductTypeId;
        product.UnitId = snapshot.UnitId;
        product.MinimumOrderQuantity = snapshot.MinimumOrderQuantity;
        product.MaximumOrderQuantity = snapshot.MaximumOrderQuantity;
        product.DiscountPercentage = snapshot.DiscountPercentage;
        product.DiscountDays = snapshot.DiscountDays;
        product.ShippingDescriptionEn = snapshot.ShippingDescriptionEn;
        product.Packaging = snapshot.Packaging;
        product.PackagingDetails = snapshot.PackagingDetails;
        product.OriginCountryId = snapshot.OriginCountryId;
        product.DestinationCountryId = snapshot.DestinationCountryId;
        product.LoadingPortId = snapshot.LoadingPortId;
        product.ArrivalPortId = snapshot.ArrivalPortId;
        product.VideoPath = snapshot.VideoPath;
        product.VideoDurationSeconds = snapshot.VideoDurationSeconds;
        product.IsVideoMuted = snapshot.IsVideoMuted;
        product.ShippingDuration = snapshot.ShippingDuration;
        product.OfferDuration = snapshot.OfferDuration;
        product.AddressId = snapshot.AddressId;
        product.Negotiable = snapshot.Negotiable;
        product.RetailPrice = snapshot.RetailPrice;
        product.RetailUnitId = snapshot.RetailUnitId;
        product.RetailQuantity = snapshot.RetailQuantity;
        product.RetailPackaging = snapshot.RetailPackaging;
        product.RetailPackagingDetails = snapshot.RetailPackagingDetails;
        product.RetailDescriptionEn = snapshot.RetailDescriptionEn;
        product.RequestTypeId = snapshot.RequestTypeId;
        product.BookingPriceTypeId = snapshot.BookingPriceTypeId;
        product.Status = snapshot.Status ?? product.Status;
        product.IsApproved = snapshot.IsApproved;
    }

    public static bool PathExistsInSnapshot(PendingProductEditSnapshot? snapshot, string? path)
    {
        if (snapshot is null || string.IsNullOrWhiteSpace(path))
        {
            return false;
        }

        var normalized = NormalizePath(path);
        return snapshot.ImagePaths.Any(p => string.Equals(p, normalized, StringComparison.OrdinalIgnoreCase))
            || snapshot.DocumentPaths.Any(p => string.Equals(p, normalized, StringComparison.OrdinalIgnoreCase))
            || snapshot.ExtraVideoPaths.Any(p => string.Equals(p, normalized, StringComparison.OrdinalIgnoreCase))
            || string.Equals(
                NormalizePath(snapshot.VideoPath),
                normalized,
                StringComparison.OrdinalIgnoreCase);
    }

    public static string NormalizePath(string? path)
    {
        if (string.IsNullOrWhiteSpace(path))
        {
            return string.Empty;
        }

        var value = path.Trim().Replace('\\', '/');
        if (value.StartsWith("http://", StringComparison.OrdinalIgnoreCase)
            || value.StartsWith("https://", StringComparison.OrdinalIgnoreCase))
        {
            try
            {
                value = new Uri(value).AbsolutePath;
            }
            catch
            {
                // keep as-is
            }
        }

        if (!value.StartsWith('/'))
        {
            value = "/" + value.TrimStart('/');
        }

        return value;
    }

    public static HashSet<string> ToPathSet(IEnumerable<string?> paths) =>
        paths
            .Where(p => !string.IsNullOrWhiteSpace(p))
            .Select(p => NormalizePath(p!))
            .Where(p => p.Length > 0)
            .ToHashSet(StringComparer.OrdinalIgnoreCase);
}
