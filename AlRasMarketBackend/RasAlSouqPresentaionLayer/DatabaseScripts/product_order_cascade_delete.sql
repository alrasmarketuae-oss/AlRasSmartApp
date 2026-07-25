-- Enables cascade delete when a product/ad is removed:
-- Product -> Orders -> (OrderImages, OrderVideos, PendingPayments, InternationalShipments)
-- Product -> PendingOrderItems
-- Run once on production if migrator has not applied yet.

DECLARE @shipmentFk SYSNAME;
SELECT TOP (1) @shipmentFk = fk.name
FROM sys.foreign_keys AS fk
INNER JOIN sys.foreign_key_columns AS fkc ON fk.object_id = fkc.constraint_object_id
WHERE fk.parent_object_id = OBJECT_ID(N'dbo.InternationalShipments')
  AND COL_NAME(fkc.parent_object_id, fkc.parent_column_id) = N'OrderId';

IF @shipmentFk IS NOT NULL
BEGIN
    DECLARE @dropShipmentFk NVARCHAR(400) =
        N'ALTER TABLE dbo.InternationalShipments DROP CONSTRAINT ' + QUOTENAME(@shipmentFk);
    EXEC sp_executesql @dropShipmentFk;
END

IF OBJECT_ID(N'dbo.InternationalShipments', N'U') IS NOT NULL
   AND NOT EXISTS (
        SELECT 1 FROM sys.foreign_keys
        WHERE name = N'FK_InternationalShipments_Orders'
          AND parent_object_id = OBJECT_ID(N'dbo.InternationalShipments')
   )
BEGIN
    ALTER TABLE dbo.InternationalShipments
        ADD CONSTRAINT FK_InternationalShipments_Orders
        FOREIGN KEY (OrderId) REFERENCES dbo.Orders(Id) ON DELETE CASCADE;
END

DECLARE @productFk SYSNAME;
SELECT TOP (1) @productFk = fk.name
FROM sys.foreign_keys AS fk
INNER JOIN sys.foreign_key_columns AS fkc ON fk.object_id = fkc.constraint_object_id
WHERE fk.parent_object_id = OBJECT_ID(N'dbo.Orders')
  AND COL_NAME(fkc.parent_object_id, fkc.parent_column_id) = N'ProductId';

IF @productFk IS NOT NULL
BEGIN
    DECLARE @dropProductFk NVARCHAR(400) =
        N'ALTER TABLE dbo.Orders DROP CONSTRAINT ' + QUOTENAME(@productFk);
    EXEC sp_executesql @dropProductFk;
END

IF NOT EXISTS (
    SELECT 1 FROM sys.foreign_keys
    WHERE name = N'FK_Orders_Products'
      AND parent_object_id = OBJECT_ID(N'dbo.Orders')
)
BEGIN
    ALTER TABLE dbo.Orders
        ADD CONSTRAINT FK_Orders_Products
        FOREIGN KEY (ProductId) REFERENCES dbo.Products(ProductId) ON DELETE CASCADE;
END

IF OBJECT_ID(N'dbo.PendingOrderItems', N'U') IS NOT NULL
BEGIN
    DECLARE @pendingItemFk SYSNAME;
    SELECT TOP (1) @pendingItemFk = fk.name
    FROM sys.foreign_keys AS fk
    INNER JOIN sys.foreign_key_columns AS fkc ON fk.object_id = fkc.constraint_object_id
    WHERE fk.parent_object_id = OBJECT_ID(N'dbo.PendingOrderItems')
      AND COL_NAME(fkc.parent_object_id, fkc.parent_column_id) = N'ProductId';

    IF @pendingItemFk IS NOT NULL
    BEGIN
        DECLARE @dropPendingItemFk NVARCHAR(400) =
            N'ALTER TABLE dbo.PendingOrderItems DROP CONSTRAINT ' + QUOTENAME(@pendingItemFk);
        EXEC sp_executesql @dropPendingItemFk;
    END

    IF NOT EXISTS (
        SELECT 1 FROM sys.foreign_keys
        WHERE name = N'FK_PendingOrderItems_Products'
          AND parent_object_id = OBJECT_ID(N'dbo.PendingOrderItems')
    )
    BEGIN
        ALTER TABLE dbo.PendingOrderItems
            ADD CONSTRAINT FK_PendingOrderItems_Products
            FOREIGN KEY (ProductId) REFERENCES dbo.Products(ProductId) ON DELETE CASCADE;
    END
END
