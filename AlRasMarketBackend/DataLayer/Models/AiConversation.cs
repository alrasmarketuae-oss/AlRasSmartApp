namespace DataLayer.Models;

public enum AiConversationMessageRole : byte
{
    User = 1,
    Assistant = 2
}

/// <summary>One AI chat thread per user + client session id.</summary>
public class AiConversation
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    /// <summary>Client-supplied session id from the mobile app (max 64 chars).</summary>
    public string ClientSessionId { get; set; } = string.Empty;
    /// <summary>First user question preview for inbox lists.</summary>
    public string? TitlePreview { get; set; }
    public DateTime CreatedAtUtc { get; set; }
    public DateTime LastMessageAtUtc { get; set; }

    public User? User { get; set; }
    public ICollection<AiConversationMessage> Messages { get; set; } = [];
}

public class AiConversationMessage
{
    public long Id { get; set; }
    public Guid ConversationId { get; set; }
    public AiConversationMessageRole Role { get; set; }
    public string Content { get; set; } = string.Empty;
    public string Language { get; set; } = "en";
    public bool? UsedKnowledge { get; set; }
    public string? SourcesJson { get; set; }
    public string? ListingsJson { get; set; }
    public string? ThinkingJson { get; set; }
    public DateTime CreatedAtUtc { get; set; }

    public AiConversation? Conversation { get; set; }
}
