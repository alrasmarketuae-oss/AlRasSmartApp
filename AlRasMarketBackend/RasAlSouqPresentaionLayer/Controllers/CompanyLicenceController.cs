using BusinessLayer.Dtos;
using BusinessLayer.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace RasAlSouqPresentaionLayer.Controllers;

/// <summary>
/// Endpoints for uploading company licence files.
/// </summary>
[Route("api/[controller]")]
[ApiController]
public class CompanyLicenceController(ICompanyLicenceAppService companyLicenceAppService, IWebHostEnvironment environment) : ControllerBase
{
    private readonly ICompanyLicenceAppService _companyLicenceAppService = companyLicenceAppService;
    private readonly IWebHostEnvironment _environment = environment;

    /// <summary>
    /// Uploads a temporary company licence file before account registration.
    /// </summary>
    [HttpPost("upload")]
    [Consumes("multipart/form-data")]
    [RequestSizeLimit(20 * 1024 * 1024)]
    public async Task<IActionResult> Upload([FromForm] UploadCompanyLicenceRequest request, CancellationToken cancellationToken = default)
    {
        try
        {
            var root = _environment.WebRootPath ?? Path.Combine(Directory.GetCurrentDirectory(), "wwwroot");
            var result = await _companyLicenceAppService.UploadAsync(new UploadCompanyLicenceInput
            {
                File = request.File,
                WebRootPath = root
            }, cancellationToken);

            return Ok(result);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }
}

public sealed class UploadCompanyLicenceRequest
{
    public IFormFile? File { get; set; }
}
