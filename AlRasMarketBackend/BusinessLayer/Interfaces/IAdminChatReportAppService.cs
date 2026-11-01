using BusinessLayer.Dtos;

namespace BusinessLayer.Interfaces;

public interface IAdminChatReportAppService
{
    Task<AdminChatCompanyReportDto> GenerateCompanyReportAsync(
        AdminChatCompanyReportRequest request,
        CancellationToken cancellationToken = default);

    Task<AdminChatCompanyReportDto> GenerateAiConversationReportAsync(
        Guid conversationId,
        string language = "ar",
        CancellationToken cancellationToken = default);

    /// <summary>Arabic text is translated to English, anything else to Arabic.</summary>
    Task<AdminChatTranslateDto> TranslateMessageAsync(
        AdminChatTranslateRequest request,
        CancellationToken cancellationToken = default);
}
