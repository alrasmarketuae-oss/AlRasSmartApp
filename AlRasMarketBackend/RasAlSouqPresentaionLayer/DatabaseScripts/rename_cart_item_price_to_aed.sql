-- Cart prices are stored in AED only (sent from the mobile app).
IF COL_LENGTH('dbo.CartItems', 'UnitPriceAed') IS NULL
BEGIN
    ALTER TABLE dbo.CartItems ADD UnitPriceAed DECIMAL(12,2) NULL;
END
GO

IF COL_LENGTH('dbo.CartItems', 'UnitPriceUsd') IS NOT NULL
BEGIN
    UPDATE dbo.CartItems
    SET UnitPriceAed = ROUND(UnitPriceUsd * 3.6725, 2)
    WHERE UnitPriceAed IS NULL;

    UPDATE dbo.CartItems
    SET UnitPriceAed = 0
    WHERE UnitPriceAed IS NULL;

    ALTER TABLE dbo.CartItems ALTER COLUMN UnitPriceAed DECIMAL(12,2) NOT NULL;

    ALTER TABLE dbo.CartItems DROP COLUMN UnitPriceUsd;
END
GO
