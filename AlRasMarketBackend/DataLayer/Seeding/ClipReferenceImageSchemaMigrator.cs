using DataLayer.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace DataLayer.Seeding;

public static class ClipReferenceImageSchemaMigrator
{
    public static async Task EnsureAsync(IRasAlSouqDbContext db, CancellationToken cancellationToken = default)
    {
        var context = (DbContext)db;
        var connection = context.Database.GetDbConnection();
        await SqlSchemaHelper.OpenIfNeededAsync(connection, cancellationToken).ConfigureAwait(false);

        if (await SqlSchemaHelper.TableExistsAsync(connection, "ClipReferenceImages", cancellationToken)
                .ConfigureAwait(false))
        {
            return;
        }

        var userIdType = await SqlSchemaHelper.GetColumnSqlTypeAsync(connection, "Users", "Id", cancellationToken)
            .ConfigureAwait(false);

        var adminColumn = string.IsNullOrWhiteSpace(userIdType)
            ? "CreatedByAdminUserId UNIQUEIDENTIFIER NULL"
            : $"CreatedByAdminUserId {userIdType} NULL";

        var sql = $"""
            CREATE TABLE dbo.ClipReferenceImages (
                Id BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_ClipReferenceImages PRIMARY KEY,
                ProductName NVARCHAR(300) NOT NULL,
                ProductNameAr NVARCHAR(300) NULL,
                ProductCode NVARCHAR(80) NULL,
                ImagePath NVARCHAR(500) NOT NULL,
                CreatedAtUtc DATETIME2 NOT NULL CONSTRAINT DF_ClipReferenceImages_CreatedAtUtc DEFAULT SYSUTCDATETIME(),
                {adminColumn}
            );

            CREATE INDEX IX_ClipReferenceImages_CreatedAtUtc ON dbo.ClipReferenceImages (CreatedAtUtc DESC);
            CREATE INDEX IX_ClipReferenceImages_ProductName ON dbo.ClipReferenceImages (ProductName);
            """;

        if (!string.IsNullOrWhiteSpace(userIdType))
        {
            sql += """

                ALTER TABLE dbo.ClipReferenceImages
                ADD CONSTRAINT FK_ClipReferenceImages_Admin
                    FOREIGN KEY (CreatedByAdminUserId) REFERENCES dbo.Users(Id);
                """;
        }

        await SqlSchemaHelper.ExecuteBatchAsync(connection, sql, cancellationToken).ConfigureAwait(false);
    }
}
