using BusinessLayer.Dtos;

namespace BusinessLayer.Interfaces;

public interface IAdminChatReportAppService
{
    Task<AdminChatCompanyReportDto> GenerateCompanyReportAsync(
        AdminChatCompanyReportRequest request,
        CancellationToken cancellationToken = default);
}
