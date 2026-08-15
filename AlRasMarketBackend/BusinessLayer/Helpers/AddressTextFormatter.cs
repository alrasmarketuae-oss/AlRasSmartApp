using DataLayer.Models;

namespace BusinessLayer.Helpers;

public static class AddressTextFormatter
{
    public static string ComposeLine1(AddAddressParts parts)
    {
        var joined = Join(
            parts.Street,
            parts.Building,
            FormatFloor(parts.FloorNo),
            FormatUnit(parts.UnitNo),
            parts.Area);
        if (!string.IsNullOrWhiteSpace(joined))
        {
            return Truncate(joined, 255);
        }

        return Truncate(parts.AddressLine1, 255);
    }

    public static string? ToDisplayText(Address? address, string? cityName = null, string? countryName = null)
    {
        if (address is null)
        {
            return null;
        }

        var typeId = address.AddressTypeId == 0 ? AddressTypeCodes.Home : address.AddressTypeId;
        var typeName = address.AddressType is not null
            ? $"{address.AddressType.NameEn} / {address.AddressType.NameAr}"
            : $"{AddressTypeCodes.NameEn(typeId)} / {AddressTypeCodes.NameAr(typeId)}";

        var city = FirstNonEmpty(cityName, address.City?.CityName);
        var country = FirstNonEmpty(countryName, address.City?.Country?.CountryNameEn);

        var parts = new List<string>();
        Add(parts, typeName);
        Add(parts, address.Street);
        Add(parts, address.Building);
        Add(parts, FormatFloor(address.FloorNo));
        Add(parts, FormatUnit(address.UnitNo));
        Add(parts, address.Area);
        Add(parts, city);
        Add(parts, country);
        if (string.IsNullOrWhiteSpace(address.Street) && string.IsNullOrWhiteSpace(address.Building))
        {
            Add(parts, address.AddressLine1);
            Add(parts, address.AddressLine2);
        }
        Add(parts, FormatLabeled("Landmark", address.Landmark));
        Add(parts, FormatLabeled("P.O. Box", address.PostalCode));
        Add(parts, FormatLabeled("Contact", address.ContactPerson));
        Add(parts, FormatLabeled("Mobile", address.MobileNumber));
        Add(parts, FormatLabeled("Instructions", address.DeliveryInstructions));

        return parts.Count == 0 ? null : string.Join(" · ", parts);
    }

    public static string? FormatCoordinates(decimal? latitude, decimal? longitude)
    {
        if (latitude is null || longitude is null)
        {
            return null;
        }

        return $"{latitude.Value.ToString("0.######")}, {longitude.Value.ToString("0.######")}";
    }

    public static string? MapsUrl(decimal? latitude, decimal? longitude)
    {
        if (latitude is null || longitude is null)
        {
            return null;
        }

        return $"https://www.google.com/maps?q={latitude.Value.ToString(System.Globalization.CultureInfo.InvariantCulture)},{longitude.Value.ToString(System.Globalization.CultureInfo.InvariantCulture)}";
    }

    private static string? FormatFloor(string? floorNo) =>
        string.IsNullOrWhiteSpace(floorNo) ? null : $"Floor {floorNo.Trim()}";

    private static string? FormatUnit(string? unitNo) =>
        string.IsNullOrWhiteSpace(unitNo) ? null : $"Unit {unitNo.Trim()}";

    private static string? FormatLabeled(string label, string? value) =>
        string.IsNullOrWhiteSpace(value) ? null : $"{label}: {value.Trim()}";

    private static void Add(List<string> parts, string? value)
    {
        if (!string.IsNullOrWhiteSpace(value))
        {
            parts.Add(value.Trim());
        }
    }

    private static string Join(params string?[] values) =>
        string.Join(", ", values.Where(v => !string.IsNullOrWhiteSpace(v)).Select(v => v!.Trim()));

    private static string FirstNonEmpty(params string?[] values) =>
        values.FirstOrDefault(v => !string.IsNullOrWhiteSpace(v))?.Trim() ?? string.Empty;

    private static string Truncate(string? value, int max)
    {
        var trimmed = value?.Trim() ?? string.Empty;
        return trimmed.Length <= max ? trimmed : trimmed[..max];
    }
}

public readonly record struct AddAddressParts(
    string? AddressLine1,
    string? Street,
    string? Building,
    string? FloorNo,
    string? UnitNo,
    string? Area);
