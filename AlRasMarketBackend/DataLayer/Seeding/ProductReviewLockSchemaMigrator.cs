using DataLayer.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace DataLayer.Seeding;

/// <summary>Exclusive ad-review locks for admin employees (idempotent).</summary>
public static class ProductReviewLockSchemaMigrator
{
    public static async Task EnsureAsync(IRasAlSouqDbContext db, CancellationToken cancellationToken = default)
    {
        var context = (DbContext)db;
        var connection = context.Database.GetDbConnection();
        await SqlSchemaHelper.OpenIfNeededAsync(connection, cancellationToken).ConfigureAwait(false);

        if (!await SqlSchemaHelper.TableExistsAsync(connection, "ProductReviewLocks", cancellationToken)
                .ConfigureAwait(false))
        {
            var userIdType = await SqlSchemaHelper.GetColumnSqlTypeAsync(connection, "Users", "Id", cancellationToken)
                .ConfigureAwait(false)
                ?? throw new InvalidOperationException("Cannot create ProductReviewLocks: dbo.Users.Id was not found.");

            var productIdType = await SqlSchemaHelper.GetColumnSqlTypeAsync(connection, "Products", "ProductId", cancellationToken)
                .ConfigureAwait(false)
                ?? throw new InvalidOperationException("Cannot create ProductReviewLocks: dbo.Products.ProductId was not found.");

            var createSql = string.Format(CreateTableTemplate, productIdType, userIdType);
            await SqlSchemaHelper.ExecuteBatchAsync(connection, createSql, cancellationToken).ConfigureAwait(false);
        }

        // Always ensure one active lock per product (fixes concurrent Preview race).
        await SqlSchemaHelper.ExecuteBatchAsync(connection, EnsureUniqueActiveLockIndexBatch, cancellationToken)
            .ConfigureAwait(false);
    }

    private const string CreateTableTemplate = """
        CREATE TABLE dbo.ProductReviewLocks (
            Id UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
            ProductId {0} NOT NULL,
            AgentUserId {1} NOT NULL,
            LockedAtUtc DATETIME NOT NULL CONSTRAINT DF_ProductReviewLocks_LockedAtUtc DEFAULT GETUTCDATE(),
            LastHeartbeatUtc DATETIME NOT NULL CONSTRAINT DF_ProductReviewLocks_LastHeartbeatUtc DEFAULT GETUTCDATE(),
            ReleasedAtUtc DATETIME NULL,
            CONSTRAINT FK_ProductReviewLocks_Product FOREIGN KEY (ProductId) REFERENCES dbo.Products(ProductId),
            CONSTRAINT FK_ProductReviewLocks_Agent FOREIGN KEY (AgentUserId) REFERENCES dbo.Users(Id)
        );

        CREATE UNIQUE INDEX UX_ProductReviewLocks_Product_Active
            ON dbo.ProductReviewLocks (ProductId)
            WHERE ReleasedAtUtc IS NULL;

        CREATE INDEX IX_ProductReviewLocks_Agent_Active
            ON dbo.ProductReviewLocks (AgentUserId)
            WHERE ReleasedAtUtc IS NULL;
        """;

    private const string EnsureUniqueActiveLockIndexBatch = """
        -- Keep the earliest active lock if duplicates already exist.
        ;WITH ActiveDupes AS (
            SELECT Id,
                   ROW_NUMBER() OVER (PARTITION BY ProductId ORDER BY LockedAtUtc ASC, Id ASC) AS rn
            FROM dbo.ProductReviewLocks
            WHERE ReleasedAtUtc IS NULL
        )
        UPDATE l
        SET ReleasedAtUtc = GETUTCDATE()
        FROM dbo.ProductReviewLocks l
        INNER JOIN ActiveDupes d ON d.Id = l.Id
        WHERE d.rn > 1;

        IF EXISTS (
            SELECT 1
            FROM sys.indexes
            WHERE name = N'IX_ProductReviewLocks_Product_Active'
              AND object_id = OBJECT_ID(N'dbo.ProductReviewLocks')
        )
        BEGIN
            DROP INDEX IX_ProductReviewLocks_Product_Active ON dbo.ProductReviewLocks;
        END

        IF NOT EXISTS (
            SELECT 1
            FROM sys.indexes
            WHERE name = N'UX_ProductReviewLocks_Product_Active'
              AND object_id = OBJECT_ID(N'dbo.ProductReviewLocks')
        )
        BEGIN
            CREATE UNIQUE INDEX UX_ProductReviewLocks_Product_Active
                ON dbo.ProductReviewLocks (ProductId)
                WHERE ReleasedAtUtc IS NULL;
        END
        """;
}
