using System.Text.Json;
using BusinessLayer.Helpers;
using BusinessLayer.Interfaces;
using DataLayer.Interfaces;
using DataLayer.Models;
using Microsoft.EntityFrameworkCore;

namespace BusinessLayer.Services;

public sealed class AiConversationAppService(IRasAlSouqDbContext dbContext) : IAiConversationStore
{
    private const int MaxTitlePreviewLength = 120;
    private const int MaxPageSize = 100;

    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase
    };

    public async Task<Guid> GetOrCreateConversationAsync(
        Guid userId,
        string clientSessionId,
        CancellationToken cancellationToken = default)
    {
        var sessionId = NormalizeSessionId(clientSessionId);
        var existing = await dbContext.AiConversations
            .AsNoTracking()
            .Where(x => x.UserId == userId && x.ClientSessionId == sessionId)
            .Select(x => x.Id)
            .FirstOrDefaultAsync(cancellationToken);

        if (existing != Guid.Empty)
        {
            return existing;
        }

        var utcNow = DateTime.UtcNow;
        var conversation = new AiConversation
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            ClientSessionId = sessionId,
            CreatedAtUtc = utcNow,
            LastMessageAtUtc = utcNow
        };

        await dbContext.AiConversations.AddAsync(conversation, cancellationToken);
        await dbContext.SaveChangesAsync(cancellationToken);
        return conversation.Id;
    }

    public async Task AppendUserMessageAsync(
        Guid conversationId,
        string content,
        string language,
        CancellationToken cancellationToken = default)
    {
        var conversation = await dbContext.AiConversations
            .FirstOrDefaultAsync(x => x.Id == conversationId, cancellationToken)
            ?? throw new KeyNotFoundException("AI conversation not found.");

        var utcNow = DateTime.UtcNow;
        if (string.IsNullOrWhiteSpace(conversation.TitlePreview))
        {
            conversation.TitlePreview = BuildTitlePreview(content);
        }

        conversation.LastMessageAtUtc = utcNow;
        await dbContext.AiConversationMessages.AddAsync(new AiConversationMessage
        {
            ConversationId = conversationId,
            Role = AiConversationMessageRole.User,
            Content = content.Trim(),
            Language = NormalizeLanguage(language),
            CreatedAtUtc = utcNow
        }, cancellationToken);

        await dbContext.SaveChangesAsync(cancellationToken);
    }

    public async Task AppendAssistantMessageAsync(
        Guid conversationId,
        string content,
        string language,
        bool usedKnowledge,
        IReadOnlyList<string>? sources,
        CancellationToken cancellationToken = default)
    {
        var conversation = await dbContext.AiConversations
            .FirstOrDefaultAsync(x => x.Id == conversationId, cancellationToken)
            ?? throw new KeyNotFoundException("AI conversation not found.");

        var utcNow = DateTime.UtcNow;
        conversation.LastMessageAtUtc = utcNow;

        await dbContext.AiConversationMessages.AddAsync(new AiConversationMessage
        {
            ConversationId = conversationId,
            Role = AiConversationMessageRole.Assistant,
            Content = content.Trim(),
            Language = NormalizeLanguage(language),
            UsedKnowledge = usedKnowledge,
            SourcesJson = sources is { Count: > 0 } ? JsonSerializer.Serialize(sources, JsonOptions) : null,
            CreatedAtUtc = utcNow
        }, cancellationToken);

        await dbContext.SaveChangesAsync(cancellationToken);
    }

    public async Task<IReadOnlyList<AiAssistantHistoryMessage>> GetRecentHistoryAsync(
        Guid conversationId,
        int maxMessages = 15,
        CancellationToken cancellationToken = default)
    {
        maxMessages = Math.Clamp(maxMessages, 1, 30);
        var rows = await dbContext.AiConversationMessages
            .AsNoTracking()
            .Where(x => x.ConversationId == conversationId)
            .OrderByDescending(x => x.CreatedAtUtc)
            .ThenByDescending(x => x.Id)
            .Take(maxMessages)
            .ToListAsync(cancellationToken);

        rows.Reverse();
        return rows.Select(x => new AiAssistantHistoryMessage(
            x.Role == AiConversationMessageRole.User ? "user" : "assistant",
            x.Content)).ToList();
    }

    public async Task<AiConversationMessagesPageDto> GetMessagesPageAsync(
        Guid conversationId,
        int limit = 50,
        long? beforeMessageId = null,
        CancellationToken cancellationToken = default)
    {
        limit = Math.Clamp(limit, 1, MaxPageSize);
        var query = dbContext.AiConversationMessages
            .AsNoTracking()
            .Where(x => x.ConversationId == conversationId);

        if (beforeMessageId is > 0)
        {
            var cursor = await dbContext.AiConversationMessages
                .AsNoTracking()
                .Where(x => x.Id == beforeMessageId && x.ConversationId == conversationId)
                .Select(x => new { x.Id, x.CreatedAtUtc })
                .FirstOrDefaultAsync(cancellationToken);

            if (cursor is not null)
            {
                query = query.Where(x =>
                    x.CreatedAtUtc < cursor.CreatedAtUtc ||
                    (x.CreatedAtUtc == cursor.CreatedAtUtc && x.Id < cursor.Id));
            }
        }

        var batch = await query
            .OrderByDescending(x => x.CreatedAtUtc)
            .ThenByDescending(x => x.Id)
            .Take(limit + 1)
            .ToListAsync(cancellationToken);

        var hasMore = batch.Count > limit;
        if (hasMore)
        {
            batch.RemoveAt(limit);
        }

        batch.Reverse();
        var messages = batch.Select(MapMessage).ToList();
        var nextBefore = hasMore && messages.Count > 0 ? messages[0].Id : (long?)null;
        return new AiConversationMessagesPageDto(messages, hasMore, nextBefore);
    }

    public async Task<AiConversationListPageDto> ListForUserAsync(
        Guid userId,
        int page = 1,
        int pageSize = 20,
        CancellationToken cancellationToken = default)
    {
        return await ListInternalAsync(userId, page, pageSize, cancellationToken);
    }

    public async Task<AiConversationListPageDto> ListForAdminAsync(
        Guid? userId,
        int page = 1,
        int pageSize = 20,
        CancellationToken cancellationToken = default)
    {
        return await ListInternalAsync(userId, page, pageSize, cancellationToken);
    }

    public async Task<bool> UserOwnsConversationAsync(
        Guid userId,
        Guid conversationId,
        CancellationToken cancellationToken = default)
    {
        return await dbContext.AiConversations
            .AsNoTracking()
            .AnyAsync(x => x.Id == conversationId && x.UserId == userId, cancellationToken);
    }

    private async Task<AiConversationListPageDto> ListInternalAsync(
        Guid? userId,
        int page,
        int pageSize,
        CancellationToken cancellationToken)
    {
        page = Math.Max(1, page);
        pageSize = Math.Clamp(pageSize, 1, MaxPageSize);

        var query = dbContext.AiConversations.AsNoTracking();
        if (userId is not null)
        {
            query = query.Where(x => x.UserId == userId.Value);
        }

        var totalCount = await query.CountAsync(cancellationToken);
        var totalPages = totalCount == 0 ? 1 : (int)Math.Ceiling(totalCount / (double)pageSize);

        var rows = await query
            .OrderByDescending(x => x.LastMessageAtUtc)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(x => new
            {
                x.Id,
                x.ClientSessionId,
                x.TitlePreview,
                x.LastMessageAtUtc,
                MessageCount = x.Messages.Count
            })
            .ToListAsync(cancellationToken);

        var items = rows.Select(x => new AiConversationListItemDto(
            x.Id,
            x.ClientSessionId,
            x.TitlePreview,
            UtcDateTimeHelper.FormatApiDateTime(x.LastMessageAtUtc)!,
            x.MessageCount)).ToList();

        return new AiConversationListPageDto(items, page, pageSize, totalCount, totalPages);
    }

    private static AiConversationMessageDto MapMessage(AiConversationMessage message)
    {
        IReadOnlyList<string>? sources = null;
        if (!string.IsNullOrWhiteSpace(message.SourcesJson))
        {
            try
            {
                sources = JsonSerializer.Deserialize<List<string>>(message.SourcesJson, JsonOptions);
            }
            catch
            {
                sources = null;
            }
        }

        return new AiConversationMessageDto(
            message.Id,
            message.Role == AiConversationMessageRole.User ? "user" : "assistant",
            message.Content,
            message.Language,
            message.UsedKnowledge,
            sources,
            UtcDateTimeHelper.FormatApiDateTime(message.CreatedAtUtc)!);
    }

    private static string NormalizeSessionId(string clientSessionId)
    {
        var clean = (clientSessionId ?? string.Empty).Trim();
        if (clean.Length is 0 or > 64)
        {
            throw new ArgumentException("clientSessionId must be between 1 and 64 characters.");
        }

        return clean;
    }

    private static string NormalizeLanguage(string language)
    {
        var clean = (language ?? "en").Trim().ToLowerInvariant();
        return clean.Length is > 0 and <= 8 ? clean : "en";
    }

    private static string BuildTitlePreview(string content)
    {
        var trimmed = content.Trim();
        if (trimmed.Length <= MaxTitlePreviewLength)
        {
            return trimmed;
        }

        return trimmed[..MaxTitlePreviewLength].TrimEnd() + "…";
    }
}
