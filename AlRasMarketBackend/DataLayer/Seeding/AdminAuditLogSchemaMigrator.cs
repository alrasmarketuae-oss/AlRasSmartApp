using DataLayer.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace DataLayer.Seeding;

/// <summary>Creates AdminAuditLogs table (Guid PK) for admin action history.</summary>
public static class AdminAuditLogSchemaMigrator
{
    public static async Task EnsureAsync(IRasAlSouqDbContext db, CancellationToken cancellationToken = default)
    {
        var context = (DbContext)db;
        var connection = context.Database.GetDbConnection();
        await SqlSchemaHelper.OpenIfNeededAsync(connection, cancellationToken).ConfigureAwait(false);

        if (await SqlSchemaHelper.TableExistsAsync(connection, "AdminAuditLogs", cancellationToken)
                .ConfigureAwait(false))
        {
            return;
        }

        var userIdType = await SqlSchemaHelper.GetColumnSqlTypeAsync(connection, "Users", "Id", cancellationToken)
            .ConfigureAwait(false)
            ?? throw new InvalidOperationException("Cannot create AdminAuditLogs: dbo.Users.Id was not found.");

        var sql = string.Format(CreateTableTemplate, userIdType);
        await SqlSchemaHelper.ExecuteBatchAsync(connection, sql, cancellationToken).ConfigureAwait(false);
    }

    private const string CreateTableTemplate = """
        CREATE TABLE dbo.AdminAuditLogs (
            Id UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_AdminAuditLogs PRIMARY KEY,
            ActorUserId {0} NOT NULL,
            ActorName NVARCHAR(200) NOT NULL,
            Action VARCHAR(80) NOT NULL,
            EntityType VARCHAR(50) NOT NULL,
            EntityId NVARCHAR(64) NULL,
            Summary NVARCHAR(500) NOT NULL,
            DetailsJson NVARCHAR(MAX) NULL,
            CreatedAtUtc DATETIME2 NOT NULL CONSTRAINT DF_AdminAuditLogs_CreatedAtUtc DEFAULT SYSUTCDATETIME(),
            CONSTRAINT FK_AdminAuditLogs_Actor FOREIGN KEY (ActorUserId) REFERENCES dbo.Users(Id)
        );

        CREATE INDEX IX_AdminAuditLogs_CreatedAtUtc ON dbo.AdminAuditLogs (CreatedAtUtc DESC);
        CREATE INDEX IX_AdminAuditLogs_Action_CreatedAtUtc ON dbo.AdminAuditLogs (Action, CreatedAtUtc DESC);
        CREATE INDEX IX_AdminAuditLogs_EntityType_EntityId ON dbo.AdminAuditLogs (EntityType, EntityId);
        CREATE INDEX IX_AdminAuditLogs_ActorUserId_CreatedAtUtc ON dbo.AdminAuditLogs (ActorUserId, CreatedAtUtc DESC);
        """;
}
