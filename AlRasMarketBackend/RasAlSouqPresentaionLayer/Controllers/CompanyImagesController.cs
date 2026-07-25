using BusinessLayer.Dtos;
using BusinessLayer.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace RasAlSouqPresentaionLayer.Controllers;

/// <summary>
/// Endpoints for uploading and managing company images.
/// </summary>
[Route("api/[controller]")]
[ApiController]
public class CompanyImagesController(ICompanyImagesAppService companyImagesAppService, IWebHostEnvironment environment) : ControllerBase
{
    private readonly ICompanyImagesAppService _companyImagesAppService = companyImagesAppService;
    private readonly IWebHostEnvironment _environment = environment;

    /// <summary>
    /// Uploads a temporary company image before account registration.
    /// </summary>
    /// <param name="request">Multipart form payload containing file and primary flag.</param>
    /// <param name="cancellationToken">Cancellation token.</param>
    /// <returns>Saved image metadata.</returns>
    [HttpPost("upload")]
    [Consumes("multipart/form-data")]
    [RequestSizeLimit(10 * 1024 * 1024)]
    public async Task<IActionResult> Upload([FromForm] UploadCompanyImageRequest request, CancellationToken cancellationToken = default)
    {
        try
        {
            var root = _environment.WebRootPath ?? Path.Combine(Directory.GetCurrentDirectory(), "wwwroot");
            var result = await _companyImagesAppService.UploadAsync(new UploadCompanyImageInput
            {
                File = request.File,
                IsPrimary = request.IsPrimary,
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

/// <summary>
/// Request model for company image upload.
/// </summary>
public sealed class UploadCompanyImageRequest
{
    /// <summary>
    /// Image file to upload (jpg/png supported by decoder).
    /// </summary>
    public IFormFile? File { get; set; }
    /// <summary>
    /// Marks the uploaded image as primary company image.
    /// </summary>
    public bool IsPrimary { get; set; }
}
