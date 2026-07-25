-- International shipping shipment statuses + shipment log
-- InternationalShippingPosts = route posts (existing)
-- InternationalShipments = tracked shipments per provider/order
--
-- OrderId / ProviderUserId types are detected from dbo.Orders.Id and dbo.Users.Id.
-- NOTE: API startup also runs ShippingSchemaMigrator (idempotent, no DROP).

IF OBJECT_ID(N'dbo.ShipmentStatuses', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.ShipmentStatuses (
        Id TINYINT NOT NULL PRIMARY KEY,
        NameEn VARCHAR(50) NOT NULL,
        NameAr NVARCHAR(50) NOT NULL
    );

    INSERT INTO dbo.ShipmentStatuses (Id, NameEn, NameAr) VALUES
        (1, N'Pending', N'قيد الانتظار'),
        (2, N'InDelivery', N'قيد التوصيل'),
        (3, N'Completed', N'مكتمل'),
        (4, N'Late', N'متأخر');
END
ELSE IF NOT EXISTS (SELECT 1 FROM dbo.ShipmentStatuses)
BEGIN
    INSERT INTO dbo.ShipmentStatuses (Id, NameEn, NameAr) VALUES
        (1, N'Pending', N'قيد الانتظار'),
        (2, N'InDelivery', N'قيد التوصيل'),
        (3, N'Completed', N'مكتمل'),
        (4, N'Late', N'متأخر');
END
GO

IF OBJECT_ID(N'dbo.InternationalShipments', N'U') IS NULL
BEGIN
    DECLARE @OrderIdSqlType NVARCHAR(128);
    DECLARE @ProviderUserIdSqlType NVARCHAR(128);

    SELECT @OrderIdSqlType =
        CASE
            WHEN ty.name IN (N'varchar', N'char', N'varbinary', N'binary') THEN
                ty.name + N'(' +
                CASE WHEN c.max_length = -1 THEN N'MAX' ELSE CAST(c.max_length AS NVARCHAR(10)) END + N')'
            WHEN ty.name IN (N'nvarchar', N'nchar') THEN
                ty.name + N'(' +
                CASE WHEN c.max_length = -1 THEN N'MAX' ELSE CAST(c.max_length / 2 AS NVARCHAR(10)) END + N')'
            WHEN ty.name IN (N'decimal', N'numeric') THEN
                ty.name + N'(' + CAST(c.precision AS NVARCHAR(10)) + N',' + CAST(c.scale AS NVARCHAR(10)) + N')'
            ELSE ty.name
        END
    FROM sys.columns AS c
    INNER JOIN sys.types AS ty ON c.user_type_id = ty.user_type_id
    WHERE c.object_id = OBJECT_ID(N'dbo.Orders')
      AND c.name = N'Id';

    SELECT @ProviderUserIdSqlType =
        CASE
            WHEN ty.name IN (N'varchar', N'char', N'varbinary', N'binary') THEN
                ty.name + N'(' +
                CASE WHEN c.max_length = -1 THEN N'MAX' ELSE CAST(c.max_length AS NVARCHAR(10)) END + N')'
            WHEN ty.name IN (N'nvarchar', N'nchar') THEN
                ty.name + N'(' +
                CASE WHEN c.max_length = -1 THEN N'MAX' ELSE CAST(c.max_length / 2 AS NVARCHAR(10)) END + N')'
            WHEN ty.name IN (N'decimal', N'numeric') THEN
                ty.name + N'(' + CAST(c.precision AS NVARCHAR(10)) + N',' + CAST(c.scale AS NVARCHAR(10)) + N')'
            ELSE ty.name
        END
    FROM sys.columns AS c
    INNER JOIN sys.types AS ty ON c.user_type_id = ty.user_type_id
    WHERE c.object_id = OBJECT_ID(N'dbo.Users')
      AND c.name = N'Id';

    IF @OrderIdSqlType IS NULL
    BEGIN
        RAISERROR(N'Column dbo.Orders.Id was not found.', 16, 1);
        RETURN;
    END;

    IF @ProviderUserIdSqlType IS NULL
    BEGIN
        RAISERROR(N'Column dbo.Users.Id was not found.', 16, 1);
        RETURN;
    END;

    DECLARE @CreateShipmentsSql NVARCHAR(MAX) = N'
    CREATE TABLE dbo.InternationalShipments (
        Id BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        ShipmentCode VARCHAR(20) NOT NULL,
        OrderId ' + @OrderIdSqlType + N' NOT NULL,
        ProviderUserId ' + @ProviderUserIdSqlType + N' NOT NULL,
        StatusId TINYINT NOT NULL CONSTRAINT DF_InternationalShipments_StatusId DEFAULT 1,
        CreatedAt DATETIME NOT NULL CONSTRAINT DF_InternationalShipments_CreatedAt DEFAULT GETUTCDATE(),
        UpdatedAt DATETIME NULL,
        CONSTRAINT FK_InternationalShipments_Orders FOREIGN KEY (OrderId) REFERENCES dbo.Orders(Id),
        CONSTRAINT FK_InternationalShipments_ProviderUser FOREIGN KEY (ProviderUserId) REFERENCES dbo.Users(Id),
        CONSTRAINT FK_InternationalShipments_Status FOREIGN KEY (StatusId) REFERENCES dbo.ShipmentStatuses(Id)
    );

    CREATE UNIQUE INDEX IX_InternationalShipments_ShipmentCode
        ON dbo.InternationalShipments(ShipmentCode);

    CREATE INDEX IX_InternationalShipments_ProviderUserId
        ON dbo.InternationalShipments(ProviderUserId);

    CREATE INDEX IX_InternationalShipments_OrderId
        ON dbo.InternationalShipments(OrderId);';

    EXEC sys.sp_executesql @CreateShipmentsSql;
END
GO

-- Sample insert (use real ids from your database):
/*
INSERT INTO dbo.InternationalShipments (ShipmentCode, OrderId, ProviderUserId, StatusId)
SELECT TOP (1) N'S123', o.Id, p.PublisherUserId, 3
FROM dbo.InternationalShippingPosts AS p
CROSS APPLY (SELECT TOP (1) Id FROM dbo.Orders ORDER BY Id DESC) AS o
WHERE NOT EXISTS (SELECT 1 FROM dbo.InternationalShipments s WHERE s.ShipmentCode = N'S123');
*/
