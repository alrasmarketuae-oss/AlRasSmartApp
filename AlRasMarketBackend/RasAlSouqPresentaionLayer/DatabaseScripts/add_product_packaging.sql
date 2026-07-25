/*
  Optional packing weight in kg (tinyint 1–255).
  PackagingDetails kept nullable for compatibility (unused by app UI).
*/
IF COL_LENGTH('dbo.Products', 'PackagingEn') IS NOT NULL
BEGIN
    ALTER TABLE dbo.Products DROP COLUMN PackagingEn;
END
GO

IF COL_LENGTH('dbo.Products', 'Packaging') IS NULL
BEGIN
    ALTER TABLE dbo.Products
        ADD Packaging TINYINT NULL;
END
GO

IF COL_LENGTH('dbo.Products', 'PackagingDetails') IS NULL
BEGIN
    ALTER TABLE dbo.Products
        ADD PackagingDetails NVARCHAR(255) NULL;
END
GO

/*
  Packaging = weight in kg (1–255), NULL = not set
  UI: Packing [number] kg
*/
