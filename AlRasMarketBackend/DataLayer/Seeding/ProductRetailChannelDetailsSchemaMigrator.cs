using DataLayer.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace DataLayer.Seeding;

/// <summary>
/// Hybrid category+retail ads: separate packing and specs for the retail channel.
/// </summary>
public static class ProductRetailChannelDetailsSchemaMigrator
{
    public static async Task EnsureAsync(IRasAlSouqDbContext db, CancellationToken cancellationToken = default)
    {
        var context = (DbContext)db;
        var connection = context.Database.GetDbConnection();
        await SqlSchemaHelper.OpenIfNeededAsync(connection, cancellationToken).ConfigureAwait(false);

        if (!await SqlSchemaHelper.ColumnExistsAsync(connection, "Products", "RetailPackaging", cancellationToken)
                .ConfigureAwait(false))
        {
            await SqlSchemaHelper.ExecuteBatchAsync(
                connection,
                """
                ALTER TABLE dbo.Products ADD RetailPackaging TINYINT NULL;
                """,
                cancellationToken).ConfigureAwait(false);
        }

        if (!await SqlSchemaHelper.ColumnExistsAsync(connection, "Products", "RetailPackagingDetails", cancellationToken)
                .ConfigureAwait(false))
        {
            await SqlSchemaHelper.ExecuteBatchAsync(
                connection,
                """
                ALTER TABLE dbo.Products ADD RetailPackagingDetails NVARCHAR(255) NULL;
                """,
                cancellationToken).ConfigureAwait(false);
        }

        if (!await SqlSchemaHelper.ColumnExistsAsync(connection, "Products", "RetailDescriptionEn", cancellationToken)
                .ConfigureAwait(false))
        {
            await SqlSchemaHelper.ExecuteBatchAsync(
                connection,
                """
                ALTER TABLE dbo.Products ADD RetailDescriptionEn NVARCHAR(MAX) NULL;
                """,
                cancellationToken).ConfigureAwait(false);
        }
    }
}
