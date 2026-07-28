using DataLayer.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace DataLayer.Seeding;

public static class BalanceSchemaMigrator
{
    public static async Task EnsureAsync(IRasAlSouqDbContext db, CancellationToken cancellationToken = default)
    {
        var context = (DbContext)db;
        var connection = context.Database.GetDbConnection();
        await SqlSchemaHelper.OpenIfNeededAsync(connection, cancellationToken).ConfigureAwait(false);

        if (!await SqlSchemaHelper.TableExistsAsync(connection, "Balances", cancellationToken)
                .ConfigureAwait(false))
        {
            var userIdType = await SqlSchemaHelper.GetColumnSqlTypeAsync(connection, "Users", "Id", cancellationToken)
                .ConfigureAwait(false)
                ?? throw new InvalidOperationException("Cannot create Balances: dbo.Users.Id was not found.");

            var orderIdType = await SqlSchemaHelper.GetColumnSqlTypeAsync(connection, "Orders", "Id", cancellationToken)
                .ConfigureAwait(false)
                ?? throw new InvalidOperationException("Cannot create Balances: dbo.Orders.Id was not found.");

            var sql = string.Format(CreateTableTemplate, userIdType, orderIdType);
            await SqlSchemaHelper.ExecuteBatchAsync(connection, sql, cancellationToken).ConfigureAwait(false);
            return;
        }

        // Existing installs: Order delete must cascade so account/order cleanup cannot block on Balances.
        // User FK stays NO ACTION — SQL Server rejects User CASCADE (multiple paths via Products→Orders).
        await EnsureOrderCascadeDeleteAsync(connection, cancellationToken).ConfigureAwait(false);
    }

    private static async Task EnsureOrderCascadeDeleteAsync(
        System.Data.Common.DbConnection connection,
        CancellationToken cancellationToken)
    {
        const string sql = """
            DECLARE @orderFk SYSNAME;
            SELECT TOP (1) @orderFk = fk.name
            FROM sys.foreign_keys AS fk
            INNER JOIN sys.foreign_key_columns AS fkc ON fk.object_id = fkc.constraint_object_id
            WHERE fk.parent_object_id = OBJECT_ID(N'dbo.Balances')
              AND COL_NAME(fkc.parent_object_id, fkc.parent_column_id) = N'OrderId';

            IF @orderFk IS NOT NULL
               AND NOT EXISTS (
                    SELECT 1
                    FROM sys.foreign_keys AS fk
                    INNER JOIN sys.foreign_key_columns AS fkc ON fk.object_id = fkc.constraint_object_id
                    WHERE fk.parent_object_id = OBJECT_ID(N'dbo.Balances')
                      AND COL_NAME(fkc.parent_object_id, fkc.parent_column_id) = N'OrderId'
                      AND fk.delete_referential_action = 1
               )
            BEGIN
                DECLARE @dropOrderFk NVARCHAR(400) =
                    N'ALTER TABLE dbo.Balances DROP CONSTRAINT ' + QUOTENAME(@orderFk);
                EXEC sp_executesql @dropOrderFk;

                ALTER TABLE dbo.Balances
                    ADD CONSTRAINT FK_Balances_Order
                    FOREIGN KEY (OrderId) REFERENCES dbo.Orders(Id) ON DELETE CASCADE;
            END
            """;

        await SqlSchemaHelper.ExecuteBatchAsync(connection, sql, cancellationToken).ConfigureAwait(false);
    }

    private const string CreateTableTemplate = """
        CREATE TABLE dbo.Balances (
            Id NVARCHAR(64) NOT NULL CONSTRAINT PK_Balances PRIMARY KEY,
            UserId {0} NOT NULL,
            OrderId {1} NULL,
            BalanceAmount DECIMAL(18,2) NOT NULL,
            EntryType TINYINT NOT NULL,
            ReasonEn NVARCHAR(300) NULL,
            ReasonAr NVARCHAR(300) NULL,
            CreatedAtUtc DATETIME2 NOT NULL CONSTRAINT DF_Balances_CreatedAtUtc DEFAULT SYSUTCDATETIME(),
            CONSTRAINT FK_Balances_User FOREIGN KEY (UserId) REFERENCES dbo.Users(Id) ON DELETE NO ACTION,
            CONSTRAINT FK_Balances_Order FOREIGN KEY (OrderId) REFERENCES dbo.Orders(Id) ON DELETE CASCADE
        );

        CREATE INDEX IX_Balances_UserId_CreatedAtUtc ON dbo.Balances (UserId, CreatedAtUtc DESC);
        CREATE UNIQUE INDEX UX_Balances_OrderId_EntryType
            ON dbo.Balances (OrderId, EntryType)
            WHERE OrderId IS NOT NULL;
        """;
}
