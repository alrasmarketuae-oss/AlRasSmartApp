using DataLayer.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace DataLayer.Seeding;

/// <summary>
/// Converts legacy product text columns from varchar to nvarchar so Arabic
/// (and other non-ASCII) is not stored as "????".
/// </summary>
public static class ProductUnicodeColumnsMigrator
{
    public static async Task EnsureAsync(IRasAlSouqDbContext db, CancellationToken cancellationToken = default)
    {
        var context = (DbContext)db;
        var connection = context.Database.GetDbConnection();
        await SqlSchemaHelper.OpenIfNeededAsync(connection, cancellationToken).ConfigureAwait(false);

        await EnsureNvarcharAsync(connection, "Products", "NameEn", 255, cancellationToken)
            .ConfigureAwait(false);
        await EnsureNvarcharAsync(connection, "Products", "ShippingDescriptionEn", 255, cancellationToken)
            .ConfigureAwait(false);
        await EnsureNvarcharAsync(connection, "Products", "SupplierNotesEn", 255, cancellationToken)
            .ConfigureAwait(false);
    }

    private static async Task EnsureNvarcharAsync(
        System.Data.Common.DbConnection connection,
        string table,
        string column,
        int maxLength,
        CancellationToken cancellationToken)
    {
        if (!await SqlSchemaHelper.ColumnExistsAsync(connection, table, column, cancellationToken)
                .ConfigureAwait(false))
        {
            return;
        }

        var sqlType = await SqlSchemaHelper.GetColumnSqlTypeAsync(
            connection,
            table,
            column,
            cancellationToken).ConfigureAwait(false);
        if (string.IsNullOrWhiteSpace(sqlType)
            || sqlType.StartsWith("nvarchar", StringComparison.OrdinalIgnoreCase)
            || sqlType.StartsWith("nchar", StringComparison.OrdinalIgnoreCase))
        {
            return;
        }

        // Indexes on the column block ALTER COLUMN — drop them first, then recreate.
        await SqlSchemaHelper.ExecuteBatchAsync(
            connection,
            $"""
            DECLARE @sql NVARCHAR(MAX) = N'';
            SELECT @sql = @sql + N'DROP INDEX ' + QUOTENAME(i.name) + N' ON '
                + QUOTENAME(SCHEMA_NAME(t.schema_id)) + N'.' + QUOTENAME(t.name) + N';'
            FROM sys.indexes i
            INNER JOIN sys.index_columns ic
                ON i.object_id = ic.object_id AND i.index_id = ic.index_id
            INNER JOIN sys.columns c
                ON ic.object_id = c.object_id AND ic.column_id = c.column_id
            INNER JOIN sys.tables t
                ON i.object_id = t.object_id
            WHERE t.name = N'{table}'
              AND SCHEMA_NAME(t.schema_id) = N'dbo'
              AND c.name = N'{column}'
              AND i.is_primary_key = 0
              AND i.is_unique_constraint = 0
              AND i.name IS NOT NULL;

            IF LEN(@sql) > 0
                EXEC sp_executesql @sql;

            ALTER TABLE dbo.[{table}]
            ALTER COLUMN [{column}] NVARCHAR({maxLength}) NULL;
            """,
            cancellationToken).ConfigureAwait(false);

        if (!string.Equals(table, "Products", StringComparison.OrdinalIgnoreCase))
        {
            return;
        }

        if (string.Equals(column, "NameEn", StringComparison.OrdinalIgnoreCase))
        {
            await SqlSchemaHelper.EnsureIndexAsync(
                connection,
                "Products",
                "IX_Products_NameEn",
                """
                CREATE NONCLUSTERED INDEX [IX_Products_NameEn]
                ON [dbo].[Products]([NameEn]);
                """,
                cancellationToken).ConfigureAwait(false);
        }

        if (string.Equals(column, "ShippingDescriptionEn", StringComparison.OrdinalIgnoreCase))
        {
            await SqlSchemaHelper.EnsureIndexAsync(
                connection,
                "Products",
                "IX_Products_RequestFulfillment",
                """
                CREATE NONCLUSTERED INDEX [IX_Products_RequestFulfillment]
                ON [dbo].[Products]([ProductTypeId], [ShippingDescriptionEn])
                WHERE [ProductTypeId] = 4
                  AND [ShippingDescriptionEn] IN (N'Local', N'Booking');
                """,
                cancellationToken).ConfigureAwait(false);
        }
    }
}
