using DataLayer.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace DataLayer.Seeding;

/// <summary>Creates ChatMessages table and Users.LastSeenAtUtc if missing (idempotent).</summary>
public static class ChatSchemaMigrator
{
    public static async Task EnsureAsync(IRasAlSouqDbContext db, CancellationToken cancellationToken = default)
    {
        var context = (DbContext)db;
        var connection = context.Database.GetDbConnection();
        await SqlSchemaHelper.OpenIfNeededAsync(connection, cancellationToken).ConfigureAwait(false);

        if (!await SqlSchemaHelper.ColumnExistsAsync(connection, "Users", "LastSeenAtUtc", cancellationToken)
                .ConfigureAwait(false))
        {
            await SqlSchemaHelper.ExecuteBatchAsync(connection, AddLastSeenColumnBatch, cancellationToken)
                .ConfigureAwait(false);
        }

        if (await SqlSchemaHelper.TableExistsAsync(connection, "ChatMessages", cancellationToken).ConfigureAwait(false))
        {
            if (!await SqlSchemaHelper.ColumnExistsAsync(connection, "ChatMessages", "IsDelivered", cancellationToken)
                    .ConfigureAwait(false))
            {
                await SqlSchemaHelper.ExecuteBatchAsync(connection, AddIsDeliveredColumnBatch, cancellationToken)
                    .ConfigureAwait(false);
                await SqlSchemaHelper.ExecuteBatchAsync(connection, AddDeliveredAtUtcColumnBatch, cancellationToken)
                    .ConfigureAwait(false);
            }

            await EnsureChatMessageIndexesAsync(connection, cancellationToken).ConfigureAwait(false);
            await EnsureReplyForwardDeleteColumnsAsync(connection, cancellationToken).ConfigureAwait(false);
        }
        else
        {
            var userIdType = await SqlSchemaHelper.GetColumnSqlTypeAsync(connection, "Users", "Id", cancellationToken)
                .ConfigureAwait(false);

            if (userIdType is null)
            {
                throw new InvalidOperationException("Cannot create ChatMessages: dbo.Users.Id was not found.");
            }

            var createSql = string.Format(CreateChatMessagesTemplate, userIdType, userIdType);
            await SqlSchemaHelper.ExecuteBatchAsync(connection, createSql, cancellationToken).ConfigureAwait(false);
        }

        if (!await SqlSchemaHelper.TableExistsAsync(connection, "ChatUserKeys", cancellationToken).ConfigureAwait(false))
        {
            var userIdType = await SqlSchemaHelper.GetColumnSqlTypeAsync(connection, "Users", "Id", cancellationToken)
                .ConfigureAwait(false)
                ?? throw new InvalidOperationException("Cannot create ChatUserKeys: dbo.Users.Id was not found.");
            var createKeysSql = string.Format(CreateChatUserKeysTemplate, userIdType);
            await SqlSchemaHelper.ExecuteBatchAsync(connection, createKeysSql, cancellationToken).ConfigureAwait(false);
        }
    }

    private const string AddLastSeenColumnBatch = """
        ALTER TABLE dbo.Users ADD LastSeenAtUtc DATETIME NULL;
        """;

    private const string AddIsDeliveredColumnBatch = """
        ALTER TABLE dbo.ChatMessages ADD IsDelivered BIT NOT NULL CONSTRAINT DF_ChatMessages_IsDelivered DEFAULT 0;
        """;

    private const string AddDeliveredAtUtcColumnBatch = """
        ALTER TABLE dbo.ChatMessages ADD DeliveredAtUtc DATETIME NULL;
        """;

    private const string CreateChatMessagesTemplate = """
        CREATE TABLE dbo.ChatMessages (
            MessageId CHAR(32) NOT NULL PRIMARY KEY,
            FromUserId {0} NOT NULL,
            ToUserId {1} NOT NULL,
            MessageType TINYINT NOT NULL,
            Content NVARCHAR(MAX) NOT NULL,
            SentAtUtc DATETIME NOT NULL CONSTRAINT DF_ChatMessages_SentAtUtc DEFAULT GETUTCDATE(),
            IsEdited BIT NOT NULL CONSTRAINT DF_ChatMessages_IsEdited DEFAULT 0,
            EditedAtUtc DATETIME NULL,
            IsSeen BIT NOT NULL CONSTRAINT DF_ChatMessages_IsSeen DEFAULT 0,
            SeenAtUtc DATETIME NULL,
            IsDelivered BIT NOT NULL CONSTRAINT DF_ChatMessages_IsDelivered DEFAULT 0,
            DeliveredAtUtc DATETIME NULL,
            ReplyToMessageId CHAR(32) NULL,
            ReplyToPreview NVARCHAR(280) NULL,
            ReplyToMessageType TINYINT NULL,
            IsForwarded BIT NOT NULL CONSTRAINT DF_ChatMessages_IsForwarded DEFAULT 0,
            IsDeleted BIT NOT NULL CONSTRAINT DF_ChatMessages_IsDeleted DEFAULT 0,
            DeletedAtUtc DATETIME NULL,
            DeletedForFromUser BIT NOT NULL CONSTRAINT DF_ChatMessages_DeletedForFromUser DEFAULT 0,
            DeletedForToUser BIT NOT NULL CONSTRAINT DF_ChatMessages_DeletedForToUser DEFAULT 0,
            CONSTRAINT FK_ChatMessages_FromUser FOREIGN KEY (FromUserId) REFERENCES dbo.Users(Id),
            CONSTRAINT FK_ChatMessages_ToUser FOREIGN KEY (ToUserId) REFERENCES dbo.Users(Id)
        );

        CREATE INDEX IX_ChatMessages_FromUserId ON dbo.ChatMessages (FromUserId);
        CREATE INDEX IX_ChatMessages_ToUserId ON dbo.ChatMessages (ToUserId);
        CREATE INDEX IX_ChatMessages_SentAtUtc ON dbo.ChatMessages (SentAtUtc DESC);
        CREATE INDEX IX_ChatMessages_Pair ON dbo.ChatMessages (FromUserId, ToUserId, SentAtUtc DESC);
        """;

    private static async Task EnsureReplyForwardDeleteColumnsAsync(
        System.Data.Common.DbConnection connection,
        CancellationToken cancellationToken)
    {
        await AddColumnIfMissingAsync(
            connection,
            "ReplyToMessageId",
            "ALTER TABLE dbo.ChatMessages ADD ReplyToMessageId CHAR(32) NULL;",
            cancellationToken).ConfigureAwait(false);
        await AddColumnIfMissingAsync(
            connection,
            "ReplyToPreview",
            "ALTER TABLE dbo.ChatMessages ADD ReplyToPreview NVARCHAR(280) NULL;",
            cancellationToken).ConfigureAwait(false);
        await AddColumnIfMissingAsync(
            connection,
            "ReplyToMessageType",
            "ALTER TABLE dbo.ChatMessages ADD ReplyToMessageType TINYINT NULL;",
            cancellationToken).ConfigureAwait(false);
        await AddColumnIfMissingAsync(
            connection,
            "IsForwarded",
            "ALTER TABLE dbo.ChatMessages ADD IsForwarded BIT NOT NULL CONSTRAINT DF_ChatMessages_IsForwarded DEFAULT 0;",
            cancellationToken).ConfigureAwait(false);
        await AddColumnIfMissingAsync(
            connection,
            "IsDeleted",
            "ALTER TABLE dbo.ChatMessages ADD IsDeleted BIT NOT NULL CONSTRAINT DF_ChatMessages_IsDeleted DEFAULT 0;",
            cancellationToken).ConfigureAwait(false);
        await AddColumnIfMissingAsync(
            connection,
            "DeletedAtUtc",
            "ALTER TABLE dbo.ChatMessages ADD DeletedAtUtc DATETIME NULL;",
            cancellationToken).ConfigureAwait(false);
        await AddColumnIfMissingAsync(
            connection,
            "DeletedForFromUser",
            "ALTER TABLE dbo.ChatMessages ADD DeletedForFromUser BIT NOT NULL CONSTRAINT DF_ChatMessages_DeletedForFromUser DEFAULT 0;",
            cancellationToken).ConfigureAwait(false);
        await AddColumnIfMissingAsync(
            connection,
            "DeletedForToUser",
            "ALTER TABLE dbo.ChatMessages ADD DeletedForToUser BIT NOT NULL CONSTRAINT DF_ChatMessages_DeletedForToUser DEFAULT 0;",
            cancellationToken).ConfigureAwait(false);
    }

    private static async Task AddColumnIfMissingAsync(
        System.Data.Common.DbConnection connection,
        string columnName,
        string alterSql,
        CancellationToken cancellationToken)
    {
        if (await SqlSchemaHelper.ColumnExistsAsync(connection, "ChatMessages", columnName, cancellationToken)
                .ConfigureAwait(false))
        {
            return;
        }

        await SqlSchemaHelper.ExecuteBatchAsync(connection, alterSql, cancellationToken).ConfigureAwait(false);
    }

    private static async Task EnsureChatMessageIndexesAsync(
        System.Data.Common.DbConnection connection,
        CancellationToken cancellationToken)
    {
        const string batch = """
            IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_ChatMessages_Pair_Reverse' AND object_id = OBJECT_ID('dbo.ChatMessages'))
                CREATE INDEX IX_ChatMessages_Pair_Reverse ON dbo.ChatMessages (ToUserId, FromUserId, SentAtUtc DESC);

            IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_ChatMessages_ToUser_Unread' AND object_id = OBJECT_ID('dbo.ChatMessages'))
                CREATE INDEX IX_ChatMessages_ToUser_Unread ON dbo.ChatMessages (ToUserId, IsSeen, SentAtUtc DESC);
            """;

        await SqlSchemaHelper.ExecuteBatchAsync(connection, batch, cancellationToken).ConfigureAwait(false);
    }

    private const string CreateChatUserKeysTemplate = """
        CREATE TABLE dbo.ChatUserKeys (
            UserId {0} NOT NULL PRIMARY KEY,
            PublicKeySpkiBase64 NVARCHAR(MAX) NOT NULL,
            SupportPrivateKeyPkcs8Base64 NVARCHAR(MAX) NULL,
            UpdatedAtUtc DATETIME NOT NULL CONSTRAINT DF_ChatUserKeys_UpdatedAtUtc DEFAULT GETUTCDATE(),
            CONSTRAINT FK_ChatUserKeys_Users FOREIGN KEY (UserId) REFERENCES dbo.Users(Id)
        );
        """;
}
