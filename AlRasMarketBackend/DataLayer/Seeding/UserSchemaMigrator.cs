using DataLayer.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace DataLayer.Seeding;

/// <summary>Adds Users.IsCustomer and Users.IsApproved if missing (idempotent).</summary>
public static class UserSchemaMigrator
{
    public static async Task EnsureAsync(IRasAlSouqDbContext db, CancellationToken cancellationToken = default)
    {
        var context = (DbContext)db;
        var connection = context.Database.GetDbConnection();
        await SqlSchemaHelper.OpenIfNeededAsync(connection, cancellationToken).ConfigureAwait(false);

        if (!await SqlSchemaHelper.ColumnExistsAsync(connection, "Users", "IsCustomer", cancellationToken)
                .ConfigureAwait(false))
        {
            await SqlSchemaHelper.ExecuteBatchAsync(connection,
                "ALTER TABLE dbo.Users ADD IsCustomer BIT NULL;",
                cancellationToken).ConfigureAwait(false);

            await SqlSchemaHelper.ExecuteBatchAsync(connection,
                "UPDATE dbo.Users SET IsCustomer = 0 WHERE IsCustomer IS NULL;",
                cancellationToken).ConfigureAwait(false);
        }

        if (!await SqlSchemaHelper.ColumnExistsAsync(connection, "Users", "IsApproved", cancellationToken)
                .ConfigureAwait(false))
        {
            await SqlSchemaHelper.ExecuteBatchAsync(connection,
                "ALTER TABLE dbo.Users ADD IsApproved BIT NOT NULL CONSTRAINT DF_Users_IsApproved DEFAULT 0;",
                cancellationToken).ConfigureAwait(false);

            await SqlSchemaHelper.ExecuteBatchAsync(connection,
                """
                UPDATE dbo.Users
                SET IsApproved = CASE
                    WHEN RoleId = 2 THEN CASE WHEN IsActive = 1 THEN 1 ELSE 0 END
                    ELSE 1
                END;
                """,
                cancellationToken).ConfigureAwait(false);
        }

        if (!await SqlSchemaHelper.ColumnExistsAsync(connection, "Users", "PreferredLanguage", cancellationToken)
                .ConfigureAwait(false))
        {
            await SqlSchemaHelper.ExecuteBatchAsync(connection,
                "ALTER TABLE dbo.Users ADD PreferredLanguage VARCHAR(10) NOT NULL CONSTRAINT DF_Users_PreferredLanguage DEFAULT 'en';",
                cancellationToken).ConfigureAwait(false);
        }

        if (!await SqlSchemaHelper.ColumnExistsAsync(connection, "Users", "IsRejected", cancellationToken)
                .ConfigureAwait(false))
        {
            await SqlSchemaHelper.ExecuteBatchAsync(connection,
                "ALTER TABLE dbo.Users ADD IsRejected BIT NOT NULL CONSTRAINT DF_Users_IsRejected DEFAULT 0;",
                cancellationToken).ConfigureAwait(false);
        }

        if (!await SqlSchemaHelper.ColumnExistsAsync(connection, "Users", "RejectionReason", cancellationToken)
                .ConfigureAwait(false))
        {
            await SqlSchemaHelper.ExecuteBatchAsync(connection,
                "ALTER TABLE dbo.Users ADD RejectionReason NVARCHAR(500) NULL;",
                cancellationToken).ConfigureAwait(false);
        }

        if (!await SqlSchemaHelper.ColumnExistsAsync(connection, "Users", "PendingProfileChanges", cancellationToken)
                .ConfigureAwait(false))
        {
            await SqlSchemaHelper.ExecuteBatchAsync(connection,
                "ALTER TABLE dbo.Users ADD PendingProfileChanges NVARCHAR(MAX) NULL;",
                cancellationToken).ConfigureAwait(false);
        }

        if (!await SqlSchemaHelper.ColumnExistsAsync(connection, "Users", "Website", cancellationToken)
                .ConfigureAwait(false))
        {
            await SqlSchemaHelper.ExecuteBatchAsync(connection,
                "ALTER TABLE dbo.Users ADD Website NVARCHAR(500) NULL;",
                cancellationToken).ConfigureAwait(false);
        }
    }
}
