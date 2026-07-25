using BusinessLayer.Interfaces;
using BusinessLayer.Dtos;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace RasAlSouqPresentaionLayer.Controllers;

/// <summary>
/// Notification endpoints for sending and storing push notifications.
/// </summary>
[Route("api/[controller]")]
[ApiController]
[Authorize]
public class NotificationsController(
    INotificationsAppService notificationsAppService) : ControllerBase
{
    private readonly INotificationsAppService _notificationsAppService = notificationsAppService;

    /// <summary>
    /// Returns notifications for the authenticated user.
    /// </summary>
    [HttpGet("mine")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> GetMine(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 50,
        CancellationToken cancellationToken = default)
    {
        var userId = User.FindFirst("EntityId")?.Value ?? User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrWhiteSpace(userId))
        {
            return Unauthorized(new { message = "Invalid token." });
        }

        try
        {
            var result = await _notificationsAppService.GetMineAsync(userId, page, pageSize, cancellationToken);
            return Ok(result);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpGet("unread-count")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> GetUnreadCount(CancellationToken cancellationToken = default)
    {
        var userId = User.FindFirst("EntityId")?.Value ?? User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrWhiteSpace(userId))
        {
            return Unauthorized(new { message = "Invalid token." });
        }

        try
        {
            var result = await _notificationsAppService.GetUnreadCountAsync(userId, cancellationToken);
            return Ok(result);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPost("{notificationId}/read")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> MarkRead(
        [FromRoute] string notificationId,
        CancellationToken cancellationToken = default)
    {
        var userId = User.FindFirst("EntityId")?.Value ?? User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrWhiteSpace(userId))
        {
            return Unauthorized(new { message = "Invalid token." });
        }

        try
        {
            var result = await _notificationsAppService.MarkReadAsync(userId, notificationId, cancellationToken);
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

    [HttpPost("read-all")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> MarkAllRead(CancellationToken cancellationToken = default)
    {
        var userId = User.FindFirst("EntityId")?.Value ?? User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrWhiteSpace(userId))
        {
            return Unauthorized(new { message = "Invalid token." });
        }

        try
        {
            var result = await _notificationsAppService.MarkAllReadAsync(userId, cancellationToken);
            return Ok(result);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    /// <summary>
    /// Sends an FCM notification and stores it in database.
    /// </summary>
    [HttpPost("send")]
    public async Task<IActionResult> Send([FromBody] SendNotificationRequest request, CancellationToken cancellationToken)
    {
        try
        {
            var message = await _notificationsAppService.SendAsync(new SendNotificationInput
            {
                Title = request.Title,
                Body = request.Body,
                TitleAr = request.TitleAr,
                BodyAr = request.BodyAr,
                FromUserId = request.FromUserId,
                ToUserId = request.ToUserId,
                TypeId = request.TypeId,
                Type = request.Type,
                RouteId = request.RouteId,
                ReferenceId = request.ReferenceId
            }, cancellationToken);
            return Ok(new { message });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }
}

/// <summary>
/// Request payload for sending a push notification.
/// </summary>
public sealed class SendNotificationRequest
{
    public string Title { get; set; } = string.Empty;
    public string Body { get; set; } = string.Empty;
    public string? TitleAr { get; set; }
    public string? BodyAr { get; set; }
    public string FromUserId { get; set; } = string.Empty;
    public string ToUserId { get; set; } = string.Empty;
    public byte TypeId { get; set; }
    public string Type { get; set; } = "notification";
    public string RouteId { get; set; } = string.Empty;
    public string ReferenceId { get; set; } = string.Empty;
}
