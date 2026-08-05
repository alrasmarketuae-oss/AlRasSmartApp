using System.Security.Claims;
using BusinessLayer.Dtos;
using BusinessLayer.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace RasAlSouqPresentaionLayer.Controllers;

/// <summary>
/// Checkout and order placement for authenticated buyers.
/// </summary>
[Route("api/[controller]")]
[ApiController]
[Authorize]
public class OrdersController(
    IOrdersAppService ordersAppService,
    IProductAssetsAppService productAssetsAppService,
    IWebHostEnvironment environment) : ControllerBase
{
    /// <summary>
    /// Creates a direct order for any product type. FromUserId is taken from the JWT token.
    /// Omit productId to checkout from cart.
    /// </summary>
    [HttpPost]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> PlaceOrder([FromBody] CreateOrderRequest request, CancellationToken cancellationToken)
    {
        var userId = GetUserId();
        if (userId is null)
        {
            return Unauthorized(new { message = "Invalid token." });
        }

        try
        {
            if (!string.IsNullOrWhiteSpace(request.ProductId))
            {
                var result = await ordersAppService.PlaceBookingOrderAsync(MapBookingOrder(request, userId), cancellationToken);
                return Ok(result);
            }

            var cartResult = await ordersAppService.PlaceOrderFromCartAsync(new PlaceOrderInput
            {
                UserId = userId,
                AddressId = request.AddressId,
                AddressLine = request.AddressLine,
                CityName = request.CityName,
                PaymentMethodName = request.PaymentMethodName ?? "Online",
                ShippingCostAed = request.ShippingCostAed,
                IsSelfPickup = request.IsSelfPickup,
                Notes = request.Notes
            }, cancellationToken);

            return Ok(cartResult);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (UnauthorizedAccessException ex)
        {
            return StatusCode(StatusCodes.Status403Forbidden, new { message = ex.Message });
        }
    }

    /// <summary>
    /// Creates a direct order for any product type — same body as POST /api/Orders with productId.
    /// </summary>
    [HttpPost("booking")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> PlaceBookingOrder([FromBody] CreateOrderRequest request, CancellationToken cancellationToken)
    {
        var userId = GetUserId();
        if (userId is null)
        {
            return Unauthorized(new { message = "Invalid token." });
        }

        try
        {
            var result = await ordersAppService.PlaceBookingOrderAsync(MapBookingOrder(request, userId), cancellationToken);
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
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (UnauthorizedAccessException ex)
        {
            return StatusCode(StatusCodes.Status403Forbidden, new { message = ex.Message });
        }
    }

    /// <summary>
    /// Lists orders for the authenticated user (buyer or supplier) — same shape as admin dashboard orders.
    /// </summary>
    [HttpGet("myOrders")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> GetMyOrders(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20,
        [FromQuery] byte? statusId = null,
        [FromQuery] string? search = null,
        CancellationToken cancellationToken = default)
    {
        var userId = GetUserId();
        if (userId is null)
        {
            return Unauthorized(new { message = "Invalid token." });
        }

        try
        {
            var result = await ordersAppService.GetMyOrdersAsync(
                userId,
                page,
                pageSize,
                statusId,
                search,
                cancellationToken);
            return Ok(result);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    /// <summary>
    /// Lists offers the authenticated user submitted on Request ads (Account → My Offers).
    /// </summary>
    [HttpGet("myOffers")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> GetMyOffers(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20,
        [FromQuery] byte? statusId = null,
        [FromQuery] string? search = null,
        CancellationToken cancellationToken = default)
    {
        var userId = GetUserId();
        if (userId is null)
        {
            return Unauthorized(new { message = "Invalid token." });
        }

        try
        {
            var result = await ordersAppService.GetMyOffersAsync(
                userId,
                page,
                pageSize,
                statusId,
                search,
                cancellationToken);
            return Ok(result);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    /// <summary>
    /// Lists all orders (supplier offers) submitted on a Requests ad, with the same shape as myOrders.
    /// </summary>
    [HttpGet("getOffersForRequest")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetOffersForRequest(
        [FromQuery] string productId,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20,
        [FromQuery] byte? statusId = null,
        [FromQuery] string? search = null,
        CancellationToken cancellationToken = default)
    {
        var userId = GetUserId();
        if (userId is null)
        {
            return Unauthorized(new { message = "Invalid token." });
        }

        try
        {
            var result = await ordersAppService.GetOffersForRequestAsync(
                userId,
                productId,
                page,
                pageSize,
                statusId,
                search,
                cancellationToken);
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
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (UnauthorizedAccessException ex)
        {
            return StatusCode(StatusCodes.Status403Forbidden, new { message = ex.Message });
        }
    }

    /// <summary>
    /// Lists supplier offers received on the authenticated user's Requests ads.
    /// Prices include Requests commission; supplier identity is not exposed.
    /// </summary>
    [HttpGet("getMyOffersOnMyRequests")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> GetMyOffersOnMyRequests(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20,
        [FromQuery] string? productId = null,
        [FromQuery] byte? statusId = null,
        CancellationToken cancellationToken = default)
    {
        var userId = GetUserId();
        if (userId is null)
        {
            return Unauthorized(new { message = "Invalid token." });
        }

        try
        {
            var result = await ordersAppService.GetMyOffersOnMyRequestsAsync(
                userId,
                page,
                pageSize,
                productId,
                statusId,
                cancellationToken);
            return Ok(result);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    /// <summary>
    /// Returns a single order with all stored fields.
    /// </summary>
    [HttpGet("{orderId:long}")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetOrder([FromRoute] long orderId, CancellationToken cancellationToken)
    {
        var userId = GetUserId();
        if (userId is null)
        {
            return Unauthorized(new { message = "Invalid token." });
        }

        try
        {
            var result = await ordersAppService.GetOrderByIdAsync(userId, orderId, cancellationToken);
            return Ok(result);
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
        catch (UnauthorizedAccessException ex)
        {
            return StatusCode(StatusCodes.Status403Forbidden, new { message = ex.Message });
        }
    }

    /// <summary>
    /// Retail buyer requests a return after delivery (reason + optional images/videos).
    /// </summary>
    [HttpPost("{orderId:long}/return")]
    [Consumes("multipart/form-data")]
    [RequestSizeLimit(40 * 1024 * 1024)]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> RequestReturn(
        [FromRoute] long orderId,
        [FromForm] string reason,
        [FromForm] List<IFormFile>? mediaFiles,
        CancellationToken cancellationToken)
    {
        var userId = GetUserId();
        if (userId is null)
        {
            return Unauthorized(new { message = "Invalid token." });
        }

        try
        {
            var result = await ordersAppService.RequestOrderReturnAsync(new RequestOrderReturnInput
            {
                UserId = userId,
                OrderId = orderId,
                Reason = reason ?? string.Empty,
                MediaFiles = mediaFiles ?? [],
                WebRootPath = environment.WebRootPath
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
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (UnauthorizedAccessException ex)
        {
            return StatusCode(StatusCodes.Status403Forbidden, new { message = ex.Message });
        }
    }

    /// <summary>
    /// Updates order status along the workflow: Ordered → Approved → Paid → Shipping → Delivered.
    /// </summary>
    [HttpPatch("{orderId:long}/status")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<IActionResult> UpdateOrderStatus(
        [FromRoute] long orderId,
        [FromBody] UpdateOrderStatusRequest request,
        CancellationToken cancellationToken)
    {
        var userId = GetUserId();
        if (userId is null)
        {
            return Unauthorized(new { message = "Invalid token." });
        }

        try
        {
            var result = await ordersAppService.UpdateOrderStatusAsync(new UpdateOrderStatusInput
            {
                UserId = userId,
                OrderId = orderId,
                StatusId = request.StatusId
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
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (UnauthorizedAccessException ex)
        {
            return StatusCode(StatusCodes.Status403Forbidden, new { message = ex.Message });
        }
    }

    /// <summary>
    /// Lists videos attached to an order (buyer, seller, or admin).
    /// </summary>
    [HttpGet("{orderId:long}/videos")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetOrderVideos([FromRoute] long orderId, CancellationToken cancellationToken)
    {
        var userId = GetUserId();
        if (userId is null)
        {
            return Unauthorized(new { message = "Invalid token." });
        }

        try
        {
            var result = await ordersAppService.GetOrderVideosAsync(userId, orderId, cancellationToken);
            return Ok(result);
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
        catch (UnauthorizedAccessException ex)
        {
            return StatusCode(StatusCodes.Status403Forbidden, new { message = ex.Message });
        }
    }

    /// <summary>
    /// Uploads a video for an order (buyer, seller, or admin).
    /// </summary>
    [HttpPost("{orderId:long}/videos/upload")]
    [Consumes("multipart/form-data")]
    [RequestSizeLimit(50 * 1024 * 1024)]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> UploadOrderVideo(
        [FromRoute] long orderId,
        [FromForm] UploadOrderVideoRequest request,
        CancellationToken cancellationToken)
    {
        var userId = GetUserId();
        if (userId is null)
        {
            return Unauthorized(new { message = "Invalid token." });
        }

        try
        {
            var root = environment.WebRootPath ?? Path.Combine(Directory.GetCurrentDirectory(), "wwwroot");
            var result = await ordersAppService.UploadOrderVideoAsync(new UploadOrderVideoInput
            {
                UserId = userId,
                OrderId = orderId,
                File = request.File,
                WebRootPath = root
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
            return StatusCode(StatusCodes.Status403Forbidden, new { message = ex.Message });
        }
    }

    /// <summary>
    /// Deletes a video from an order.
    /// </summary>
    [HttpDelete("{orderId:long}/videos/{videoId:long}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> DeleteOrderVideo(
        [FromRoute] long orderId,
        [FromRoute] long videoId,
        CancellationToken cancellationToken)
    {
        var userId = GetUserId();
        if (userId is null)
        {
            return Unauthorized(new { message = "Invalid token." });
        }

        try
        {
            await ordersAppService.DeleteOrderVideoAsync(userId, orderId, videoId, cancellationToken);
            return NoContent();
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
            return StatusCode(StatusCodes.Status403Forbidden, new { message = ex.Message });
        }
    }

    private static CreateDirectOrderInput MapBookingOrder(CreateOrderRequest request, string authenticatedUserId)
    {
        if (!request.Quantity.HasValue || request.Quantity.Value <= 0)
        {
            throw new ArgumentException("Quantity is required and must be greater than zero.");
        }

        if (!request.UnitPrice.HasValue || request.UnitPrice.Value <= 0)
        {
            throw new ArgumentException("UnitPrice is required and must be greater than zero.");
        }

        if (!request.TotalPrice.HasValue || request.TotalPrice.Value <= 0)
        {
            throw new ArgumentException("TotalPrice is required and must be greater than zero.");
        }

        if (string.IsNullOrWhiteSpace(request.ProductId))
        {
            throw new ArgumentException("ProductId is required.");
        }

        if (string.IsNullOrWhiteSpace(request.ToUserId))
        {
            throw new ArgumentException("ToUserId is required.");
        }

        return new CreateDirectOrderInput
        {
            AuthenticatedUserId = authenticatedUserId,
            ToUserId = request.ToUserId.Trim(),
            ProductId = request.ProductId.Trim(),
            SupplierEmail = request.SupplierEmail,
            UnitName = request.UnitName?.Trim() ?? string.Empty,
            Quantity = request.Quantity.Value,
            UnitPrice = request.UnitPrice.Value,
            TotalPrice = request.TotalPrice.Value,
            PaymentMethodName = request.PaymentMethodName ?? "CashOnDelivery",
            Notes = request.Notes,
            ImagePaths = request.ImagePaths,
            VideoPaths = request.VideoPaths,
            DocumentPaths = request.DocumentPaths,
            PortName = request.PortName?.Trim()
        };
    }

    private string? GetUserId() =>
        User.FindFirst("EntityId")?.Value ?? User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

    /// <summary>
    /// Uploads an image for a request offer without attaching it to the request product.
    /// </summary>
    [HttpPost("offer-staging/images/upload")]
    [Consumes("multipart/form-data")]
    [RequestSizeLimit(10 * 1024 * 1024)]
    public async Task<IActionResult> UploadOfferStagingImage(
        [FromForm] UploadProductAssetRequest request,
        CancellationToken cancellationToken)
    {
        if (GetUserId() is null)
        {
            return Unauthorized(new { message = "Invalid token." });
        }

        try
        {
            var root = environment.WebRootPath ?? Path.Combine(Directory.GetCurrentDirectory(), "wwwroot");
            var result = await productAssetsAppService.UploadOfferStagingImageAsync(
                new UploadStagingAssetInput
                {
                    File = request.File,
                    WebRootPath = root,
                },
                cancellationToken);
            return Ok(result);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    /// <summary>
    /// Uploads a document for a request offer without attaching it to the request product.
    /// </summary>
    [HttpPost("offer-staging/documents/upload")]
    [Consumes("multipart/form-data")]
    [RequestSizeLimit(20 * 1024 * 1024)]
    public async Task<IActionResult> UploadOfferStagingDocument(
        [FromForm] UploadProductAssetRequest request,
        CancellationToken cancellationToken)
    {
        if (GetUserId() is null)
        {
            return Unauthorized(new { message = "Invalid token." });
        }

        try
        {
            var root = environment.WebRootPath ?? Path.Combine(Directory.GetCurrentDirectory(), "wwwroot");
            var result = await productAssetsAppService.UploadOfferStagingDocumentAsync(
                new UploadStagingAssetInput
                {
                    File = request.File,
                    WebRootPath = root,
                },
                cancellationToken);
            return Ok(result);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    /// <summary>
    /// Uploads a video for a request offer without attaching it to the request product.
    /// </summary>
    [HttpPost("offer-staging/videos/upload")]
    [Consumes("multipart/form-data")]
    [RequestSizeLimit(50 * 1024 * 1024)]
    public async Task<IActionResult> UploadOfferStagingVideo(
        [FromForm] UploadProductAssetRequest request,
        CancellationToken cancellationToken)
    {
        if (GetUserId() is null)
        {
            return Unauthorized(new { message = "Invalid token." });
        }

        try
        {
            var root = environment.WebRootPath ?? Path.Combine(Directory.GetCurrentDirectory(), "wwwroot");
            var result = await productAssetsAppService.UploadOfferStagingVideoAsync(
                new UploadStagingAssetInput
                {
                    File = request.File,
                    WebRootPath = root,
                },
                cancellationToken);
            return Ok(result);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }
}

/// <summary>
/// Direct order request (Retail, Booking, Offers, Requests). FromUserId is set from the JWT token.
/// ToUserId must match the product owner. Omit productId for cart checkout.
/// </summary>
public sealed class CreateOrderRequest
{
    public string ToUserId { get; set; } = string.Empty;
    public string ProductId { get; set; } = string.Empty;
    public string? SupplierEmail { get; set; }
    public string UnitName { get; set; } = string.Empty;
    public decimal? Quantity { get; set; }
    public decimal? UnitPrice { get; set; }
    public decimal? TotalPrice { get; set; }
    public string? PaymentMethodName { get; set; }
    public string? Notes { get; set; }
    public List<string>? ImagePaths { get; set; }
    public List<string>? VideoPaths { get; set; }
    public List<string>? DocumentPaths { get; set; }
    /// <summary>Required for Booking — any valid port name. Resolved to PortId server-side.</summary>
    public string? PortName { get; set; }

    /// <summary>Cart checkout — omit productId and send these instead.</summary>
    public Guid? AddressId { get; set; }
    public string? AddressLine { get; set; }
    public string? CityName { get; set; }
    public decimal? ShippingCostAed { get; set; }
    public bool? IsSelfPickup { get; set; }
}



public sealed class UpdateOrderStatusRequest
{
    public byte StatusId { get; set; }
}
