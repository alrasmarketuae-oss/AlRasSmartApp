using DataLayer.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace DataLayer.Seeding;

/// <summary>
/// Creates OrderCancellationReasons and nullable cancellation columns on Orders.
/// Existing orders stay untouched (CancellationReasonId is nullable).
/// </summary>
public static class OrderCancellationSchemaMigrator
{
    public static async Task EnsureAsync(IRasAlSouqDbContext db, CancellationToken cancellationToken = default)
    {
        var context = (DbContext)db;
        var connection = context.Database.GetDbConnection();
        await SqlSchemaHelper.OpenIfNeededAsync(connection, cancellationToken).ConfigureAwait(false);

        if (!await SqlSchemaHelper.TableExistsAsync(connection, "OrderCancellationReasons", cancellationToken)
                .ConfigureAwait(false))
        {
            await SqlSchemaHelper.ExecuteBatchAsync(connection, """
                CREATE TABLE dbo.OrderCancellationReasons (
                    Id TINYINT NOT NULL CONSTRAINT PK_OrderCancellationReasons PRIMARY KEY,
                    NameEn NVARCHAR(200) NOT NULL,
                    NameAr NVARCHAR(200) NOT NULL,
                    IsActive BIT NOT NULL CONSTRAINT DF_OrderCancellationReasons_IsActive DEFAULT 1,
                    CreatedAt DATETIME2 NOT NULL CONSTRAINT DF_OrderCancellationReasons_CreatedAt DEFAULT SYSUTCDATETIME()
                );
                """, cancellationToken).ConfigureAwait(false);
        }

        await SqlSchemaHelper.ExecuteBatchAsync(connection, """
            IF NOT EXISTS (SELECT 1 FROM dbo.OrderCancellationReasons WHERE Id = 1)
                INSERT INTO dbo.OrderCancellationReasons (Id, NameEn, NameAr, IsActive)
                VALUES (1, N'Buyer requested cancellation', N'طلب المشتري إلغاء الصفقة', 1);
            IF NOT EXISTS (SELECT 1 FROM dbo.OrderCancellationReasons WHERE Id = 2)
                INSERT INTO dbo.OrderCancellationReasons (Id, NameEn, NameAr, IsActive)
                VALUES (2, N'Supplier unavailable', N'المورد غير متاح', 1);
            IF NOT EXISTS (SELECT 1 FROM dbo.OrderCancellationReasons WHERE Id = 3)
                INSERT INTO dbo.OrderCancellationReasons (Id, NameEn, NameAr, IsActive)
                VALUES (3, N'Product unavailable', N'المنتج غير متوفر', 1);
            IF NOT EXISTS (SELECT 1 FROM dbo.OrderCancellationReasons WHERE Id = 4)
                INSERT INTO dbo.OrderCancellationReasons (Id, NameEn, NameAr, IsActive)
                VALUES (4, N'Payment issue', N'مشكلة في الدفع', 1);
            IF NOT EXISTS (SELECT 1 FROM dbo.OrderCancellationReasons WHERE Id = 5)
                INSERT INTO dbo.OrderCancellationReasons (Id, NameEn, NameAr, IsActive)
                VALUES (5, N'Admin cancelled', N'ألغاه المسؤول', 1);
            IF NOT EXISTS (SELECT 1 FROM dbo.OrderCancellationReasons WHERE Id = 6)
                INSERT INTO dbo.OrderCancellationReasons (Id, NameEn, NameAr, IsActive)
                VALUES (6, N'Other', N'سبب آخر', 1);
            """, cancellationToken).ConfigureAwait(false);

        if (!await SqlSchemaHelper.ColumnExistsAsync(connection, "Orders", "CancellationReasonId", cancellationToken)
                .ConfigureAwait(false))
        {
            await SqlSchemaHelper.ExecuteBatchAsync(connection, """
                ALTER TABLE dbo.Orders ADD CancellationReasonId TINYINT NULL;
                ALTER TABLE dbo.Orders ADD CONSTRAINT FK_Orders_OrderCancellationReasons
                    FOREIGN KEY (CancellationReasonId) REFERENCES dbo.OrderCancellationReasons(Id);
                """, cancellationToken).ConfigureAwait(false);
        }

        if (!await SqlSchemaHelper.ColumnExistsAsync(connection, "Orders", "CancelledAt", cancellationToken)
                .ConfigureAwait(false))
        {
            await SqlSchemaHelper.ExecuteBatchAsync(connection,
                "ALTER TABLE dbo.Orders ADD CancelledAt DATETIME2 NULL;",
                cancellationToken).ConfigureAwait(false);
        }

        if (!await SqlSchemaHelper.ColumnExistsAsync(connection, "Orders", "CancelledByUserId", cancellationToken)
                .ConfigureAwait(false))
        {
            var userIdType = await SqlSchemaHelper.GetColumnSqlTypeAsync(connection, "Users", "Id", cancellationToken)
                .ConfigureAwait(false)
                ?? "UNIQUEIDENTIFIER";

            await SqlSchemaHelper.ExecuteBatchAsync(connection, $"""
                ALTER TABLE dbo.Orders ADD CancelledByUserId {userIdType} NULL;
                ALTER TABLE dbo.Orders ADD CONSTRAINT FK_Orders_CancelledByUser
                    FOREIGN KEY (CancelledByUserId) REFERENCES dbo.Users(Id);
                """, cancellationToken).ConfigureAwait(false);
        }

        if (!await SqlSchemaHelper.ColumnExistsAsync(connection, "Orders", "CancellationNote", cancellationToken)
                .ConfigureAwait(false))
        {
            await SqlSchemaHelper.ExecuteBatchAsync(connection,
                "ALTER TABLE dbo.Orders ADD CancellationNote NVARCHAR(2000) NULL;",
                cancellationToken).ConfigureAwait(false);
        }
    }
}
