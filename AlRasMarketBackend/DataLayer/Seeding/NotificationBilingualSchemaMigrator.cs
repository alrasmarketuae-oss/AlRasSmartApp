using DataLayer.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace DataLayer.Seeding;

/// <summary>
/// Adds Notifications.TitleAr / BodyAr and widens Body for bilingual inbox storage.
/// </summary>
public static class NotificationBilingualSchemaMigrator
{
    public static async Task EnsureAsync(IRasAlSouqDbContext db, CancellationToken cancellationToken = default)
    {
        var context = (DbContext)db;
        var connection = context.Database.GetDbConnection();
        await SqlSchemaHelper.OpenIfNeededAsync(connection, cancellationToken).ConfigureAwait(false);

        if (!await SqlSchemaHelper.ColumnExistsAsync(connection, "Notifications", "TitleAr", cancellationToken)
                .ConfigureAwait(false))
        {
            await SqlSchemaHelper.ExecuteBatchAsync(
                connection,
                """
                ALTER TABLE dbo.Notifications ADD TitleAr NVARCHAR(255) NULL;
                """,
                cancellationToken).ConfigureAwait(false);
        }

        if (!await SqlSchemaHelper.ColumnExistsAsync(connection, "Notifications", "BodyAr", cancellationToken)
                .ConfigureAwait(false))
        {
            await SqlSchemaHelper.ExecuteBatchAsync(
                connection,
                """
                ALTER TABLE dbo.Notifications ADD BodyAr NVARCHAR(1000) NULL;
                """,
                cancellationToken).ConfigureAwait(false);
        }

        // Widen Body if it is still the old NVARCHAR(255) (max_length 510 bytes for nvarchar).
        await SqlSchemaHelper.ExecuteBatchAsync(
            connection,
            """
            IF EXISTS (
                SELECT 1
                FROM sys.columns
                WHERE object_id = OBJECT_ID(N'dbo.Notifications')
                  AND name = N'Body'
                  AND max_length = 510
            )
            BEGIN
                ALTER TABLE dbo.Notifications ALTER COLUMN Body NVARCHAR(1000) NOT NULL;
            END
            """,
            cancellationToken).ConfigureAwait(false);
    }
}
