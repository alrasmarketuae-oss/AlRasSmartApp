-- Corrected SQL Server schema for RasAlSouq
CREATE TABLE Roles (
    Id TINYINT IDENTITY(1,1) PRIMARY KEY,
    RoleName NVARCHAR(255) NOT NULL
);

CREATE TABLE Users (
    Id UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
    FullName NVARCHAR(250) NOT NULL,
    FcmToken VARCHAR(512) NULL,
    Email NVARCHAR(250) NOT NULL UNIQUE,
    HashedPassword NVARCHAR(250) NULL,
    RoleId TINYINT NOT NULL,
    CreatedAt DATETIME NOT NULL DEFAULT GETUTCDATE(),
    ImgPath NVARCHAR(250) NULL,
    LoginProviderName NVARCHAR(250) NOT NULL DEFAULT N'Local',
    IsActive BIT NOT NULL DEFAULT 1,
    IsApproved BIT NOT NULL DEFAULT 0,
    IsVerified BIT NOT NULL DEFAULT 0,
    PhoneNumber VARCHAR(255) NULL,
    LandNumber VARCHAR(255) NULL,
    LicenseNumber VARCHAR(100) NULL,
    LicencePath NVARCHAR(255) NULL,
    CompanyName NVARCHAR(250) NULL,
    BirthDate DATE NULL,
    CommercialRegister VARCHAR(100) NULL,
    TaxNumber VARCHAR(100) NULL,
    IsCustomer BIT NULL,
    CONSTRAINT FK_Users_Roles FOREIGN KEY (RoleId) REFERENCES Roles(Id)
);
CREATE INDEX IX_Users_PhoneNumber ON Users (PhoneNumber) WHERE PhoneNumber IS NOT NULL;

CREATE TABLE Categories (
    CategoryId TINYINT IDENTITY(1,1) PRIMARY KEY,
    NameEn VARCHAR(255) NOT NULL,
    ImgPath NVARCHAR(255) NOT NULL
);

CREATE TABLE ProductTypes (
    Id TINYINT IDENTITY(1,1) PRIMARY KEY,
    TypeNameEn NVARCHAR(255) NOT NULL
);

CREATE TABLE Units (
    Id TINYINT IDENTITY(1,1) PRIMARY KEY,
    UnitNameEn NVARCHAR(255) NOT NULL
);

CREATE TABLE Products (
    ProductId UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
    NameEn VARCHAR(255) NULL,
    USDPrice DECIMAL(8,2) NOT NULL,
    CategoryId TINYINT NULL,
    ProductTypeId TINYINT NULL,
    OwnerId UNIQUEIDENTIFIER NULL,
    Quantity BIGINT NOT NULL,
    DescriptionEn NVARCHAR(MAX) NULL,
    MinimumOrderQuantity INT NULL,
    Status TINYINT NULL,
    CreatedAt DATETIME NOT NULL DEFAULT GETUTCDATE(),
    UpdatedAt DATETIME NULL,
    IsApproved BIT NULL,
    DiscountPercentage TINYINT NULL,
    DiscountDays SMALLINT NULL,
    ShippingDescriptionEn VARCHAR(255) NULL,
    SupplierNotesEn VARCHAR(255) NULL,
    UnitId TINYINT NULL,
    OriginCountryId SMALLINT NULL,
    DestinationCountryId SMALLINT NULL,
    LoadingPortId INT NULL,
    ArrivalPortId INT NULL,
    VideoPath NVARCHAR(500) NULL,
    VideoDurationSeconds TINYINT NULL,
    ShippingDuration VARCHAR(20) NULL,
    MaximumOrderQuantity INT NULL,
    Negotiable BIT NULL,
    IsFeatured BIT NOT NULL DEFAULT 0,
    ViewsCount BIGINT NOT NULL DEFAULT 0,
    CONSTRAINT FK_Products_Users FOREIGN KEY (OwnerId) REFERENCES Users(Id),
    CONSTRAINT FK_Products_Categories FOREIGN KEY (CategoryId) REFERENCES Categories(CategoryId),
    CONSTRAINT FK_Products_ProductTypes FOREIGN KEY (ProductTypeId) REFERENCES ProductTypes(Id),
    CONSTRAINT FK_Products_Units FOREIGN KEY (UnitId) REFERENCES Units(Id)
);
CREATE INDEX IX_Products_IsFeatured ON Products (IsFeatured);
CREATE INDEX IX_Products_ProductTypeId ON Products (ProductTypeId);
CREATE INDEX IX_Products_OwnerId ON Products (OwnerId);
CREATE INDEX IX_Products_CategoryId ON Products (CategoryId);
CREATE INDEX IX_Products_CreatedAt ON Products (CreatedAt);
CREATE INDEX IX_Products_NameEn ON Products (NameEn);

CREATE TABLE OrderStatus (
    Id TINYINT IDENTITY(1,1) PRIMARY KEY,
    Name NVARCHAR(255) NOT NULL
);

CREATE TABLE OfferStatuses (
    Id TINYINT PRIMARY KEY,
    NameEn VARCHAR(50) NOT NULL
);

CREATE TABLE Orders (
    Id BIGINT IDENTITY(1,1) PRIMARY KEY,
    FromUserId UNIQUEIDENTIFIER NOT NULL,
    ToUserId UNIQUEIDENTIFIER NOT NULL,
    ProductId UNIQUEIDENTIFIER NOT NULL,
    Quantity DECIMAL(18,3) NOT NULL,
    UnitPrice DECIMAL(8,2) NOT NULL,
    TotalPrice DECIMAL(8,2) NOT NULL,
    CreatedAt DATETIME NOT NULL DEFAULT GETUTCDATE(),
    StatusId TINYINT NOT NULL,
    IsApproved BIT NOT NULL DEFAULT 0,
    Notes NVARCHAR(2000) NULL,
    CONSTRAINT FK_Orders_FromUser FOREIGN KEY (FromUserId) REFERENCES Users(Id),
    CONSTRAINT FK_Orders_ToUser FOREIGN KEY (ToUserId) REFERENCES Users(Id),
    CONSTRAINT FK_Orders_Product FOREIGN KEY (ProductId) REFERENCES Products(ProductId),
    CONSTRAINT FK_Orders_Status FOREIGN KEY (StatusId) REFERENCES OrderStatus(Id)
);

CREATE TABLE OrderVideos (
    Id BIGINT IDENTITY(1,1) PRIMARY KEY,
    OrderId BIGINT NOT NULL,
    VideoPath NVARCHAR(500) NOT NULL,
    UploadedByUserId UNIQUEIDENTIFIER NOT NULL,
    CreatedAt DATETIME NOT NULL DEFAULT GETUTCDATE(),
    CONSTRAINT FK_OrderVideos_Orders FOREIGN KEY (OrderId) REFERENCES Orders(Id) ON DELETE CASCADE
);
CREATE INDEX IX_OrderVideos_OrderId ON OrderVideos(OrderId);

CREATE TABLE OrderImages (
    Id BIGINT IDENTITY(1,1) PRIMARY KEY,
    OrderId BIGINT NOT NULL,
    ImagePath NVARCHAR(500) NOT NULL,
    UploadedByUserId UNIQUEIDENTIFIER NOT NULL,
    CreatedAt DATETIME NOT NULL DEFAULT GETUTCDATE(),
    CONSTRAINT FK_OrderImages_Orders FOREIGN KEY (OrderId) REFERENCES Orders(Id) ON DELETE CASCADE
);
CREATE INDEX IX_OrderImages_OrderId ON OrderImages(OrderId);

CREATE TABLE Countries (
    Id SMALLINT IDENTITY(1,1) PRIMARY KEY,
    Iso2Code VARCHAR(2) NOT NULL UNIQUE,
    CountryNameEn VARCHAR(255) NOT NULL,
    CountryNameAr NVARCHAR(255) NULL
);

CREATE TABLE Cities (
    Id UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
    CityName NVARCHAR(255) NOT NULL,
    CountryId SMALLINT NOT NULL,
    CONSTRAINT FK_Cities_Countries FOREIGN KEY (CountryId) REFERENCES Countries(Id)
);

CREATE TABLE Ports (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    PortNameEn NVARCHAR(255) NOT NULL,
    UnLocode VARCHAR(10) NULL,
    CountryId SMALLINT NOT NULL,
    CONSTRAINT FK_Ports_Countries FOREIGN KEY (CountryId) REFERENCES Countries(Id)
);
CREATE UNIQUE INDEX IX_Ports_UnLocode ON Ports (UnLocode) WHERE UnLocode IS NOT NULL;

CREATE TABLE OffersOnRequests (
    Id BIGINT IDENTITY(1,1) PRIMARY KEY,
    FromUserId UNIQUEIDENTIFIER NOT NULL,
    ToUserId UNIQUEIDENTIFIER NOT NULL,
    CountryId SMALLINT NOT NULL,
    PortId INT NOT NULL,
    DeliveryWindow VARCHAR(100) NOT NULL,
    ProductId UNIQUEIDENTIFIER NOT NULL,
    RequestedQuantity BIGINT NOT NULL,
    UnitId TINYINT NOT NULL,
    UnitPrice DECIMAL(12,2) NOT NULL,
    TotalPrice DECIMAL(12,2) NOT NULL,
    StatusId TINYINT NOT NULL,
    CreatedAt DATETIME NOT NULL DEFAULT GETUTCDATE(),
    CONSTRAINT FK_Offers_FromUser FOREIGN KEY (FromUserId) REFERENCES Users(Id),
    CONSTRAINT FK_Offers_ToUser FOREIGN KEY (ToUserId) REFERENCES Users(Id),
    CONSTRAINT FK_Offers_Country FOREIGN KEY (CountryId) REFERENCES Countries(Id),
    CONSTRAINT FK_Offers_Port FOREIGN KEY (PortId) REFERENCES Ports(Id),
    CONSTRAINT FK_Offers_Product FOREIGN KEY (ProductId) REFERENCES Products(ProductId),
    CONSTRAINT FK_Offers_Unit FOREIGN KEY (UnitId) REFERENCES Units(Id),
    CONSTRAINT FK_Offers_Status FOREIGN KEY (StatusId) REFERENCES OfferStatuses(Id)
);

CREATE TABLE OfferOnRequestImages (
    Id BIGINT IDENTITY(1,1) PRIMARY KEY,
    OfferId BIGINT NOT NULL,
    ImagePath NVARCHAR(500) NOT NULL,
    CreatedAt DATETIME NOT NULL DEFAULT GETUTCDATE(),
    CONSTRAINT FK_OfferOnRequestImages_Offers FOREIGN KEY (OfferId) REFERENCES OffersOnRequests(Id) ON DELETE CASCADE
);
CREATE INDEX IX_OfferOnRequestImages_OfferId ON OfferOnRequestImages(OfferId);

CREATE TABLE OfferOnRequestDocuments (
    Id BIGINT IDENTITY(1,1) PRIMARY KEY,
    OfferId BIGINT NOT NULL,
    DocumentPath NVARCHAR(500) NOT NULL,
    CreatedAt DATETIME NOT NULL DEFAULT GETUTCDATE(),
    CONSTRAINT FK_OfferOnRequestDocuments_Offers FOREIGN KEY (OfferId) REFERENCES OffersOnRequests(Id) ON DELETE CASCADE
);
CREATE INDEX IX_OfferOnRequestDocuments_OfferId ON OfferOnRequestDocuments(OfferId);

CREATE TABLE OffersOnNegotiable (
    Id BIGINT IDENTITY(1,1) PRIMARY KEY,
    ProductId UNIQUEIDENTIFIER NOT NULL,
    FromUserId UNIQUEIDENTIFIER NOT NULL,
    ToUserId UNIQUEIDENTIFIER NOT NULL,
    OfferedPrice DECIMAL(12,2) NOT NULL,
    UnitId TINYINT NOT NULL,
    BaseUnitPrice DECIMAL(12,2) NOT NULL,
    RequestedQuantity DECIMAL(18,3) NOT NULL,
    StatusId TINYINT NOT NULL DEFAULT 1,
    CreatedAt DATETIME NOT NULL DEFAULT GETUTCDATE(),
    CONSTRAINT FK_OffersOnNegotiable_Products FOREIGN KEY (ProductId) REFERENCES Products(ProductId),
    CONSTRAINT FK_OffersOnNegotiable_FromUser FOREIGN KEY (FromUserId) REFERENCES Users(Id),
    CONSTRAINT FK_OffersOnNegotiable_ToUser FOREIGN KEY (ToUserId) REFERENCES Users(Id),
    CONSTRAINT FK_OffersOnNegotiable_Units FOREIGN KEY (UnitId) REFERENCES Units(Id),
    CONSTRAINT FK_OffersOnNegotiable_Statuses FOREIGN KEY (StatusId) REFERENCES OfferStatuses(Id)
);

CREATE TABLE InternationalShippingPosts (
    Id BIGINT IDENTITY(1,1) PRIMARY KEY,
    FromCountryId SMALLINT NOT NULL,
    FromPortId INT NOT NULL,
    ToCountryId SMALLINT NOT NULL,
    ToPortId INT NOT NULL,
    PriceUsd DECIMAL(12,2) NOT NULL,
    ShippingCostUsd DECIMAL(12,2) NOT NULL,
    PublisherUserId UNIQUEIDENTIFIER NOT NULL,
    PhoneNumber VARCHAR(50) NOT NULL,
    Container20ftPriceUsd DECIMAL(12,2) NOT NULL,
    Container40ftPriceUsd DECIMAL(12,2) NOT NULL,
    CreatedAt DATETIME NOT NULL DEFAULT GETUTCDATE(),
    CONSTRAINT FK_InternationalShippingPosts_FromCountry FOREIGN KEY (FromCountryId) REFERENCES Countries(Id),
    CONSTRAINT FK_InternationalShippingPosts_FromPort FOREIGN KEY (FromPortId) REFERENCES Ports(Id),
    CONSTRAINT FK_InternationalShippingPosts_ToCountry FOREIGN KEY (ToCountryId) REFERENCES Countries(Id),
    CONSTRAINT FK_InternationalShippingPosts_ToPort FOREIGN KEY (ToPortId) REFERENCES Ports(Id),
    CONSTRAINT FK_InternationalShippingPosts_PublisherUser FOREIGN KEY (PublisherUserId) REFERENCES Users(Id)
);

CREATE TABLE Carts (
    CartId UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
    UserId UNIQUEIDENTIFIER NOT NULL UNIQUE,
    CreatedAt DATETIME NOT NULL DEFAULT GETUTCDATE(),
    UpdatedAt DATETIME NULL,
    CONSTRAINT FK_Carts_Users FOREIGN KEY (UserId) REFERENCES Users(Id) ON DELETE CASCADE
);

CREATE TABLE CartItems (
    Id BIGINT IDENTITY(1,1) PRIMARY KEY,
    CartId UNIQUEIDENTIFIER NOT NULL,
    ProductId UNIQUEIDENTIFIER NOT NULL,
    Quantity DECIMAL(18,3) NOT NULL,
    UnitId TINYINT NOT NULL,
    UnitPriceAed DECIMAL(12,2) NOT NULL,
    CreatedAt DATETIME NOT NULL DEFAULT GETUTCDATE(),
    CONSTRAINT FK_CartItems_Carts FOREIGN KEY (CartId) REFERENCES Carts(CartId) ON DELETE CASCADE,
    CONSTRAINT FK_CartItems_Products FOREIGN KEY (ProductId) REFERENCES Products(ProductId),
    CONSTRAINT FK_CartItems_Units FOREIGN KEY (UnitId) REFERENCES Units(Id)
);
CREATE UNIQUE INDEX IX_CartItems_Cart_Product_Unit ON CartItems (CartId, ProductId, UnitId);

CREATE TABLE Addresses (
    Id UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
    UserId UNIQUEIDENTIFIER NOT NULL,
    CityId UNIQUEIDENTIFIER NOT NULL,
    AddressLine1 NVARCHAR(255) NOT NULL,
    AddressLine2 NVARCHAR(255) NULL,
    CONSTRAINT FK_Addresses_Users FOREIGN KEY (UserId) REFERENCES Users(Id),
    CONSTRAINT FK_Addresses_Cities FOREIGN KEY (CityId) REFERENCES Cities(Id)
);

CREATE TABLE NotificationTypes (
    Id TINYINT IDENTITY(1,1) PRIMARY KEY,
    Name NVARCHAR(255) NOT NULL
);

CREATE TABLE NotificationRoutes (
    Id UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
    Name NVARCHAR(255) NOT NULL
);

CREATE TABLE Notifications (
    Id UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
    Title NVARCHAR(255) NOT NULL,
    FromUserId UNIQUEIDENTIFIER NOT NULL,
    ToUserId UNIQUEIDENTIFIER NOT NULL,
    TypeId TINYINT NOT NULL,
    RouteId UNIQUEIDENTIFIER NOT NULL,
    Body NVARCHAR(255) NOT NULL,
    ReferenceId NVARCHAR(255) NOT NULL,
    CONSTRAINT FK_Notifications_FromUser FOREIGN KEY (FromUserId) REFERENCES Users(Id),
    CONSTRAINT FK_Notifications_ToUser FOREIGN KEY (ToUserId) REFERENCES Users(Id),
    CONSTRAINT FK_Notifications_Type FOREIGN KEY (TypeId) REFERENCES NotificationTypes(Id),
    CONSTRAINT FK_Notifications_Route FOREIGN KEY (RouteId) REFERENCES NotificationRoutes(Id)
);

CREATE TABLE CompanyImages (
    Id BIGINT IDENTITY(1,1) PRIMARY KEY,
    UserId UNIQUEIDENTIFIER NOT NULL,
    ImagePath NVARCHAR(500) NOT NULL,
    IsPrimary BIT NOT NULL DEFAULT 0,
    CreatedAt DATETIME NOT NULL DEFAULT GETUTCDATE(),
    CONSTRAINT FK_CompanyImages_Users FOREIGN KEY (UserId) REFERENCES Users(Id) ON DELETE CASCADE
);

CREATE TABLE ProductImages (
    Id BIGINT IDENTITY(1,1) PRIMARY KEY,
    ProductId UNIQUEIDENTIFIER NOT NULL,
    ImagePath NVARCHAR(500) NOT NULL,
    CreatedAt DATETIME NOT NULL DEFAULT GETUTCDATE(),
    CONSTRAINT FK_ProductImages_Products FOREIGN KEY (ProductId) REFERENCES Products(ProductId) ON DELETE CASCADE
);

CREATE TABLE ProductDocuments (
    Id BIGINT IDENTITY(1,1) PRIMARY KEY,
    ProductId UNIQUEIDENTIFIER NOT NULL,
    DocumentPath NVARCHAR(500) NOT NULL,
    CreatedAt DATETIME NOT NULL DEFAULT GETUTCDATE(),
    CONSTRAINT FK_ProductDocuments_Products FOREIGN KEY (ProductId) REFERENCES Products(ProductId) ON DELETE CASCADE
);

CREATE TABLE HomeBanners (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    ImagePath NVARCHAR(500) NOT NULL,
    LinkUrl NVARCHAR(1000) NOT NULL,
    DisplayOrder SMALLINT NOT NULL UNIQUE,
    CreatedAt DATETIME NOT NULL DEFAULT GETUTCDATE()
);

CREATE TABLE EmailOtps (
    Id BIGINT IDENTITY(1,1) PRIMARY KEY,
    Email NVARCHAR(250) NOT NULL,
    Code NVARCHAR(10) NOT NULL,
    ExpiresAt DATETIME NOT NULL,
    IsUsed BIT NOT NULL DEFAULT 0,
    CreatedAt DATETIME NOT NULL DEFAULT GETUTCDATE()
);

CREATE TABLE PasswordResetCodes (
    Id BIGINT IDENTITY(1,1) PRIMARY KEY,
    UserId UNIQUEIDENTIFIER NOT NULL,
    ProviderName VARCHAR(20) NOT NULL,
    Destination NVARCHAR(250) NOT NULL,
    Code VARCHAR(10) NOT NULL,
    ExpiresAt DATETIME NOT NULL,
    IsUsed BIT NOT NULL DEFAULT 0,
    CreatedAt DATETIME NOT NULL DEFAULT GETUTCDATE(),
    CONSTRAINT FK_PasswordResetCodes_Users FOREIGN KEY (UserId) REFERENCES Users(Id) ON DELETE CASCADE
);

ALTER TABLE Products ADD CONSTRAINT FK_Products_OriginCountry FOREIGN KEY (OriginCountryId) REFERENCES Countries(Id);
ALTER TABLE Products ADD CONSTRAINT FK_Products_DestinationCountry FOREIGN KEY (DestinationCountryId) REFERENCES Countries(Id);
ALTER TABLE Products ADD CONSTRAINT FK_Products_LoadingPort FOREIGN KEY (LoadingPortId) REFERENCES Ports(Id);
ALTER TABLE Products ADD CONSTRAINT FK_Products_ArrivalPort FOREIGN KEY (ArrivalPortId) REFERENCES Ports(Id);

INSERT INTO Roles (RoleName) VALUES (N'Admin'), (N'Seller'), (N'Buyer');
INSERT INTO Units (UnitNameEn) VALUES
(N'Ton'),
(N'Gram'),
(N'Kilogram'),
(N'Carton'),
(N'Bag'),
(N'Dozen'),
(N'Box'),
(N'Piece'),
(N'Packet'),
(N'Bundle'),
(N'Drum'),
(N'Bottle'),
(N'Tin'),
(N'Sack'),
(N'Case'),
(N'Pallet'),
(N'Liter'),
(N'Ml'),
(N'Jar');

INSERT INTO ProductTypes (TypeNameEn) VALUES
(N'Retail'),
(N'Booking'),
(N'Offers'),
(N'Requests');

INSERT INTO OfferStatuses (Id, NameEn) VALUES
(1, N'Pending'),
(2, N'Accepted'),
(3, N'Rejected');

INSERT INTO OrderStatus (Name) VALUES
(N'Ordered'),
(N'Approved'),
(N'Paid'),
(N'Shipping'),
(N'Delivered'),
(N'Cancelled');

SET IDENTITY_INSERT Categories ON;
INSERT INTO Categories (CategoryId, NameEn, ImgPath) VALUES
(1, N'Herbs', N'/images/categories/herbs.jpg'),
(2, N'Pulses', N'/images/categories/pulses.jpg'),
(3, N'Spices', N'/images/categories/spices.jpg'),
(4, N'Nuts', N'/images/categories/nuts.jpg'),
(5, N'Coffee', N'/images/categories/coffee.jpg'),
(6, N'Cardamom', N'/images/categories/cardamom.jpg'),
(7, N'Cocoa', N'/images/categories/cocoa.jpg'),
(8, N'Acids', N'/images/categories/acids.jpg'),
(9, N'Milk', N'/images/categories/milk.jpg'),
(10, N'Dates', N'/images/categories/dates.jpg'),
(11, N'Sugar', N'/images/categories/sugar.jpg'),
(12, N'Rice', N'/images/categories/rice.jpg'),
(13, N'Sweets', N'/images/categories/sweets.jpg'),
(14, N'Canned', N'/images/categories/canned-foods.jpg'),
(15, N'Flour', N'/images/categories/flour.jpg'),
(16, N'Beauty', N'/images/categories/beauty.jpg'),
(17, N'Poultry', N'/images/categories/poultry.jpg'),
(18, N'Frozen Foods', N'/images/categories/frozen-foods.jpg');
SET IDENTITY_INSERT Categories OFF;

