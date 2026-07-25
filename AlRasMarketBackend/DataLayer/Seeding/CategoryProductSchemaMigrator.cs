using DataLayer.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace DataLayer.Seeding;

/// <summary>Adds Categories.CommissionPercent and Products.Currency if missing (idempotent).</summary>
public static class CategoryProductSchemaMigrator
{
    public static async Task EnsureAsync(IRasAlSouqDbContext db, CancellationToken cancellationToken = default)
    {
        var context = (DbContext)db;
        var connection = context.Database.GetDbConnection();
        await SqlSchemaHelper.OpenIfNeededAsync(connection, cancellationToken).ConfigureAwait(false);

        if (!await SqlSchemaHelper.ColumnExistsAsync(connection, "Categories", "CommissionPercent", cancellationToken)
                .ConfigureAwait(false))
        {
            await SqlSchemaHelper.ExecuteBatchAsync(connection,
                """
                ALTER TABLE dbo.Categories
                ADD CommissionPercent DECIMAL(5,2) NOT NULL
                    CONSTRAINT DF_Categories_CommissionPercent DEFAULT 0;
                """,
                cancellationToken).ConfigureAwait(false);
        }

        if (!await SqlSchemaHelper.ColumnExistsAsync(connection, "Categories", "IsHide", cancellationToken)
                .ConfigureAwait(false))
        {
            await SqlSchemaHelper.ExecuteBatchAsync(connection,
                """
                ALTER TABLE dbo.Categories
                ADD IsHide BIT NOT NULL
                    CONSTRAINT DF_Categories_IsHide DEFAULT 0;
                """,
                cancellationToken).ConfigureAwait(false);
        }

        if (!await SqlSchemaHelper.ColumnExistsAsync(connection, "Categories", "IsHide", cancellationToken)
                .ConfigureAwait(false))
        {
            await SqlSchemaHelper.ExecuteBatchAsync(connection,
                """
                ALTER TABLE dbo.Categories
                ADD IsHide BIT NOT NULL
                    CONSTRAINT DF_Categories_IsHide DEFAULT 0;
                """,
                cancellationToken).ConfigureAwait(false);
        }

        if (!await SqlSchemaHelper.ColumnExistsAsync(connection, "Categories", "NameAr", cancellationToken)
                .ConfigureAwait(false))
        {
            await SqlSchemaHelper.ExecuteBatchAsync(connection,
                """
                ALTER TABLE dbo.Categories
                ADD NameAr NVARCHAR(255) NOT NULL
                    CONSTRAINT DF_Categories_NameAr DEFAULT N'';
                """,
                cancellationToken).ConfigureAwait(false);
        }

        if (await SqlSchemaHelper.ColumnExistsAsync(connection, "Categories", "NameAr", cancellationToken)
                .ConfigureAwait(false))
        {
            await SqlSchemaHelper.ExecuteBatchAsync(connection,
                """
                UPDATE dbo.Categories SET NameAr = N'أعشاب' WHERE NameEn = N'Herbs' AND (NameAr IS NULL OR LTRIM(RTRIM(NameAr)) = N'');
                UPDATE dbo.Categories SET NameAr = N'بقوليات' WHERE NameEn = N'Pulses' AND (NameAr IS NULL OR LTRIM(RTRIM(NameAr)) = N'');
                UPDATE dbo.Categories SET NameAr = N'توابل' WHERE NameEn = N'Spices' AND (NameAr IS NULL OR LTRIM(RTRIM(NameAr)) = N'');
                UPDATE dbo.Categories SET NameAr = N'مكسرات' WHERE NameEn = N'Nuts' AND (NameAr IS NULL OR LTRIM(RTRIM(NameAr)) = N'');
                UPDATE dbo.Categories SET NameAr = N'قهوة' WHERE NameEn = N'Coffee' AND (NameAr IS NULL OR LTRIM(RTRIM(NameAr)) = N'');
                UPDATE dbo.Categories SET NameAr = N'الهيل' WHERE NameEn = N'Cardamom' AND (NameAr IS NULL OR LTRIM(RTRIM(NameAr)) = N'');
                UPDATE dbo.Categories SET NameAr = N'كاكو' WHERE NameEn = N'Cocoa' AND (NameAr IS NULL OR LTRIM(RTRIM(NameAr)) = N'');
                UPDATE dbo.Categories SET NameAr = N'أحماض' WHERE NameEn = N'Acids' AND (NameAr IS NULL OR LTRIM(RTRIM(NameAr)) = N'');
                UPDATE dbo.Categories SET NameAr = N'حليب' WHERE NameEn = N'Milk' AND (NameAr IS NULL OR LTRIM(RTRIM(NameAr)) = N'');
                UPDATE dbo.Categories SET NameAr = N'تمور' WHERE NameEn = N'Dates' AND (NameAr IS NULL OR LTRIM(RTRIM(NameAr)) = N'');
                UPDATE dbo.Categories SET NameAr = N'سكر' WHERE NameEn = N'Sugar' AND (NameAr IS NULL OR LTRIM(RTRIM(NameAr)) = N'');
                UPDATE dbo.Categories SET NameAr = N'أرز' WHERE NameEn = N'Rice' AND (NameAr IS NULL OR LTRIM(RTRIM(NameAr)) = N'');
                UPDATE dbo.Categories SET NameAr = N'حلويات' WHERE NameEn = N'Sweets' AND (NameAr IS NULL OR LTRIM(RTRIM(NameAr)) = N'');
                UPDATE dbo.Categories SET NameAr = N'معلبات' WHERE NameEn IN (N'Canned', N'Canned Foods') AND (NameAr IS NULL OR LTRIM(RTRIM(NameAr)) = N'');
                UPDATE dbo.Categories SET NameAr = N'طحين' WHERE NameEn = N'Flour' AND (NameAr IS NULL OR LTRIM(RTRIM(NameAr)) = N'');
                UPDATE dbo.Categories SET NameAr = N'تجميل' WHERE NameEn = N'Beauty' AND (NameAr IS NULL OR LTRIM(RTRIM(NameAr)) = N'');
                UPDATE dbo.Categories SET NameAr = N'دواجن' WHERE NameEn = N'Poultry' AND (NameAr IS NULL OR LTRIM(RTRIM(NameAr)) = N'');
                UPDATE dbo.Categories SET NameAr = N'مجمدات' WHERE NameEn = N'Frozen Foods' AND (NameAr IS NULL OR LTRIM(RTRIM(NameAr)) = N'');
                UPDATE dbo.Categories SET NameAr = NameEn WHERE NameAr IS NULL OR LTRIM(RTRIM(NameAr)) = N'';
                """,
                cancellationToken).ConfigureAwait(false);
        }

        if (!await SqlSchemaHelper.ColumnExistsAsync(connection, "Products", "Currency", cancellationToken)
                .ConfigureAwait(false))
        {
            await SqlSchemaHelper.ExecuteBatchAsync(connection,
                """
                ALTER TABLE dbo.Products
                ADD Currency NVARCHAR(3) NOT NULL
                    CONSTRAINT DF_Products_Currency DEFAULT N'AED';
                """,
                cancellationToken).ConfigureAwait(false);

            await SqlSchemaHelper.ExecuteBatchAsync(connection,
                """
                UPDATE dbo.Products
                SET Currency = N'USD'
                WHERE ProductTypeId = 2;
                """,
                cancellationToken).ConfigureAwait(false);
        }

        if (!await SqlSchemaHelper.ColumnExistsAsync(connection, "Products", "AddressId", cancellationToken)
                .ConfigureAwait(false))
        {
            if (await SqlSchemaHelper.ColumnExistsAsync(connection, "Products", "Address", cancellationToken)
                    .ConfigureAwait(false))
            {
                await SqlSchemaHelper.ExecuteBatchAsync(connection,
                    """
                    ALTER TABLE dbo.Products DROP COLUMN Address;
                    """,
                    cancellationToken).ConfigureAwait(false);
            }

            await SqlSchemaHelper.ExecuteBatchAsync(connection,
                """
                ALTER TABLE dbo.Products
                ADD AddressId UNIQUEIDENTIFIER NULL;

                IF NOT EXISTS (
                    SELECT 1
                    FROM sys.foreign_keys
                    WHERE name = N'FK_Products_Addresses'
                      AND parent_object_id = OBJECT_ID(N'dbo.Products'))
                BEGIN
                    ALTER TABLE dbo.Products
                    ADD CONSTRAINT FK_Products_Addresses
                        FOREIGN KEY (AddressId) REFERENCES dbo.Addresses(Id);
                END
                """,
                cancellationToken).ConfigureAwait(false);
        }

        if (!await SqlSchemaHelper.ColumnExistsAsync(connection, "Products", "DisplayExpiresAtUtc", cancellationToken)
                .ConfigureAwait(false))
        {
            await SqlSchemaHelper.ExecuteBatchAsync(connection,
                """
                ALTER TABLE dbo.Products
                ADD DisplayExpiresAtUtc DATETIME NULL;
                """,
                cancellationToken).ConfigureAwait(false);

            await SqlSchemaHelper.ExecuteBatchAsync(connection,
                """
                UPDATE p
                SET p.DisplayExpiresAtUtc = DATEADD(
                    DAY,
                    s.AdDisplayDurationDays,
                    COALESCE(p.UpdatedAt, p.CreatedAt))
                FROM dbo.Products p
                CROSS JOIN dbo.SystemSettings s
                WHERE s.Id = 1
                  AND s.AdDisplayDurationDays > 0
                  AND p.IsApproved = 1
                  AND p.Status = 2;
                """,
                cancellationToken).ConfigureAwait(false);
        }

        if (!await SqlSchemaHelper.ColumnExistsAsync(connection, "Products", "IsVideoMuted", cancellationToken)
                .ConfigureAwait(false))
        {
            await SqlSchemaHelper.ExecuteBatchAsync(connection,
                """
                ALTER TABLE dbo.Products
                ADD IsVideoMuted BIT NOT NULL
                    CONSTRAINT DF_Products_IsVideoMuted DEFAULT 1;
                """,
                cancellationToken).ConfigureAwait(false);
        }
    }
}
