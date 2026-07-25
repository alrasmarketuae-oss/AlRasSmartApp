using DataLayer.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace DataLayer.Seeding;

/// <summary>
/// Idempotent performance indexes for orders, products, and related lookups.
/// </summary>
public static class QueryPerformanceIndexMigrator
{
    public static async Task EnsureAsync(IRasAlSouqDbContext db, CancellationToken cancellationToken = default)
    {
        var context = (DbContext)db;
        var connection = context.Database.GetDbConnection();
        await SqlSchemaHelper.OpenIfNeededAsync(connection, cancellationToken).ConfigureAwait(false);

        if (await SqlSchemaHelper.TableExistsAsync(connection, "Orders", cancellationToken).ConfigureAwait(false))
        {
            await EnsureOrderIndexesAsync(connection, cancellationToken).ConfigureAwait(false);
        }

        if (await SqlSchemaHelper.TableExistsAsync(connection, "ProductImages", cancellationToken).ConfigureAwait(false))
        {
            await SqlSchemaHelper.EnsureIndexAsync(
                connection,
                "ProductImages",
                "IX_ProductImages_ProductId",
                "CREATE INDEX IX_ProductImages_ProductId ON dbo.ProductImages (ProductId);",
                cancellationToken).ConfigureAwait(false);
        }

        if (await SqlSchemaHelper.TableExistsAsync(connection, "ProductDocuments", cancellationToken).ConfigureAwait(false))
        {
            await SqlSchemaHelper.EnsureIndexAsync(
                connection,
                "ProductDocuments",
                "IX_ProductDocuments_ProductId",
                "CREATE INDEX IX_ProductDocuments_ProductId ON dbo.ProductDocuments (ProductId);",
                cancellationToken).ConfigureAwait(false);
        }

        if (await SqlSchemaHelper.TableExistsAsync(connection, "Products", cancellationToken).ConfigureAwait(false))
        {
            await EnsureProductIndexesAsync(connection, cancellationToken).ConfigureAwait(false);
        }

        if (await SqlSchemaHelper.TableExistsAsync(connection, "Ports", cancellationToken).ConfigureAwait(false))
        {
            await SqlSchemaHelper.EnsureIndexAsync(
                connection,
                "Ports",
                "IX_Ports_CountryId_PortNameEn",
                "CREATE INDEX IX_Ports_CountryId_PortNameEn ON dbo.Ports (CountryId, PortNameEn);",
                cancellationToken).ConfigureAwait(false);
        }

        if (await SqlSchemaHelper.TableExistsAsync(connection, "Cities", cancellationToken).ConfigureAwait(false))
        {
            await SqlSchemaHelper.EnsureIndexAsync(
                connection,
                "Cities",
                "IX_Cities_CityName",
                "CREATE INDEX IX_Cities_CityName ON dbo.Cities (CityName);",
                cancellationToken).ConfigureAwait(false);
        }

        if (await SqlSchemaHelper.TableExistsAsync(connection, "Addresses", cancellationToken).ConfigureAwait(false))
        {
            await SqlSchemaHelper.EnsureIndexAsync(
                connection,
                "Addresses",
                "IX_Addresses_UserId_CityId",
                "CREATE INDEX IX_Addresses_UserId_CityId ON dbo.Addresses (UserId, CityId);",
                cancellationToken).ConfigureAwait(false);
        }

        if (await SqlSchemaHelper.TableExistsAsync(connection, "PendingOrderItems", cancellationToken).ConfigureAwait(false))
        {
            await SqlSchemaHelper.EnsureIndexAsync(
                connection,
                "PendingOrderItems",
                "IX_PendingOrderItems_PendingOrderId",
                "CREATE INDEX IX_PendingOrderItems_PendingOrderId ON dbo.PendingOrderItems (PendingOrderId);",
                cancellationToken).ConfigureAwait(false);
        }
    }

    private static async Task EnsureOrderIndexesAsync(
        System.Data.Common.DbConnection connection,
        CancellationToken cancellationToken)
    {
        await SqlSchemaHelper.EnsureIndexAsync(
            connection,
            "Orders",
            "IX_Orders_CreatedAt",
            "CREATE INDEX IX_Orders_CreatedAt ON dbo.Orders (CreatedAt DESC);",
            cancellationToken).ConfigureAwait(false);

        await SqlSchemaHelper.EnsureIndexAsync(
            connection,
            "Orders",
            "IX_Orders_StatusId_CreatedAt",
            "CREATE INDEX IX_Orders_StatusId_CreatedAt ON dbo.Orders (StatusId, CreatedAt DESC);",
            cancellationToken).ConfigureAwait(false);

        await SqlSchemaHelper.EnsureIndexAsync(
            connection,
            "Orders",
            "IX_Orders_ProductId",
            "CREATE INDEX IX_Orders_ProductId ON dbo.Orders (ProductId);",
            cancellationToken).ConfigureAwait(false);

        await SqlSchemaHelper.EnsureIndexAsync(
            connection,
            "Orders",
            "IX_Orders_FromUserId",
            "CREATE INDEX IX_Orders_FromUserId ON dbo.Orders (FromUserId);",
            cancellationToken).ConfigureAwait(false);

        await SqlSchemaHelper.EnsureIndexAsync(
            connection,
            "Orders",
            "IX_Orders_ToUserId",
            "CREATE INDEX IX_Orders_ToUserId ON dbo.Orders (ToUserId);",
            cancellationToken).ConfigureAwait(false);

        await SqlSchemaHelper.EnsureIndexAsync(
            connection,
            "Orders",
            "IX_Orders_PendingOrderId",
            """
            CREATE INDEX IX_Orders_PendingOrderId
                ON dbo.Orders (PendingOrderId)
                WHERE PendingOrderId IS NOT NULL;
            """,
            cancellationToken).ConfigureAwait(false);
    }

    private static async Task EnsureProductIndexesAsync(
        System.Data.Common.DbConnection connection,
        CancellationToken cancellationToken)
    {
        await SqlSchemaHelper.EnsureIndexAsync(
            connection,
            "Products",
            "IX_Products_Status_IsApproved_CreatedAt",
            "CREATE INDEX IX_Products_Status_IsApproved_CreatedAt ON dbo.Products (Status, IsApproved, CreatedAt DESC);",
            cancellationToken).ConfigureAwait(false);

        await SqlSchemaHelper.EnsureIndexAsync(
            connection,
            "Products",
            "IX_Products_IsApproved_CreatedAt",
            "CREATE INDEX IX_Products_IsApproved_CreatedAt ON dbo.Products (IsApproved, CreatedAt DESC);",
            cancellationToken).ConfigureAwait(false);

        await SqlSchemaHelper.EnsureIndexAsync(
            connection,
            "Products",
            "IX_Products_ProductTypeId_Status_CreatedAt",
            "CREATE INDEX IX_Products_ProductTypeId_Status_CreatedAt ON dbo.Products (ProductTypeId, Status, CreatedAt DESC);",
            cancellationToken).ConfigureAwait(false);
    }
}
