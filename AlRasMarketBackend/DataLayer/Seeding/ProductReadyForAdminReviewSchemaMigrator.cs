using DataLayer.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace DataLayer.Seeding;

/// <summary>
/// Products.IsReadyForAdminReview — hide from admin pending until media uploads finish.
/// Existing rows default to ready so current queue is unchanged.
/// </summary>
public static class ProductReadyForAdminReviewSchemaMigrator
{
    public static async Task EnsureAsync(IRasAlSouqDbContext db, CancellationToken cancellationToken = default)
    {
        var context = (DbContext)db;
        var connection = context.Database.GetDbConnection();
        await SqlSchemaHelper.OpenIfNeededAsync(connection, cancellationToken).ConfigureAwait(false);

        if (!await SqlSchemaHelper.ColumnExistsAsync(
                connection, "Products", "IsReadyForAdminReview", cancellationToken)
            .ConfigureAwait(false))
        {
            await SqlSchemaHelper.ExecuteBatchAsync(
                connection,
                """
                ALTER TABLE dbo.Products
                ADD IsReadyForAdminReview BIT NOT NULL
                    CONSTRAINT DF_Products_IsReadyForAdminReview DEFAULT (1);
                """,
                cancellationToken).ConfigureAwait(false);
        }
    }
}
