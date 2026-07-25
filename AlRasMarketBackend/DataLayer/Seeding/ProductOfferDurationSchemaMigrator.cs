using DataLayer.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace DataLayer.Seeding;

/// <summary>
/// Adds Products.OfferDuration and moves mis-stored offer days out of ShippingDuration.
/// </summary>
public static class ProductOfferDurationSchemaMigrator
{
    public static async Task EnsureAsync(IRasAlSouqDbContext db, CancellationToken cancellationToken = default)
    {
        var context = (DbContext)db;
        var connection = context.Database.GetDbConnection();
        await SqlSchemaHelper.OpenIfNeededAsync(connection, cancellationToken).ConfigureAwait(false);

        if (!await SqlSchemaHelper.ColumnExistsAsync(connection, "Products", "OfferDuration", cancellationToken)
                .ConfigureAwait(false))
        {
            await SqlSchemaHelper.ExecuteBatchAsync(
                connection,
                """
                ALTER TABLE dbo.Products
                ADD OfferDuration VARCHAR(20) NULL;
                """,
                cancellationToken).ConfigureAwait(false);
        }

        // Offers historically wrote duration into ShippingDuration — move to OfferDuration.
        await SqlSchemaHelper.ExecuteBatchAsync(
            connection,
            """
            UPDATE p
            SET OfferDuration = LEFT(LTRIM(RTRIM(p.ShippingDuration)), 20)
            FROM dbo.Products p
            WHERE p.ProductTypeId = 3
              AND (p.OfferDuration IS NULL OR LTRIM(RTRIM(p.OfferDuration)) = N'')
              AND p.ShippingDuration IS NOT NULL
              AND LTRIM(RTRIM(p.ShippingDuration)) <> N'';

            UPDATE p
            SET OfferDuration = LEFT(CONVERT(VARCHAR(20), p.DiscountDays), 20)
            FROM dbo.Products p
            WHERE p.ProductTypeId = 3
              AND (p.OfferDuration IS NULL OR LTRIM(RTRIM(p.OfferDuration)) = N'')
              AND p.DiscountDays IS NOT NULL
              AND p.DiscountDays > 0;

            UPDATE p
            SET ShippingDuration = NULL
            FROM dbo.Products p
            WHERE p.ProductTypeId = 3
              AND p.OfferDuration IS NOT NULL
              AND LTRIM(RTRIM(p.OfferDuration)) <> N''
              AND p.ShippingDuration IS NOT NULL;
            """,
            cancellationToken).ConfigureAwait(false);
    }
}
