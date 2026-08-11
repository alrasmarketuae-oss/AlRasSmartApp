using DataLayer.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace DataLayer.Seeding;

/// <summary>Adds Orders.IsApproved/Notes, PendingOrders.Notes, OrderVideos, OrderImages if missing.</summary>
public static class OrderSchemaMigrator
{
    public static async Task EnsureAsync(IRasAlSouqDbContext db, CancellationToken cancellationToken = default)
    {
        var context = (DbContext)db;
        var connection = context.Database.GetDbConnection();
        await SqlSchemaHelper.OpenIfNeededAsync(connection, cancellationToken).ConfigureAwait(false);

        await EnsureOrderStatusesAsync(connection, cancellationToken).ConfigureAwait(false);

        if (!await SqlSchemaHelper.ColumnExistsAsync(connection, "Orders", "IsApproved", cancellationToken)
            .ConfigureAwait(false))
        {
            await SqlSchemaHelper.ExecuteBatchAsync(connection,
                "ALTER TABLE dbo.Orders ADD IsApproved BIT NOT NULL CONSTRAINT DF_Orders_IsApproved DEFAULT 0;",
                cancellationToken).ConfigureAwait(false);
        }

        if (!await SqlSchemaHelper.ColumnExistsAsync(connection, "Orders", "IsAdminApproved", cancellationToken)
            .ConfigureAwait(false))
        {
            await SqlSchemaHelper.ExecuteBatchAsync(connection,
                "ALTER TABLE dbo.Orders ADD IsAdminApproved BIT NOT NULL CONSTRAINT DF_Orders_IsAdminApproved DEFAULT 0;",
                cancellationToken).ConfigureAwait(false);
        }

        if (!await SqlSchemaHelper.ColumnExistsAsync(connection, "Orders", "Notes", cancellationToken)
            .ConfigureAwait(false))
        {
            await SqlSchemaHelper.ExecuteBatchAsync(connection,
                "ALTER TABLE dbo.Orders ADD Notes NVARCHAR(2000) NULL;",
                cancellationToken).ConfigureAwait(false);
        }

        if (!await SqlSchemaHelper.ColumnExistsAsync(connection, "Orders", "CustomStatusNameEn", cancellationToken)
            .ConfigureAwait(false))
        {
            await SqlSchemaHelper.ExecuteBatchAsync(connection,
                "ALTER TABLE dbo.Orders ADD CustomStatusNameEn NVARCHAR(200) NULL;",
                cancellationToken).ConfigureAwait(false);
        }

        if (!await SqlSchemaHelper.ColumnExistsAsync(connection, "Orders", "CustomStatusNameAr", cancellationToken)
            .ConfigureAwait(false))
        {
            await SqlSchemaHelper.ExecuteBatchAsync(connection,
                "ALTER TABLE dbo.Orders ADD CustomStatusNameAr NVARCHAR(200) NULL;",
                cancellationToken).ConfigureAwait(false);
        }

        if (!await SqlSchemaHelper.ColumnExistsAsync(connection, "Orders", "StockQuantityDeducted", cancellationToken)
            .ConfigureAwait(false))
        {
            await SqlSchemaHelper.ExecuteBatchAsync(connection,
                "ALTER TABLE dbo.Orders ADD StockQuantityDeducted BIT NOT NULL CONSTRAINT DF_Orders_StockQuantityDeducted DEFAULT 0;",
                cancellationToken).ConfigureAwait(false);
        }

        if (!await SqlSchemaHelper.ColumnExistsAsync(connection, "Orders", "PortId", cancellationToken)
            .ConfigureAwait(false))
        {
            await SqlSchemaHelper.ExecuteBatchAsync(connection, """
                IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.Orders') AND name = N'PortId')
                BEGIN
                    ALTER TABLE dbo.Orders ADD PortId INT NULL;
                    IF EXISTS (SELECT 1 FROM sys.tables WHERE name = N'Ports')
                        ALTER TABLE dbo.Orders ADD CONSTRAINT FK_Orders_Ports FOREIGN KEY (PortId) REFERENCES dbo.Ports(Id);
                END
                """, cancellationToken).ConfigureAwait(false);
        }

        if (!await SqlSchemaHelper.ColumnExistsAsync(connection, "Orders", "StripeRefundId", cancellationToken)
            .ConfigureAwait(false))
        {
            await SqlSchemaHelper.ExecuteBatchAsync(connection,
                "ALTER TABLE dbo.Orders ADD StripeRefundId NVARCHAR(128) NULL;",
                cancellationToken).ConfigureAwait(false);
        }

        if (!await SqlSchemaHelper.ColumnExistsAsync(connection, "Orders", "RefundedAtUtc", cancellationToken)
            .ConfigureAwait(false))
        {
            await SqlSchemaHelper.ExecuteBatchAsync(connection,
                "ALTER TABLE dbo.Orders ADD RefundedAtUtc DATETIME2 NULL;",
                cancellationToken).ConfigureAwait(false);
        }

        if (await SqlSchemaHelper.ColumnExistsAsync(connection, "Orders", "StockQuantityDeducted", cancellationToken)
            .ConfigureAwait(false))
        {
            await SqlSchemaHelper.ExecuteBatchAsync(connection, """
                UPDATE o
                SET o.StockQuantityDeducted = 1
                FROM dbo.Orders o
                INNER JOIN dbo.Products p ON p.ProductId = o.ProductId
                WHERE p.ProductTypeId = 2
                  AND o.StockQuantityDeducted = 0
                  AND o.PendingOrderId IS NULL;
                """, cancellationToken).ConfigureAwait(false);
        }

        if (await SqlSchemaHelper.TableExistsAsync(connection, "PendingOrders", cancellationToken).ConfigureAwait(false)
            && !await SqlSchemaHelper.ColumnExistsAsync(connection, "PendingOrders", "Notes", cancellationToken)
                .ConfigureAwait(false))
        {
            await SqlSchemaHelper.ExecuteBatchAsync(connection,
                "ALTER TABLE dbo.PendingOrders ADD Notes NVARCHAR(2000) NULL;",
                cancellationToken).ConfigureAwait(false);
        }

        if (await SqlSchemaHelper.ColumnExistsAsync(connection, "Orders", "IsApproved", cancellationToken)
            .ConfigureAwait(false))
        {
            await SqlSchemaHelper.ExecuteBatchAsync(connection, """
                UPDATE o
                SET o.IsApproved = 0
                FROM dbo.Orders o
                INNER JOIN dbo.Products p ON p.ProductId = o.ProductId
                WHERE p.ProductTypeId IN (2, 3, 4)
                  AND o.IsApproved = 1
                  AND o.StatusId IN (1, 11)
                  AND o.StockQuantityDeducted = 0;
                """, cancellationToken).ConfigureAwait(false);
        }

        if (await SqlSchemaHelper.ColumnExistsAsync(connection, "Orders", "IsAdminApproved", cancellationToken)
            .ConfigureAwait(false))
        {
            await SqlSchemaHelper.ExecuteBatchAsync(connection, """
                UPDATE o
                SET o.StatusId = 11
                FROM dbo.Orders o
                INNER JOIN dbo.Products p ON p.ProductId = o.ProductId
                WHERE p.ProductTypeId IN (2, 3, 4)
                  AND o.IsAdminApproved = 1
                  AND o.IsApproved = 0
                  AND o.StatusId = 1;
                """, cancellationToken).ConfigureAwait(false);
        }

        if (!await SqlSchemaHelper.TableExistsAsync(connection, "OrderVideos", cancellationToken).ConfigureAwait(false))
        {
            await CreateOrderAssetTableAsync(
                connection,
                "OrderVideos",
                "DF_OrderVideos_CreatedAt",
                "FK_OrderVideos_Orders",
                "IX_OrderVideos_OrderId",
                cancellationToken).ConfigureAwait(false);
        }

        if (!await SqlSchemaHelper.TableExistsAsync(connection, "OrderImages", cancellationToken).ConfigureAwait(false))
        {
            await CreateOrderAssetTableAsync(
                connection,
                "OrderImages",
                "DF_OrderImages_CreatedAt",
                "FK_OrderImages_Orders",
                "IX_OrderImages_OrderId",
                cancellationToken).ConfigureAwait(false);
        }

        await EnsureOrderStatusHistoriesAsync(connection, cancellationToken).ConfigureAwait(false);

        var quantityType = await SqlSchemaHelper.GetColumnSqlTypeAsync(connection, "Orders", "Quantity", cancellationToken)
            .ConfigureAwait(false);
        if (quantityType is not null
            && !quantityType.Contains("decimal", StringComparison.OrdinalIgnoreCase))
        {
            await SqlSchemaHelper.ExecuteBatchAsync(connection,
                "ALTER TABLE dbo.Orders ALTER COLUMN Quantity DECIMAL(18,3) NOT NULL;",
                cancellationToken).ConfigureAwait(false);
        }

        // Offer totals can exceed decimal(8,2) (max 999,999.99) — widen money columns.
        await WidenOrdersMoneyColumnAsync(connection, "UnitPrice", cancellationToken).ConfigureAwait(false);
        await WidenOrdersMoneyColumnAsync(connection, "TotalPrice", cancellationToken).ConfigureAwait(false);
    }

    private static async Task WidenOrdersMoneyColumnAsync(
        System.Data.Common.DbConnection connection,
        string columnName,
        CancellationToken cancellationToken)
    {
        var sqlType = await SqlSchemaHelper.GetColumnSqlTypeAsync(connection, "Orders", columnName, cancellationToken)
            .ConfigureAwait(false);
        if (sqlType is null)
        {
            return;
        }

        // Already wide enough (precision >= 12).
        if (sqlType.Contains("decimal(18", StringComparison.OrdinalIgnoreCase)
            || sqlType.Contains("decimal(16", StringComparison.OrdinalIgnoreCase)
            || sqlType.Contains("decimal(14", StringComparison.OrdinalIgnoreCase)
            || sqlType.Contains("decimal(12", StringComparison.OrdinalIgnoreCase))
        {
            return;
        }

        await SqlSchemaHelper.ExecuteBatchAsync(connection,
            $"ALTER TABLE dbo.Orders ALTER COLUMN [{columnName}] DECIMAL(18,2) NOT NULL;",
            cancellationToken).ConfigureAwait(false);
    }

    private static async Task EnsureOrderStatusHistoriesAsync(
        System.Data.Common.DbConnection connection,
        CancellationToken cancellationToken)
    {
        if (!await SqlSchemaHelper.TableExistsAsync(connection, "OrderStatusHistories", cancellationToken)
            .ConfigureAwait(false))
        {
            var orderIdType = await SqlSchemaHelper.GetColumnSqlTypeAsync(connection, "Orders", "Id", cancellationToken)
                .ConfigureAwait(false);
            var userIdType = await SqlSchemaHelper.GetColumnSqlTypeAsync(connection, "Users", "Id", cancellationToken)
                .ConfigureAwait(false);

            if (orderIdType is null || userIdType is null)
            {
                throw new InvalidOperationException(
                    "Cannot create OrderStatusHistories: dbo.Orders.Id or dbo.Users.Id was not found.");
            }

            var sql = string.Format(
                """
                CREATE TABLE dbo.OrderStatusHistories (
                    Id BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
                    OrderId {0} NOT NULL,
                    StatusId TINYINT NOT NULL,
                    StatusNameEn NVARCHAR(200) NOT NULL,
                    StatusNameAr NVARCHAR(200) NOT NULL,
                    CreatedAtUtc DATETIME2 NOT NULL CONSTRAINT DF_OrderStatusHistories_CreatedAtUtc DEFAULT GETUTCDATE(),
                    CreatedByUserId {1} NULL,
                    CONSTRAINT FK_OrderStatusHistories_Orders FOREIGN KEY (OrderId) REFERENCES dbo.Orders(Id) ON DELETE CASCADE
                );

                CREATE INDEX IX_OrderStatusHistories_OrderId ON dbo.OrderStatusHistories(OrderId);
                CREATE INDEX IX_OrderStatusHistories_OrderId_CreatedAtUtc ON dbo.OrderStatusHistories(OrderId, CreatedAtUtc);
                """,
                orderIdType,
                userIdType);

            await SqlSchemaHelper.ExecuteBatchAsync(connection, sql, cancellationToken).ConfigureAwait(false);
        }

        // Seed one history row from the current custom label so existing orders keep a visible trail.
        await SqlSchemaHelper.ExecuteBatchAsync(connection, """
            INSERT INTO dbo.OrderStatusHistories (OrderId, StatusId, StatusNameEn, StatusNameAr, CreatedAtUtc, CreatedByUserId)
            SELECT o.Id,
                   o.StatusId,
                   COALESCE(NULLIF(LTRIM(RTRIM(o.CustomStatusNameEn)), N''), N'Status update'),
                   COALESCE(NULLIF(LTRIM(RTRIM(o.CustomStatusNameAr)), N''), N'تحديث الحالة'),
                   COALESCE(o.CreatedAt, GETUTCDATE()),
                   NULL
            FROM dbo.Orders o
            WHERE (
                    (o.CustomStatusNameEn IS NOT NULL AND LTRIM(RTRIM(o.CustomStatusNameEn)) <> N'')
                 OR (o.CustomStatusNameAr IS NOT NULL AND LTRIM(RTRIM(o.CustomStatusNameAr)) <> N'')
                  )
              AND NOT EXISTS (
                    SELECT 1 FROM dbo.OrderStatusHistories h WHERE h.OrderId = o.Id
                  );
            """, cancellationToken).ConfigureAwait(false);
    }

    private static async Task CreateOrderAssetTableAsync(
        System.Data.Common.DbConnection connection,
        string tableName,
        string createdAtDefaultName,
        string ordersFkName,
        string orderIdIndexName,
        CancellationToken cancellationToken)
    {
        var orderIdType = await SqlSchemaHelper.GetColumnSqlTypeAsync(connection, "Orders", "Id", cancellationToken)
            .ConfigureAwait(false);
        var userIdType = await SqlSchemaHelper.GetColumnSqlTypeAsync(connection, "Users", "Id", cancellationToken)
            .ConfigureAwait(false);

        if (orderIdType is null || userIdType is null)
        {
            throw new InvalidOperationException(
                $"Cannot create {tableName}: dbo.Orders.Id or dbo.Users.Id was not found.");
        }

        var pathColumn = tableName == "OrderVideos" ? "VideoPath" : "ImagePath";
        var sql = string.Format(
            """
            CREATE TABLE dbo.{0} (
                Id BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
                OrderId {1} NOT NULL,
                {2} NVARCHAR(500) NOT NULL,
                UploadedByUserId {3} NOT NULL,
                CreatedAt DATETIME NOT NULL CONSTRAINT {4} DEFAULT GETUTCDATE(),
                CONSTRAINT {5} FOREIGN KEY (OrderId) REFERENCES dbo.Orders(Id) ON DELETE CASCADE
            );

            CREATE INDEX {6} ON dbo.{0}(OrderId);
            """,
            tableName,
            orderIdType,
            pathColumn,
            userIdType,
            createdAtDefaultName,
            ordersFkName,
            orderIdIndexName);

        await SqlSchemaHelper.ExecuteBatchAsync(connection, sql, cancellationToken).ConfigureAwait(false);
    }

    /// <summary>Ensures OrderStatus Ids 1–6 exist (FK_Orders_Status).</summary>
    private static async Task EnsureOrderStatusesAsync(
        System.Data.Common.DbConnection connection,
        CancellationToken cancellationToken)
    {
        if (!await SqlSchemaHelper.TableExistsAsync(connection, "OrderStatus", cancellationToken).ConfigureAwait(false))
        {
            return;
        }

        await SqlSchemaHelper.ExecuteBatchAsync(connection, """
            SET IDENTITY_INSERT dbo.OrderStatus ON;

            IF NOT EXISTS (SELECT 1 FROM dbo.OrderStatus WHERE Id = 1)
                INSERT INTO dbo.OrderStatus (Id, Name) VALUES (1, N'Ordered');
            ELSE
                UPDATE dbo.OrderStatus SET Name = N'Ordered' WHERE Id = 1;

            IF NOT EXISTS (SELECT 1 FROM dbo.OrderStatus WHERE Id = 2)
                INSERT INTO dbo.OrderStatus (Id, Name) VALUES (2, N'Approved');
            ELSE
                UPDATE dbo.OrderStatus SET Name = N'Approved' WHERE Id = 2;

            IF NOT EXISTS (SELECT 1 FROM dbo.OrderStatus WHERE Id = 3)
                INSERT INTO dbo.OrderStatus (Id, Name) VALUES (3, N'Paid');
            ELSE
                UPDATE dbo.OrderStatus SET Name = N'Paid' WHERE Id = 3;

            IF NOT EXISTS (SELECT 1 FROM dbo.OrderStatus WHERE Id = 4)
                INSERT INTO dbo.OrderStatus (Id, Name) VALUES (4, N'Shipping');
            ELSE
                UPDATE dbo.OrderStatus SET Name = N'Shipping' WHERE Id = 4;

            IF NOT EXISTS (SELECT 1 FROM dbo.OrderStatus WHERE Id = 5)
                INSERT INTO dbo.OrderStatus (Id, Name) VALUES (5, N'Delivered');
            ELSE
                UPDATE dbo.OrderStatus SET Name = N'Delivered' WHERE Id = 5;

            IF NOT EXISTS (SELECT 1 FROM dbo.OrderStatus WHERE Id = 6)
                INSERT INTO dbo.OrderStatus (Id, Name) VALUES (6, N'Cancelled');
            ELSE
                UPDATE dbo.OrderStatus SET Name = N'Cancelled' WHERE Id = 6;

            IF NOT EXISTS (SELECT 1 FROM dbo.OrderStatus WHERE Id = 7)
                INSERT INTO dbo.OrderStatus (Id, Name) VALUES (7, N'Delivered');
            ELSE
                UPDATE dbo.OrderStatus SET Name = N'Delivered' WHERE Id = 7;

            -- Legacy Received (7) is the same business state as Delivered (5).
            UPDATE dbo.Orders SET StatusId = 5 WHERE StatusId = 7;

            IF NOT EXISTS (SELECT 1 FROM dbo.OrderStatus WHERE Id = 8)
                INSERT INTO dbo.OrderStatus (Id, Name) VALUES (8, N'PaidToSupplier');
            ELSE
                UPDATE dbo.OrderStatus SET Name = N'PaidToSupplier' WHERE Id = 8;

            IF NOT EXISTS (SELECT 1 FROM dbo.OrderStatus WHERE Id = 9)
                INSERT INTO dbo.OrderStatus (Id, Name) VALUES (9, N'ReturnRequested');
            ELSE
                UPDATE dbo.OrderStatus SET Name = N'ReturnRequested' WHERE Id = 9;

            IF NOT EXISTS (SELECT 1 FROM dbo.OrderStatus WHERE Id = 10)
                INSERT INTO dbo.OrderStatus (Id, Name) VALUES (10, N'ReturnApproved');
            ELSE
                UPDATE dbo.OrderStatus SET Name = N'ReturnApproved' WHERE Id = 10;

            IF NOT EXISTS (SELECT 1 FROM dbo.OrderStatus WHERE Id = 11)
                INSERT INTO dbo.OrderStatus (Id, Name) VALUES (11, N'AwaitingSellerApproval');
            ELSE
                UPDATE dbo.OrderStatus SET Name = N'AwaitingSellerApproval' WHERE Id = 11;

            SET IDENTITY_INSERT dbo.OrderStatus OFF;
            """, cancellationToken).ConfigureAwait(false);

        await EnsureOrderReturnColumnsAsync(connection, cancellationToken).ConfigureAwait(false);

        if (!await SqlSchemaHelper.ColumnExistsAsync(connection, "PendingOrders", "CheckoutCurrency", cancellationToken)
                .ConfigureAwait(false))
        {
            await SqlSchemaHelper.ExecuteBatchAsync(connection,
                "ALTER TABLE dbo.PendingOrders ADD CheckoutCurrency NVARCHAR(3) NULL;",
                cancellationToken).ConfigureAwait(false);
        }

        if (!await SqlSchemaHelper.ColumnExistsAsync(connection, "PendingOrders", "CheckoutAmount", cancellationToken)
                .ConfigureAwait(false))
        {
            await SqlSchemaHelper.ExecuteBatchAsync(connection,
                "ALTER TABLE dbo.PendingOrders ADD CheckoutAmount DECIMAL(12,2) NULL;",
                cancellationToken).ConfigureAwait(false);
        }

        if (!await SqlSchemaHelper.ColumnExistsAsync(connection, "PendingOrders", "SubtotalAed", cancellationToken)
                .ConfigureAwait(false))
        {
            await SqlSchemaHelper.ExecuteBatchAsync(connection,
                "ALTER TABLE dbo.PendingOrders ADD SubtotalAed DECIMAL(12,2) NOT NULL CONSTRAINT DF_PendingOrders_SubtotalAed DEFAULT 0;",
                cancellationToken).ConfigureAwait(false);
        }

        if (!await SqlSchemaHelper.ColumnExistsAsync(connection, "PendingOrders", "VatAed", cancellationToken)
                .ConfigureAwait(false))
        {
            await SqlSchemaHelper.ExecuteBatchAsync(connection,
                "ALTER TABLE dbo.PendingOrders ADD VatAed DECIMAL(12,2) NOT NULL CONSTRAINT DF_PendingOrders_VatAed DEFAULT 0;",
                cancellationToken).ConfigureAwait(false);
        }

        if (!await SqlSchemaHelper.ColumnExistsAsync(connection, "Orders", "VatAed", cancellationToken)
            .ConfigureAwait(false))
        {
            await SqlSchemaHelper.ExecuteBatchAsync(connection,
                "ALTER TABLE dbo.Orders ADD VatAed DECIMAL(12,2) NOT NULL CONSTRAINT DF_Orders_VatAed DEFAULT 0;",
                cancellationToken).ConfigureAwait(false);
        }

        if (!await SqlSchemaHelper.ColumnExistsAsync(connection, "Orders", "ShippingCostAed", cancellationToken)
            .ConfigureAwait(false))
        {
            await SqlSchemaHelper.ExecuteBatchAsync(connection,
                "ALTER TABLE dbo.Orders ADD ShippingCostAed DECIMAL(12,2) NOT NULL CONSTRAINT DF_Orders_ShippingCostAed DEFAULT 0;",
                cancellationToken).ConfigureAwait(false);
        }

        if (!await SqlSchemaHelper.ColumnExistsAsync(connection, "Orders", "IsSelfPickup", cancellationToken)
            .ConfigureAwait(false))
        {
            await SqlSchemaHelper.ExecuteBatchAsync(connection,
                "ALTER TABLE dbo.Orders ADD IsSelfPickup BIT NOT NULL CONSTRAINT DF_Orders_IsSelfPickup DEFAULT 0;",
                cancellationToken).ConfigureAwait(false);
        }

        if (!await SqlSchemaHelper.ColumnExistsAsync(connection, "Orders", "DeliveryAddressLine", cancellationToken)
            .ConfigureAwait(false))
        {
            await SqlSchemaHelper.ExecuteBatchAsync(connection,
                "ALTER TABLE dbo.Orders ADD DeliveryAddressLine NVARCHAR(500) NULL;",
                cancellationToken).ConfigureAwait(false);
        }

        if (!await SqlSchemaHelper.ColumnExistsAsync(connection, "Orders", "DeliveryCityName", cancellationToken)
            .ConfigureAwait(false))
        {
            await SqlSchemaHelper.ExecuteBatchAsync(connection,
                "ALTER TABLE dbo.Orders ADD DeliveryCityName NVARCHAR(200) NULL;",
                cancellationToken).ConfigureAwait(false);
        }

        if (!await SqlSchemaHelper.ColumnExistsAsync(connection, "PendingOrders", "IsSelfPickup", cancellationToken)
            .ConfigureAwait(false))
        {
            await SqlSchemaHelper.ExecuteBatchAsync(connection,
                "ALTER TABLE dbo.PendingOrders ADD IsSelfPickup BIT NOT NULL CONSTRAINT DF_PendingOrders_IsSelfPickup DEFAULT 0;",
                cancellationToken).ConfigureAwait(false);
        }

        if (!await SqlSchemaHelper.ColumnExistsAsync(connection, "PendingOrders", "DeliveryAddressLine", cancellationToken)
            .ConfigureAwait(false))
        {
            await SqlSchemaHelper.ExecuteBatchAsync(connection,
                "ALTER TABLE dbo.PendingOrders ADD DeliveryAddressLine NVARCHAR(500) NULL;",
                cancellationToken).ConfigureAwait(false);
        }

        if (!await SqlSchemaHelper.ColumnExistsAsync(connection, "PendingOrders", "DeliveryCityName", cancellationToken)
            .ConfigureAwait(false))
        {
            await SqlSchemaHelper.ExecuteBatchAsync(connection,
                "ALTER TABLE dbo.PendingOrders ADD DeliveryCityName NVARCHAR(200) NULL;",
                cancellationToken).ConfigureAwait(false);
        }

        await EnsureProductOrderCascadeDeleteAsync(connection, cancellationToken).ConfigureAwait(false);
    }

    private static async Task EnsureProductOrderCascadeDeleteAsync(
        System.Data.Common.DbConnection connection,
        CancellationToken cancellationToken)
    {
        const string recreateProductFkSql = """
            DECLARE @productFk SYSNAME;
            SELECT TOP (1) @productFk = fk.name
            FROM sys.foreign_keys AS fk
            INNER JOIN sys.foreign_key_columns AS fkc ON fk.object_id = fkc.constraint_object_id
            WHERE fk.parent_object_id = OBJECT_ID(N'dbo.Orders')
              AND COL_NAME(fkc.parent_object_id, fkc.parent_column_id) = N'ProductId';

            IF @productFk IS NOT NULL
               AND NOT EXISTS (
                    SELECT 1
                    FROM sys.foreign_keys AS fk
                    INNER JOIN sys.foreign_key_columns AS fkc ON fk.object_id = fkc.constraint_object_id
                    WHERE fk.parent_object_id = OBJECT_ID(N'dbo.Orders')
                      AND COL_NAME(fkc.parent_object_id, fkc.parent_column_id) = N'ProductId'
                      AND fk.delete_referential_action = 1
               )
            BEGIN
                DECLARE @dropProductFk NVARCHAR(400) =
                    N'ALTER TABLE dbo.Orders DROP CONSTRAINT ' + QUOTENAME(@productFk);
                EXEC sp_executesql @dropProductFk;

                ALTER TABLE dbo.Orders
                    ADD CONSTRAINT FK_Orders_Products
                    FOREIGN KEY (ProductId) REFERENCES dbo.Products(ProductId) ON DELETE CASCADE;
            END
            """;

        const string recreateShipmentFkSql = """
            DECLARE @shipmentFk SYSNAME;
            SELECT TOP (1) @shipmentFk = fk.name
            FROM sys.foreign_keys AS fk
            INNER JOIN sys.foreign_key_columns AS fkc ON fk.object_id = fkc.constraint_object_id
            WHERE fk.parent_object_id = OBJECT_ID(N'dbo.InternationalShipments')
              AND COL_NAME(fkc.parent_object_id, fkc.parent_column_id) = N'OrderId';

            IF @shipmentFk IS NOT NULL
               AND NOT EXISTS (
                    SELECT 1
                    FROM sys.foreign_keys AS fk
                    INNER JOIN sys.foreign_key_columns AS fkc ON fk.object_id = fkc.constraint_object_id
                    WHERE fk.parent_object_id = OBJECT_ID(N'dbo.InternationalShipments')
                      AND COL_NAME(fkc.parent_object_id, fkc.parent_column_id) = N'OrderId'
                      AND fk.delete_referential_action = 1
               )
            BEGIN
                DECLARE @dropShipmentFk NVARCHAR(400) =
                    N'ALTER TABLE dbo.InternationalShipments DROP CONSTRAINT ' + QUOTENAME(@shipmentFk);
                EXEC sp_executesql @dropShipmentFk;

                ALTER TABLE dbo.InternationalShipments
                    ADD CONSTRAINT FK_InternationalShipments_Orders
                    FOREIGN KEY (OrderId) REFERENCES dbo.Orders(Id) ON DELETE CASCADE;
            END
            """;

        const string recreatePendingItemFkSql = """
            IF OBJECT_ID(N'dbo.PendingOrderItems', N'U') IS NOT NULL
            BEGIN
                DECLARE @pendingItemFk SYSNAME;
                SELECT TOP (1) @pendingItemFk = fk.name
                FROM sys.foreign_keys AS fk
                INNER JOIN sys.foreign_key_columns AS fkc ON fk.object_id = fkc.constraint_object_id
                WHERE fk.parent_object_id = OBJECT_ID(N'dbo.PendingOrderItems')
                  AND COL_NAME(fkc.parent_object_id, fkc.parent_column_id) = N'ProductId';

                IF @pendingItemFk IS NOT NULL
                   AND NOT EXISTS (
                        SELECT 1
                        FROM sys.foreign_keys AS fk
                        INNER JOIN sys.foreign_key_columns AS fkc ON fk.object_id = fkc.constraint_object_id
                        WHERE fk.parent_object_id = OBJECT_ID(N'dbo.PendingOrderItems')
                          AND COL_NAME(fkc.parent_object_id, fkc.parent_column_id) = N'ProductId'
                          AND fk.delete_referential_action = 1
                   )
                BEGIN
                    DECLARE @dropPendingItemFk NVARCHAR(400) =
                        N'ALTER TABLE dbo.PendingOrderItems DROP CONSTRAINT ' + QUOTENAME(@pendingItemFk);
                    EXEC sp_executesql @dropPendingItemFk;

                    ALTER TABLE dbo.PendingOrderItems
                        ADD CONSTRAINT FK_PendingOrderItems_Products
                        FOREIGN KEY (ProductId) REFERENCES dbo.Products(ProductId) ON DELETE CASCADE;
                END
            END
            """;

        await SqlSchemaHelper.ExecuteBatchAsync(connection, recreateShipmentFkSql, cancellationToken)
            .ConfigureAwait(false);
        await SqlSchemaHelper.ExecuteBatchAsync(connection, recreateProductFkSql, cancellationToken)
            .ConfigureAwait(false);
        await SqlSchemaHelper.ExecuteBatchAsync(connection, recreatePendingItemFkSql, cancellationToken)
            .ConfigureAwait(false);
    }

    private static async Task EnsureOrderReturnColumnsAsync(
        System.Data.Common.DbConnection connection,
        CancellationToken cancellationToken)
    {
        if (!await SqlSchemaHelper.ColumnExistsAsync(connection, "Orders", "ReturnReason", cancellationToken)
            .ConfigureAwait(false))
        {
            await SqlSchemaHelper.ExecuteBatchAsync(connection,
                "ALTER TABLE dbo.Orders ADD ReturnReason NVARCHAR(2000) NULL;",
                cancellationToken).ConfigureAwait(false);
        }

        if (!await SqlSchemaHelper.ColumnExistsAsync(connection, "Orders", "ReturnMediaPathsJson", cancellationToken)
            .ConfigureAwait(false))
        {
            await SqlSchemaHelper.ExecuteBatchAsync(connection,
                "ALTER TABLE dbo.Orders ADD ReturnMediaPathsJson NVARCHAR(4000) NULL;",
                cancellationToken).ConfigureAwait(false);
        }

        if (!await SqlSchemaHelper.ColumnExistsAsync(connection, "Orders", "ReturnRequestedAtUtc", cancellationToken)
            .ConfigureAwait(false))
        {
            await SqlSchemaHelper.ExecuteBatchAsync(connection,
                "ALTER TABLE dbo.Orders ADD ReturnRequestedAtUtc DATETIME2 NULL;",
                cancellationToken).ConfigureAwait(false);
        }

        if (!await SqlSchemaHelper.ColumnExistsAsync(connection, "Orders", "ReturnAdminResponse", cancellationToken)
            .ConfigureAwait(false))
        {
            await SqlSchemaHelper.ExecuteBatchAsync(connection,
                "ALTER TABLE dbo.Orders ADD ReturnAdminResponse NVARCHAR(2000) NULL;",
                cancellationToken).ConfigureAwait(false);
        }

        if (!await SqlSchemaHelper.ColumnExistsAsync(connection, "Orders", "ReturnRespondedAtUtc", cancellationToken)
            .ConfigureAwait(false))
        {
            await SqlSchemaHelper.ExecuteBatchAsync(connection,
                "ALTER TABLE dbo.Orders ADD ReturnRespondedAtUtc DATETIME2 NULL;",
                cancellationToken).ConfigureAwait(false);
        }

        if (!await SqlSchemaHelper.TableExistsAsync(connection, "OrderAdminOfferPrices", cancellationToken)
            .ConfigureAwait(false))
        {
            await SqlSchemaHelper.ExecuteBatchAsync(connection, """
                CREATE TABLE dbo.OrderAdminOfferPrices
                (
                    OrderId BIGINT NOT NULL CONSTRAINT PK_OrderAdminOfferPrices PRIMARY KEY,
                    AdminUnitPrice DECIMAL(18,2) NOT NULL,
                    AdminTotalPrice DECIMAL(18,2) NOT NULL,
                    UpdatedAtUtc DATETIME2 NOT NULL CONSTRAINT DF_OrderAdminOfferPrices_UpdatedAtUtc DEFAULT (SYSUTCDATETIME()),
                    UpdatedByAdminUserId UNIQUEIDENTIFIER NULL,
                    CONSTRAINT FK_OrderAdminOfferPrices_Orders
                        FOREIGN KEY (OrderId) REFERENCES dbo.Orders(Id) ON DELETE CASCADE
                );
                """, cancellationToken).ConfigureAwait(false);
        }
    }
}
