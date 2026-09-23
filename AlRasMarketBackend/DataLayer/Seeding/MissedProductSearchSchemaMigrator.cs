using DataLayer.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace DataLayer.Seeding;

public static class MissedProductSearchSchemaMigrator
{
    public static async Task EnsureAsync(IRasAlSouqDbContext db, CancellationToken cancellationToken = default)
    {
        var context = (DbContext)db;
        var connection = context.Database.GetDbConnection();
        await SqlSchemaHelper.OpenIfNeededAsync(connection, cancellationToken).ConfigureAwait(false);

        if (!await SqlSchemaHelper.TableExistsAsync(connection, "MissedProductSearches", cancellationToken)
                .ConfigureAwait(false))
        {
            var userIdType = await SqlSchemaHelper.GetColumnSqlTypeAsync(connection, "Users", "Id", cancellationToken)
                .ConfigureAwait(false)
                ?? throw new InvalidOperationException("Cannot create MissedProductSearches: dbo.Users.Id was not found.");

            var sql = string.Format(CreateTableTemplate, userIdType);
            await SqlSchemaHelper.ExecuteBatchAsync(connection, sql, cancellationToken).ConfigureAwait(false);
            return;
        }

        if (!await SqlSchemaHelper.ColumnExistsAsync(connection, "MissedProductSearches", "NotifiedAtUtc", cancellationToken)
                .ConfigureAwait(false))
        {
            await SqlSchemaHelper.ExecuteBatchAsync(
                connection,
                "ALTER TABLE dbo.MissedProductSearches ADD NotifiedAtUtc DATETIME2 NULL;",
                cancellationToken).ConfigureAwait(false);
        }

        if (!await SqlSchemaHelper.ColumnExistsAsync(connection, "MissedProductSearches", "MatchedProductId", cancellationToken)
                .ConfigureAwait(false))
        {
            await SqlSchemaHelper.ExecuteBatchAsync(
                connection,
                "ALTER TABLE dbo.MissedProductSearches ADD MatchedProductId UNIQUEIDENTIFIER NULL;",
                cancellationToken).ConfigureAwait(false);
        }

        await SqlSchemaHelper.EnsureIndexAsync(
            connection,
            "MissedProductSearches",
            "IX_MissedProductSearches_PendingNotify",
            """
            CREATE INDEX IX_MissedProductSearches_PendingNotify
            ON dbo.MissedProductSearches (CreatedAtUtc DESC)
            INCLUDE (UserId, QueryText, NotifiedAtUtc)
            WHERE NotifiedAtUtc IS NULL AND UserId IS NOT NULL;
            """,
            cancellationToken).ConfigureAwait(false);
    }

    private const string CreateTableTemplate = """
        CREATE TABLE dbo.MissedProductSearches (
            Id UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_MissedProductSearches PRIMARY KEY,
            QueryText NVARCHAR(200) NOT NULL,
            UserId {0} NULL,
            UserDisplayName NVARCHAR(200) NULL,
            UserEmail NVARCHAR(256) NULL,
            UserPhone NVARCHAR(50) NULL,
            CreatedAtUtc DATETIME2 NOT NULL CONSTRAINT DF_MissedProductSearches_CreatedAtUtc DEFAULT SYSUTCDATETIME(),
            Notes NVARCHAR(500) NULL,
            NotifiedAtUtc DATETIME2 NULL,
            MatchedProductId UNIQUEIDENTIFIER NULL,
            CONSTRAINT FK_MissedProductSearches_User FOREIGN KEY (UserId) REFERENCES dbo.Users(Id)
                ON DELETE SET NULL
        );

        CREATE INDEX IX_MissedProductSearches_CreatedAtUtc ON dbo.MissedProductSearches (CreatedAtUtc DESC);
        CREATE INDEX IX_MissedProductSearches_QueryText ON dbo.MissedProductSearches (QueryText);
        CREATE INDEX IX_MissedProductSearches_UserId_CreatedAtUtc ON dbo.MissedProductSearches (UserId, CreatedAtUtc DESC);
        CREATE INDEX IX_MissedProductSearches_PendingNotify
            ON dbo.MissedProductSearches (CreatedAtUtc DESC)
            INCLUDE (UserId, QueryText, NotifiedAtUtc)
            WHERE NotifiedAtUtc IS NULL AND UserId IS NOT NULL;
        """;
}
