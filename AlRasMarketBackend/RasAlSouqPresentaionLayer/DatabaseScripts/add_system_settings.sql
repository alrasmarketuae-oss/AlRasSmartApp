-- System settings singleton (commission rates, app info, ad settings).
IF OBJECT_ID(N'dbo.SystemSettings', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.SystemSettings (
        Id TINYINT NOT NULL PRIMARY KEY,
        RetailCommissionPercent DECIMAL(5,2) NOT NULL CONSTRAINT DF_SystemSettings_RetailCommission DEFAULT 0,
        BookingCommissionPercent DECIMAL(5,2) NOT NULL CONSTRAINT DF_SystemSettings_BookingCommission DEFAULT 0,
        RequestsCommissionPercent DECIMAL(5,2) NOT NULL CONSTRAINT DF_SystemSettings_RequestsCommission DEFAULT 0,
        OffersCommissionPercent DECIMAL(5,2) NOT NULL CONSTRAINT DF_SystemSettings_OffersCommission DEFAULT 0,
        ShippingCommissionPercent DECIMAL(5,2) NOT NULL CONSTRAINT DF_SystemSettings_ShippingCommission DEFAULT 0,
        AppName NVARCHAR(200) NOT NULL CONSTRAINT DF_SystemSettings_AppName DEFAULT N'سوق الراس',
        SupportEmail NVARCHAR(255) NULL,
        PhoneNumber NVARCHAR(50) NULL,
        LandlineNumber NVARCHAR(50) NULL,
        Timezone NVARCHAR(100) NULL,
        Address NVARCHAR(500) NULL,
        FeaturedAdPriceAed DECIMAL(12,2) NOT NULL CONSTRAINT DF_SystemSettings_FeaturedAdPrice DEFAULT 0,
        AdDisplayDurationDays INT NOT NULL CONSTRAINT DF_SystemSettings_AdDisplayDays DEFAULT 0,
        UpdatedAt DATETIME NOT NULL CONSTRAINT DF_SystemSettings_UpdatedAt DEFAULT GETUTCDATE()
    );

    INSERT INTO dbo.SystemSettings (Id) VALUES (1);
END
GO
