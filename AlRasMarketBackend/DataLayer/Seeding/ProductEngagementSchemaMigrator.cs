using DataLayer.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace DataLayer.Seeding;

/// <summary>
/// Adds Products engagement counters used by seller ad statistics.
/// Must run before any EF Products query that maps these columns.
/// </summary>
public static class ProductEngagementSchemaMigrator
{
    public static async Task EnsureAsync(IRasAlSouqDbContext db, CancellationToken cancellationToken = default)
    {
        var context = (DbContext)db;
        var connection = context.Database.GetDbConnection();
        await SqlSchemaHelper.OpenIfNeededAsync(connection, cancellationToken).ConfigureAwait(false);

        await SqlSchemaHelper.ExecuteBatchAsync(
            connection,
            """
            IF COL_LENGTH(N'dbo.Products', N'CartAddsCount') IS NULL
            BEGIN
                ALTER TABLE dbo.Products
                ADD CartAddsCount BIGINT NOT NULL
                    CONSTRAINT DF_Products_CartAddsCount DEFAULT (0);
            END

            IF COL_LENGTH(N'dbo.Products', N'FavoritesCount') IS NULL
            BEGIN
                ALTER TABLE dbo.Products
                ADD FavoritesCount BIGINT NOT NULL
                    CONSTRAINT DF_Products_FavoritesCount DEFAULT (0);
            END

            IF COL_LENGTH(N'dbo.Products', N'SharesCount') IS NULL
            BEGIN
                ALTER TABLE dbo.Products
                ADD SharesCount BIGINT NOT NULL
                    CONSTRAINT DF_Products_SharesCount DEFAULT (0);
            END
            """,
            cancellationToken).ConfigureAwait(false);
    }
}
