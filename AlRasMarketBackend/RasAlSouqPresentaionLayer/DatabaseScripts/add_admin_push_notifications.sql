-- Admin broadcast push notification history (created automatically at startup via AdminPushNotificationSchemaMigrator)
IF OBJECT_ID(N'dbo.AdminPushNotifications', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.AdminPushNotifications (
        Id UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
        Title NVARCHAR(255) NOT NULL,
        Body NVARCHAR(1000) NOT NULL,
        Audience NVARCHAR(50) NOT NULL,
        CreatedAt DATETIME NOT NULL CONSTRAINT DF_AdminPushNotifications_CreatedAt DEFAULT GETUTCDATE(),
        CreatedByAdminId UNIQUEIDENTIFIER NULL,
        SentCount INT NOT NULL CONSTRAINT DF_AdminPushNotifications_SentCount DEFAULT 0,
        FailedCount INT NOT NULL CONSTRAINT DF_AdminPushNotifications_FailedCount DEFAULT 0,
        Type NVARCHAR(100) NULL
    );

    CREATE INDEX IX_AdminPushNotifications_CreatedAt ON dbo.AdminPushNotifications (CreatedAt DESC);
    CREATE INDEX IX_AdminPushNotifications_Audience ON dbo.AdminPushNotifications (Audience, CreatedAt DESC);
END;
