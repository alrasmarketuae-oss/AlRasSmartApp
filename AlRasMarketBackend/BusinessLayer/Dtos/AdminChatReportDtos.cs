namespace BusinessLayer.Dtos;

public sealed class AdminChatCompanyReportRequest
{
    public Guid ParticipantUserId { get; set; }
    public string Language { get; set; } = "ar";
    public List<AdminChatReportMessageInput> Messages { get; set; } = [];
}

public sealed class AdminChatReportMessageInput
{
    public string Sender { get; set; } = "customer";
    public string Content { get; set; } = string.Empty;
    public string MessageType { get; set; } = "Text";
    public string SentAtUtc { get; set; } = string.Empty;
}

public sealed class AdminChatCompanyReportDto
{
    public string CompanyName { get; set; } = string.Empty;
    public string? ContactFullName { get; set; }
    public string? CompanyImageUrl { get; set; }
    public int AdsCount { get; set; }
    public string Report { get; set; } = string.Empty;
    public string Language { get; set; } = "ar";
}

public sealed class AdminAiConversationReportRequest
{
    public string Language { get; set; } = "ar";
}

public sealed class AdminChatReportAdLine
{
    public string Name { get; set; } = string.Empty;
    public string TypeName { get; set; } = string.Empty;
    public string? CategoryName { get; set; }
}
