using BusinessLayer.Constants;
using BusinessLayer.Dtos;
using BusinessLayer.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using RasAlSouqPresentaionLayer.Authorization;

namespace RasAlSouqPresentaionLayer.Controllers;

[Route("api/admin/shipping")]
[ApiController]
[Authorize(Roles = "Admin,Employee")]
[RequireAdminPermission(AdminPermissions.ShippingView)]
public class AdminShippingController(
    IAdminShippingAppService adminShippingAppService,
    IWebHostEnvironment environment) : ControllerBase
{
    [HttpGet("providers")]
    public async Task<IActionResult> GetProviders(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20,
        [FromQuery] string? search = null,
        CancellationToken cancellationToken = default)
    {
        var result = await adminShippingAppService.GetProvidersAsync(page, pageSize, search, cancellationToken);
        return Ok(result);
    }

    [HttpGet("providers/{providerUserId}")]
    public async Task<IActionResult> GetProviderDetail(
        string providerUserId,
        CancellationToken cancellationToken = default)
    {
        try
        {
            var result = await adminShippingAppService.GetProviderDetailAsync(providerUserId, cancellationToken);
            return Ok(result);
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPatch("providers/{providerUserId}/active")]
    public async Task<IActionResult> SetProviderActive(
        string providerUserId,
        [FromBody] SetShippingProviderActiveRequest request,
        CancellationToken cancellationToken = default)
    {
        try
        {
            var result = await adminShippingAppService.SetProviderActiveAsync(
                providerUserId,
                request.IsActive,
                cancellationToken);
            return Ok(result);
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPost("providers")]
    public async Task<IActionResult> CreateProvider(
        [FromBody] CreateShippingProviderRequest request,
        CancellationToken cancellationToken = default)
    {
        try
        {
            var result = await adminShippingAppService.CreateProviderAsync(new AdminCreateShippingProviderInput
            {
                CompanyName = request.CompanyName,
                FullName = request.FullName,
                Email = request.Email,
                PhoneNumber = request.PhoneNumber,
                FromCountryName = request.FromCountryName,
                FromPortName = request.FromPortName,
                ToCountryName = request.ToCountryName,
                ToPortName = request.ToPortName,
                Container20ftPriceUsd = request.Container20ftPriceUsd,
                Container40ftPriceUsd = request.Container40ftPriceUsd
            }, cancellationToken);
            return Ok(result);
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (InvalidOperationException ex)
        {
            return Conflict(new { message = ex.Message });
        }
    }

    [HttpPut("providers/{providerUserId}")]
    public async Task<IActionResult> UpdateProvider(
        string providerUserId,
        [FromBody] UpdateShippingProviderRequest request,
        CancellationToken cancellationToken = default)
    {
        try
        {
            var result = await adminShippingAppService.UpdateProviderAsync(providerUserId, new AdminUpdateShippingProviderInput
            {
                CompanyName = request.CompanyName,
                FullName = request.FullName,
                Email = request.Email,
                PhoneNumber = request.PhoneNumber,
                FromCountryName = request.FromCountryName,
                FromPortName = request.FromPortName,
                ToCountryName = request.ToCountryName,
                ToPortName = request.ToPortName,
                Container20ftPriceUsd = request.Container20ftPriceUsd,
                Container40ftPriceUsd = request.Container40ftPriceUsd
            }, cancellationToken);
            return Ok(result);
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (InvalidOperationException ex)
        {
            return Conflict(new { message = ex.Message });
        }
    }

    [HttpPost("providers/{providerUserId}/image")]
    [RequestSizeLimit(5 * 1024 * 1024)]
    public async Task<IActionResult> UploadProviderImage(
        string providerUserId,
        [FromForm] UploadShippingProviderImageRequest request,
        CancellationToken cancellationToken = default)
    {
        try
        {
            var webRoot = environment.WebRootPath
                ?? Path.Combine(environment.ContentRootPath, "wwwroot");
            var result = await adminShippingAppService.UploadProviderImageAsync(
                new AdminUploadShippingProviderImageInput
                {
                    ProviderUserId = providerUserId,
                    File = request.File,
                    WebRootPath = webRoot
                },
                cancellationToken);
            return Ok(result);
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpDelete("providers/{providerUserId}")]
    public async Task<IActionResult> DeleteProvider(
        string providerUserId,
        CancellationToken cancellationToken = default)
    {
        try
        {
            var result = await adminShippingAppService.DeleteProviderAsync(providerUserId, cancellationToken);
            return Ok(result);
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (InvalidOperationException ex)
        {
            return Conflict(new { message = ex.Message });
        }
    }

    [HttpPost("posts/{postId:long}/approve")]
    public async Task<IActionResult> ApprovePost(long postId, CancellationToken cancellationToken = default)
    {
        try
        {
            var message = await adminShippingAppService.ApprovePostAsync(postId, cancellationToken);
            return Ok(new { message });
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
        catch (InvalidOperationException ex)
        {
            return Conflict(new { message = ex.Message });
        }
    }

    [HttpPost("posts/{postId:long}/reject")]
    public async Task<IActionResult> RejectPost(
        long postId,
        [FromBody] RejectShippingPostRequest? request,
        CancellationToken cancellationToken = default)
    {
        try
        {
            var message = await adminShippingAppService.RejectPostAsync(
                postId,
                request?.Reason,
                cancellationToken);
            return Ok(new { message });
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
        catch (InvalidOperationException ex)
        {
            return Conflict(new { message = ex.Message });
        }
    }
}

public sealed class RejectShippingPostRequest
{
    public string? Reason { get; set; }
}

public sealed class SetShippingProviderActiveRequest
{
    public bool IsActive { get; set; }
}

public sealed class CreateShippingProviderRequest
{
    public string CompanyName { get; set; } = string.Empty;
    public string FullName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string PhoneNumber { get; set; } = string.Empty;
    public string FromCountryName { get; set; } = string.Empty;
    public string FromPortName { get; set; } = string.Empty;
    public string ToCountryName { get; set; } = string.Empty;
    public string ToPortName { get; set; } = string.Empty;
    public decimal? Container20ftPriceUsd { get; set; }
    public decimal? Container40ftPriceUsd { get; set; }
}

public sealed class UpdateShippingProviderRequest
{
    public string CompanyName { get; set; } = string.Empty;
    public string FullName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string PhoneNumber { get; set; } = string.Empty;
    public string FromCountryName { get; set; } = string.Empty;
    public string FromPortName { get; set; } = string.Empty;
    public string ToCountryName { get; set; } = string.Empty;
    public string ToPortName { get; set; } = string.Empty;
    public decimal? Container20ftPriceUsd { get; set; }
    public decimal? Container40ftPriceUsd { get; set; }
}

public sealed class UploadShippingProviderImageRequest
{
    public IFormFile? File { get; set; }
}
