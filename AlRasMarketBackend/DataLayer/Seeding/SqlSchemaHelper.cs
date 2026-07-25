using System.Data;
using System.Text.RegularExpressions;

namespace DataLayer.Seeding;

internal static class SqlSchemaHelper
{
    public static async Task OpenIfNeededAsync(
        System.Data.Common.DbConnection connection,
        CancellationToken cancellationToken)
    {
        if (connection.State != ConnectionState.Open)
        {
            await connection.OpenAsync(cancellationToken).ConfigureAwait(false);
        }
    }

    public static async Task<bool> ColumnExistsAsync(
        System.Data.Common.DbConnection connection,
        string tableName,
        string columnName,
        CancellationToken cancellationToken)
    {
        await using var command = connection.CreateCommand();
        command.CommandText = """
            SELECT CASE WHEN COL_LENGTH(@tableName, @columnName) IS NULL THEN 0 ELSE 1 END;
            """;

        var tableParam = command.CreateParameter();
        tableParam.ParameterName = "@tableName";
        tableParam.Value = $"dbo.{tableName}";
        command.Parameters.Add(tableParam);

        var columnParam = command.CreateParameter();
        columnParam.ParameterName = "@columnName";
        columnParam.Value = columnName;
        command.Parameters.Add(columnParam);

        var result = await command.ExecuteScalarAsync(cancellationToken).ConfigureAwait(false);
        return Convert.ToInt32(result) == 1;
    }

    public static async Task<bool> TableExistsAsync(
        System.Data.Common.DbConnection connection,
        string tableName,
        CancellationToken cancellationToken)
    {
        await using var command = connection.CreateCommand();
        command.CommandText = """
            SELECT CASE WHEN OBJECT_ID(@tableName, N'U') IS NOT NULL THEN 1 ELSE 0 END;
            """;
        var parameter = command.CreateParameter();
        parameter.ParameterName = "@tableName";
        parameter.Value = $"dbo.{tableName}";
        command.Parameters.Add(parameter);

        var result = await command.ExecuteScalarAsync(cancellationToken).ConfigureAwait(false);
        return Convert.ToInt32(result) == 1;
    }

    public static async Task<string?> GetColumnSqlTypeAsync(
        System.Data.Common.DbConnection connection,
        string tableName,
        string columnName,
        CancellationToken cancellationToken)
    {
        await using var command = connection.CreateCommand();
        command.CommandText = """
            SELECT
                CASE
                    WHEN ty.name IN (N'varchar', N'char', N'varbinary', N'binary') THEN
                        ty.name + N'(' +
                        CASE WHEN c.max_length = -1 THEN N'MAX' ELSE CAST(c.max_length AS NVARCHAR(10)) END + N')'
                    WHEN ty.name IN (N'nvarchar', N'nchar') THEN
                        ty.name + N'(' +
                        CASE WHEN c.max_length = -1 THEN N'MAX' ELSE CAST(c.max_length / 2 AS NVARCHAR(10)) END + N')'
                    WHEN ty.name IN (N'decimal', N'numeric') THEN
                        ty.name + N'(' + CAST(c.precision AS NVARCHAR(10)) + N',' + CAST(c.scale AS NVARCHAR(10)) + N')'
                    ELSE ty.name
                END
            FROM sys.columns AS c
            INNER JOIN sys.types AS ty ON c.user_type_id = ty.user_type_id
            WHERE c.object_id = OBJECT_ID(@tableName)
              AND c.name = @columnName;
            """;

        var tableParam = command.CreateParameter();
        tableParam.ParameterName = "@tableName";
        tableParam.Value = $"dbo.{tableName}";
        command.Parameters.Add(tableParam);

        var columnParam = command.CreateParameter();
        columnParam.ParameterName = "@columnName";
        columnParam.Value = columnName;
        command.Parameters.Add(columnParam);

        var result = await command.ExecuteScalarAsync(cancellationToken).ConfigureAwait(false);
        return result as string;
    }

    public static async Task<bool> IndexExistsAsync(
        System.Data.Common.DbConnection connection,
        string tableName,
        string indexName,
        CancellationToken cancellationToken)
    {
        await using var command = connection.CreateCommand();
        command.CommandText = """
            SELECT CASE WHEN EXISTS (
                SELECT 1
                FROM sys.indexes AS i
                WHERE i.name = @indexName
                  AND i.object_id = OBJECT_ID(@tableName)
            ) THEN 1 ELSE 0 END;
            """;

        var tableParam = command.CreateParameter();
        tableParam.ParameterName = "@tableName";
        tableParam.Value = $"dbo.{tableName}";
        command.Parameters.Add(tableParam);

        var indexParam = command.CreateParameter();
        indexParam.ParameterName = "@indexName";
        indexParam.Value = indexName;
        command.Parameters.Add(indexParam);

        var result = await command.ExecuteScalarAsync(cancellationToken).ConfigureAwait(false);
        return Convert.ToInt32(result) == 1;
    }

    public static async Task EnsureIndexAsync(
        System.Data.Common.DbConnection connection,
        string tableName,
        string indexName,
        string createIndexSql,
        CancellationToken cancellationToken)
    {
        if (await IndexExistsAsync(connection, tableName, indexName, cancellationToken).ConfigureAwait(false))
        {
            return;
        }

        await ExecuteBatchAsync(connection, createIndexSql, cancellationToken).ConfigureAwait(false);
    }

    public static async Task ExecuteBatchAsync(
        System.Data.Common.DbConnection connection,
        string sql,
        CancellationToken cancellationToken)
    {
        foreach (var batch in SplitBatches(sql))
        {
            await using var command = connection.CreateCommand();
            command.CommandText = batch;
            await command.ExecuteNonQueryAsync(cancellationToken).ConfigureAwait(false);
        }
    }

    private static IEnumerable<string> SplitBatches(string script)
    {
        return Regex.Split(script, @"^\s*GO\s*$", RegexOptions.Multiline | RegexOptions.IgnoreCase)
            .Select(batch => batch.Trim())
            .Where(batch => !string.IsNullOrWhiteSpace(batch));
    }
}
