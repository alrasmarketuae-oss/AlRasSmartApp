-- نسب العمولة على أصناف Categories + عمود Currency في Products
-- آمن للتشغيل أكثر من مرة (idempotent)

IF COL_LENGTH('dbo.Categories', 'CommissionPercent') IS NULL
BEGIN
    ALTER TABLE dbo.Categories
    ADD CommissionPercent DECIMAL(5,2) NOT NULL
        CONSTRAINT DF_Categories_CommissionPercent DEFAULT 0;
END
GO

IF COL_LENGTH('dbo.Products', 'Currency') IS NULL
BEGIN
    ALTER TABLE dbo.Products
    ADD Currency NVARCHAR(3) NOT NULL
        CONSTRAINT DF_Products_Currency DEFAULT N'AED';
END
GO

-- منتجات البوكنج بالدولار
UPDATE dbo.Products
SET Currency = N'USD'
WHERE ProductTypeId = 2
  AND (Currency IS NULL OR Currency = N'AED');
GO

IF COL_LENGTH('dbo.PendingOrders', 'CheckoutCurrency') IS NULL
BEGIN
    ALTER TABLE dbo.PendingOrders ADD CheckoutCurrency NVARCHAR(3) NULL;
END
GO

IF COL_LENGTH('dbo.PendingOrders', 'CheckoutAmount') IS NULL
BEGIN
    ALTER TABLE dbo.PendingOrders ADD CheckoutAmount DECIMAL(12,2) NULL;
END
GO
