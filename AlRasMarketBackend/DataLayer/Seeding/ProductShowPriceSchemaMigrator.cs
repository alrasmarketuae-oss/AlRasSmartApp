using DataLayer.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace DataLayer.Seeding;

/// <summary>
/// Adds Products.ShowPrice (default true). When false, public UI hides price and shows Ask for price.
/// Must run before any EF Products query and before ProductStoredProceduresSchemaMigrator.
/// </summary>
public static class ProductShowPriceSchemaMigrator
{
    public static async Task EnsureAsync(IRasAlSouqDbContext db, CancellationToken cancellationToken = default)
    {
        var context = (DbContext)db;
        var connection = context.Database.GetDbConnection();
        await SqlSchemaHelper.OpenIfNeededAsync(connection, cancellationToken).ConfigureAwait(false);

        await SqlSchemaHelper.ExecuteBatchAsync(
            connection,
            """
            IF COL_LENGTH(N'dbo.Products', N'ShowPrice') IS NULL
            BEGIN
                ALTER TABLE dbo.Products
                ADD ShowPrice BIT NOT NULL
                    CONSTRAINT DF_Products_ShowPrice DEFAULT (1);
            END
            """,
            cancellationToken).ConfigureAwait(false);
    }
}
