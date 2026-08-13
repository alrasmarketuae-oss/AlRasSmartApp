using DataLayer.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace DataLayer.Seeding;

public static class SupportCallbackRequestSchemaMigrator
{
    public static async Task EnsureAsync(IRasAlSouqDbContext db, CancellationToken cancellationToken = default)
    {
        var context = (DbContext)db;
        var connection = context.Database.GetDbConnection();
        await SqlSchemaHelper.OpenIfNeededAsync(connection, cancellationToken).ConfigureAwait(false);

        if (await SqlSchemaHelper.TableExistsAsync(connection, "SupportCallbackRequests", cancellationToken)
                .ConfigureAwait(false))
        {
            return;
        }

        var userIdType = await SqlSchemaHelper.GetColumnSqlTypeAsync(connection, "Users", "Id", cancellationToken)
            .ConfigureAwait(false)
            ?? throw new InvalidOperationException(
                "Cannot create SupportCallbackRequests: dbo.Users.Id was not found.");

        var sql = string.Format(CreateTableTemplate, userIdType);
        await SqlSchemaHelper.ExecuteBatchAsync(connection, sql, cancellationToken).ConfigureAwait(false);
    }

    private const string CreateTableTemplate = """
        CREATE TABLE dbo.SupportCallbackRequests (
            Id UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_SupportCallbackRequests PRIMARY KEY,
            UserId {0} NULL,
            FullName NVARCHAR(200) NOT NULL,
            Phone NVARCHAR(50) NOT NULL,
            Email NVARCHAR(256) NOT NULL,
            Question NVARCHAR(1000) NULL,
            Language NVARCHAR(10) NOT NULL CONSTRAINT DF_SupportCallbackRequests_Language DEFAULT N'ar',
            Status NVARCHAR(30) NOT NULL CONSTRAINT DF_SupportCallbackRequests_Status DEFAULT N'Pending',
            Source NVARCHAR(80) NULL,
            AiConversationId NVARCHAR(64) NULL,
            CreatedAtUtc DATETIME2 NOT NULL CONSTRAINT DF_SupportCallbackRequests_CreatedAtUtc DEFAULT SYSUTCDATETIME(),
            ContactedAtUtc DATETIME2 NULL,
            ContactedByAdminUserId {0} NULL,
            AdminNotes NVARCHAR(500) NULL,
            CONSTRAINT FK_SupportCallbackRequests_User FOREIGN KEY (UserId) REFERENCES dbo.Users(Id),
            CONSTRAINT FK_SupportCallbackRequests_Admin FOREIGN KEY (ContactedByAdminUserId) REFERENCES dbo.Users(Id)
        );

        CREATE INDEX IX_SupportCallbackRequests_CreatedAtUtc ON dbo.SupportCallbackRequests (CreatedAtUtc DESC);
        CREATE INDEX IX_SupportCallbackRequests_Status_CreatedAtUtc ON dbo.SupportCallbackRequests (Status, CreatedAtUtc DESC);
        CREATE INDEX IX_SupportCallbackRequests_UserId_CreatedAtUtc ON dbo.SupportCallbackRequests (UserId, CreatedAtUtc DESC);
        """;
}
