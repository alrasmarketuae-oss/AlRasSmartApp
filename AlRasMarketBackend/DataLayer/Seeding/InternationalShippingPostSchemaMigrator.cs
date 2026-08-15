using DataLayer.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace DataLayer.Seeding;

/// <summary>Adds optional columns to InternationalShippingPosts when missing.</summary>
public static class InternationalShippingPostSchemaMigrator
{
    public static async Task EnsureAsync(IRasAlSouqDbContext db, CancellationToken cancellationToken = default)
    {
        var context = (DbContext)db;
        var connection = context.Database.GetDbConnection();
        await SqlSchemaHelper.OpenIfNeededAsync(connection, cancellationToken).ConfigureAwait(false);

        if (!await SqlSchemaHelper.TableExistsAsync(connection, "InternationalShippingPosts", cancellationToken)
                .ConfigureAwait(false))
        {
            return;
        }

        if (!await SqlSchemaHelper.ColumnExistsAsync(connection, "InternationalShippingPosts", "MinDurationDays", cancellationToken)
                .ConfigureAwait(false))
        {
            await SqlSchemaHelper.ExecuteBatchAsync(connection,
                "ALTER TABLE dbo.InternationalShippingPosts ADD MinDurationDays INT NULL;",
                cancellationToken).ConfigureAwait(false);
        }

        if (!await SqlSchemaHelper.ColumnExistsAsync(connection, "InternationalShippingPosts", "MaxDurationDays", cancellationToken)
                .ConfigureAwait(false))
        {
            await SqlSchemaHelper.ExecuteBatchAsync(connection,
                "ALTER TABLE dbo.InternationalShippingPosts ADD MaxDurationDays INT NULL;",
                cancellationToken).ConfigureAwait(false);
        }

        if (!await SqlSchemaHelper.ColumnExistsAsync(connection, "InternationalShippingPosts", "Details", cancellationToken)
                .ConfigureAwait(false))
        {
            await SqlSchemaHelper.ExecuteBatchAsync(connection,
                "ALTER TABLE dbo.InternationalShippingPosts ADD Details NVARCHAR(2000) NULL;",
                cancellationToken).ConfigureAwait(false);
        }

        if (!await SqlSchemaHelper.ColumnExistsAsync(connection, "InternationalShippingPosts", "Status", cancellationToken)
                .ConfigureAwait(false))
        {
            await SqlSchemaHelper.ExecuteBatchAsync(connection,
                "ALTER TABLE dbo.InternationalShippingPosts ADD Status TINYINT NOT NULL CONSTRAINT DF_InternationalShippingPosts_Status DEFAULT 1;",
                cancellationToken).ConfigureAwait(false);
        }

        if (!await SqlSchemaHelper.ColumnExistsAsync(connection, "InternationalShippingPosts", "IsApproved", cancellationToken)
                .ConfigureAwait(false))
        {
            await SqlSchemaHelper.ExecuteBatchAsync(connection,
                "ALTER TABLE dbo.InternationalShippingPosts ADD IsApproved BIT NOT NULL CONSTRAINT DF_InternationalShippingPosts_IsApproved DEFAULT 0;",
                cancellationToken).ConfigureAwait(false);

            await SqlSchemaHelper.ExecuteBatchAsync(connection,
                """
                UPDATE dbo.InternationalShippingPosts
                SET IsApproved = 1, Status = 2
                WHERE IsApproved = 0;
                """,
                cancellationToken).ConfigureAwait(false);
        }

        await SqlSchemaHelper.ExecuteBatchAsync(connection, """
            IF EXISTS (
                SELECT 1 FROM sys.columns
                WHERE object_id = OBJECT_ID(N'dbo.InternationalShippingPosts')
                  AND name = N'Container20ftPriceUsd' AND is_nullable = 0)
            BEGIN
                ALTER TABLE dbo.InternationalShippingPosts
                    ALTER COLUMN Container20ftPriceUsd DECIMAL(12,2) NULL;
            END
            GO
            IF EXISTS (
                SELECT 1 FROM sys.columns
                WHERE object_id = OBJECT_ID(N'dbo.InternationalShippingPosts')
                  AND name = N'Container40ftPriceUsd' AND is_nullable = 0)
            BEGIN
                ALTER TABLE dbo.InternationalShippingPosts
                    ALTER COLUMN Container40ftPriceUsd DECIMAL(12,2) NULL;
            END
            GO
            UPDATE dbo.InternationalShippingPosts
            SET Container20ftPriceUsd = NULL
            WHERE Container20ftPriceUsd <= 0;

            UPDATE dbo.InternationalShippingPosts
            SET Container40ftPriceUsd = NULL
            WHERE Container40ftPriceUsd <= 0;
            """,
            cancellationToken).ConfigureAwait(false);
    }
}
