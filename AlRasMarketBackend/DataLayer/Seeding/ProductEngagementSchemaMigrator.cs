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

        // One ALTER per batch — SQL Server can fail compiling multiple ADD+DEFAULT in one batch.
        await EnsureBigIntCounterAsync(
            connection,
            "ViewsCount",
            "DF_Products_ViewsCount",
            cancellationToken).ConfigureAwait(false);
        await EnsureBigIntCounterAsync(
            connection,
            "CartAddsCount",
            "DF_Products_CartAddsCount",
            cancellationToken).ConfigureAwait(false);
        await EnsureBigIntCounterAsync(
            connection,
            "FavoritesCount",
            "DF_Products_FavoritesCount",
            cancellationToken).ConfigureAwait(false);
        await EnsureBigIntCounterAsync(
            connection,
            "SharesCount",
            "DF_Products_SharesCount",
            cancellationToken).ConfigureAwait(false);
    }

    private static async Task EnsureBigIntCounterAsync(
        System.Data.Common.DbConnection connection,
        string columnName,
        string defaultConstraintName,
        CancellationToken cancellationToken)
    {
        if (await SqlSchemaHelper.ColumnExistsAsync(connection, "Products", columnName, cancellationToken)
                .ConfigureAwait(false))
        {
            return;
        }

        await SqlSchemaHelper.ExecuteBatchAsync(
            connection,
            $"""
            ALTER TABLE dbo.Products
            ADD {columnName} BIGINT NOT NULL
                CONSTRAINT {defaultConstraintName} DEFAULT (0);
            """,
            cancellationToken).ConfigureAwait(false);
    }
}
