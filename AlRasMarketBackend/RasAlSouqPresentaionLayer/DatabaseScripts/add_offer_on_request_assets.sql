-- Stores image/document paths for offers on requests (files live in product-images / product-documents).

IF OBJECT_ID(N'dbo.OfferOnRequestImages', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.OfferOnRequestImages (
        Id BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        OfferId BIGINT NOT NULL,
        ImagePath NVARCHAR(500) NOT NULL,
        CreatedAt DATETIME NOT NULL CONSTRAINT DF_OfferOnRequestImages_CreatedAt DEFAULT GETUTCDATE(),
        CONSTRAINT FK_OfferOnRequestImages_Offers FOREIGN KEY (OfferId) REFERENCES dbo.OffersOnRequests(Id) ON DELETE CASCADE
    );

    CREATE INDEX IX_OfferOnRequestImages_OfferId ON dbo.OfferOnRequestImages(OfferId);
END

IF OBJECT_ID(N'dbo.OfferOnRequestDocuments', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.OfferOnRequestDocuments (
        Id BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        OfferId BIGINT NOT NULL,
        DocumentPath NVARCHAR(500) NOT NULL,
        CreatedAt DATETIME NOT NULL CONSTRAINT DF_OfferOnRequestDocuments_CreatedAt DEFAULT GETUTCDATE(),
        CONSTRAINT FK_OfferOnRequestDocuments_Offers FOREIGN KEY (OfferId) REFERENCES dbo.OffersOnRequests(Id) ON DELETE CASCADE
    );

    CREATE INDEX IX_OfferOnRequestDocuments_OfferId ON dbo.OfferOnRequestDocuments(OfferId);
END
