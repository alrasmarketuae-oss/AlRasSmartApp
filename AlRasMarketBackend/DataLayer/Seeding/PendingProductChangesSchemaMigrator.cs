using DataLayer.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace DataLayer.Seeding;

/// <summary>
/// Products.PendingProductChanges — JSON snapshot of previous ad state while an edit awaits admin review.
/// </summary>
public static class PendingProductChangesSchemaMigrator
{
    public static async Task EnsureAsync(IRasAlSouqDbContext db, CancellationToken cancellationToken = default)
    {
        var context = (DbContext)db;
        var connection = context.Database.GetDbConnection();
        await SqlSchemaHelper.OpenIfNeededAsync(connection, cancellationToken).ConfigureAwait(false);

        if (!await SqlSchemaHelper.ColumnExistsAsync(
                connection, "Products", "PendingProductChanges", cancellationToken)
            .ConfigureAwait(false))
        {
            await SqlSchemaHelper.ExecuteBatchAsync(
                connection,
                """
                ALTER TABLE dbo.Products
                ADD PendingProductChanges NVARCHAR(MAX) NULL;
                """,
                cancellationToken).ConfigureAwait(false);
        }
    }
}
