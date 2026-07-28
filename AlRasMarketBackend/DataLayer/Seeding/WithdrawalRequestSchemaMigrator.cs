using DataLayer.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace DataLayer.Seeding;

public static class WithdrawalRequestSchemaMigrator
{
    public static async Task EnsureAsync(IRasAlSouqDbContext db, CancellationToken cancellationToken = default)
    {
        var context = (DbContext)db;
        var connection = context.Database.GetDbConnection();
        await SqlSchemaHelper.OpenIfNeededAsync(connection, cancellationToken).ConfigureAwait(false);

        if (await SqlSchemaHelper.TableExistsAsync(connection, "WithdrawalRequests", cancellationToken).ConfigureAwait(false))
        {
            return;
        }

        var userIdType = await SqlSchemaHelper.GetColumnSqlTypeAsync(connection, "Users", "Id", cancellationToken)
            .ConfigureAwait(false)
            ?? throw new InvalidOperationException("Cannot create WithdrawalRequests: dbo.Users.Id was not found.");

        var ibanIdType = await SqlSchemaHelper.GetColumnSqlTypeAsync(connection, "UserIbans", "Id", cancellationToken)
            .ConfigureAwait(false)
            ?? throw new InvalidOperationException("Cannot create WithdrawalRequests: dbo.UserIbans.Id was not found.");

        var sql = string.Format(CreateTableTemplate, userIdType, ibanIdType);
        await SqlSchemaHelper.ExecuteBatchAsync(connection, sql, cancellationToken).ConfigureAwait(false);
    }

    private const string CreateTableTemplate = """
        CREATE TABLE dbo.WithdrawalRequests (
            Id NVARCHAR(64) NOT NULL CONSTRAINT PK_WithdrawalRequests PRIMARY KEY,
            UserId {0} NOT NULL,
            UserIbanId {1} NOT NULL,
            Amount DECIMAL(18,2) NOT NULL,
            StatusId TINYINT NOT NULL CONSTRAINT DF_WithdrawalRequests_StatusId DEFAULT 1,
            Notes NVARCHAR(500) NULL,
            IbanSnapshot VARCHAR(34) NOT NULL,
            AccountHolderNameSnapshot NVARCHAR(150) NULL,
            BankNameSnapshot NVARCHAR(150) NULL,
            RequestedAtUtc DATETIME2 NOT NULL CONSTRAINT DF_WithdrawalRequests_RequestedAtUtc DEFAULT SYSUTCDATETIME(),
            CompletedAtUtc DATETIME2 NULL,
            CompletedByAdminUserId {0} NULL,
            CONSTRAINT FK_WithdrawalRequests_User FOREIGN KEY (UserId) REFERENCES dbo.Users(Id) ON DELETE CASCADE,
            CONSTRAINT FK_WithdrawalRequests_UserIban FOREIGN KEY (UserIbanId) REFERENCES dbo.UserIbans(Id) ON DELETE NO ACTION,
            CONSTRAINT FK_WithdrawalRequests_CompletedByAdmin FOREIGN KEY (CompletedByAdminUserId) REFERENCES dbo.Users(Id) ON DELETE NO ACTION
        );

        CREATE INDEX IX_WithdrawalRequests_UserId_RequestedAtUtc ON dbo.WithdrawalRequests (UserId, RequestedAtUtc DESC);
        CREATE INDEX IX_WithdrawalRequests_StatusId_RequestedAtUtc ON dbo.WithdrawalRequests (StatusId, RequestedAtUtc DESC);
        """;
}
