-- Stripe checkout tables for Ras Al Souq (run once on production DB)
IF OBJECT_ID(N'dbo.PendingOrders', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.PendingOrders (
        Id UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
        FromUserId UNIQUEIDENTIFIER NOT NULL,
        AddressId UNIQUEIDENTIFIER NULL,
        ShippingCostAed DECIMAL(12,2) NOT NULL DEFAULT 0,
        TotalPriceUsd DECIMAL(12,2) NOT NULL,
        TotalPriceAed DECIMAL(12,2) NOT NULL,
        PaymentMethod TINYINT NOT NULL DEFAULT 1,
        StripeSessionId NVARCHAR(255) NULL,
        PaymentIntentId NVARCHAR(255) NULL,
        StripeRefundId NVARCHAR(255) NULL,
        RefundedAtUtc DATETIME NULL,
        IsPaymentCompleted BIT NOT NULL DEFAULT 0,
        FinalOrderGroupId UNIQUEIDENTIFIER NULL,
        CreatedAt DATETIME NOT NULL DEFAULT GETUTCDATE(),
        CONSTRAINT FK_PendingOrders_Users FOREIGN KEY (FromUserId) REFERENCES dbo.Users(Id),
        CONSTRAINT FK_PendingOrders_Addresses FOREIGN KEY (AddressId) REFERENCES dbo.Addresses(Id)
    );
    CREATE UNIQUE INDEX IX_PendingOrders_StripeSessionId ON dbo.PendingOrders(StripeSessionId) WHERE StripeSessionId IS NOT NULL;
END
GO

IF OBJECT_ID(N'dbo.PendingOrderItems', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.PendingOrderItems (
        Id BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        PendingOrderId UNIQUEIDENTIFIER NOT NULL,
        ProductId UNIQUEIDENTIFIER NOT NULL,
        ToUserId UNIQUEIDENTIFIER NOT NULL,
        UnitId TINYINT NOT NULL,
        Quantity DECIMAL(18,3) NOT NULL,
        UnitPriceUsd DECIMAL(12,2) NOT NULL,
        UnitPriceAed DECIMAL(12,2) NOT NULL,
        LineTotalAed DECIMAL(12,2) NOT NULL,
        CONSTRAINT FK_PendingOrderItems_PendingOrders FOREIGN KEY (PendingOrderId) REFERENCES dbo.PendingOrders(Id) ON DELETE CASCADE,
        CONSTRAINT FK_PendingOrderItems_Products FOREIGN KEY (ProductId) REFERENCES dbo.Products(ProductId),
        CONSTRAINT FK_PendingOrderItems_Users FOREIGN KEY (ToUserId) REFERENCES dbo.Users(Id),
        CONSTRAINT FK_PendingOrderItems_Units FOREIGN KEY (UnitId) REFERENCES dbo.Units(Id)
    );
END
GO

IF OBJECT_ID(N'dbo.PendingPayments', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.PendingPayments (
        Id BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        OrderId BIGINT NOT NULL,
        StripeSessionId NVARCHAR(255) NOT NULL,
        PaymentIntentId NVARCHAR(255) NULL,
        StripeRefundId NVARCHAR(255) NULL,
        RefundedAtUtc DATETIME NULL,
        IsCompleted BIT NOT NULL DEFAULT 0,
        CreatedAt DATETIME NOT NULL DEFAULT GETUTCDATE(),
        CONSTRAINT FK_PendingPayments_Orders FOREIGN KEY (OrderId) REFERENCES dbo.Orders(Id) ON DELETE CASCADE
    );
    CREATE UNIQUE INDEX IX_PendingPayments_StripeSessionId ON dbo.PendingPayments(StripeSessionId);
END
GO

IF COL_LENGTH('dbo.Orders', 'OrderGroupId') IS NULL
    ALTER TABLE dbo.Orders ADD OrderGroupId UNIQUEIDENTIFIER NULL;
GO
IF COL_LENGTH('dbo.Orders', 'PendingOrderId') IS NULL
    ALTER TABLE dbo.Orders ADD PendingOrderId UNIQUEIDENTIFIER NULL;
GO
IF COL_LENGTH('dbo.Orders', 'PaymentMethod') IS NULL
    ALTER TABLE dbo.Orders ADD PaymentMethod TINYINT NOT NULL DEFAULT 0;
GO
IF COL_LENGTH('dbo.Orders', 'StripeSessionId') IS NULL
    ALTER TABLE dbo.Orders ADD StripeSessionId NVARCHAR(255) NULL;
GO
IF COL_LENGTH('dbo.Orders', 'UnitId') IS NULL
    ALTER TABLE dbo.Orders ADD UnitId TINYINT NULL;
GO

IF NOT EXISTS (SELECT 1 FROM dbo.OrderStatus WHERE Id = 6 OR Name = N'Cancelled')
BEGIN
    SET IDENTITY_INSERT dbo.OrderStatus ON;
    INSERT INTO dbo.OrderStatus (Id, Name) VALUES (6, N'Cancelled');
    SET IDENTITY_INSERT dbo.OrderStatus OFF;
END
GO
