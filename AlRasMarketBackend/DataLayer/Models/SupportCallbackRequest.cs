namespace DataLayer.Models;

/// <summary>Customer asked AI for human/tech support and left callback contact details.</summary>
public class SupportCallbackRequest
{
    public Guid Id { get; set; }

    public Guid? UserId { get; set; }

    public string FullName { get; set; } = string.Empty;

    public string Phone { get; set; } = string.Empty;

    public string Email { get; set; } = string.Empty;

    /// <summary>Last user question / reason, if any.</summary>
    public string? Question { get; set; }

    public string Language { get; set; } = "ar";

    /// <summary>Pending | Contacted | Closed</summary>
    public string Status { get; set; } = "Pending";

    public string? Source { get; set; }

    public string? AiConversationId { get; set; }

    public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;

    public DateTime? ContactedAtUtc { get; set; }

    public Guid? ContactedByAdminUserId { get; set; }

    public string? AdminNotes { get; set; }

    public User? User { get; set; }
}
