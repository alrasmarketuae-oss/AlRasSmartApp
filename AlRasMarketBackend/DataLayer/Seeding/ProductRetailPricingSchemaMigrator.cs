using DataLayer.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace DataLayer.Seeding;

/// <summary>
/// Adds optional retail pricing columns on Products for category listings that also sell retail,
/// and Orders.IsRetailPurchase for dual-channel order workflow.
/// </summary>
public static class ProductRetailPricingSchemaMigrator
{
    public static async Task EnsureAsync(IRasAlSouqDbContext db, CancellationToken cancellationToken = default)
    {
        var context = (DbContext)db;
        var connection = context.Database.GetDbConnection();
        await SqlSchemaHelper.OpenIfNeededAsync(connection, cancellationToken).ConfigureAwait(false);

        if (!await SqlSchemaHelper.ColumnExistsAsync(connection, "Products", "RetailPrice", cancellationToken)
                .ConfigureAwait(false))
        {
            await SqlSchemaHelper.ExecuteBatchAsync(
                connection,
                """
                ALTER TABLE dbo.Products
                ADD RetailPrice DECIMAL(8,2) NULL;
                """,
                cancellationToken).ConfigureAwait(false);
        }

        if (!await SqlSchemaHelper.ColumnExistsAsync(connection, "Products", "RetailUnitId", cancellationToken)
                .ConfigureAwait(false))
        {
            await SqlSchemaHelper.ExecuteBatchAsync(
                connection,
                """
                IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.Products') AND name = N'RetailUnitId')
                BEGIN
                    ALTER TABLE dbo.Products ADD RetailUnitId TINYINT NULL;
                    IF EXISTS (SELECT 1 FROM sys.tables WHERE name = N'Units')
                        ALTER TABLE dbo.Products ADD CONSTRAINT FK_Products_RetailUnits
                            FOREIGN KEY (RetailUnitId) REFERENCES dbo.Units(Id);
                END
                """,
                cancellationToken).ConfigureAwait(false);
        }

        if (!await SqlSchemaHelper.ColumnExistsAsync(connection, "Products", "RetailQuantity", cancellationToken)
                .ConfigureAwait(false))
        {
            await SqlSchemaHelper.ExecuteBatchAsync(
                connection,
                """
                ALTER TABLE dbo.Products
                ADD RetailQuantity BIGINT NULL;
                """,
                cancellationToken).ConfigureAwait(false);
        }

        if (!await SqlSchemaHelper.ColumnExistsAsync(connection, "Orders", "IsRetailPurchase", cancellationToken)
                .ConfigureAwait(false))
        {
            await SqlSchemaHelper.ExecuteBatchAsync(
                connection,
                """
                ALTER TABLE dbo.Orders
                ADD IsRetailPurchase BIT NOT NULL CONSTRAINT DF_Orders_IsRetailPurchase DEFAULT 0;
                """,
                cancellationToken).ConfigureAwait(false);
        }

        // Existing cart/checkout orders for pure Retail products behave as retail purchases.
        await SqlSchemaHelper.ExecuteBatchAsync(
            connection,
            """
            UPDATE o
            SET o.IsRetailPurchase = 1
            FROM dbo.Orders o
            INNER JOIN dbo.Products p ON p.ProductId = o.ProductId
            WHERE o.IsRetailPurchase = 0
              AND p.ProductTypeId = 1
              AND o.PendingOrderId IS NOT NULL;
            """,
            cancellationToken).ConfigureAwait(false);
    }
}
