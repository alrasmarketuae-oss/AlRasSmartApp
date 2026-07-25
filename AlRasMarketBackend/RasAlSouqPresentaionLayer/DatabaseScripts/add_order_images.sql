-- OrderImages table for order image paths (files stored under /product-images/).

IF OBJECT_ID(N'dbo.OrderImages', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.OrderImages (
        Id BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        OrderId BIGINT NOT NULL,
        ImagePath NVARCHAR(500) NOT NULL,
        UploadedByUserId UNIQUEIDENTIFIER NOT NULL,
        CreatedAt DATETIME NOT NULL CONSTRAINT DF_OrderImages_CreatedAt DEFAULT GETUTCDATE(),
        CONSTRAINT FK_OrderImages_Orders FOREIGN KEY (OrderId) REFERENCES dbo.Orders(Id) ON DELETE CASCADE
    );

    CREATE INDEX IX_OrderImages_OrderId ON dbo.OrderImages(OrderId);
END
GO
