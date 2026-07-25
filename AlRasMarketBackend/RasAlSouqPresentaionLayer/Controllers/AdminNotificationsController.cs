using System.Security.Claims;
using BusinessLayer.Constants;
using BusinessLayer.Dtos;
using BusinessLayer.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using RasAlSouqPresentaionLayer.Authorization;

namespace RasAlSouqPresentaionLayer.Controllers;

[Route("api/admin/notifications")]
[ApiController]
[Authorize(Roles = "Admin,Employee")]
[RequireAdminPermission(AdminPermissions.NotificationsView)]
public class AdminNotificationsController(
    IAdminNotificationsAppService adminNotificationsAppService,
    IAdminRealtimeNotificationService adminRealtimeNotificationService) : ControllerBase
{
    [HttpGet("live-counts")]
    public async Task<IActionResult> GetLiveCounts(CancellationToken cancellationToken = default)
    {
        var counts = await adminRealtimeNotificationService.GetLiveCountsAsync(cancellationToken);
        return Ok(counts);
    }

    [HttpGet]
    public async Task<IActionResult> GetHistory(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20,
        [FromQuery] string? audience = null,
        CancellationToken cancellationToken = default)
    {
        var result = await adminNotificationsAppService.GetBroadcastHistoryAsync(
            page,
            pageSize,
            audience,
            cancellationToken);
        return Ok(result);
    }

    [HttpPost("send")]
    public async Task<IActionResult> Send(
        [FromBody] AdminSendPushNotificationRequest request,
        CancellationToken cancellationToken = default)
    {
        try
        {
            Guid? adminUserId = null;
            var adminIdClaim = User.FindFirstValue(ClaimTypes.NameIdentifier)
                ?? User.FindFirstValue("sub");
            if (Guid.TryParse(adminIdClaim, out var parsedAdminId))
            {
                adminUserId = parsedAdminId;
            }

            var result = await adminNotificationsAppService.QueueBroadcastAsync(
                request,
                adminUserId,
                cancellationToken);
            return Ok(result);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }
}
