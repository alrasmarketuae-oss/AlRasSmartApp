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
                """
                ALTER TABLE dbo.ContentTranslations ADD UserId UNIQUEIDENTIFIER NULL;

                ALTER TABLE dbo.ContentTranslations WITH CHECK
                    ADD CONSTRAINT FK_ContentTranslations_User
                    FOREIGN KEY (UserId) REFERENCES dbo.Users(Id) ON DELETE CASCADE;

                IF EXISTS (
                    SELECT 1 FROM sys.check_constraints
                    WHERE name = N'CK_ContentTranslations_Scope'
                      AND parent_object_id = OBJECT_ID(N'dbo.ContentTranslations')
                )
                BEGIN
                    ALTER TABLE dbo.ContentTranslations DROP CONSTRAINT CK_ContentTranslations_Scope;
                END

                IF EXISTS (
                    SELECT 1 FROM sys.check_constraints
                    WHERE name = N'CK_ContentTranslations_Owner'
                      AND parent_object_id = OBJECT_ID(N'dbo.ContentTranslations')
                )
                BEGIN
                    ALTER TABLE dbo.ContentTranslations DROP CONSTRAINT CK_ContentTranslations_Owner;
                END

                ALTER TABLE dbo.ContentTranslations WITH CHECK
                    ADD CONSTRAINT CK_ContentTranslations_Scope
                    CHECK (Scope IN (N'Product', N'Order', N'User'));

                ALTER TABLE dbo.ContentTranslations WITH CHECK
                    ADD CONSTRAINT CK_ContentTranslations_Owner
                    CHECK (
                        (Scope = N'Product' AND ProductId IS NOT NULL AND OrderId IS NULL AND UserId IS NULL)
                        OR (Scope = N'Order' AND OrderId IS NOT NULL AND ProductId IS NULL AND UserId IS NULL)
                        OR (Scope = N'User' AND UserId IS NOT NULL AND ProductId IS NULL AND OrderId IS NULL)
                    );

                CREATE UNIQUE INDEX UX_ContentTranslations_User_Field
                    ON dbo.ContentTranslations (UserId, Field)
                    WHERE UserId IS NOT NULL;

                CREATE INDEX IX_ContentTranslations_UserId
                    ON dbo.ContentTranslations (UserId)
                    WHERE UserId IS NOT NULL;
                """,
                cancellationToken).ConfigureAwait(false);
        }
    }
}
