using DataLayer.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace DataLayer.Seeding;

/// <summary>
/// Shipping company accounts are auto-approved. Activate any legacy pending ones (idempotent).
/// </summary>
public static class ShippingCompanyAutoApproveMigrator
{
    private const byte ShippingCompanyRoleId = 5;

    public static async Task EnsureAsync(IRasAlSouqDbContext db, CancellationToken cancellationToken = default)
    {
        var context = (DbContext)db;
        var connection = context.Database.GetDbConnection();
        await SqlSchemaHelper.OpenIfNeededAsync(connection, cancellationToken).ConfigureAwait(false);

        await SqlSchemaHelper.ExecuteBatchAsync(
            connection,
            $"""
            UPDATE dbo.Users
            SET IsApproved = 1,
                IsActive = CASE WHEN IsRejected = 1 THEN IsActive ELSE 1 END
            WHERE RoleId = {ShippingCompanyRoleId}
              AND IsRejected = 0
              AND (IsApproved = 0 OR IsActive = 0);
            """,
            cancellationToken).ConfigureAwait(false);
    }
}
