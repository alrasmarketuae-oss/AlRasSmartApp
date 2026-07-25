using DataLayer.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace DataLayer.Seeding;

/// <summary>
/// Adds ProductVideos for multi-video ad listings (primary video remains on Products.VideoPath).
/// </summary>
public static class ProductVideoSchemaMigrator
{
    public static async Task EnsureAsync(IRasAlSouqDbContext db, CancellationToken cancellationToken = default)
    {
        var context = (DbContext)db;
        var connection = context.Database.GetDbConnection();
        await SqlSchemaHelper.OpenIfNeededAsync(connection, cancellationToken).ConfigureAwait(false);

        if (await SqlSchemaHelper.TableExistsAsync(connection, "ProductVideos", cancellationToken)
                .ConfigureAwait(false))
        {
            return;
        }

        await SqlSchemaHelper.ExecuteBatchAsync(
            connection,
            """
            CREATE TABLE dbo.ProductVideos (
                Id BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
                ProductId UNIQUEIDENTIFIER NOT NULL,
                VideoPath NVARCHAR(500) NOT NULL,
                VideoDurationSeconds TINYINT NULL,
                CreatedAt DATETIME NOT NULL CONSTRAINT DF_ProductVideos_CreatedAt DEFAULT (GETUTCDATE()),
                CONSTRAINT FK_ProductVideos_Products FOREIGN KEY (ProductId)
                    REFERENCES dbo.Products(ProductId) ON DELETE CASCADE
            );
            CREATE INDEX IX_ProductVideos_ProductId ON dbo.ProductVideos (ProductId);
            """,
            cancellationToken).ConfigureAwait(false);
    }
}
