-- Links products to saved user addresses (nullable FK).
IF COL_LENGTH('dbo.Products', 'Address') IS NOT NULL
BEGIN
    ALTER TABLE dbo.Products DROP COLUMN Address;
END
GO

IF COL_LENGTH('dbo.Products', 'AddressId') IS NULL
BEGIN
    ALTER TABLE dbo.Products
        ADD AddressId UNIQUEIDENTIFIER NULL;
END
GOa

IF NOT EXISTS (
    SELECT 1
    FROM sys.foreign_keys
    WHERE name = N'FK_Products_Addresses'
      AND parent_object_id = OBJECT_ID(N'dbo.Products'))
BEGIN
    ALTER TABLE dbo.Products
        ADD CONSTRAINT FK_Products_Addresses
            FOREIGN KEY (AddressId) REFERENCES dbo.Addresses(Id);
END
GO
