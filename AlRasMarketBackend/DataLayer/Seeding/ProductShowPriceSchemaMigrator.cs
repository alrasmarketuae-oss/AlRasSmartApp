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
            ELSE
            BEGIN
                -- Repair rows / nullable column from a partial earlier deploy.
                UPDATE dbo.Products SET ShowPrice = 1 WHERE ShowPrice IS NULL;

                IF EXISTS (
                    SELECT 1
                    FROM sys.columns
                    WHERE object_id = OBJECT_ID(N'dbo.Products')
                      AND name = N'ShowPrice'
                      AND is_nullable = 1
                )
                BEGIN
                    IF NOT EXISTS (
                        SELECT 1
                        FROM sys.default_constraints dc
                        INNER JOIN sys.columns c
                            ON c.default_object_id = dc.object_id
                        WHERE dc.parent_object_id = OBJECT_ID(N'dbo.Products')
                          AND c.name = N'ShowPrice'
                    )
                    BEGIN
                        ALTER TABLE dbo.Products
                        ADD CONSTRAINT DF_Products_ShowPrice DEFAULT (1) FOR ShowPrice;
                    END

                    ALTER TABLE dbo.Products
                    ALTER COLUMN ShowPrice BIT NOT NULL;
                END
            END

            -- Offers (ProductTypeId = 3) always show price publicly.
            IF COL_LENGTH(N'dbo.Products', N'ShowPrice') IS NOT NULL
               AND COL_LENGTH(N'dbo.Products', N'ProductTypeId') IS NOT NULL
            BEGIN
                UPDATE dbo.Products
                SET ShowPrice = 1
                WHERE ProductTypeId = 3
                  AND ShowPrice = 0;
            END
            """,
            cancellationToken).ConfigureAwait(false);
    }
}
