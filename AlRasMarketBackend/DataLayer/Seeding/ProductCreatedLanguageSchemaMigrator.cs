using DataLayer.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace DataLayer.Seeding;

/// <summary>
/// Adds Products.CreatedLanguage (app UI locale when the ad was authored: en / ar).
/// </summary>
public static class ProductCreatedLanguageSchemaMigrator
{
    public static async Task EnsureAsync(IRasAlSouqDbContext db, CancellationToken cancellationToken = default)
    {
        var context = (DbContext)db;
        var connection = context.Database.GetDbConnection();
        await SqlSchemaHelper.OpenIfNeededAsync(connection, cancellationToken).ConfigureAwait(false);

        if (!await SqlSchemaHelper.ColumnExistsAsync(connection, "Products", "CreatedLanguage", cancellationToken)
                .ConfigureAwait(false))
        {
            await SqlSchemaHelper.ExecuteBatchAsync(
                connection,
                """
                ALTER TABLE dbo.Products
                ADD CreatedLanguage VARCHAR(5) NOT NULL
                    CONSTRAINT DF_Products_CreatedLanguage DEFAULT ('en');
                """,
                cancellationToken).ConfigureAwait(false);
        }

        // Backfill from ContentTranslations source language when the name was authored in Arabic.
        await SqlSchemaHelper.ExecuteBatchAsync(
            connection,
            """
            UPDATE p
            SET CreatedLanguage = 'ar'
            FROM dbo.Products p
            INNER JOIN dbo.ContentTranslations t
                ON t.ProductId = p.ProductId
               AND t.Scope = N'Product'
               AND t.Field = N'Name'
            WHERE LOWER(LTRIM(RTRIM(t.SourceLanguage))) = 'ar'
              AND (p.CreatedLanguage IS NULL
                   OR LOWER(LTRIM(RTRIM(p.CreatedLanguage))) <> 'ar');
            """,
            cancellationToken).ConfigureAwait(false);
    }
}
