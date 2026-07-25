using System.Security.Claims;
using BusinessLayer.Helpers;
using BusinessLayer.Interfaces;
using BusinessLayer.Options;
using DataLayer.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using RasAlSouqPresentaionLayer.Hubs;

namespace RasAlSouqPresentaionLayer.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class ChatController(
    IChatAppService chatAppService,
    IFcmNotificationService fcmService,
    IRasAlSouqDbContext dbContext,
    IHubContext<ChatHub> chatHub,
    IAdminRealtimeNotificationService adminRealtimeNotificationService,
    IMediaStorageService mediaStorage,
    IMediaUrlResolver mediaUrlResolver,
    IOptions<CloudflareR2Options> r2Options,
    IWebHostEnvironment environment) : ControllerBase
{
    /// <summary>قائمة المحادثات للمستخدم الحالي (مع كاش سيرفر).</summary>
    [HttpGet("my")]
    public async Task<ActionResult<ChatInboxDto>> GetMyInbox(CancellationToken ct)
    {
        var userId = GetCurrentUserId();
        if (userId is null)
        {
            return Unauthorized();
        }

        var inbox = await chatAppService.GetMyInboxAsync(userId, ct);
        return Ok(inbox);
    }

    /// <summary>alias لـ my — نفس قائمة الكونتاكت.</summary>
    [HttpGet("contacts")]
    public Task<ActionResult<ChatInboxDto>> GetContacts(CancellationToken ct) => GetMyInbox(ct);

    [HttpGet("unread-count")]
    public async Task<ActionResult<ChatUnreadSummaryDto>> GetUnreadCount(CancellationToken ct)
    {
        var userId = GetCurrentUserId();
        if (userId is null)
        {
            return Unauthorized();
        }

        var summary = await chatAppService.GetUnreadCountAsync(userId, ct);
        return Ok(summary);
    }

    [HttpGet("search")]
    public async Task<ActionResult<IReadOnlyList<ChatContactDto>>> SearchConversations(
        [FromQuery] string q,
        CancellationToken ct)
    {
        var userId = GetCurrentUserId();
        if (userId is null)
        {
            return Unauthorized();
        }

        if (string.IsNullOrWhiteSpace(q))
        {
            return Ok(Array.Empty<ChatContactDto>());
        }

        var results = await chatAppService.SearchConversationsAsync(userId, q, ct);
        return Ok(results);
    }

    [HttpGet("messages")]
    public async Task<ActionResult<IReadOnlyList<ChatMessageDto>>> GetConversation(
        [FromQuery] string otherUserId,
        CancellationToken ct)
    {
        var userId = GetCurrentUserId();
        if (userId is null)
        {
            return Unauthorized();
        }

        if (string.IsNullOrWhiteSpace(otherUserId))
        {
            return BadRequest(new { message = "otherUserId is required." });
        }

        try
        {
            var messages = await chatAppService.GetConversationAsync(userId, otherUserId, ct);
            return Ok(messages);
        }
        catch (InvalidOperationException ex)
        {
            return StatusCode(StatusCodes.Status409Conflict, new { message = ex.Message });
        }
    }

    [HttpGet("conversation")]
    public async Task<ActionResult<ChatConversationDetailsDto>> GetConversationDetails(
        [FromQuery] string otherUserId,
        CancellationToken ct)
    {
        var userId = GetCurrentUserId();
        if (userId is null)
        {
            return Unauthorized();
        }

        if (string.IsNullOrWhiteSpace(otherUserId))
        {
            return BadRequest(new { message = "otherUserId is required." });
        }

        try
        {
            var details = await chatAppService.GetConversationDetailsAsync(userId, otherUserId, ct);
            return Ok(details);
        }
        catch (InvalidOperationException ex)
        {
            return StatusCode(StatusCodes.Status409Conflict, new { message = ex.Message });
        }
    }

    [HttpPost("support/claim")]
    public async Task<ActionResult<ChatSupportAssignmentDto>> ClaimSupportConversation(
        [FromBody] MarkConversationSeenRequest request,
        CancellationToken ct)
    {
        var userId = GetCurrentUserId();
        if (userId is null)
        {
            return Unauthorized();
        }

        try
        {
            var assignment = await chatAppService.ClaimSupportConversationAsync(userId, request.OtherUserId, ct);
            if (assignment.IsLockedByOtherAgent)
            {
                return StatusCode(StatusCodes.Status409Conflict, assignment);
            }

            // Always notify the customer when an agent opens/claims the chat so the
            // app title switches from "Live Chat" to the agent name immediately.
            if (!string.IsNullOrWhiteSpace(assignment.AssignedAgentId))
            {
                await NotifySupportSessionAsync(
                    "supportSessionStarted",
                    request.OtherUserId,
                    assignment,
                    isActive: true,
                    ct);
            }

            return Ok(assignment);
        }
        catch (UnauthorizedAccessException ex)
        {
            return Forbid(ex.Message);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPost("support/release")]
    public async Task<IActionResult> ReleaseSupportConversation(
        [FromBody] MarkConversationSeenRequest request,
        CancellationToken ct)
    {
        var userId = GetCurrentUserId();
        if (userId is null)
        {
            return Unauthorized();
        }

        var released = await chatAppService.ReleaseSupportConversationAsync(
            userId,
            request.OtherUserId,
            ct);

        if (released is not null && !string.IsNullOrWhiteSpace(released.AssignedAgentId))
        {
            await NotifySupportSessionAsync(
                "supportSessionEnded",
                request.OtherUserId,
                released,
                isActive: false,
                ct);
        }

        return Ok(new { message = "Released." });
    }

    [HttpGet("support/assignment")]
    public async Task<ActionResult<ChatSupportAssignmentDto>> GetSupportAssignment(
        [FromQuery] string customerUserId,
        CancellationToken ct)
    {
        var userId = GetCurrentUserId();
        if (userId is null)
        {
            return Unauthorized();
        }

        var assignment = await chatAppService.GetSupportAssignmentAsync(userId, customerUserId, ct);
        return Ok(assignment);
    }

    [HttpGet("keys/{targetUserId}")]
    public async Task<IActionResult> GetPublicKey(string targetUserId, CancellationToken ct)
    {
        var userId = GetCurrentUserId();
        if (userId is null)
        {
            return Unauthorized();
        }

        try
        {
            var key = await chatAppService.GetPublicKeyAsync(targetUserId, ct);
            if (key is null)
            {
                return NotFound(new { message = "Public key not found." });
            }

            return Ok(key);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPut("keys/me")]
    public async Task<IActionResult> UpsertMyPublicKey(
        [FromBody] UpsertChatPublicKeyRequest request,
        CancellationToken ct)
    {
        var userId = GetCurrentUserId();
        if (userId is null)
        {
            return Unauthorized();
        }

        try
        {
            var key = await chatAppService.UpsertMyPublicKeyAsync(userId, request, ct);
            return Ok(key);
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

    [HttpGet("keys/me/private")]
    public async Task<IActionResult> GetMyPrivateKey(CancellationToken ct)
    {
        var userId = GetCurrentUserId();
        if (userId is null)
        {
            return Unauthorized();
        }

        try
        {
            var key = await chatAppService.GetMyPrivateKeyAsync(userId, ct);
            if (key is null)
            {
                return NotFound(new { message = "Private key not provisioned yet." });
            }

            return Ok(key);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPut("keys/support")]
    public async Task<IActionResult> UpsertSupportKeys(
        [FromBody] UpsertSupportChatKeysRequest request,
        CancellationToken ct)
    {
        var userId = GetCurrentUserId();
        if (userId is null)
        {
            return Unauthorized();
        }

        try
        {
            var key = await chatAppService.UpsertSupportKeysAsync(userId, request, ct);
            return Ok(key);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (UnauthorizedAccessException ex)
        {
            return Forbid(ex.Message);
        }
    }

    [HttpGet("keys/support/private")]
    public async Task<IActionResult> GetSupportPrivateKey(CancellationToken ct)
    {
        var userId = GetCurrentUserId();
        if (userId is null)
        {
            return Unauthorized();
        }

        try
        {
            var key = await chatAppService.GetSupportPrivateKeyAsync(userId, ct);
            if (key is null)
            {
                return NotFound(new { message = "Support private key not provisioned yet." });
            }

            return Ok(key);
        }
        catch (UnauthorizedAccessException ex)
        {
            return Forbid(ex.Message);
        }
    }

    [HttpPost("messages")]
    public async Task<ActionResult<ChatMessageDto>> CreateMessage(
        [FromBody] CreateChatMessageRequest request,
        CancellationToken ct)
    {
        var userId = GetCurrentUserId();
        if (userId is null)
        {
            return Unauthorized();
        }

        try
        {
            var result = await chatAppService.CreateMessageAsync(userId, request, ct);
            result = await PushRealtimeMessageAsync(result, ct);
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
            return StatusCode(StatusCodes.Status409Conflict, new { message = ex.Message });
        }
    }

    [HttpPut("messages/{messageId}")]
    public async Task<ActionResult<ChatMessageDto>> UpdateMessage(
        [FromRoute] string messageId,
        [FromBody] UpdateChatMessageRequest request,
        CancellationToken ct)
    {
        var userId = GetCurrentUserId();
        if (userId is null)
        {
            return Unauthorized();
        }

        try
        {
            var result = await chatAppService.UpdateMessageAsync(userId, messageId, request, ct);
            await PushMessageUpdatedAsync(result, ct);
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
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPost("seen")]
    public async Task<IActionResult> MarkConversationSeen(
        [FromBody] MarkConversationSeenRequest request,
        CancellationToken ct)
    {
        var userId = GetCurrentUserId();
        if (userId is null)
        {
            return Unauthorized();
        }

        var count = await chatAppService.MarkConversationSeenAsync(userId, request.OtherUserId, ct);

        var payload = new
        {
            viewerUserId = userId,
            otherUserId = request.OtherUserId,
            seenAtUtc = DateTime.UtcNow.ToString("o"),
            markedCount = count
        };

        try
        {
            await chatHub.Clients
                .Group(ChatHub.GetGroupName(request.OtherUserId))
                .SendAsync("conversationSeen", payload, ct);
        }
        catch
        {
            // ignore realtime failures
        }

        return Ok(payload);
    }

    [HttpPost("delivered")]
    public async Task<IActionResult> MarkConversationDelivered(
        [FromBody] MarkConversationDeliveredRequest request,
        CancellationToken ct)
    {
        var userId = GetCurrentUserId();
        if (userId is null)
        {
            return Unauthorized();
        }

        var result = await chatAppService.MarkConversationDeliveredAsync(userId, request.OtherUserId, ct);

        if (result.MarkedCount > 0)
        {
            await NotifyMessagesDeliveredAsync(result, ct);
        }

        return Ok(result);
    }

    [HttpPost("presence")]
    public async Task<ActionResult<ChatPresenceDto>> UpdatePresence(CancellationToken ct)
    {
        var userId = GetCurrentUserId();
        if (userId is null)
        {
            return Unauthorized();
        }

        var presence = await chatAppService.UpdatePresenceAsync(userId, ct);

        try
        {
            await chatHub.Clients
                .Group(ChatHub.GetGroupName(userId))
                .SendAsync("userLastSeen", presence, ct);
        }
        catch
        {
            // ignore realtime failures
        }

        return Ok(presence);
    }

    /// <summary>
    /// بث ملف صوتي — المسار يحتوي الامتداد (.m4a) ليتوافق مع Safari/iOS.
    /// </summary>
    [HttpGet("voice/{*storagePath}")]
    [AllowAnonymous]
    public Task<IActionResult> StreamVoiceByPath(string storagePath, CancellationToken ct) =>
        StreamVoiceInternalAsync(storagePath, ct);

    [HttpGet("voice")]
    [AllowAnonymous]
    public Task<IActionResult> StreamVoice([FromQuery] string path, CancellationToken ct) =>
        StreamVoiceInternalAsync(path, ct);

    private async Task<IActionResult> StreamVoiceInternalAsync(string? path, CancellationToken ct)
    {
        if (string.IsNullOrWhiteSpace(path))
        {
            return BadRequest(new { message = "path is required." });
        }

        var normalized = WebRootFileHelper.NormalizeStoredPath(path);
        if (!normalized.StartsWith("/chat-voice/", StringComparison.OrdinalIgnoreCase)
            || normalized.Contains("..", StringComparison.Ordinal))
        {
            return BadRequest(new { message = "Invalid voice path." });
        }

        if (TryRedirectToCdn(normalized, out var redirect))
        {
            return redirect!;
        }

        var stream = await mediaStorage.OpenReadAsync(normalized, ct);
        if (stream is null)
        {
            return NotFound();
        }

        var contentType = VoiceFileHelper.GetContentType(normalized);
        var fileName = Path.GetFileName(normalized);
        Response.Headers.ContentDisposition = $"inline; filename=\"{fileName}\"";
        return File(stream, contentType, enableRangeProcessing: true);
    }

    [HttpGet("video/{*storagePath}")]
    [AllowAnonymous]
    public Task<IActionResult> StreamVideoByPath(string storagePath, CancellationToken ct) =>
        StreamVideoInternalAsync(storagePath, ct);

    [HttpGet("video")]
    [AllowAnonymous]
    public Task<IActionResult> StreamVideo([FromQuery] string path, CancellationToken ct) =>
        StreamVideoInternalAsync(path, ct);

    private async Task<IActionResult> StreamVideoInternalAsync(string? path, CancellationToken ct)
    {
        if (string.IsNullOrWhiteSpace(path))
        {
            return BadRequest(new { message = "path is required." });
        }

        var normalized = WebRootFileHelper.NormalizeStoredPath(path);
        if (!normalized.StartsWith("/chat-videos/", StringComparison.OrdinalIgnoreCase)
            || normalized.Contains("..", StringComparison.Ordinal))
        {
            return BadRequest(new { message = "Invalid video path." });
        }

        if (TryRedirectToCdn(normalized, out var redirect))
        {
            return redirect!;
        }

        var stream = await mediaStorage.OpenReadAsync(normalized, ct);
        if (stream is null)
        {
            return NotFound();
        }

        var extension = Path.GetExtension(normalized).ToLowerInvariant();
        var contentType = extension switch
        {
            ".mov" => "video/quicktime",
            ".webm" => "video/webm",
            ".m4v" => "video/x-m4v",
            _ => "video/mp4"
        };
        var fileName = Path.GetFileName(normalized);
        Response.Headers.ContentDisposition = $"inline; filename=\"{fileName}\"";
        return File(stream, contentType, enableRangeProcessing: true);
    }

    private bool TryRedirectToCdn(string normalizedPath, out IActionResult? result)
    {
        result = null;
        var options = r2Options.Value;
        if (!options.IsConfigured || string.IsNullOrWhiteSpace(options.PublicBaseUrl))
        {
            return false;
        }

        var publicUrl = mediaUrlResolver.ToPublicUrl(normalizedPath);
        if (string.IsNullOrWhiteSpace(publicUrl)
            || !publicUrl.StartsWith("http", StringComparison.OrdinalIgnoreCase))
        {
            return false;
        }

        result = Redirect(publicUrl);
        return true;
    }

    [HttpPost("upload")]
    [RequestSizeLimit(30 * 1024 * 1024)]
    public async Task<ActionResult<ChatUploadResultDto>> UploadMedia(
        [FromForm] ChatUploadRequest request,
        CancellationToken ct)
    {
        var userId = GetCurrentUserId();
        if (userId is null)
        {
            return Unauthorized();
        }

        if (request.File is null)
        {
            return BadRequest(new { message = "File is required." });
        }

        try
        {
            var webRoot = environment.WebRootPath
                ?? Path.Combine(environment.ContentRootPath, "wwwroot");
            var result = await chatAppService.UploadMediaAsync(
                userId,
                request.MessageType,
                request.File,
                webRoot,
                ct);
            return Ok(result);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPost("upload-images")]
    [RequestSizeLimit(50 * 1024 * 1024)]
    public async Task<ActionResult<ChatUploadImagesResultDto>> UploadImages(
        [FromForm] ChatUploadImagesRequest request,
        CancellationToken ct)
    {
        var userId = GetCurrentUserId();
        if (userId is null)
        {
            return Unauthorized();
        }

        var files = request.Files?.Where(f => f is not null && f.Length > 0).ToList() ?? [];
        if (files.Count == 0)
        {
            return BadRequest(new { message = "At least one image file is required." });
        }

        try
        {
            var webRoot = environment.WebRootPath
                ?? Path.Combine(environment.ContentRootPath, "wwwroot");
            var result = await chatAppService.UploadImagesAsync(userId, files, webRoot, ct);
            return Ok(result);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    private const byte AdminRoleId = 1;

    private async Task<ChatMessageDto> PushRealtimeMessageAsync(ChatMessageDto result, CancellationToken ct)
    {
        try
        {
            await chatHub.Clients
                .Group(ChatHub.GetGroupName(result.ToUserId))
                .SendAsync("receiveMessage", result, ct);
        }
        catch
        {
            // ignore realtime failures
        }

        try
        {
            await SendChatPushIfNeededAsync(result, ct);
        }
        catch
        {
            // ignore push failures
        }

        try
        {
            await adminRealtimeNotificationService.NotifyAdminChatMessageAsync(
                result.ToUserId,
                result.FromUserId,
                ct);
        }
        catch
        {
            // ignore admin alert failures
        }

        return result;
    }

    private async Task NotifyMessagesDeliveredAsync(ChatMessagesDeliveredDto deliveryEvent, CancellationToken ct)
    {
        try
        {
            await chatHub.Clients
                .Group(ChatHub.GetGroupName(deliveryEvent.FromUserId))
                .SendAsync("messagesDelivered", deliveryEvent, ct);
        }
        catch
        {
            // ignore realtime failures
        }
    }

    private async Task SendChatPushIfNeededAsync(ChatMessageDto result, CancellationToken ct)
    {
        if (!Guid.TryParse(result.ToUserId, out var recipientId) ||
            !Guid.TryParse(result.FromUserId, out var senderId))
        {
            return;
        }

        var userIds = new[] { recipientId, senderId };
        var users = await dbContext.Users
            .AsNoTracking()
            .Where(u => userIds.Contains(u.Id))
            .Select(u => new ChatPushUserInfo(
                u.Id,
                u.RoleId,
                u.FcmToken,
                u.FullName,
                u.CompanyName,
                u.PreferredLanguage))
            .ToListAsync(ct);

        var recipient = users.FirstOrDefault(u => u.Id == recipientId);
        var sender = users.FirstOrDefault(u => u.Id == senderId);

        if (recipient is null || recipient.RoleId == AdminRoleId)
        {
            return;
        }

        if (string.IsNullOrWhiteSpace(recipient.FcmToken))
        {
            return;
        }

        var senderName = ResolveChatSenderName(sender, recipient.PreferredLanguage);
        var preview = NotificationMessages.BuildChatPushBody(
            recipient.PreferredLanguage,
            result.MessageType,
            result.Content);
        var messageType = result.MessageType.ToString();

        await fcmService.SendNotificationAsync(recipient.FcmToken!, new FcmNotificationPayload
        {
            Title = senderName,
            Body = preview,
            Type = "chat_message",
            ReferenceId = result.MessageId,
            RouteId = result.FromUserId,
            Data = new Dictionary<string, string>
            {
                ["messageType"] = messageType,
                ["fromUserId"] = result.FromUserId,
                ["toUserId"] = result.ToUserId,
                ["senderName"] = senderName,
                ["messagePreview"] = preview,
                ["sentAtUtc"] = result.SentAtUtc,
            }
        }, ct);
    }

    private static string ResolveChatSenderName(ChatPushUserInfo? sender, string? recipientLanguage)
    {
        if (sender is null)
        {
            return NotificationMessages.ChatFallbackSenderName(recipientLanguage);
        }

        if (sender.RoleId == AdminRoleId)
        {
            if (!string.IsNullOrWhiteSpace(sender.CompanyName))
            {
                return sender.CompanyName.Trim();
            }

            if (!string.IsNullOrWhiteSpace(sender.FullName))
            {
                return sender.FullName.Trim();
            }

            return NotificationMessages.ChatAdminSenderName(recipientLanguage);
        }

        if (!string.IsNullOrWhiteSpace(sender.CompanyName))
        {
            return sender.CompanyName.Trim();
        }

        return string.IsNullOrWhiteSpace(sender.FullName)
            ? NotificationMessages.ChatUserFallbackName(recipientLanguage)
            : sender.FullName.Trim();
    }

    private sealed record ChatPushUserInfo(
        Guid Id,
        byte RoleId,
        string? FcmToken,
        string FullName,
        string? CompanyName,
        string PreferredLanguage);

    private async Task PushMessageUpdatedAsync(ChatMessageDto result, CancellationToken ct)
    {
        var senderGroup = ChatHub.GetGroupName(result.FromUserId);
        var receiverGroup = ChatHub.GetGroupName(result.ToUserId);

        try
        {
            await chatHub.Clients.Group(senderGroup).SendAsync("messageUpdated", result, ct);
            if (!string.Equals(senderGroup, receiverGroup, StringComparison.Ordinal))
            {
                await chatHub.Clients.Group(receiverGroup).SendAsync("messageUpdated", result, ct);
            }
        }
        catch
        {
            // ignore realtime failures
        }
    }

    private async Task NotifySupportSessionAsync(
        string eventName,
        string customerUserId,
        ChatSupportAssignmentDto assignment,
        bool isActive,
        CancellationToken ct)
    {
        var payload = new
        {
            customerUserId,
            agentUserId = assignment.AssignedAgentId,
            agentName = assignment.AssignedAgentName,
            assignedAtUtc = assignment.AssignedAtUtc,
            releasedAtUtc = isActive ? null : DateTime.UtcNow.ToString("o"),
            isActive,
        };

        try
        {
            await chatHub.Clients
                .Group(ChatHub.GetGroupName(customerUserId))
                .SendAsync(eventName, payload, ct);
        }
        catch
        {
            // ignore realtime failures
        }
    }

    private string? GetCurrentUserId() =>
        User.FindFirst("EntityId")?.Value ?? User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
}

public sealed class ChatUploadRequest
{
    public ChatApiMessageType MessageType { get; set; }
    public IFormFile? File { get; set; }
}

public sealed class ChatUploadImagesRequest
{
    public List<IFormFile>? Files { get; set; }
}
