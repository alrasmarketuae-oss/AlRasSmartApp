using DataLayer.Models;

namespace BusinessLayer.Helpers;

public static class AdminShippingDisplayHelper
{
    public static string BuildRouteSummary(
        string? originCountry,
        string? loadingPort,
        string? destinationCountry,
        string? arrivalPort)
    {
        if (string.IsNullOrWhiteSpace(originCountry)
            || string.IsNullOrWhiteSpace(destinationCountry)
            || string.IsNullOrWhiteSpace(loadingPort)
            || string.IsNullOrWhiteSpace(arrivalPort))
        {
            return string.Empty;
        }

        return $"من {originCountry.Trim()} ({loadingPort.Trim()}) → إلى {destinationCountry.Trim()} ({arrivalPort.Trim()})";
    }

    public static string? FormatProductAddress(Address? address)
    {
        if (address is null)
        {
            return null;
        }

        return AddressTextFormatter.ToDisplayText(address, address.City?.CityName, address.City?.Country?.CountryNameEn)
            ?? FormatAddressParts(address.AddressLine1, address.AddressLine2, address.City?.CityName);
    }

    public static string? FormatAddressParts(string? line1, string? line2, string? cityName)
    {
        var parts = new List<string>(3);
        if (!string.IsNullOrWhiteSpace(line1))
        {
            parts.Add(line1.Trim());
        }

        if (!string.IsNullOrWhiteSpace(line2))
        {
            parts.Add(line2.Trim());
        }

        if (!string.IsNullOrWhiteSpace(cityName))
        {
            parts.Add(cityName.Trim());
        }

        return parts.Count == 0 ? null : string.Join(", ", parts);
    }
}
