using System.Security.Claims;
using BusinessLayer.Dtos;
using BusinessLayer.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace RasAlSouqPresentaionLayer.Controllers;

[Route("api/[controller]")]
[ApiController]
[Authorize]
public class ShippingCompanyController(IShippingCompanyAppService shippingCompanyAppService) : ControllerBase
{
    [HttpGet("dashboard")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    public async Task<IActionResult> GetDashboard(CancellationToken cancellationToken)
    {
        var userId = GetUserId();
        if (userId is null) return Unauthorized();

        try
        {
            var result = await shippingCompanyAppService.GetDashboardAsync(userId, cancellationToken);
            return Ok(result);
        }
        catch (UnauthorizedAccessException ex)
        {
            return Forbid(ex.Message);
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
    }

    [HttpGet("posts")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    public async Task<IActionResult> GetMyPosts(CancellationToken cancellationToken)
    {
        var userId = GetUserId();
        if (userId is null) return Unauthorized();

        try
        {
            var result = await shippingCompanyAppService.GetMyPostsAsync(userId, cancellationToken);
            return Ok(result);
        }
        catch (UnauthorizedAccessException)
        {
            return Forbid();
        }
    }

    [HttpPost("posts")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> CreatePost(
        [FromBody] ShippingCompanyPostRequest request,
        CancellationToken cancellationToken)
    {
        var userId = GetUserId();
        if (userId is null) return Unauthorized();

        try
        {
            var result = await shippingCompanyAppService.CreatePostAsync(userId, MapCreate(request), cancellationToken);
            return Ok(result);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
        catch (UnauthorizedAccessException ex)
        {
            return Forbid(ex.Message);
        }
    }

    [HttpPut("posts/{postId:long}")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> UpdatePost(
        long postId,
        [FromBody] ShippingCompanyPostRequest request,
        CancellationToken cancellationToken)
    {
        var userId = GetUserId();
        if (userId is null) return Unauthorized();

        try
        {
            var result = await shippingCompanyAppService.UpdatePostAsync(new UpdateInternationalShippingPostInput
            {
                UserId = userId,
                PostId = postId,
                FromCountryName = request.FromCountryName,
                FromPortName = request.FromPortName,
                ToCountryName = request.ToCountryName,
                ToPortName = request.ToPortName,
                Container20ftPriceUsd = request.Container20ftPriceUsd,
                Container40ftPriceUsd = request.Container40ftPriceUsd,
                MinDurationDays = request.MinDurationDays,
                MaxDurationDays = request.MaxDurationDays,
                Details = request.Details,
                PhoneNumber = request.PhoneNumber
            }, cancellationToken);

            return Ok(result);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
        catch (UnauthorizedAccessException ex)
        {
            return Forbid(ex.Message);
        }
    }

    [HttpDelete("posts/{postId:long}")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    public async Task<IActionResult> DeletePost(long postId, CancellationToken cancellationToken)
    {
        var userId = GetUserId();
        if (userId is null) return Unauthorized();

        try
        {
            var result = await shippingCompanyAppService.DeletePostAsync(userId, postId, cancellationToken);
            return Ok(result);
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
        catch (UnauthorizedAccessException)
        {
            return Forbid();
        }
    }

    private string? GetUserId() =>
        User.FindFirst("EntityId")?.Value ?? User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

    private static CreateInternationalShippingPostInput MapCreate(ShippingCompanyPostRequest request) =>
        new()
        {
            FromCountryName = request.FromCountryName,
            FromPortName = request.FromPortName,
            ToCountryName = request.ToCountryName,
            ToPortName = request.ToPortName,
            PhoneNumber = request.PhoneNumber,
            Container20ftPriceUsd = request.Container20ftPriceUsd,
            Container40ftPriceUsd = request.Container40ftPriceUsd,
            MinDurationDays = request.MinDurationDays,
            MaxDurationDays = request.MaxDurationDays,
            Details = request.Details,
            PriceUsd = request.Container20ftPriceUsd,
            ShippingCostUsd = 0
        };
}

public sealed class ShippingCompanyPostRequest
{
    public string FromCountryName { get; set; } = string.Empty;
    public string FromPortName { get; set; } = string.Empty;
    public string ToCountryName { get; set; } = string.Empty;
    public string ToPortName { get; set; } = string.Empty;
    public string PhoneNumber { get; set; } = string.Empty;
    public decimal Container20ftPriceUsd { get; set; }
    public decimal Container40ftPriceUsd { get; set; }
    public int? MinDurationDays { get; set; }
    public int? MaxDurationDays { get; set; }
    public string? Details { get; set; }
}
