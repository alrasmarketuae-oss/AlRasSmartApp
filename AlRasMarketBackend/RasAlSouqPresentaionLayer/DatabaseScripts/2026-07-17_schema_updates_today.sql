/*
  Schema updates (2026-07-17)
  --------------------------
  1) Products.PendingProductChanges — previous ad snapshot while edit awaits admin review
  2) BookingPriceTypes + Products.BookingPriceTypeId — FOB / CNF / CIF on booking ads
  3) Products.RetailPackaging / RetailPackagingDetails / RetailDescriptionEn
     — separate packing + specs for hybrid category+retail ads

  Safe to re-run (idempotent checks).
  App startup migrators also apply these automatically.
*/

/* ========== 1) Pending product edit snapshot ========== */
IF COL_LENGTH('dbo.Products', 'PendingProductChanges') IS NULL
BEGIN
    ALTER TABLE dbo.Products
        ADD PendingProductChanges NVARCHAR(MAX) NULL;
END
GO

/* ========== 2) Booking price types (FOB / CNF / CIF) ========== */
IF OBJECT_ID(N'dbo.BookingPriceTypes', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.BookingPriceTypes
    (
        Id TINYINT NOT NULL CONSTRAINT PK_BookingPriceTypes PRIMARY KEY,
        NameEn VARCHAR(50) NOT NULL
    );

    INSERT INTO dbo.BookingPriceTypes (Id, NameEn)
    VALUES (1, 'FOB'), (2, 'CNF'), (3, 'CIF');
END
ELSE
BEGIN
    IF NOT EXISTS (SELECT 1 FROM dbo.BookingPriceTypes WHERE Id = 1)
        INSERT INTO dbo.BookingPriceTypes (Id, NameEn) VALUES (1, 'FOB');
    IF NOT EXISTS (SELECT 1 FROM dbo.BookingPriceTypes WHERE Id = 2)
        INSERT INTO dbo.BookingPriceTypes (Id, NameEn) VALUES (2, 'CNF');
    IF NOT EXISTS (SELECT 1 FROM dbo.BookingPriceTypes WHERE Id = 3)
        INSERT INTO dbo.BookingPriceTypes (Id, NameEn) VALUES (3, 'CIF');
END
GO

IF COL_LENGTH('dbo.Products', 'BookingPriceTypeId') IS NULL
BEGIN
    ALTER TABLE dbo.Products
        ADD BookingPriceTypeId TINYINT NULL;

    ALTER TABLE dbo.Products
        ADD CONSTRAINT FK_Products_BookingPriceTypes
            FOREIGN KEY (BookingPriceTypeId) REFERENCES dbo.BookingPriceTypes(Id);
END
GO

/* ========== 3) Hybrid retail channel: packing + specifications ==========
   Wholesale keeps: Packaging, PackagingDetails, DescriptionEn
   Retail channel:  RetailPackaging, RetailPackagingDetails, RetailDescriptionEn
*/
IF COL_LENGTH('dbo.Products', 'RetailPackaging') IS NULL
BEGIN
    ALTER TABLE dbo.Products
        ADD RetailPackaging TINYINT NULL;
END
GO

IF COL_LENGTH('dbo.Products', 'RetailPackagingDetails') IS NULL
BEGIN
    ALTER TABLE dbo.Products
        ADD RetailPackagingDetails NVARCHAR(255) NULL;
END
GO

IF COL_LENGTH('dbo.Products', 'RetailDescriptionEn') IS NULL
BEGIN
    ALTER TABLE dbo.Products
        ADD RetailDescriptionEn NVARCHAR(MAX) NULL;
END
GO
