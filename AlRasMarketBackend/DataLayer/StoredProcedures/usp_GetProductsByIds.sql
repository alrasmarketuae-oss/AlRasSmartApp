-- Must create the TVP before the procedure.
IF NOT EXISTS (
    SELECT 1
    FROM sys.types
    WHERE is_table_type = 1
      AND name = N'ProductIdListType'
      AND schema_id = SCHEMA_ID(N'dbo')
)
BEGIN
    CREATE TYPE dbo.ProductIdListType AS TABLE
    (
        ProductId uniqueidentifier NOT NULL
    );
END
GO

CREATE OR ALTER PROCEDURE dbo.usp_GetProductsByIds
(
    @ProductIds dbo.ProductIdListType READONLY
)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        p.ProductId,
        p.ProductCode,
        p.NameEn,
        p.USDPrice,
        p.OwnerId,
        p.Quantity,
        p.DescriptionEn,
        p.MinimumOrderQuantity,
        p.MaximumOrderQuantity,
        p.Status,
        p.IsApproved,
        p.DiscountPercentage,
        p.DiscountDays,
        p.ShippingDescriptionEn,
        p.ShippingDuration,
        p.OfferDuration,
        p.SupplierNotesEn,
        p.Packaging,
        p.PackagingDetails,
        p.RetailPackaging,
        p.RetailPackagingDetails,
        p.RetailDescriptionEn,
        p.Negotiable,
        p.IsFeatured,
        p.ViewsCount,
        p.VideoPath,
        p.VideoDurationSeconds,
        p.CreatedAt,

        c.NameEn AS CategoryName,
        c.NameAr AS CategoryNameAr,

        pt.TypeNameEn AS ProductTypeName,
        u.UnitNameEn AS UnitName,

        oc.CountryNameEn AS OriginCountryName,
        oc.CountryNameAr AS OriginCountryNameAr,

        dc.CountryNameEn AS DestinationCountryName,
        dc.CountryNameAr AS DestinationCountryNameAr,

        lp.PortNameEn AS LoadingPortName,
        lp.PortNameAr AS LoadingPortNameAr,

        ap.PortNameEn AS ArrivalPortName,
        ap.PortNameAr AS ArrivalPortNameAr,

        p.CategoryId,
        COALESCE(p.Currency, N'AED') AS Currency,
        p.ProductTypeId,
        p.AddressId,

        p.RetailPrice,
        p.RetailUnitId,
        p.RetailQuantity,
        ru.UnitNameEn AS RetailUnitName,

        p.RequestTypeId,
        rt.NameEn AS RequestTypeName,

        p.BookingPriceTypeId,
        bpt.NameEn AS BookingPriceTypeName
    FROM @ProductIds ids
    INNER JOIN dbo.Products p
        ON p.ProductId = ids.ProductId
    LEFT JOIN dbo.Categories c
        ON c.CategoryId = p.CategoryId
    LEFT JOIN dbo.ProductTypes pt
        ON pt.Id = p.ProductTypeId
    LEFT JOIN dbo.Units u
        ON u.Id = p.UnitId
    LEFT JOIN dbo.Countries oc
        ON oc.Id = p.OriginCountryId
    LEFT JOIN dbo.Countries dc
        ON dc.Id = p.DestinationCountryId
    LEFT JOIN dbo.Ports lp
        ON lp.Id = p.LoadingPortId
    LEFT JOIN dbo.Ports ap
        ON ap.Id = p.ArrivalPortId
    LEFT JOIN dbo.Units ru
        ON ru.Id = p.RetailUnitId
    LEFT JOIN dbo.RequestTypes rt
        ON rt.Id = p.RequestTypeId
    LEFT JOIN dbo.BookingPriceTypes bpt
        ON bpt.Id = p.BookingPriceTypeId;
END
GO
