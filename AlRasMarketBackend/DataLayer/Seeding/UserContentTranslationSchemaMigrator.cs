using DataLayer.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace DataLayer.Seeding;

/// <summary>
/// Extends ContentTranslations for bilingual user/company names (User scope).
/// </summary>
public static class UserContentTranslationSchemaMigrator
{
    public static async Task EnsureAsync(IRasAlSouqDbContext db, CancellationToken cancellationToken = default)
    {
        var context = (DbContext)db;
        var connection = context.Database.GetDbConnection();
        await SqlSchemaHelper.OpenIfNeededAsync(connection, cancellationToken).ConfigureAwait(false);

        if (!await SqlSchemaHelper.TableExistsAsync(connection, "ContentTranslations", cancellationToken)
                .ConfigureAwait(false))
        {
            return;
        }

        if (!await SqlSchemaHelper.ColumnExistsAsync(connection, "ContentTranslations", "UserId", cancellationToken)
                .ConfigureAwait(false))
        {
            await SqlSchemaHelper.ExecuteBatchAsync(
                connection,
                "ALTER TABLE dbo.ContentTranslations ADD UserId UNIQUEIDENTIFIER NULL;",
                cancellationToken).ConfigureAwait(false);
        }

        await SqlSchemaHelper.ExecuteBatchAsync(
            connection,
            """
            IF NOT EXISTS (
                SELECT 1
                FROM sys.foreign_keys
                WHERE name = N'FK_ContentTranslations_User'
                  AND parent_object_id = OBJECT_ID(N'dbo.ContentTranslations')
            )
            BEGIN
                ALTER TABLE dbo.ContentTranslations WITH CHECK
                    ADD CONSTRAINT FK_ContentTranslations_User
                    FOREIGN KEY (UserId) REFERENCES dbo.Users(Id) ON DELETE CASCADE;
            END
            """,
            cancellationToken).ConfigureAwait(false);

        if (await ScopeConstraintsNeedUserUpdateAsync(connection, cancellationToken).ConfigureAwait(false))
        {
            await SqlSchemaHelper.ExecuteBatchAsync(
                connection,
                """
                IF EXISTS (
                    SELECT 1 FROM sys.check_constraints
                    WHERE name = N'CK_ContentTranslations_Scope'
                      AND parent_object_id = OBJECT_ID(N'dbo.ContentTranslations')
                )
                BEGIN
                    ALTER TABLE dbo.ContentTranslations DROP CONSTRAINT CK_ContentTranslations_Scope;
                END
                """,
                cancellationToken).ConfigureAwait(false);

            await SqlSchemaHelper.ExecuteBatchAsync(
                connection,
                """
                IF NOT EXISTS (
                    SELECT 1 FROM sys.check_constraints
                    WHERE name = N'CK_ContentTranslations_Scope'
                      AND parent_object_id = OBJECT_ID(N'dbo.ContentTranslations')
                )
                BEGIN
                    ALTER TABLE dbo.ContentTranslations WITH CHECK
                        ADD CONSTRAINT CK_ContentTranslations_Scope
                        CHECK (Scope IN (N'Product', N'Order', N'User'));
                END
                """,
                cancellationToken).ConfigureAwait(false);

            await SqlSchemaHelper.ExecuteBatchAsync(
                connection,
                """
                IF EXISTS (
                    SELECT 1 FROM sys.check_constraints
                    WHERE name = N'CK_ContentTranslations_Owner'
                      AND parent_object_id = OBJECT_ID(N'dbo.ContentTranslations')
                )
                BEGIN
                    ALTER TABLE dbo.ContentTranslations DROP CONSTRAINT CK_ContentTranslations_Owner;
                END
                """,
                cancellationToken).ConfigureAwait(false);

            await SqlSchemaHelper.ExecuteBatchAsync(
                connection,
                """
                IF NOT EXISTS (
                    SELECT 1 FROM sys.check_constraints
                    WHERE name = N'CK_ContentTranslations_Owner'
                      AND parent_object_id = OBJECT_ID(N'dbo.ContentTranslations')
                )
                BEGIN
                    ALTER TABLE dbo.ContentTranslations WITH CHECK
                        ADD CONSTRAINT CK_ContentTranslations_Owner
                        CHECK (
                            (Scope = N'Product' AND ProductId IS NOT NULL AND OrderId IS NULL AND UserId IS NULL)
                            OR (Scope = N'Order' AND OrderId IS NOT NULL AND ProductId IS NULL AND UserId IS NULL)
                            OR (Scope = N'User' AND UserId IS NOT NULL AND ProductId IS NULL AND OrderId IS NULL)
                        );
                END
                """,
                cancellationToken).ConfigureAwait(false);
        }

        await SqlSchemaHelper.EnsureIndexAsync(
            connection,
            "ContentTranslations",
            "UX_ContentTranslations_User_Field",
            """
            CREATE UNIQUE INDEX UX_ContentTranslations_User_Field
                ON dbo.ContentTranslations (UserId, Field)
                WHERE UserId IS NOT NULL;
            """,
            cancellationToken).ConfigureAwait(false);

        await SqlSchemaHelper.EnsureIndexAsync(
            connection,
            "ContentTranslations",
            "IX_ContentTranslations_UserId",
            """
            CREATE INDEX IX_ContentTranslations_UserId
                ON dbo.ContentTranslations (UserId)
                WHERE UserId IS NOT NULL;
            """,
            cancellationToken).ConfigureAwait(false);
    }

    private static async Task<bool> ScopeConstraintsNeedUserUpdateAsync(
        System.Data.Common.DbConnection connection,
        CancellationToken cancellationToken)
    {
        await using var command = connection.CreateCommand();
        command.CommandText = """
            SELECT CASE WHEN EXISTS (
                SELECT 1
                FROM sys.check_constraints
                WHERE parent_object_id = OBJECT_ID(N'dbo.ContentTranslations')
                  AND name = N'CK_ContentTranslations_Scope'
                  AND definition LIKE N'%User%'
            ) THEN 0 ELSE 1 END;
            """;

        var result = await command.ExecuteScalarAsync(cancellationToken).ConfigureAwait(false);
        return Convert.ToInt32(result) == 1;
    }
}
