using DataLayer.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace DataLayer.Seeding;

/// <summary>
/// Removes duplicate categories (same English name). Never reassigns products on startup —
/// that moved listings (e.g. CategoryId 14 → 5) after every IIS/Plesk restart.
/// </summary>
public static class CategoryDuplicateCleanup
{
    public static async Task EnsureAsync(IRasAlSouqDbContext db, CancellationToken cancellationToken = default)
    {
        var all = await db.Categories.ToListAsync(cancellationToken).ConfigureAwait(false);
        var duplicateGroups = all
            .GroupBy(c => NormalizeName(c.NameEn))
            .Where(g => g.Count() > 1)
            .ToList();

        if (duplicateGroups.Count == 0)
        {
            return;
        }

        var changed = false;

        foreach (var group in duplicateGroups)
        {
            var keeper = group.OrderBy(c => c.CategoryId).First();

            foreach (var duplicate in group.Where(c => c.CategoryId != keeper.CategoryId))
            {
                var linkedProducts = await db.Products
                    .CountAsync(p => p.CategoryId == duplicate.CategoryId, cancellationToken)
                    .ConfigureAwait(false);

                // Keep duplicates that still have products — admin must merge manually.
                if (linkedProducts > 0)
                {
                    continue;
                }

                db.Categories.Remove(duplicate);
                changed = true;
            }
        }

        if (changed)
        {
            await db.SaveChangesAsync(cancellationToken).ConfigureAwait(false);
        }
    }

    private static string NormalizeName(string name) =>
        name.Trim().ToLowerInvariant();
}
