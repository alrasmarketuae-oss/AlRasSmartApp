namespace DataLayer.Models;

public static class UserFeedbackTypes
{
    public const string Complaint = "Complaint";
    public const string Suggestion = "Suggestion";
}

public static class UserFeedbackStatuses
{
    public const string Pending = "Pending";
    public const string InReview = "InReview";
    public const string Resolved = "Resolved";
    public const string Closed = "Closed";
}

/// <summary>User complaint or suggestion from profile or AI assistant.</summary>
public class UserFeedbackSubmission
{
    public Guid Id { get; set; }

    public Guid? UserId { get; set; }

    /// <summary>Complaint | Suggestion</summary>
    public string Type { get; set; } = UserFeedbackTypes.Complaint;

    public string Subject { get; set; } = string.Empty;

    public string Message { get; set; } = string.Empty;

    public string? OrderReference { get; set; }

    public string FullName { get; set; } = string.Empty;

    public string? Email { get; set; }

    public string? Phone { get; set; }

    public string Language { get; set; } = "ar";

    /// <summary>Pending | InReview | Resolved | Closed</summary>
    public string Status { get; set; } = UserFeedbackStatuses.Pending;

    public string? Source { get; set; }

    public string? AiConversationId { get; set; }

    public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;

    public DateTime? ResolvedAtUtc { get; set; }

    public Guid? ResolvedByAdminUserId { get; set; }

    public string? AdminNotes { get; set; }

    public User? User { get; set; }
}
