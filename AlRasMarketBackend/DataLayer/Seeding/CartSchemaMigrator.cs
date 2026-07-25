using DataLayer.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace DataLayer.Seeding;

public static class CartSchemaMigrator
{
    public static async Task EnsureAsync(IRasAlSouqDbContext db, CancellationToken cancellationToken = default)
    {
        var context = (DbContext)db;
        var connection = context.Database.GetDbConnection();
        await SqlSchemaHelper.OpenIfNeededAsync(connection, cancellationToken).ConfigureAwait(false);

        if (!await SqlSchemaHelper.TableExistsAsync(connection, "CartItems", cancellationToken).ConfigureAwait(false))
        {
            return;
        }

        if (!await SqlSchemaHelper.ColumnExistsAsync(connection, "CartItems", "UnitPriceAed", cancellationToken)
            .ConfigureAwait(false))
        {
            await SqlSchemaHelper.ExecuteBatchAsync(connection, """
                ALTER TABLE dbo.CartItems ADD UnitPriceAed DECIMAL(12,2) NULL;
                """, cancellationToken).ConfigureAwait(false);
        }

        if (await SqlSchemaHelper.ColumnExistsAsync(connection, "CartItems", "UnitPriceUsd", cancellationToken)
            .ConfigureAwait(false))
        {
            await SqlSchemaHelper.ExecuteBatchAsync(connection, """
                UPDATE dbo.CartItems
                SET UnitPriceAed = ROUND(UnitPriceUsd * 3.6725, 2)
                WHERE UnitPriceAed IS NULL;

                UPDATE dbo.CartItems
                SET UnitPriceAed = 0
                WHERE UnitPriceAed IS NULL;

                ALTER TABLE dbo.CartItems ALTER COLUMN UnitPriceAed DECIMAL(12,2) NOT NULL;

                ALTER TABLE dbo.CartItems DROP COLUMN UnitPriceUsd;
                """, cancellationToken).ConfigureAwait(false);
        }
    }
}
