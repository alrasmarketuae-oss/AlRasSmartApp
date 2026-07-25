-- Internal domestic shipping rates per UAE emirate + user preferred language
IF OBJECT_ID(N'dbo.InternalDomesticShipping', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.InternalDomesticShipping (
        Id TINYINT NOT NULL PRIMARY KEY,
        EmirateNameEn VARCHAR(100) NOT NULL,
        EmirateNameAr NVARCHAR(100) NOT NULL,
        PriceAed DECIMAL(12,2) NOT NULL CONSTRAINT DF_InternalDomesticShipping_PriceAed DEFAULT 0,
        UpdatedAt DATETIME NOT NULL CONSTRAINT DF_InternalDomesticShipping_UpdatedAt DEFAULT GETUTCDATE()
    );

    CREATE UNIQUE INDEX IX_InternalDomesticShipping_EmirateNameEn
        ON dbo.InternalDomesticShipping(EmirateNameEn);

    INSERT INTO dbo.InternalDomesticShipping (Id, EmirateNameEn, EmirateNameAr, PriceAed, UpdatedAt) VALUES
        (1, N'Abu Dhabi', N'أبو ظبي', 0, GETUTCDATE()),
        (2, N'Dubai', N'دبي', 0, GETUTCDATE()),
        (3, N'Sharjah', N'الشارقة', 0, GETUTCDATE()),
        (4, N'Ajman', N'عجمان', 0, GETUTCDATE()),
        (5, N'Umm Al Quwain', N'أم القيوين', 0, GETUTCDATE()),
        (6, N'Ras Al Khaimah', N'رأس الخيمة', 0, GETUTCDATE()),
        (7, N'Fujairah', N'الفجيرة', 0, GETUTCDATE());
END

IF COL_LENGTH('dbo.Users', 'PreferredLanguage') IS NULL
BEGIN
    ALTER TABLE dbo.Users
        ADD PreferredLanguage VARCHAR(10) NOT NULL CONSTRAINT DF_Users_PreferredLanguage DEFAULT 'en';
END
