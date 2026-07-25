-- Performance indexes for orders, products, ports, and checkout lookups.
-- Idempotent: safe to run multiple times. API startup also runs QueryPerformanceIndexMigrator.

IF OBJECT_ID(N'dbo.Orders', N'U') IS NOT NULL
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Orders_CreatedAt' AND object_id = OBJECT_ID(N'dbo.Orders'))
        CREATE INDEX IX_Orders_CreatedAt ON dbo.Orders (CreatedAt DESC);

    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Orders_StatusId_CreatedAt' AND object_id = OBJECT_ID(N'dbo.Orders'))
        CREATE INDEX IX_Orders_StatusId_CreatedAt ON dbo.Orders (StatusId, CreatedAt DESC);

    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Orders_ProductId' AND object_id = OBJECT_ID(N'dbo.Orders'))
        CREATE INDEX IX_Orders_ProductId ON dbo.Orders (ProductId);

    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Orders_FromUserId' AND object_id = OBJECT_ID(N'dbo.Orders'))
        CREATE INDEX IX_Orders_FromUserId ON dbo.Orders (FromUserId);

    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Orders_ToUserId' AND object_id = OBJECT_ID(N'dbo.Orders'))
        CREATE INDEX IX_Orders_ToUserId ON dbo.Orders (ToUserId);

    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Orders_PendingOrderId' AND object_id = OBJECT_ID(N'dbo.Orders'))
        CREATE INDEX IX_Orders_PendingOrderId ON dbo.Orders (PendingOrderId) WHERE PendingOrderId IS NOT NULL;
END
GO

IF OBJECT_ID(N'dbo.ProductImages', N'U') IS NOT NULL
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_ProductImages_ProductId' AND object_id = OBJECT_ID(N'dbo.ProductImages'))
        CREATE INDEX IX_ProductImages_ProductId ON dbo.ProductImages (ProductId);
END
GO

IF OBJECT_ID(N'dbo.ProductDocuments', N'U') IS NOT NULL
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_ProductDocuments_ProductId' AND object_id = OBJECT_ID(N'dbo.ProductDocuments'))
        CREATE INDEX IX_ProductDocuments_ProductId ON dbo.ProductDocuments (ProductId);
END
GO

IF OBJECT_ID(N'dbo.Products', N'U') IS NOT NULL
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Products_Status_IsApproved_CreatedAt' AND object_id = OBJECT_ID(N'dbo.Products'))
        CREATE INDEX IX_Products_Status_IsApproved_CreatedAt ON dbo.Products (Status, IsApproved, CreatedAt DESC);

    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Products_IsApproved_CreatedAt' AND object_id = OBJECT_ID(N'dbo.Products'))
        CREATE INDEX IX_Products_IsApproved_CreatedAt ON dbo.Products (IsApproved, CreatedAt DESC);

    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Products_ProductTypeId_Status_CreatedAt' AND object_id = OBJECT_ID(N'dbo.Products'))
        CREATE INDEX IX_Products_ProductTypeId_Status_CreatedAt ON dbo.Products (ProductTypeId, Status, CreatedAt DESC);
END
GO

IF OBJECT_ID(N'dbo.Ports', N'U') IS NOT NULL
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Ports_CountryId_PortNameEn' AND object_id = OBJECT_ID(N'dbo.Ports'))
        CREATE INDEX IX_Ports_CountryId_PortNameEn ON dbo.Ports (CountryId, PortNameEn);
END
GO

IF OBJECT_ID(N'dbo.Cities', N'U') IS NOT NULL
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Cities_CityName' AND object_id = OBJECT_ID(N'dbo.Cities'))
        CREATE INDEX IX_Cities_CityName ON dbo.Cities (CityName);
END
GO

IF OBJECT_ID(N'dbo.Addresses', N'U') IS NOT NULL
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Addresses_UserId_CityId' AND object_id = OBJECT_ID(N'dbo.Addresses'))
        CREATE INDEX IX_Addresses_UserId_CityId ON dbo.Addresses (UserId, CityId);
END
GO

IF OBJECT_ID(N'dbo.PendingOrderItems', N'U') IS NOT NULL
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_PendingOrderItems_PendingOrderId' AND object_id = OBJECT_ID(N'dbo.PendingOrderItems'))
        CREATE INDEX IX_PendingOrderItems_PendingOrderId ON dbo.PendingOrderItems (PendingOrderId);
END
GO
