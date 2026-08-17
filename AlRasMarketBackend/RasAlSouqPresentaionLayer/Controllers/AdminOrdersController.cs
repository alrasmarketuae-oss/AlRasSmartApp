using System.Security.Claims;
using BusinessLayer.Constants;
using BusinessLayer.Dtos;
using BusinessLayer.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.ModelBinding;
using RasAlSouqPresentaionLayer.Authorization;

namespace RasAlSouqPresentaionLayer.Controllers;

[Route("api/admin/orders")]
[ApiController]
[Authorize(Roles = "Admin,Employee")]
[RequireAdminPermission(AdminPermissions.OrdersView)]
public class AdminOrdersController(
    IAdminOrdersAppService adminOrdersAppService,
    IOrdersAppService ordersAppService,
    IWebHostEnvironment environment) : ControllerBase
{
    [HttpGet("stats")]
    public async Task<IActionResult> GetOrderStats(CancellationToken cancellationToken = default)
    {
        var result = await adminOrdersAppService.GetOrderStatsAsync(cancellationToken);
        return Ok(result);
    }

    [HttpGet("cancellation-reasons")]
    public async Task<IActionResult> GetCancellationReasons(CancellationToken cancellationToken = default)
    {
        var result = await ordersAppService.GetCancellationReasonsAsync(cancellationToken);
        return Ok(result);
    }

    [HttpGet("{orderId:long}")]
    public async Task<IActionResult> GetOrderById(
        [FromRoute] long orderId,
        CancellationToken cancellationToken = default)
    {
        try
        {
            var result = await adminOrdersAppService.GetOrderByIdAsync(orderId, cancellationToken);
            return Ok(result);
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
    }

    [HttpGet]
    public async Task<IActionResult> GetOrders(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20,
        [FromQuery] byte? statusId = null,
        [FromQuery] byte? productTypeId = null,
        [FromQuery] byte? excludeProductTypeId = null,
        [FromQuery] string? productId = null,
        [FromQuery] string? search = null,
        [FromQuery] DateTime? createdFrom = null,
        [FromQuery] DateTime? createdTo = null,
        [FromQuery] string? offerReview = null,
        [FromQuery] string? orderChannel = null,
        CancellationToken cancellationToken = default)
    {
        var result = await adminOrdersAppService.GetOrdersAsync(
            page,
            pageSize,
            statusId,
            productTypeId,
            excludeProductTypeId,
            productId,
            search,
            createdFrom,
            createdTo,
            offerReview,
            orderChannel,
            cancellationToken);
        return Ok(result);
    }

    [HttpPatch("{orderId:long}/status")]
    public async Task<IActionResult> UpdateOrderStatus(
        [FromRoute] long orderId,
        [FromBody] UpdateOrderStatusRequest request,
        CancellationToken cancellationToken = default)
    {
        var userId = GetUserId();
        if (userId is null)
        {
            return Unauthorized(new { message = "Invalid token." });
        }

        try
        {
            var result = await adminOrdersAppService.UpdateOrderStatusAsync(
                userId,
                orderId,
                request.StatusId,
                request.CancellationReasonId,
                request.CancellationNote,
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

    /// <summary>Admin approves a supplier offer on a request before the owner is notified.</summary>
    [HttpPost("{orderId:long}/request-offer/approve")]
    [RequireAdminPermission(AdminPermissions.OrdersManage)]
    public async Task<IActionResult> ApproveRequestOffer(
        [FromRoute] long orderId,
        [FromBody(EmptyBodyBehavior = EmptyBodyBehavior.Allow)] ApproveRequestOfferRequest? body = null,
        CancellationToken cancellationToken = default)
    {
        var userId = GetUserId();
        if (userId is null)
        {
            return Unauthorized(new { message = "Invalid token." });
        }

        try
        {
            var result = await adminOrdersAppService.ApproveRequestOfferAsync(
                userId,
                orderId,
                body?.AdminUnitPrice,
                body?.AdminTotalPrice,
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
    }

    /// <summary>
    /// Sets the unit price shown to the request-ad owner without changing the supplier's offer.
    /// </summary>
    [HttpPatch("{orderId:long}/request-offer/advertiser-price")]
    [RequireAdminPermission(AdminPermissions.OrdersManage)]
    public async Task<IActionResult> SetRequestOfferAdvertiserPrice(
        [FromRoute] long orderId,
        [FromBody] ApproveRequestOfferRequest body,
        CancellationToken cancellationToken = default)
    {
        var userId = GetUserId();
        if (userId is null)
        {
            return Unauthorized(new { message = "Invalid token." });
        }

        if (body?.AdminUnitPrice is not > 0)
        {
            return BadRequest(new { message = "AdminUnitPrice is required." });
        }

        try
        {
            var result = await adminOrdersAppService.SetRequestOfferAdvertiserPriceAsync(
                userId,
                orderId,
                body.AdminUnitPrice.Value,
                body.AdminTotalPrice,
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
    }

    /// <summary>Admin rejects a supplier offer on a request before the owner sees it.</summary>
    [HttpPost("{orderId:long}/request-offer/reject")]
    [RequireAdminPermission(AdminPermissions.OrdersManage)]
    public async Task<IActionResult> RejectRequestOffer(
        [FromRoute] long orderId,
        CancellationToken cancellationToken = default)
    {
        var userId = GetUserId();
        if (userId is null)
        {
            return Unauthorized(new { message = "Invalid token." });
        }

        try
        {
            var result = await adminOrdersAppService.RejectRequestOfferAsync(
                userId,
                orderId,
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
    }

    /// <summary>
    /// Admin sets a free-text bilingual status on an accepted request offer.
    /// Notifies offeror and advertiser using each user's preferred language.
    /// </summary>
    [HttpPatch("{orderId:long}/custom-status")]
    [RequireAdminPermission(AdminPermissions.OrdersManage)]
    public async Task<IActionResult> SetCustomOrderStatus(
        [FromRoute] long orderId,
        [FromBody] SetCustomOrderStatusRequest request,
        CancellationToken cancellationToken = default)
    {
        var userId = GetUserId();
        if (userId is null)
        {
            return Unauthorized(new { message = "Invalid token." });
        }

        try
        {
            var result = await adminOrdersAppService.SetCustomOrderStatusAsync(
                userId,
                orderId,
                request.StatusNameEn,
                request.StatusNameAr,
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
    }

    /// <summary>Final step: mark order as Received (تم الاستلام) so retail returns can start.</summary>
    [HttpPost("{orderId:long}/mark-received")]
    [RequireAdminPermission(AdminPermissions.OrdersManage)]
    public async Task<IActionResult> MarkOrderReceived(
        [FromRoute] long orderId,
        CancellationToken cancellationToken = default)
    {
        var userId = GetUserId();
        if (userId is null)
        {
            return Unauthorized(new { message = "Invalid token." });
        }

        try
        {
            var result = await adminOrdersAppService.MarkOrderReceivedAsync(
                userId,
                orderId,
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
    }

    /// <summary>Admin reply to a retail return request (email + push + notification history).</summary>
    [HttpPost("{orderId:long}/return/respond")]
    [RequireAdminPermission(AdminPermissions.OrdersManage)]
    public async Task<IActionResult> RespondToReturn(
        [FromRoute] long orderId,
        [FromBody] RespondToOrderReturnRequest request,
        CancellationToken cancellationToken = default)
    {
        var userId = GetUserId();
        if (userId is null)
        {
            return Unauthorized(new { message = "Invalid token." });
        }

        try
        {
            var result = await adminOrdersAppService.RespondToReturnAsync(
                userId,
                orderId,
                request.Response ?? string.Empty,
                request.Approved,
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

    [HttpPost("{orderId:long}/images/upload")]
    [Consumes("multipart/form-data")]
    [RequestSizeLimit(10 * 1024 * 1024)]
    public async Task<IActionResult> UploadOrderImage(
        [FromRoute] long orderId,
        [FromForm] UploadOrderImageRequest request,
        CancellationToken cancellationToken = default)
    {
        var userId = GetUserId();
        if (userId is null)
        {
            return Unauthorized(new { message = "Invalid token." });
        }

        try
        {
            var root = environment.WebRootPath ?? Path.Combine(Directory.GetCurrentDirectory(), "wwwroot");
            var result = await ordersAppService.UploadOrderImageAsync(new UploadOrderImageInput
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

    [HttpDelete("{orderId:long}/images/{imageId:long}")]
    public async Task<IActionResult> DeleteOrderImage(
        [FromRoute] long orderId,
        [FromRoute] long imageId,
        CancellationToken cancellationToken = default)
    {
        var userId = GetUserId();
        if (userId is null)
        {
            return Unauthorized(new { message = "Invalid token." });
        }

        try
        {
            await ordersAppService.DeleteOrderImageAsync(userId, orderId, imageId, cancellationToken);
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

    [HttpPost("{orderId:long}/videos/upload")]
    [Consumes("multipart/form-data")]
    [RequestSizeLimit(50 * 1024 * 1024)]
    public async Task<IActionResult> UploadOrderVideo(
        [FromRoute] long orderId,
        [FromForm] UploadOrderVideoRequest request,
        CancellationToken cancellationToken = default)
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

    [HttpDelete("{orderId:long}/videos/{videoId:long}")]
    public async Task<IActionResult> DeleteOrderVideo(
        [FromRoute] long orderId,
        [FromRoute] long videoId,
        CancellationToken cancellationToken = default)
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

    private string? GetUserId() =>
        User.FindFirst("EntityId")?.Value ?? User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
}

public sealed class UploadOrderImageRequest
{
    public IFormFile? File { get; set; }
}

public sealed class UploadOrderVideoRequest
{
    public IFormFile? File { get; set; }
}

public sealed class RespondToOrderReturnRequest
{
    public string Response { get; set; } = string.Empty;
    /// <summary>Default true: approve return (refund online). False rejects and restores Delivered.</summary>
    public bool Approved { get; set; } = true;
}

public sealed class SetCustomOrderStatusRequest
{
    public string StatusNameEn { get; set; } = string.Empty;
    public string StatusNameAr { get; set; } = string.Empty;
}
