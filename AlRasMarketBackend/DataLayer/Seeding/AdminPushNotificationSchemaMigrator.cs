using DataLayer.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace DataLayer.Seeding;

public static class AdminPushNotificationSchemaMigrator
{
    public static async Task EnsureAsync(IRasAlSouqDbContext db, CancellationToken cancellationToken = default)
    {
        var context = (DbContext)db;
        var connection = context.Database.GetDbConnection();
        await SqlSchemaHelper.OpenIfNeededAsync(connection, cancellationToken).ConfigureAwait(false);

        if (!await SqlSchemaHelper.TableExistsAsync(connection, "AdminPushNotifications", cancellationToken).ConfigureAwait(false))
        {
            await SqlSchemaHelper.ExecuteBatchAsync(connection, """
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
                """, cancellationToken).ConfigureAwait(false);
        }

        if (await SqlSchemaHelper.TableExistsAsync(connection, "AdminPushNotifications", cancellationToken).ConfigureAwait(false)
            && !await SqlSchemaHelper.ColumnExistsAsync(connection, "AdminPushNotifications", "TargetUserId", cancellationToken).ConfigureAwait(false))
        {
            await SqlSchemaHelper.ExecuteBatchAsync(connection, """
                ALTER TABLE dbo.AdminPushNotifications ADD TargetUserId UNIQUEIDENTIFIER NULL;
                CREATE INDEX IX_AdminPushNotifications_TargetUserId ON dbo.AdminPushNotifications (TargetUserId);
                """, cancellationToken).ConfigureAwait(false);
        }

        if (await SqlSchemaHelper.TableExistsAsync(connection, "AdminPushNotifications", cancellationToken).ConfigureAwait(false)
            && !await SqlSchemaHelper.ColumnExistsAsync(connection, "AdminPushNotifications", "TitleAr", cancellationToken).ConfigureAwait(false))
        {
            await SqlSchemaHelper.ExecuteBatchAsync(connection, """
                ALTER TABLE dbo.AdminPushNotifications ADD TitleAr NVARCHAR(255) NULL;
                ALTER TABLE dbo.AdminPushNotifications ADD BodyAr NVARCHAR(1000) NULL;
                """, cancellationToken).ConfigureAwait(false);
        }
    }
}
