using BusinessLayer.Dtos;
using BusinessLayer.Interfaces;

namespace BusinessLayer.Services;

public class CompanyImagesAppService(IMediaStorageService mediaStorage) : ICompanyImagesAppService
{
    private const string CompanyImagesFolder = "company-images";
    private const string ProfileImagesFolder = "images/profiles";

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

    public async Task<object> UploadProfileLogoAsync(
        UploadCompanyImageInput input,
        CancellationToken cancellationToken = default)
    {
        if (input.File is null || input.File.Length == 0)
        {
            throw new ArgumentException("File is required.");
        }

        var fileName = $"profile-{Guid.NewGuid():N}.jpg";
        var imagePath = await mediaStorage.SaveCompressedJpegAsync(
            input.File,
            ProfileImagesFolder,
            fileName,
            cancellationToken: cancellationToken);

        return new { imagePath, imgPath = imagePath };
    }
}
