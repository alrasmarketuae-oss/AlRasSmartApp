using DataLayer.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace DataLayer.Seeding;

/// <summary>
/// Creates BookingPriceTypes lookup (FOB / CNF / CIF) and Products.BookingPriceTypeId (nullable).
/// </summary>
public static class BookingPriceTypeSchemaMigrator
{
    public static async Task EnsureAsync(IRasAlSouqDbContext db, CancellationToken cancellationToken = default)
    {
        var context = (DbContext)db;
        var connection = context.Database.GetDbConnection();
        await SqlSchemaHelper.OpenIfNeededAsync(connection, cancellationToken).ConfigureAwait(false);

        await SqlSchemaHelper.ExecuteBatchAsync(
            connection,
            """
            IF OBJECT_ID(N'dbo.BookingPriceTypes', N'U') IS NULL
            BEGIN
                CREATE TABLE dbo.BookingPriceTypes
                (
                    Id TINYINT NOT NULL CONSTRAINT PK_BookingPriceTypes PRIMARY KEY,
                    NameEn VARCHAR(50) NOT NULL
                );

                INSERT INTO dbo.BookingPriceTypes (Id, NameEn)
                VALUES (1, 'FOB'), (2, 'CNF'), (3, 'CIF');
            END
            ELSE
            BEGIN
                IF NOT EXISTS (SELECT 1 FROM dbo.BookingPriceTypes WHERE Id = 1)
                    INSERT INTO dbo.BookingPriceTypes (Id, NameEn) VALUES (1, 'FOB');
                IF NOT EXISTS (SELECT 1 FROM dbo.BookingPriceTypes WHERE Id = 2)
                    INSERT INTO dbo.BookingPriceTypes (Id, NameEn) VALUES (2, 'CNF');
                IF NOT EXISTS (SELECT 1 FROM dbo.BookingPriceTypes WHERE Id = 3)
                    INSERT INTO dbo.BookingPriceTypes (Id, NameEn) VALUES (3, 'CIF');
            END
            """,
            cancellationToken).ConfigureAwait(false);

        if (!await SqlSchemaHelper.ColumnExistsAsync(connection, "Products", "BookingPriceTypeId", cancellationToken)
                .ConfigureAwait(false))
        {
            await SqlSchemaHelper.ExecuteBatchAsync(
                connection,
                """
                IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.Products') AND name = N'BookingPriceTypeId')
                BEGIN
                    ALTER TABLE dbo.Products ADD BookingPriceTypeId TINYINT NULL;
                    ALTER TABLE dbo.Products ADD CONSTRAINT FK_Products_BookingPriceTypes
                        FOREIGN KEY (BookingPriceTypeId) REFERENCES dbo.BookingPriceTypes(Id);
                END
                """,
                cancellationToken).ConfigureAwait(false);
        }
    }
}
