using BusinessLayer.Dtos;

namespace BusinessLayer.Interfaces;

public interface IAdminMonitoringAppService
{
    Task<AdminMonitoringOverviewDto> GetOverviewAsync(string? range, CancellationToken cancellationToken = default);
}
