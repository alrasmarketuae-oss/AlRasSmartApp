using BusinessLayer.Dtos;
using BusinessLayer.Interfaces;

namespace BusinessLayer.Services;

public class CompanyImagesAppService(IMediaStorageService mediaStorage) : ICompanyImagesAppService
{
    private const string CompanyImagesFolder = "company-images";

    public async Task<object> UploadAsync(UploadCompanyImageInput input, CancellationToken cancellationToken = default)
    {
        if (input.File is null || input.File.Length == 0)
        {
            throw new ArgumentException("File is required.");
        }

        var fileName = $"company-{Guid.NewGuid():N}.jpg";
        var imagePath = await mediaStorage.SaveCompressedJpegAsync(
            input.File,
            CompanyImagesFolder,
            fileName,
            cancellationToken: cancellationToken);

        return new { imagePath, isPrimary = input.IsPrimary };
    }
}
