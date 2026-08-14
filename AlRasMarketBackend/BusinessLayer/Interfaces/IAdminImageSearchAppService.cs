using BusinessLayer.Dtos;

namespace BusinessLayer.Interfaces;

public interface IAdminImageSearchAppService
{
    Task<AdminImageSearchStatusDto> GetStatusAsync(CancellationToken cancellationToken = default);

    Task<object> TestSearchAsync(Stream imageStream, string fileName, CancellationToken cancellationToken = default);
}
