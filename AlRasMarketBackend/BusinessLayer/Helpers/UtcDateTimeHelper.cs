using System.Globalization;

namespace BusinessLayer.Helpers;

public static class UtcDateTimeHelper
{
    public static DateTime UtcNow => DateTime.UtcNow;

    public static DateTime AsUtc(DateTime value) =>
        value.Kind switch
        {
            DateTimeKind.Utc => value,
            DateTimeKind.Local => value.ToUniversalTime(),
            // SQL / Unspecified values are stored as UTC wall-clock — do not shift.
            _ => DateTime.SpecifyKind(value, DateTimeKind.Utc)
        };

    public static DateTime? AsUtc(DateTime? value) =>
        value.HasValue ? AsUtc(value.Value) : null;

    /// <summary>
    /// ISO-8601 UTC for clients. Always ends with Z so parsers treat it as UTC
    /// regardless of server OS timezone (e.g. China).
    /// </summary>
    public static string FormatApiDateTime(DateTime value) =>
        AsUtc(value).ToString("yyyy-MM-dd'T'HH:mm:ss'Z'", CultureInfo.InvariantCulture);

    public static string FormatApiDateTime(DateTime? value) =>
        value.HasValue ? FormatApiDateTime(value.Value) : string.Empty;

    public static DateTime? ComputeAdExpiresAtUtc(DateTime publishedAtUtc, int adDisplayDurationDays)
    {
        if (adDisplayDurationDays <= 0)
        {
            return null;
        }

        return AsUtc(publishedAtUtc).AddDays(adDisplayDurationDays);
    }

    public static bool IsExpired(DateTime? expiresAtUtc, DateTime utcNow) =>
        expiresAtUtc.HasValue && utcNow >= AsUtc(expiresAtUtc.Value);
}
