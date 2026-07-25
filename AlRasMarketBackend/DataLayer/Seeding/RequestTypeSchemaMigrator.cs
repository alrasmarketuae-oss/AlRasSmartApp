using DataLayer.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace DataLayer.Seeding;

/// <summary>
/// Creates RequestTypes lookup and Products.RequestTypeId for Local / Reexport (Offers, Requests, Categories).
/// </summary>
public static class RequestTypeSchemaMigrator
{
    public static async Task EnsureAsync(IRasAlSouqDbContext db, CancellationToken cancellationToken = default)
    {
        var context = (DbContext)db;
        var connection = context.Database.GetDbConnection();
        await SqlSchemaHelper.OpenIfNeededAsync(connection, cancellationToken).ConfigureAwait(false);

        await SqlSchemaHelper.ExecuteBatchAsync(
            connection,
            """
            IF OBJECT_ID(N'dbo.RequestTypes', N'U') IS NULL
            BEGIN
                CREATE TABLE dbo.RequestTypes
                (
                    Id TINYINT NOT NULL CONSTRAINT PK_RequestTypes PRIMARY KEY,
                    NameEn VARCHAR(50) NOT NULL
                );

                INSERT INTO dbo.RequestTypes (Id, NameEn) VALUES (1, 'Local'), (2, 'Reexport');
            END
            ELSE
            BEGIN
                IF NOT EXISTS (SELECT 1 FROM dbo.RequestTypes WHERE Id = 1)
                    INSERT INTO dbo.RequestTypes (Id, NameEn) VALUES (1, 'Local');
                IF NOT EXISTS (SELECT 1 FROM dbo.RequestTypes WHERE Id = 2)
                    INSERT INTO dbo.RequestTypes (Id, NameEn) VALUES (2, 'Reexport');
            END
            """,
            cancellationToken).ConfigureAwait(false);

        if (!await SqlSchemaHelper.ColumnExistsAsync(connection, "Products", "RequestTypeId", cancellationToken)
                .ConfigureAwait(false))
        {
            await SqlSchemaHelper.ExecuteBatchAsync(
                connection,
                """
                IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.Products') AND name = N'RequestTypeId')
                BEGIN
                    ALTER TABLE dbo.Products ADD RequestTypeId TINYINT NULL;
                    ALTER TABLE dbo.Products ADD CONSTRAINT FK_Products_RequestTypes
                        FOREIGN KEY (RequestTypeId) REFERENCES dbo.RequestTypes(Id);
                END
                """,
                cancellationToken).ConfigureAwait(false);
        }

        // Backfill Local / Rexport from legacy ShippingDescriptionEn for
        // Requests (4), Offers (3), and Categories (CategoryId set).
        await SqlSchemaHelper.ExecuteBatchAsync(
            connection,
            """
            UPDATE p
            SET p.RequestTypeId = 1
            FROM dbo.Products p
            WHERE p.RequestTypeId IS NULL
              AND (
                    p.ProductTypeId IN (3, 4)
                    OR (p.CategoryId IS NOT NULL AND p.CategoryId > 0)
                  )
              AND p.ShippingDescriptionEn IS NOT NULL
              AND LOWER(LTRIM(RTRIM(p.ShippingDescriptionEn))) IN ('local');

            UPDATE p
            SET p.RequestTypeId = 2
            FROM dbo.Products p
            WHERE p.RequestTypeId IS NULL
              AND (
                    p.ProductTypeId IN (3, 4)
                    OR (p.CategoryId IS NOT NULL AND p.CategoryId > 0)
                  )
              AND p.ShippingDescriptionEn IS NOT NULL
              AND LOWER(LTRIM(RTRIM(p.ShippingDescriptionEn))) IN (
                    'reexport', 'rexport', 're-export', 're_export', 'export', 'booking'
                  );
            """,
            cancellationToken).ConfigureAwait(false);
    }
}
