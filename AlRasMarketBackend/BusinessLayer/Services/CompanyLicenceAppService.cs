using BusinessLayer.Dtos;
using BusinessLayer.Interfaces;

namespace BusinessLayer.Services;

public class CompanyLicenceAppService(IMediaStorageService mediaStorage) : ICompanyLicenceAppService
{
    private const string CompanyLicencesFolder = "company-licences";

    public async Task<object> UploadAsync(UploadCompanyLicenceInput input, CancellationToken cancellationToken = default)
    {
        if (input.File is null || input.File.Length == 0)
        {
            throw new ArgumentException("File is required.");
        }

        var extension = Path.GetExtension(input.File.FileName);
        if (string.IsNullOrWhiteSpace(extension))
        {
            extension = ".jpg";
        }

        var fileName = $"licence-{Guid.NewGuid():N}{extension.ToLowerInvariant()}";
        var licencePath = await mediaStorage.SaveFormFileAsync(
            input.File,
            CompanyLicencesFolder,
            fileName,
            cancellationToken: cancellationToken);

        return new { licencePath };
    }
}
