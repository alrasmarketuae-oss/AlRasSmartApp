using DataLayer.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace DataLayer.Seeding;

/// <summary>
/// Ensures Product stored procedures + TVP exist for high-performance paths:
/// - dbo.usp_InsertProduct
/// - dbo.usp_GetProductsByIds
/// </summary>
public static class ProductStoredProceduresSchemaMigrator
{
    public static async Task EnsureAsync(IRasAlSouqDbContext db, CancellationToken cancellationToken = default)
    {
        var context = (DbContext)db;
        var connection = context.Database.GetDbConnection();
        await SqlSchemaHelper.OpenIfNeededAsync(connection, cancellationToken).ConfigureAwait(false);

        await SqlSchemaHelper.ExecuteBatchAsync(
            connection,
            """
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
            """,
            cancellationToken).ConfigureAwait(false);

        await SqlSchemaHelper.ExecuteBatchAsync(
            connection,
            """
            CREATE OR ALTER PROCEDURE dbo.usp_InsertProduct
            (
                @ProductId uniqueidentifier,
                @OwnerId uniqueidentifier,
                @NameEn nvarchar(255),
                @CreatedLanguage nvarchar(5),
                @USDPrice decimal(8,2),
                @Currency nvarchar(3),
                @Quantity bigint,
                @DescriptionEn nvarchar(max),
                @CategoryId tinyint = NULL,
                @ProductTypeId tinyint = NULL,
                @UnitId tinyint,
                @OriginCountryId smallint = NULL,
                @DestinationCountryId smallint = NULL,
                @LoadingPortId int = NULL,
                @ArrivalPortId int = NULL,
                @MinimumOrderQuantity int = NULL,
                @MaximumOrderQuantity int = NULL,
                @Status tinyint = NULL,
                @IsApproved bit = NULL,
                @IsReadyForAdminReview bit,
                @DiscountPercentage tinyint = NULL,
                @DiscountDays smallint = NULL,
                @ShippingDescriptionEn nvarchar(255) = NULL,
                @SupplierNotesEn nvarchar(255) = NULL,
                @Packaging tinyint = NULL,
                @PackagingDetails nvarchar(255) = NULL,
                @Negotiable bit = NULL,
                @VideoPath nvarchar(500) = NULL,
                @VideoDurationSeconds tinyint = NULL,
                @ShippingDuration nvarchar(20) = NULL,
                @OfferDuration nvarchar(20) = NULL,
                @AddressId uniqueidentifier = NULL,
                @RequestTypeId tinyint = NULL,
                @BookingPriceTypeId tinyint = NULL,
                @RetailPrice decimal(8,2) = NULL,
                @RetailUnitId tinyint = NULL,
                @RetailQuantity bigint = NULL,
                @RetailPackaging tinyint = NULL,
                @RetailPackagingDetails nvarchar(255) = NULL,
                @RetailDescriptionEn nvarchar(max) = NULL,
                @IsFeatured bit = 0,
                @ViewsCount bigint = 0,
                @CreatedAt datetime,
                @ProductCode nvarchar(16) OUTPUT
            )
            AS
            BEGIN
                SET NOCOUNT ON;

                DECLARE @Alphabet NVARCHAR(32) = N'23456789ABCDEFGHJKLMNPQRSTUVWXYZ';
                DECLARE @Base INT = LEN(@Alphabet); -- 32
                DECLARE @SequenceValue BIGINT;
                DECLARE @Remaining BIGINT;
                DECLARE @Result NVARCHAR(9) = REPLICATE(N' ', 9);

                SELECT @SequenceValue = NEXT VALUE FOR dbo.ProductCodeSeq;
                SET @Remaining = @SequenceValue;

                DECLARE @i INT = 8;
                WHILE @i >= 0
                BEGIN
                    DECLARE @Index INT = CAST((@Remaining % @Base) AS INT); -- 0..base-1
                    DECLARE @Char NCHAR(1) = SUBSTRING(@Alphabet, @Index + 1, 1);

                    -- STUFF is 1-based positions.
                    SET @Result = STUFF(@Result, @i + 1, 1, @Char);

                    SET @Remaining = @Remaining / @Base;
                    SET @i = @i - 1;
                END;

                SET @ProductCode = N'RS' + @Result;

                INSERT INTO dbo.Products
                (
                    ProductId,
                    ProductCode,
                    OwnerId,
                    NameEn,
                    CreatedLanguage,
                    USDPrice,
                    Currency,
                    Quantity,
                    DescriptionEn,
                    CategoryId,
                    ProductTypeId,
                    UnitId,
                    OriginCountryId,
                    DestinationCountryId,
                    LoadingPortId,
                    ArrivalPortId,
                    MinimumOrderQuantity,
                    MaximumOrderQuantity,
                    Status,
                    IsApproved,
                    IsReadyForAdminReview,
                    DiscountPercentage,
                    DiscountDays,
                    ShippingDescriptionEn,
                    SupplierNotesEn,
                    Packaging,
                    PackagingDetails,
                    Negotiable,
                    VideoPath,
                    VideoDurationSeconds,
                    ShippingDuration,
                    OfferDuration,
                    AddressId,
                    RequestTypeId,
                    BookingPriceTypeId,
                    RetailPrice,
                    RetailUnitId,
                    RetailQuantity,
                    RetailPackaging,
                    RetailPackagingDetails,
                    RetailDescriptionEn,
                    IsFeatured,
                    ViewsCount,
                    CreatedAt
                )
                VALUES
                (
                    @ProductId,
                    @ProductCode,
                    @OwnerId,
                    @NameEn,
                    @CreatedLanguage,
                    @USDPrice,
                    @Currency,
                    @Quantity,
                    @DescriptionEn,
                    @CategoryId,
                    @ProductTypeId,
                    @UnitId,
                    @OriginCountryId,
                    @DestinationCountryId,
                    @LoadingPortId,
                    @ArrivalPortId,
                    @MinimumOrderQuantity,
                    @MaximumOrderQuantity,
                    @Status,
                    @IsApproved,
                    @IsReadyForAdminReview,
                    @DiscountPercentage,
                    @DiscountDays,
                    @ShippingDescriptionEn,
                    @SupplierNotesEn,
                    @Packaging,
                    @PackagingDetails,
                    @Negotiable,
                    @VideoPath,
                    @VideoDurationSeconds,
                    @ShippingDuration,
                    @OfferDuration,
                    @AddressId,
                    @RequestTypeId,
                    @BookingPriceTypeId,
                    @RetailPrice,
                    @RetailUnitId,
                    @RetailQuantity,
                    @RetailPackaging,
                    @RetailPackagingDetails,
                    @RetailDescriptionEn,
                    @IsFeatured,
                    @ViewsCount,
                    @CreatedAt
                );
            END
            """,
            cancellationToken).ConfigureAwait(false);

        await SqlSchemaHelper.ExecuteBatchAsync(
            connection,
            """
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
            """,
            cancellationToken).ConfigureAwait(false);
    }
}

