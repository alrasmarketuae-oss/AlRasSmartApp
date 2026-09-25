using DataLayer.Helpers;
using DataLayer.Interfaces;
using DataLayer.Models;
using Microsoft.EntityFrameworkCore;

namespace DataLayer.Seeding;

/// <summary>Adds Products.ProductCode, sequence, unique index, and backfills existing rows.</summary>
public static class ProductCodeSchemaMigrator
{
    public static async Task EnsureAsync(IRasAlSouqDbContext db, CancellationToken cancellationToken = default)
    {
        var context = (DbContext)db;
        var connection = context.Database.GetDbConnection();
        await SqlSchemaHelper.OpenIfNeededAsync(connection, cancellationToken).ConfigureAwait(false);

        if (!await SqlSchemaHelper.ColumnExistsAsync(connection, "Products", "ProductCode", cancellationToken)
                .ConfigureAwait(false))
        {
            await SqlSchemaHelper.ExecuteBatchAsync(connection,
                """
                ALTER TABLE dbo.Products
                ADD ProductCode NVARCHAR(16) NULL;
                """,
                cancellationToken).ConfigureAwait(false);
        }

        await SqlSchemaHelper.ExecuteBatchAsync(connection,
            """
            IF NOT EXISTS (
                SELECT 1
                FROM sys.sequences
                WHERE name = N'ProductCodeSeq'
                  AND schema_id = SCHEMA_ID(N'dbo'))
            BEGIN
                CREATE SEQUENCE dbo.ProductCodeSeq
                    AS BIGINT
                    START WITH 100000
                    INCREMENT BY 1
                    MINVALUE 100000
                    NO CACHE;
            END
            """,
            cancellationToken).ConfigureAwait(false);

        var missingIds = await db.Products
            .AsNoTracking()
            .Where(p => p.ProductCode == null || p.ProductCode == string.Empty)
            .OrderBy(p => p.CreatedAt)
            .ThenBy(p => p.ProductId)
            .Select(p => p.ProductId)
            .ToListAsync(cancellationToken)
            .ConfigureAwait(false);

        if (missingIds.Count > 0)
        {
            foreach (var productId in missingIds)
            {
                var code = await AllocateCodeAsync(connection, cancellationToken).ConfigureAwait(false);
                await using var update = connection.CreateCommand();
                update.CommandText =
                    "UPDATE dbo.Products SET ProductCode = @code WHERE ProductId = @id AND (ProductCode IS NULL OR ProductCode = N'');";
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

        await SqlSchemaHelper.ExecuteBatchAsync(connection,
            """
            IF NOT EXISTS (
                SELECT 1
                FROM sys.indexes
                WHERE name = N'UX_Products_ProductCode'
                  AND object_id = OBJECT_ID(N'dbo.Products'))
            BEGIN
                CREATE UNIQUE INDEX UX_Products_ProductCode
                    ON dbo.Products(ProductCode)
                    WHERE ProductCode IS NOT NULL;
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
