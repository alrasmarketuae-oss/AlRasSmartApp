using DataLayer.Interfaces;

namespace DataLayer.Seeding;

/// <summary>
/// Previously remapped Product.CategoryId on every server restart (legacy mobile slot ids / name hints).
/// Disabled permanently — categories must only change via API/admin actions.
/// </summary>
public static class ProductCategoryIdMigrator
{
    public static Task EnsureAsync(IRasAlSouqDbContext db, CancellationToken cancellationToken = default)
    {
        _ = db;
        return Task.CompletedTask;
    }
}
