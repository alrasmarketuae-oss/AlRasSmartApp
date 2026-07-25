using DataLayer.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace DataLayer.Seeding;

public static class NotificationSchemaMigrator
{
    public static async Task EnsureAsync(IRasAlSouqDbContext db, CancellationToken cancellationToken = default)
    {
        var context = (DbContext)db;
        var connection = context.Database.GetDbConnection();
        await SqlSchemaHelper.OpenIfNeededAsync(connection, cancellationToken).ConfigureAwait(false);

        if (!await SqlSchemaHelper.TableExistsAsync(connection, "Notifications", cancellationToken).ConfigureAwait(false))
        {
            return;
        }

        if (!await SqlSchemaHelper.ColumnExistsAsync(connection, "Notifications", "IsRead", cancellationToken).ConfigureAwait(false))
        {
            await SqlSchemaHelper.ExecuteBatchAsync(connection, """
                ALTER TABLE dbo.Notifications ADD IsRead BIT NOT NULL
                    CONSTRAINT DF_Notifications_IsRead DEFAULT 0;
                """, cancellationToken).ConfigureAwait(false);
        }

        if (!await SqlSchemaHelper.ColumnExistsAsync(connection, "Notifications", "CreatedAt", cancellationToken).ConfigureAwait(false))
        {
            await SqlSchemaHelper.ExecuteBatchAsync(connection, """
                ALTER TABLE dbo.Notifications ADD CreatedAt DATETIME2 NOT NULL
                    CONSTRAINT DF_Notifications_CreatedAt DEFAULT SYSUTCDATETIME();
                CREATE INDEX IX_Notifications_ToUserId_CreatedAt
                    ON dbo.Notifications (ToUserId, CreatedAt DESC);
                CREATE INDEX IX_Notifications_ToUserId_IsRead
                    ON dbo.Notifications (ToUserId, IsRead);
                """, cancellationToken).ConfigureAwait(false);
        }
    }
}
