using DataLayer.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace DataLayer.Seeding;

/// <summary>Persists AI assistant Q&amp;A per user session (idempotent).</summary>
public static class AiConversationSchemaMigrator
{
    public static async Task EnsureAsync(IRasAlSouqDbContext db, CancellationToken cancellationToken = default)
    {
        var context = (DbContext)db;
        var connection = context.Database.GetDbConnection();
        await SqlSchemaHelper.OpenIfNeededAsync(connection, cancellationToken).ConfigureAwait(false);

        if (await SqlSchemaHelper.TableExistsAsync(connection, "AiConversations", cancellationToken)
                .ConfigureAwait(false))
        {
            return;
        }

        var userIdType = await SqlSchemaHelper.GetColumnSqlTypeAsync(connection, "Users", "Id", cancellationToken)
            .ConfigureAwait(false)
            ?? throw new InvalidOperationException("Cannot create AiConversations: dbo.Users.Id was not found.");

        var createSql = string.Format(CreateTablesTemplate, userIdType);
        await SqlSchemaHelper.ExecuteBatchAsync(connection, createSql, cancellationToken).ConfigureAwait(false);
    }

    private const string CreateTablesTemplate = """
        CREATE TABLE dbo.AiConversations (
            Id UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
            UserId {0} NOT NULL,
            ClientSessionId NVARCHAR(64) NOT NULL,
            TitlePreview NVARCHAR(200) NULL,
            CreatedAtUtc DATETIME NOT NULL CONSTRAINT DF_AiConversations_CreatedAtUtc DEFAULT GETUTCDATE(),
            LastMessageAtUtc DATETIME NOT NULL CONSTRAINT DF_AiConversations_LastMessageAtUtc DEFAULT GETUTCDATE(),
            CONSTRAINT FK_AiConversations_Users FOREIGN KEY (UserId) REFERENCES dbo.Users(Id)
        );

        CREATE UNIQUE INDEX UX_AiConversations_User_Session
            ON dbo.AiConversations (UserId, ClientSessionId);

        CREATE INDEX IX_AiConversations_User_LastMessage
            ON dbo.AiConversations (UserId, LastMessageAtUtc DESC);

        CREATE TABLE dbo.AiConversationMessages (
            Id BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
            ConversationId UNIQUEIDENTIFIER NOT NULL,
            Role TINYINT NOT NULL,
            Content NVARCHAR(MAX) NOT NULL,
            Language NVARCHAR(8) NOT NULL CONSTRAINT DF_AiConversationMessages_Language DEFAULT 'en',
            UsedKnowledge BIT NULL,
            SourcesJson NVARCHAR(MAX) NULL,
            CreatedAtUtc DATETIME NOT NULL CONSTRAINT DF_AiConversationMessages_CreatedAtUtc DEFAULT GETUTCDATE(),
            CONSTRAINT FK_AiConversationMessages_Conversations
                FOREIGN KEY (ConversationId) REFERENCES dbo.AiConversations(Id) ON DELETE CASCADE
        );

        CREATE INDEX IX_AiConversationMessages_Conversation_Created
            ON dbo.AiConversationMessages (ConversationId, CreatedAtUtc DESC);
        """;
}
