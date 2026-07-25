/*
  Hybrid category + retail ads: separate packing and specifications for retail.
  Wholesale continues to use Packaging / PackagingDetails / DescriptionEn.
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

/*
  RetailPackaging = weight in kg (1–255), NULL = not set
  RetailDescriptionEn = retail channel specifications text
*/
