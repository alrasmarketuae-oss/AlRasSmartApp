using System.Security.Claims;
using BusinessLayer.Dtos;
using BusinessLayer.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace RasAlSouqPresentaionLayer.Controllers;

/// <summary>
/// Endpoints for receiving and creating offers.
/// </summary>
[Route("api/[controller]")]
[ApiController]
[Authorize]
public class OffersController(IOffersAppService offersAppService) : ControllerBase
{
    /// <summary>
    /// Creates a new offer from the authenticated user to target user.
    /// Country and port are accepted as strings and mapped to FK ids.
    /// </summary>
    [HttpPost("OfferOnRequests")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> OfferOnRequests([FromBody] CreateOfferRequest request, CancellationToken cancellationToken = default)
    {
        var userId = User.FindFirst("EntityId")?.Value ?? User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrWhiteSpace(userId))
        {
            return Unauthorized(new { message = "Invalid token." });
        }

        try
        {
            var result = await offersAppService.CreateAsync(new CreateOfferInput
            {
                FromUserId = userId,
                ToUserId = request.ToUserId,
                CountryName = request.CountryName,
                PortName = request.PortName,
                DeliveryWindow = request.DeliveryWindow,
                ProductId = request.ProductId,
                RequestedQuantity = request.RequestedQuantity,
                UnitName = request.UnitName,
                UnitPrice = request.UnitPrice,
                TotalPrice = request.TotalPrice,
                ImagePaths = request.ImagePaths,
                DocumentPaths = request.DocumentPaths
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
    }

    /// <summary>
    /// Returns offers on requests, optionally filtered by product id.
    /// </summary>
    [HttpGet("OfferOnRequests")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> GetOffersOnRequests([FromQuery] string? productId, CancellationToken cancellationToken = default)
    {
        try
        {
            var result = await offersAppService.GetOffersOnRequestsAsync(productId, cancellationToken);
            return Ok(result);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    /// <summary>
    /// Creates a new negotiable offer for products with negotiable pricing.
    /// </summary>
    [HttpPost("OfferOnNegotiable")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> OfferOnNegotiable([FromBody] CreateOfferOnNegotiableRequest request, CancellationToken cancellationToken = default)
    {
        var userId = User.FindFirst("EntityId")?.Value ?? User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrWhiteSpace(userId))
        {
            return Unauthorized(new { message = "Invalid token." });
        }

        try
        {
            var result = await offersAppService.CreateOfferOnNegotiableAsync(new CreateOfferOnNegotiableInput
            {
                FromUserId = userId,
                ToUserId = request.ToUserId,
                ProductId = request.ProductId,
                OfferedPrice = request.OfferedPrice,
                UnitName = request.UnitName,
                BaseUnitPrice = request.BaseUnitPrice,
                RequestedQuantity = request.RequestedQuantity
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
    }

    /// <summary>
    /// Returns negotiable offers, optionally filtered by product id.
    /// </summary>
    [HttpGet("OfferOnNegotiable")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> GetOfferOnNegotiable([FromQuery] string? productId, CancellationToken cancellationToken = default)
    {
        try
        {
            var result = await offersAppService.GetOfferOnNegotiableAsync(productId, cancellationToken);
            return Ok(result);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }
}

public sealed class CreateOfferRequest
{
    public string ToUserId { get; set; } = string.Empty;
    public string CountryName { get; set; } = string.Empty;
    public string PortName { get; set; } = string.Empty;
    public string DeliveryWindow { get; set; } = string.Empty;
    public string ProductId { get; set; } = string.Empty;
    public decimal RequestedQuantity { get; set; }
    public string UnitName { get; set; } = string.Empty;
    public decimal UnitPrice { get; set; }
    public decimal TotalPrice { get; set; }
    public List<string>? ImagePaths { get; set; }
    public List<string>? DocumentPaths { get; set; }
}

public sealed class CreateOfferOnNegotiableRequest
{
    public string ToUserId { get; set; } = string.Empty;
    public string ProductId { get; set; } = string.Empty;
    public decimal OfferedPrice { get; set; }
    public string UnitName { get; set; } = string.Empty;
    public decimal BaseUnitPrice { get; set; }
    public decimal RequestedQuantity { get; set; }
}
