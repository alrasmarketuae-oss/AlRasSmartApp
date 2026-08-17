namespace DataLayer.Models;

public enum ChatMessageType : byte
{
    Text = 1,
    Voice = 2,
    Image = 3,
    Location = 4,
    Video = 5,
    File = 6
}

public class ChatMessage
{
    public string MessageId { get; set; } = string.Empty;
    public Guid FromUserId { get; set; }
    public Guid ToUserId { get; set; }
    public ChatMessageType MessageType { get; set; }
    public string Content { get; set; } = string.Empty;
    public DateTime SentAtUtc { get; set; }
    public bool IsEdited { get; set; }
    public DateTime? EditedAtUtc { get; set; }
    public bool IsSeen { get; set; }
    public DateTime? SeenAtUtc { get; set; }
    public bool IsDelivered { get; set; }
    public DateTime? DeliveredAtUtc { get; set; }

    public string? ReplyToMessageId { get; set; }
    public string? ReplyToPreview { get; set; }
    public ChatMessageType? ReplyToMessageType { get; set; }
    public bool IsForwarded { get; set; }
    public bool IsDeleted { get; set; }
    public DateTime? DeletedAtUtc { get; set; }
    public bool DeletedForFromUser { get; set; }
    public bool DeletedForToUser { get; set; }

    public User? FromUser { get; set; }
    public User? ToUser { get; set; }
}
