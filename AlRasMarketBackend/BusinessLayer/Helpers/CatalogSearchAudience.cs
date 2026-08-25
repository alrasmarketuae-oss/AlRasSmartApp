namespace BusinessLayer.Helpers;

/// <summary>
/// Audience used to filter text/image catalog search results.
/// Supplier and guest use <see cref="All"/> (unrestricted public catalog).
/// </summary>
public enum CatalogSearchAudience
{
    /// <summary>No role-based catalog filter.</summary>
    All = 0,

    /// <summary>Offers + Booking + wholesale/category only (no Retail/Requests).</summary>
    CompanyCustomer = 1,

    /// <summary>Retail only (pure retail + hybrid retail channel).</summary>
    PersonalCustomer = 2,
}
