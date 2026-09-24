using BusinessLayer.Constants;
using DataLayer.Models;

namespace BusinessLayer.Helpers;

/// <summary>
/// Display name for mobile auth/header surfaces. Company accounts prefer
/// <see cref="User.CompanyName"/> so the home header shows the company without
/// a mobile app change. Personal buyers keep <see cref="User.FullName"/>.
/// </summary>
public static class UserAppDisplayName
{
    public static string Resolve(User user)
    {
        if (user.RoleId is RoleIds.Seller or RoleIds.ShippingCompany)
        {
            var company = user.CompanyName?.Trim();
            if (!string.IsNullOrWhiteSpace(company))
            {
                return company;
            }
        }

        return user.FullName?.Trim() ?? string.Empty;
    }

    /// <summary>
    /// True when <paramref name="incoming"/> is only the app echoing the
    /// company display name back as fullName (not a real owner-name edit).
    /// </summary>
    public static bool IsEchoOfCompanyDisplayName(User user, string? incoming)
    {
        if (user.RoleId is not (RoleIds.Seller or RoleIds.ShippingCompany))
        {
            return false;
        }

        var value = incoming?.Trim() ?? string.Empty;
        if (value.Length == 0)
        {
            return false;
        }

        var company = user.CompanyName?.Trim() ?? string.Empty;
        return company.Length > 0
            && string.Equals(value, company, StringComparison.Ordinal);
    }
}
