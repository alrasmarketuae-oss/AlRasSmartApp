using DataLayer.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace DataLayer.Seeding;

/// <summary>
/// Keeps ProductVideos as the source of truth while Products.VideoPath remains a legacy pointer.
/// </summary>
public static class ProductVideoSchemaMigrator
{
    public static async Task EnsureAsync(IRasAlSouqDbContext db, CancellationToken cancellationToken = default)
    {
        var context = (DbContext)db;
        var connection = context.Database.GetDbConnection();
        await SqlSchemaHelper.OpenIfNeededAsync(connection, cancellationToken).ConfigureAwait(false);

        var productVideosExists = await SqlSchemaHelper.TableExistsAsync(
            connection,
            "ProductVideos",
            cancellationToken).ConfigureAwait(false);

        if (!productVideosExists)
        {
            await SqlSchemaHelper.ExecuteBatchAsync(
                connection,
                """
                CREATE TABLE dbo.ProductVideos (
                    Id BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
                    ProductId UNIQUEIDENTIFIER NOT NULL,
                    VideoPath NVARCHAR(500) NOT NULL,
                    VideoDurationSeconds TINYINT NULL,
                    IsMuted BIT NOT NULL CONSTRAINT DF_ProductVideos_IsMuted DEFAULT 1,
                    CreatedAt DATETIME NOT NULL CONSTRAINT DF_ProductVideos_CreatedAt DEFAULT (GETUTCDATE()),
                    CONSTRAINT FK_ProductVideos_Products FOREIGN KEY (ProductId)
                        REFERENCES dbo.Products(ProductId) ON DELETE CASCADE
                );
                CREATE INDEX IX_ProductVideos_ProductId ON dbo.ProductVideos (ProductId);
                """,
                cancellationToken).ConfigureAwait(false);
        }

        if (!await SqlSchemaHelper.ColumnExistsAsync(connection, "ProductVideos", "IsMuted", cancellationToken)
                .ConfigureAwait(false))
        {
            await SqlSchemaHelper.ExecuteBatchAsync(
                connection,
                "ALTER TABLE dbo.ProductVideos ADD IsMuted BIT NOT NULL CONSTRAINT DF_ProductVideos_IsMuted DEFAULT 1;",
                cancellationToken).ConfigureAwait(false);
        }

        var hasLegacyMute = await SqlSchemaHelper.ColumnExistsAsync(
            connection,
            "Products",
            "IsVideoMuted",
            cancellationToken).ConfigureAwait(false);

        var legacyMuteExpression = hasLegacyMute ? "p.IsVideoMuted" : "CAST(1 AS bit)";
        await SqlSchemaHelper.ExecuteBatchAsync(
            connection,
            $"""
            INSERT INTO dbo.ProductVideos (ProductId, VideoPath, VideoDurationSeconds, IsMuted)
            SELECT p.ProductId, p.VideoPath, p.VideoDurationSeconds, {legacyMuteExpression}
            FROM dbo.Products AS p
            WHERE NULLIF(LTRIM(RTRIM(p.VideoPath)), N'') IS NOT NULL
              AND NOT EXISTS (
                  SELECT 1
                  FROM dbo.ProductVideos AS pv
                  WHERE pv.ProductId = p.ProductId
                    AND LOWER(pv.VideoPath) = LOWER(p.VideoPath)
              );
            """,
            cancellationToken).ConfigureAwait(false);

        if (hasLegacyMute)
        {
            await SqlSchemaHelper.ExecuteBatchAsync(
                connection,
                """
                UPDATE pv
                SET pv.IsMuted = p.IsVideoMuted
                FROM dbo.ProductVideos AS pv
                INNER JOIN dbo.Products AS p ON p.ProductId = pv.ProductId;

                DECLARE @defaultConstraint sysname;
                SELECT @defaultConstraint = dc.name
                FROM sys.default_constraints AS dc
                INNER JOIN sys.columns AS c
                    ON c.object_id = dc.parent_object_id
                   AND c.column_id = dc.parent_column_id
                WHERE dc.parent_object_id = OBJECT_ID(N'dbo.Products')
                  AND c.name = N'IsVideoMuted';

                IF @defaultConstraint IS NOT NULL
                    EXEC(N'ALTER TABLE dbo.Products DROP CONSTRAINT [' + @defaultConstraint + N']');

                ALTER TABLE dbo.Products DROP COLUMN IsVideoMuted;
                """,
                cancellationToken).ConfigureAwait(false);
        }
    }
}
