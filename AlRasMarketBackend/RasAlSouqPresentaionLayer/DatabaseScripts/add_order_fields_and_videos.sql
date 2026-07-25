-- Adds IsApproved, Notes to Orders; Notes to PendingOrders; creates OrderVideos table.
-- Use GO so SQL Server recompiles after each ALTER (avoids "Invalid column name" at parse time).

IF COL_LENGTH('dbo.Orders', 'IsApproved') IS NULL
    ALTER TABLE dbo.Orders ADD IsApproved BIT NOT NULL CONSTRAINT DF_Orders_IsApproved DEFAULT 0;
GO

IF COL_LENGTH('dbo.Orders', 'Notes') IS NULL
    ALTER TABLE dbo.Orders ADD Notes NVARCHAR(2000) NULL;
GO

IF COL_LENGTH('dbo.PendingOrders', 'Notes') IS NULL
    ALTER TABLE dbo.PendingOrders ADD Notes NVARCHAR(2000) NULL;
GO

-- Retail products (ProductTypeId = 1) are auto-approved on existing orders.
IF COL_LENGTH('dbo.Orders', 'IsApproved') IS NOT NULL
BEGIN
    UPDATE o
    SET o.IsApproved = 1
    FROM dbo.Orders o
    INNER JOIN dbo.Products p ON p.ProductId = o.ProductId
    WHERE p.ProductTypeId = 1
      AND o.IsApproved = 0;
END
GO

IF OBJECT_ID(N'dbo.OrderVideos', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.OrderVideos (
        Id BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        OrderId BIGINT NOT NULL,
        VideoPath NVARCHAR(500) NOT NULL,
        UploadedByUserId UNIQUEIDENTIFIER NOT NULL,
        CreatedAt DATETIME NOT NULL CONSTRAINT DF_OrderVideos_CreatedAt DEFAULT GETUTCDATE(),
        CONSTRAINT FK_OrderVideos_Orders FOREIGN KEY (OrderId) REFERENCES dbo.Orders(Id) ON DELETE CASCADE
    );

    CREATE INDEX IX_OrderVideos_OrderId ON dbo.OrderVideos(OrderId);
END
GO
