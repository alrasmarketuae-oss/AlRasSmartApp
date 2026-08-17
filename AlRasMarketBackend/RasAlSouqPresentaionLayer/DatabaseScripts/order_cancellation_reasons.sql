-- Runtime equivalent: OrderCancellationSchemaMigrator (applied on API startup).
-- Safe for existing orders: CancellationReasonId / CancelledAt / CancelledByUserId / CancellationNote are nullable.

IF OBJECT_ID(N'dbo.OrderCancellationReasons', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.OrderCancellationReasons (
        Id TINYINT NOT NULL CONSTRAINT PK_OrderCancellationReasons PRIMARY KEY,
        NameEn NVARCHAR(200) NOT NULL,
        NameAr NVARCHAR(200) NOT NULL,
        IsActive BIT NOT NULL CONSTRAINT DF_OrderCancellationReasons_IsActive DEFAULT 1,
        CreatedAt DATETIME2 NOT NULL CONSTRAINT DF_OrderCancellationReasons_CreatedAt DEFAULT SYSUTCDATETIME()
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.OrderCancellationReasons WHERE Id = 1)
    INSERT INTO dbo.OrderCancellationReasons (Id, NameEn, NameAr, IsActive)
    VALUES (1, N'Buyer requested cancellation', N'طلب المشتري إلغاء الصفقة', 1);
IF NOT EXISTS (SELECT 1 FROM dbo.OrderCancellationReasons WHERE Id = 2)
    INSERT INTO dbo.OrderCancellationReasons (Id, NameEn, NameAr, IsActive)
    VALUES (2, N'Supplier unavailable', N'المورد غير متاح', 1);
IF NOT EXISTS (SELECT 1 FROM dbo.OrderCancellationReasons WHERE Id = 3)
    INSERT INTO dbo.OrderCancellationReasons (Id, NameEn, NameAr, IsActive)
    VALUES (3, N'Product unavailable', N'المنتج غير متوفر', 1);
IF NOT EXISTS (SELECT 1 FROM dbo.OrderCancellationReasons WHERE Id = 4)
    INSERT INTO dbo.OrderCancellationReasons (Id, NameEn, NameAr, IsActive)
    VALUES (4, N'Payment issue', N'مشكلة في الدفع', 1);
IF NOT EXISTS (SELECT 1 FROM dbo.OrderCancellationReasons WHERE Id = 5)
    INSERT INTO dbo.OrderCancellationReasons (Id, NameEn, NameAr, IsActive)
    VALUES (5, N'Admin cancelled', N'ألغاه المسؤول', 1);
IF NOT EXISTS (SELECT 1 FROM dbo.OrderCancellationReasons WHERE Id = 6)
    INSERT INTO dbo.OrderCancellationReasons (Id, NameEn, NameAr, IsActive)
    VALUES (6, N'Other', N'سبب آخر', 1);
GO

IF COL_LENGTH(N'dbo.Orders', N'CancellationReasonId') IS NULL
BEGIN
    ALTER TABLE dbo.Orders ADD CancellationReasonId TINYINT NULL;
    ALTER TABLE dbo.Orders ADD CONSTRAINT FK_Orders_OrderCancellationReasons
        FOREIGN KEY (CancellationReasonId) REFERENCES dbo.OrderCancellationReasons(Id);
END
GO

IF COL_LENGTH(N'dbo.Orders', N'CancelledAt') IS NULL
    ALTER TABLE dbo.Orders ADD CancelledAt DATETIME2 NULL;
GO

IF COL_LENGTH(N'dbo.Orders', N'CancelledByUserId') IS NULL
BEGIN
    ALTER TABLE dbo.Orders ADD CancelledByUserId UNIQUEIDENTIFIER NULL;
    ALTER TABLE dbo.Orders ADD CONSTRAINT FK_Orders_CancelledByUser
        FOREIGN KEY (CancelledByUserId) REFERENCES dbo.Users(Id);
END
GO

IF COL_LENGTH(N'dbo.Orders', N'CancellationNote') IS NULL
    ALTER TABLE dbo.Orders ADD CancellationNote NVARCHAR(2000) NULL;
GO
