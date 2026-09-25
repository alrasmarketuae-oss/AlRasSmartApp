-- Runtime equivalent: ProductEngagementSchemaMigrator (applied on API startup).
-- Seller ad statistics: views, cart adds, favorites, shares.

IF COL_LENGTH(N'dbo.Products', N'ViewsCount') IS NULL
BEGIN
    ALTER TABLE dbo.Products
    ADD ViewsCount BIGINT NOT NULL
        CONSTRAINT DF_Products_ViewsCount DEFAULT (0);
END
GO

IF COL_LENGTH(N'dbo.Products', N'CartAddsCount') IS NULL
BEGIN
    ALTER TABLE dbo.Products
    ADD CartAddsCount BIGINT NOT NULL
        CONSTRAINT DF_Products_CartAddsCount DEFAULT (0);
END
GO

IF COL_LENGTH(N'dbo.Products', N'FavoritesCount') IS NULL
BEGIN
    ALTER TABLE dbo.Products
    ADD FavoritesCount BIGINT NOT NULL
        CONSTRAINT DF_Products_FavoritesCount DEFAULT (0);
END
GO

IF COL_LENGTH(N'dbo.Products', N'SharesCount') IS NULL
BEGIN
    ALTER TABLE dbo.Products
    ADD SharesCount BIGINT NOT NULL
        CONSTRAINT DF_Products_SharesCount DEFAULT (0);
END
GO
