using DataLayer.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace DataLayer.Seeding;

public static class UserIbanSchemaMigrator
{
    public static async Task EnsureAsync(IRasAlSouqDbContext db, CancellationToken cancellationToken = default)
    {
        var context = (DbContext)db;
        var connection = context.Database.GetDbConnection();
        await SqlSchemaHelper.OpenIfNeededAsync(connection, cancellationToken).ConfigureAwait(false);

        if (await SqlSchemaHelper.TableExistsAsync(connection, "UserIbans", cancellationToken).ConfigureAwait(false))
        {
            return;
        }

        var userIdType = await SqlSchemaHelper.GetColumnSqlTypeAsync(connection, "Users", "Id", cancellationToken)
            .ConfigureAwait(false)
            ?? throw new InvalidOperationException("Cannot create UserIbans: dbo.Users.Id was not found.");

        var sql = string.Format(CreateTableTemplate, userIdType);
        await SqlSchemaHelper.ExecuteBatchAsync(connection, sql, cancellationToken).ConfigureAwait(false);
    }

    private const string CreateTableTemplate = """
        CREATE TABLE dbo.UserIbans (
            Id UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_UserIbans PRIMARY KEY,
            UserId {0} NOT NULL,
            Iban VARCHAR(34) NOT NULL,
            AccountHolderName NVARCHAR(150) NULL,
            BankName NVARCHAR(150) NULL,
            IsDefault BIT NOT NULL CONSTRAINT DF_UserIbans_IsDefault DEFAULT 0,
            CreatedAtUtc DATETIME2 NOT NULL CONSTRAINT DF_UserIbans_CreatedAtUtc DEFAULT SYSUTCDATETIME(),
            CONSTRAINT FK_UserIbans_User FOREIGN KEY (UserId) REFERENCES dbo.Users(Id) ON DELETE CASCADE
        );

        CREATE UNIQUE INDEX UX_UserIbans_UserId_Iban ON dbo.UserIbans (UserId, Iban);
        CREATE INDEX IX_UserIbans_UserId_IsDefault ON dbo.UserIbans (UserId, IsDefault DESC, CreatedAtUtc DESC);
        """;
}
