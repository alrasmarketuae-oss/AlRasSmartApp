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
    @SupplierNotesEn nvarchar(1000) = NULL,
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
GO
