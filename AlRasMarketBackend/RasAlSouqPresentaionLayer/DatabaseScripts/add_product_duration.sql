-- Adds shipping duration column to Products (e.g. "7-10 days", "2 weeks").
IF COL_LENGTH('Products', 'ShippingDuration') IS NULL
BEGIN
    IF COL_LENGTH('Products', 'Duration') IS NOT NULL
    BEGIN
        EXEC sp_rename 'Products.Duration', 'ShippingDuration', 'COLUMN';
    END
    ELSE
    BEGIN
        ALTER TABLE Products
            ADD ShippingDuration VARCHAR(20) NULL;
    END
END
GO
