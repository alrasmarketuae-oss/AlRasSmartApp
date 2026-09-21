using System.Text.Json;
using System.Text.Json.Serialization;

namespace BusinessLayer.Helpers;

/// <summary>
/// Proposed profile fields awaiting admin approval.
/// Only properties that were changed are present (null property = not changed).
/// Empty string means the user cleared that field.
/// </summary>
public sealed class PendingCompanyProfileChange
{
    public string? FullName { get; set; }
    public string? PhoneNumber { get; set; }
    public string? CompanyName { get; set; }
    public string? CommercialRegister { get; set; }
    public string? TaxNumber { get; set; }
    public string? Website { get; set; }
    public string? LandNumber { get; set; }

    /// <summary>
    /// Proposed trade-licence file path. Null = unchanged.
    /// Empty string = clear licence (not used by mobile currently).
    /// </summary>
    public string? LicencePath { get; set; }

    /// <summary>
    /// When true, <see cref="CompanyImagePaths"/> is the full proposed gallery.
    /// </summary>
    public bool? CompanyImagesChanged { get; set; }

    /// <summary>
    /// Full proposed company site-image paths (kept live paths + new pending uploads).
    /// Empty list means remove all company images after approval.
    /// </summary>
    public List<string>? CompanyImagePaths { get; set; }

    [JsonIgnore]
    public bool HasAnyChange =>
        FullName is not null
        || PhoneNumber is not null
        || CompanyName is not null
        || CommercialRegister is not null
        || TaxNumber is not null
        || Website is not null
        || LandNumber is not null
        || LicencePath is not null
        || CompanyImagesChanged == true;
}

public static class PendingCompanyProfileChangeHelper
{
    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
        PropertyNameCaseInsensitive = true,
        DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull,
        WriteIndented = false
    };

    public static string Serialize(PendingCompanyProfileChange change) =>
        JsonSerializer.Serialize(change, JsonOptions);

    public static PendingCompanyProfileChange? TryParse(string? raw)
    {
        if (string.IsNullOrWhiteSpace(raw))
        {
            return null;
        }

        try
        {
            return JsonSerializer.Deserialize<PendingCompanyProfileChange>(raw, JsonOptions);
        }
        catch
        {
            return null;
        }
    }

    public static void ApplyToUser(DataLayer.Models.User user, PendingCompanyProfileChange? pending)
    {
        if (pending is null)
        {
            return;
        }

        if (pending.FullName is not null)
        {
            var value = pending.FullName.Trim();
            if (!string.IsNullOrWhiteSpace(value))
            {
                user.FullName = value;
            }
        }

        if (pending.PhoneNumber is not null)
        {
            user.PhoneNumber = string.IsNullOrWhiteSpace(pending.PhoneNumber)
                ? null
                : pending.PhoneNumber.Trim();
        }

        if (pending.CompanyName is not null)
        {
            user.CompanyName = string.IsNullOrWhiteSpace(pending.CompanyName)
                ? null
                : pending.CompanyName.Trim();
        }

        if (pending.CommercialRegister is not null)
        {
            user.CommercialRegister = string.IsNullOrWhiteSpace(pending.CommercialRegister)
                ? null
                : pending.CommercialRegister.Trim();
        }

        if (pending.TaxNumber is not null)
        {
            user.TaxNumber = string.IsNullOrWhiteSpace(pending.TaxNumber)
                ? null
                : pending.TaxNumber.Trim();
        }

        if (pending.Website is not null)
        {
            user.Website = string.IsNullOrWhiteSpace(pending.Website)
                ? null
                : pending.Website.Trim();
        }

        if (pending.LandNumber is not null)
        {
            user.LandNumber = string.IsNullOrWhiteSpace(pending.LandNumber)
                ? null
                : pending.LandNumber.Trim();
        }
    }

    /// <summary>
    /// Media paths that exist only in the pending payload (not currently live).
    /// Safe to delete on reject or when replaced by a newer pending upload.
    /// </summary>
    public static IReadOnlyList<string> GetOrphanPendingMediaPaths(
        PendingCompanyProfileChange? pending,
        string? liveLicencePath,
        IEnumerable<string> liveCompanyImagePaths)
    {
        if (pending is null)
        {
            return [];
        }

        var liveImages = new HashSet<string>(
            liveCompanyImagePaths.Where(x => !string.IsNullOrWhiteSpace(x)),
            StringComparer.OrdinalIgnoreCase);
        var orphans = new List<string>();

        if (!string.IsNullOrWhiteSpace(pending.LicencePath)
            && !string.Equals(pending.LicencePath, liveLicencePath, StringComparison.OrdinalIgnoreCase))
        {
            orphans.Add(pending.LicencePath);
        }

        if (pending.CompanyImagesChanged == true && pending.CompanyImagePaths is not null)
        {
            foreach (var path in pending.CompanyImagePaths)
            {
                if (string.IsNullOrWhiteSpace(path))
                {
                    continue;
                }

                if (!liveImages.Contains(path))
                {
                    orphans.Add(path);
                }
            }
        }

        return orphans;
    }

    public static List<string> ResolveProposedCompanyImagePaths(
        PendingCompanyProfileChange? pending,
        IEnumerable<string> liveCompanyImagePaths)
    {
        if (pending?.CompanyImagesChanged == true)
        {
            return (pending.CompanyImagePaths ?? [])
                .Where(x => !string.IsNullOrWhiteSpace(x))
                .Distinct(StringComparer.OrdinalIgnoreCase)
                .ToList();
        }

        return liveCompanyImagePaths
            .Where(x => !string.IsNullOrWhiteSpace(x))
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .ToList();
    }
}
