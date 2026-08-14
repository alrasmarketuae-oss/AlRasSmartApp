using DataLayer.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace DataLayer.Seeding;

public static class UserFeedbackSubmissionSchemaMigrator
{
    public static async Task EnsureAsync(IRasAlSouqDbContext db, CancellationToken cancellationToken = default)
    {
        var context = (DbContext)db;
        var connection = context.Database.GetDbConnection();
        await SqlSchemaHelper.OpenIfNeededAsync(connection, cancellationToken).ConfigureAwait(false);

        if (await SqlSchemaHelper.TableExistsAsync(connection, "UserFeedbackSubmissions", cancellationToken)
                .ConfigureAwait(false))
        {
            return;
        }

        var userIdType = await SqlSchemaHelper.GetColumnSqlTypeAsync(connection, "Users", "Id", cancellationToken)
            .ConfigureAwait(false)
            ?? throw new InvalidOperationException(
                "Cannot create UserFeedbackSubmissions: dbo.Users.Id was not found.");

        var sql = string.Format(CreateTableTemplate, userIdType);
        await SqlSchemaHelper.ExecuteBatchAsync(connection, sql, cancellationToken).ConfigureAwait(false);
    }

    private const string CreateTableTemplate = """
        CREATE TABLE dbo.UserFeedbackSubmissions (
            Id UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_UserFeedbackSubmissions PRIMARY KEY,
            UserId {0} NULL,
            Type NVARCHAR(20) NOT NULL,
            Subject NVARCHAR(200) NOT NULL,
            Message NVARCHAR(2000) NOT NULL,
            OrderReference NVARCHAR(80) NULL,
            FullName NVARCHAR(200) NOT NULL,
            Email NVARCHAR(256) NULL,
            Phone NVARCHAR(50) NULL,
            Language NVARCHAR(10) NOT NULL CONSTRAINT DF_UserFeedbackSubmissions_Language DEFAULT N'ar',
            Status NVARCHAR(30) NOT NULL CONSTRAINT DF_UserFeedbackSubmissions_Status DEFAULT N'Pending',
            Source NVARCHAR(80) NULL,
            AiConversationId NVARCHAR(64) NULL,
            CreatedAtUtc DATETIME2 NOT NULL CONSTRAINT DF_UserFeedbackSubmissions_CreatedAtUtc DEFAULT SYSUTCDATETIME(),
            ResolvedAtUtc DATETIME2 NULL,
            ResolvedByAdminUserId {0} NULL,
            AdminNotes NVARCHAR(500) NULL,
            CONSTRAINT FK_UserFeedbackSubmissions_User FOREIGN KEY (UserId) REFERENCES dbo.Users(Id),
            CONSTRAINT FK_UserFeedbackSubmissions_Admin FOREIGN KEY (ResolvedByAdminUserId) REFERENCES dbo.Users(Id)
        );

        CREATE INDEX IX_UserFeedbackSubmissions_CreatedAtUtc ON dbo.UserFeedbackSubmissions (CreatedAtUtc DESC);
        CREATE INDEX IX_UserFeedbackSubmissions_Status_CreatedAtUtc ON dbo.UserFeedbackSubmissions (Status, CreatedAtUtc DESC);
        CREATE INDEX IX_UserFeedbackSubmissions_Type_CreatedAtUtc ON dbo.UserFeedbackSubmissions (Type, CreatedAtUtc DESC);
        CREATE INDEX IX_UserFeedbackSubmissions_UserId_CreatedAtUtc ON dbo.UserFeedbackSubmissions (UserId, CreatedAtUtc DESC);
        """;
}
