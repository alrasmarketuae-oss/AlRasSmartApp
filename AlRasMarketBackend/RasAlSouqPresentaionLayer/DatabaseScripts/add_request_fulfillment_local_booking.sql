/*
  Request fulfillment (Local / Booking) for ProductType = Requests

  The mobile app sends:
    ShippingDescriptionEn = 'Local'   -> pickup / no ports required
    ShippingDescriptionEn = 'Booking' -> international ports required

  ProductTypes.Id for Requests = 4 (see ProductTypes seed).

  No new column is required if Products.ShippingDescriptionEn already exists.
  Run this script on production only if the column is missing on an older database.
*/

-- 1) Ensure storage column exists
IF COL_LENGTH('dbo.Products', 'ShippingDescriptionEn') IS NULL
BEGIN
    ALTER TABLE dbo.Products
        ADD ShippingDescriptionEn VARCHAR(255) NULL;
END
GO

-- 2) Optional: index for admin dashboard / reporting on Requests fulfillment type
--    Column is VARCHAR(255) — use non-Unicode literals in the filter (not N'...').
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = N'IX_Products_RequestFulfillment'
      AND object_id = OBJECT_ID(N'dbo.Products')
)
BEGIN
    CREATE INDEX IX_Products_RequestFulfillment
        ON dbo.Products (ProductTypeId, ShippingDescriptionEn)
        WHERE ProductTypeId = 4
          AND ShippingDescriptionEn IN ('Local', 'Booking');
END
GO

/*
  Expected values (Requests ads only):
    Local   = local fulfillment, ports optional / not required
    Booking = booking fulfillment, loading + arrival ports required

  Example query — list Requests with fulfillment type:
*/
-- SELECT
--     p.ProductId,
--     p.NameEn,
--     pt.TypeNameEn AS ProductType,
--     p.ShippingDescriptionEn AS RequestFulfillment,
--     p.Negotiable,
--     oc.CountryNameEn AS OriginCountry,
--     lp.PortNameEn AS LoadingPort,
--     dc.CountryNameEn AS DestinationCountry,
--     ap.PortNameEn AS ArrivalPort
-- FROM dbo.Products p
-- INNER JOIN dbo.ProductTypes pt ON pt.Id = p.ProductTypeId
-- LEFT JOIN dbo.Countries oc ON oc.Id = p.OriginCountryId
-- LEFT JOIN dbo.Ports lp ON lp.Id = p.LoadingPortId
-- LEFT JOIN dbo.Countries dc ON dc.Id = p.DestinationCountryId
-- LEFT JOIN dbo.Ports ap ON ap.Id = p.ArrivalPortId
-- WHERE p.ProductTypeId = 4;
