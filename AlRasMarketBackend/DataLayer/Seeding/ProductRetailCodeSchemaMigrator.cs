using DataLayer.Helpers;
using DataLayer.Interfaces;
using DataLayer.Models;
using Microsoft.EntityFrameworkCore;

namespace DataLayer.Seeding;

/// <summary>
/// Adds Products.RetailCode for hybrid retail-channel identity (nullable, unique when set)
/// and backfills existing dual-priced category listings.
/// </summary>
public static class ProductRetailCodeSchemaMigrator
{
    public static async Task EnsureAsync(IRasAlSouqDbContext db, CancellationToken cancellationToken = default)
    {
        var context = (DbContext)db;
        var connection = context.Database.GetDbConnection();
        await SqlSchemaHelper.OpenIfNeededAsync(connection, cancellationToken).ConfigureAwait(false);

        if (!await SqlSchemaHelper.ColumnExistsAsync(connection, "Products", "RetailCode", cancellationToken)
                .ConfigureAwait(false))
        {
            await SqlSchemaHelper.ExecuteBatchAsync(
                connection,
                """
                ALTER TABLE dbo.Products
                ADD RetailCode NVARCHAR(16) NULL;
                """,
                cancellationToken).ConfigureAwait(false);
        }

        // Project keys only — full Product materialization requires every mapped column
        // (ShowPrice, engagement counters, …) to already exist.
        var missingIds = await db.Products
            .AsNoTracking()
            .Where(p =>
                (p.RetailCode == null || p.RetailCode == string.Empty)
                && p.CategoryId != null
                && p.RetailPrice != null
                && p.RetailPrice > 0
                && p.RetailUnitId != null
                && p.RetailQuantity != null
                && p.RetailQuantity > 0)
            .OrderBy(p => p.CreatedAt)
            .ThenBy(p => p.ProductId)
            .Select(p => p.ProductId)
            .ToListAsync(cancellationToken)
            .ConfigureAwait(false);

        if (missingIds.Count > 0)
        {
            foreach (var productId in missingIds)
            {
                var code = await AllocateCodeAsync(connection, cancellationToken)
                    .ConfigureAwait(false);
                await using var update = connection.CreateCommand();
                update.CommandText =
                    "UPDATE dbo.Products SET RetailCode = @code WHERE ProductId = @id AND (RetailCode IS NULL OR RetailCode = N'');";
                var codeParam = update.CreateParameter();
                codeParam.ParameterName = "@code";
                codeParam.Value = code;
                update.Parameters.Add(codeParam);
                var idParam = update.CreateParameter();
                idParam.ParameterName = "@id";
                idParam.Value = productId;
                update.Parameters.Add(idParam);
                await update.ExecuteNonQueryAsync(cancellationToken).ConfigureAwait(false);
            }
        }

        await SqlSchemaHelper.ExecuteBatchAsync(
            connection,
            """
            IF NOT EXISTS (
                SELECT 1
                FROM sys.indexes
                WHERE name = N'UX_Products_RetailCode'
                  AND object_id = OBJECT_ID(N'dbo.Products'))
            BEGIN
                CREATE UNIQUE INDEX UX_Products_RetailCode
                    ON dbo.Products(RetailCode)
                    WHERE RetailCode IS NOT NULL;
            END
            """,
            cancellationToken).ConfigureAwait(false);
    }

    private static async Task<string> AllocateCodeAsync(
        System.Data.Common.DbConnection connection,
        CancellationToken cancellationToken)
    {
        await using var command = connection.CreateCommand();
        command.CommandText = "SELECT NEXT VALUE FOR dbo.ProductCodeSeq;";
        var raw = await command.ExecuteScalarAsync(cancellationToken).ConfigureAwait(false);
        var sequenceValue = Convert.ToInt64(raw);
        return ProductCodeGenerator.FromSequenceValue(sequenceValue);
    }
}
