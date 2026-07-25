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

        if (await SqlSchemaHelper.TableExistsAsync(connection, "MissedProductSearches", cancellationToken)
                .ConfigureAwait(false))
        {
            return;
        }

        var userIdType = await SqlSchemaHelper.GetColumnSqlTypeAsync(connection, "Users", "Id", cancellationToken)
            .ConfigureAwait(false)
            ?? throw new InvalidOperationException("Cannot create MissedProductSearches: dbo.Users.Id was not found.");

        var sql = string.Format(CreateTableTemplate, userIdType);
        await SqlSchemaHelper.ExecuteBatchAsync(connection, sql, cancellationToken).ConfigureAwait(false);
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
            CONSTRAINT FK_MissedProductSearches_User FOREIGN KEY (UserId) REFERENCES dbo.Users(Id)
        );

        CREATE INDEX IX_MissedProductSearches_CreatedAtUtc ON dbo.MissedProductSearches (CreatedAtUtc DESC);
        CREATE INDEX IX_MissedProductSearches_QueryText ON dbo.MissedProductSearches (QueryText);
        CREATE INDEX IX_MissedProductSearches_UserId_CreatedAtUtc ON dbo.MissedProductSearches (UserId, CreatedAtUtc DESC);
        """;
}
