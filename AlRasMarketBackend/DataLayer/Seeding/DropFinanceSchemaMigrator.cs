using DataLayer.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace DataLayer.Seeding;

/// <summary>
/// Drops supplier wallet tables (WithdrawalRequests → UserIbans → Balances) if they still exist.
/// Order matters because of foreign keys.
/// </summary>
public static class DropFinanceSchemaMigrator
{
    public static async Task EnsureAsync(IRasAlSouqDbContext db, CancellationToken cancellationToken = default)
    {
        var context = (DbContext)db;
        var connection = context.Database.GetDbConnection();
        await SqlSchemaHelper.OpenIfNeededAsync(connection, cancellationToken).ConfigureAwait(false);

        const string sql = """
            IF OBJECT_ID(N'dbo.WithdrawalRequests', N'U') IS NOT NULL
                DROP TABLE dbo.WithdrawalRequests;

            IF OBJECT_ID(N'dbo.UserIbans', N'U') IS NOT NULL
                DROP TABLE dbo.UserIbans;

            IF OBJECT_ID(N'dbo.Balances', N'U') IS NOT NULL
                DROP TABLE dbo.Balances;
            """;

        await SqlSchemaHelper.ExecuteBatchAsync(connection, sql, cancellationToken).ConfigureAwait(false);
    }
}
