/*
  Allow InternationalShippingPosts.Container20ftPriceUsd and Container40ftPriceUsd
  to be NULL. Startup migrator also applies this; this script is for manual runs.
*/

IF EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID(N'dbo.InternationalShippingPosts')
      AND name = N'Container20ftPriceUsd' AND is_nullable = 0)
BEGIN
    ALTER TABLE dbo.InternationalShippingPosts
        ALTER COLUMN Container20ftPriceUsd DECIMAL(12,2) NULL;
END
GO

IF EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID(N'dbo.InternationalShippingPosts')
      AND name = N'Container40ftPriceUsd' AND is_nullable = 0)
BEGIN
    ALTER TABLE dbo.InternationalShippingPosts
        ALTER COLUMN Container40ftPriceUsd DECIMAL(12,2) NULL;
END
GO

UPDATE dbo.InternationalShippingPosts
SET Container20ftPriceUsd = NULL
WHERE Container20ftPriceUsd <= 0;

UPDATE dbo.InternationalShippingPosts
SET Container40ftPriceUsd = NULL
WHERE Container40ftPriceUsd <= 0;
GO
