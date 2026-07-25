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
    }
}
