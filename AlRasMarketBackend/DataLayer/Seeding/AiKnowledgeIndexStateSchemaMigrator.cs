using DataLayer.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace DataLayer.Seeding;

/// <summary>
/// Ensures the single-row dbo.AiKnowledgeIndexState marker table exists. The
/// AI knowledge bootstrap uses it to skip re-embedding unchanged content on
/// every startup/deploy.
/// </summary>
public static class AiKnowledgeIndexStateSchemaMigrator
{
    public static async Task EnsureAsync(IRasAlSouqDbContext db, CancellationToken cancellationToken = default)
    {
        var context = (DbContext)db;
        var connection = context.Database.GetDbConnection();
        await SqlSchemaHelper.OpenIfNeededAsync(connection, cancellationToken).ConfigureAwait(false);

        if (!await SqlSchemaHelper.TableExistsAsync(connection, "AiKnowledgeIndexState", cancellationToken).ConfigureAwait(false))
        {
            await SqlSchemaHelper.ExecuteBatchAsync(connection, """
                CREATE TABLE dbo.AiKnowledgeIndexState (
                    Id TINYINT NOT NULL PRIMARY KEY,
                    ContentHash NVARCHAR(64) NOT NULL CONSTRAINT DF_AiKnowledgeIndexState_Hash DEFAULT N'',
                    EmbeddingModel NVARCHAR(128) NOT NULL CONSTRAINT DF_AiKnowledgeIndexState_Model DEFAULT N'',
                    ChunkCount INT NOT NULL CONSTRAINT DF_AiKnowledgeIndexState_Count DEFAULT 0,
                    UpdatedAtUtc DATETIME NOT NULL CONSTRAINT DF_AiKnowledgeIndexState_UpdatedAt DEFAULT GETUTCDATE()
                );

                INSERT INTO dbo.AiKnowledgeIndexState (Id) VALUES (1);
                """, cancellationToken).ConfigureAwait(false);
        }
    }
}
