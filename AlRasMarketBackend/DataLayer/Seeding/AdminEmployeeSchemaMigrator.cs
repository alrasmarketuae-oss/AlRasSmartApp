using DataLayer.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace DataLayer.Seeding;

/// <summary>Employee role, permissions, and support chat assignment tables (idempotent).</summary>
public static class AdminEmployeeSchemaMigrator
{
    public static async Task EnsureAsync(IRasAlSouqDbContext db, CancellationToken cancellationToken = default)
    {
        var context = (DbContext)db;
        var connection = context.Database.GetDbConnection();
        await SqlSchemaHelper.OpenIfNeededAsync(connection, cancellationToken).ConfigureAwait(false);

        await SqlSchemaHelper.ExecuteBatchAsync(connection, EnsureEmployeeRoleBatch, cancellationToken)
            .ConfigureAwait(false);

        if (!await SqlSchemaHelper.TableExistsAsync(connection, "UserAdminPermissions", cancellationToken)
                .ConfigureAwait(false))
        {
            var userIdType = await SqlSchemaHelper.GetColumnSqlTypeAsync(connection, "Users", "Id", cancellationToken)
                .ConfigureAwait(false)
                ?? throw new InvalidOperationException("Cannot create UserAdminPermissions: dbo.Users.Id was not found.");

            var createPermissionsSql = string.Format(CreateUserAdminPermissionsTemplate, userIdType);
            await SqlSchemaHelper.ExecuteBatchAsync(connection, createPermissionsSql, cancellationToken)
                .ConfigureAwait(false);
        }

        if (!await SqlSchemaHelper.TableExistsAsync(connection, "ChatSupportAssignments", cancellationToken)
                .ConfigureAwait(false))
        {
            var userIdType = await SqlSchemaHelper.GetColumnSqlTypeAsync(connection, "Users", "Id", cancellationToken)
                .ConfigureAwait(false)
                ?? throw new InvalidOperationException("Cannot create ChatSupportAssignments: dbo.Users.Id was not found.");

            var createAssignmentsSql = string.Format(CreateChatSupportAssignmentsTemplate, userIdType, userIdType);
            await SqlSchemaHelper.ExecuteBatchAsync(connection, createAssignmentsSql, cancellationToken)
                .ConfigureAwait(false);
        }
    }

    private const string EnsureEmployeeRoleBatch = """
        IF NOT EXISTS (SELECT 1 FROM dbo.Roles WHERE Id = 4)
        BEGIN
            SET IDENTITY_INSERT dbo.Roles ON;
            INSERT INTO dbo.Roles (Id, RoleName) VALUES (4, N'Employee');
            SET IDENTITY_INSERT dbo.Roles OFF;
        END
        """;

    private const string CreateUserAdminPermissionsTemplate = """
        CREATE TABLE dbo.UserAdminPermissions (
            UserId {0} NOT NULL,
            PermissionKey NVARCHAR(64) NOT NULL,
            CONSTRAINT PK_UserAdminPermissions PRIMARY KEY (UserId, PermissionKey),
            CONSTRAINT FK_UserAdminPermissions_User FOREIGN KEY (UserId) REFERENCES dbo.Users(Id) ON DELETE CASCADE
        );

        CREATE INDEX IX_UserAdminPermissions_PermissionKey ON dbo.UserAdminPermissions (PermissionKey);
        """;

    private const string CreateChatSupportAssignmentsTemplate = """
        CREATE TABLE dbo.ChatSupportAssignments (
            Id UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
            CustomerUserId {0} NOT NULL,
            AgentUserId {1} NOT NULL,
            AssignedAtUtc DATETIME NOT NULL CONSTRAINT DF_ChatSupportAssignments_AssignedAtUtc DEFAULT GETUTCDATE(),
            ReleasedAtUtc DATETIME NULL,
            CONSTRAINT FK_ChatSupportAssignments_Customer FOREIGN KEY (CustomerUserId) REFERENCES dbo.Users(Id),
            CONSTRAINT FK_ChatSupportAssignments_Agent FOREIGN KEY (AgentUserId) REFERENCES dbo.Users(Id)
        );

        CREATE INDEX IX_ChatSupportAssignments_Customer_Active
            ON dbo.ChatSupportAssignments (CustomerUserId)
            WHERE ReleasedAtUtc IS NULL;

        CREATE INDEX IX_ChatSupportAssignments_Agent_Active
            ON dbo.ChatSupportAssignments (AgentUserId)
            WHERE ReleasedAtUtc IS NULL;
        """;
}
