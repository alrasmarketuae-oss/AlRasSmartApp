using BusinessLayer.Dtos;
using Microsoft.AspNetCore.Http;

namespace BusinessLayer.Interfaces;

public interface IClipReferenceImageAppService
{
    Task<AdminClipReferenceImagesPageDto> GetReferenceImagesAsync(
        int page,
        int pageSize,
        string? search,
        CancellationToken cancellationToken = default);

    Task<object> UploadReferenceImagesAsync(
        string productName,
        string? productNameAr,
        string? productCode,
        IReadOnlyList<IFormFile> files,
        Guid? adminUserId,
        CancellationToken cancellationToken = default);

    Task<object> DeleteReferenceImageAsync(long id, CancellationToken cancellationToken = default);

    Task<object> ReindexReferenceImagesAsync(CancellationToken cancellationToken = default);

    Task IndexReferenceImageAsync(long referenceImageId, CancellationToken cancellationToken = default);
}
