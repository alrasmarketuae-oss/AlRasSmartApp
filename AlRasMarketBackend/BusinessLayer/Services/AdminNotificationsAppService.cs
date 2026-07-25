using BusinessLayer.Dtos;
using BusinessLayer.Interfaces;
using DataLayer.Interfaces;
using DataLayer.Models;
using Microsoft.EntityFrameworkCore;

namespace BusinessLayer.Services;

public class AdminNotificationsAppService(
    IRasAlSouqDbContext dbContext,
    IAdminPushNotificationQueue queue,
    IOpenAiVisionService openAiVisionService) : IAdminNotificationsAppService
{
    private static readonly string[] ValidAudiences = ["All", "Suppliers", "Clients", "Shipping", "SingleUser"];

    public async Task<object> GetBroadcastHistoryAsync(
        int page,
        int pageSize,
        string? audience,
        CancellationToken cancellationToken = default)
    {
        page = page < 1 ? 1 : page;
        pageSize = pageSize is < 1 or > 100 ? 20 : pageSize;

        var query = dbContext.AdminPushNotifications.AsNoTracking().AsQueryable();
        if (!string.IsNullOrWhiteSpace(audience))
        {
            var normalized = NormalizeAudience(audience);
            query = query.Where(x => x.Audience == normalized);
        }

        var total = await query.CountAsync(cancellationToken);
        var rows = await query
            .Include(x => x.TargetUser)
            .OrderByDescending(x => x.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync(cancellationToken);

        var items = rows.Select(x => new AdminPushNotificationListItemDto
        {
            Id = x.Id,
            Title = x.Title,
            Body = x.Body,
            Audience = x.Audience,
            TargetUserId = x.TargetUserId,
            TargetUserName = x.TargetUser != null
                ? (x.TargetUser.CompanyName ?? x.TargetUser.FullName)
                : null,
            CreatedAt = x.CreatedAt,
            SentCount = x.SentCount,
            FailedCount = x.FailedCount,
            Type = x.Type
        }).ToList();

        return new { page, pageSize, total, items };
    }

    public async Task<object> QueueBroadcastAsync(
        AdminSendPushNotificationRequest request,
        Guid? adminUserId,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(request.Audience))
        {
            throw new ArgumentException("Audience is required.");
        }

        if (string.IsNullOrWhiteSpace(request.Title))
        {
            throw new ArgumentException("Title is required.");
        }

        if (string.IsNullOrWhiteSpace(request.Body))
        {
            throw new ArgumentException("Body is required.");
        }

        var audience = NormalizeAudience(request.Audience.Trim());
        if (!ValidAudiences.Contains(audience, StringComparer.Ordinal))
        {
            throw new ArgumentException("Invalid audience. Allowed: All, Suppliers, Clients, Shipping, SingleUser.");
        }

        Guid? targetUserId = null;
        if (audience == "SingleUser")
        {
            if (string.IsNullOrWhiteSpace(request.TargetUserId) || !Guid.TryParse(request.TargetUserId, out var parsedUserId))
            {
                throw new ArgumentException("Target user id is required for single-user notifications.");
            }

            var userExists = await dbContext.Users.AnyAsync(x => x.Id == parsedUserId, cancellationToken);
            if (!userExists)
            {
                throw new KeyNotFoundException("Target user not found.");
            }

            targetUserId = parsedUserId;
        }

        var bilingual = await openAiVisionService.EnsureBilingualNotificationAsync(
            request.Title.Trim(),
            request.Body.Trim(),
            cancellationToken);

        var log = new AdminPushNotification
        {
            Id = Guid.NewGuid(),
            Title = bilingual.TitleEn,
            Body = bilingual.BodyEn,
            TitleAr = bilingual.TitleAr,
            BodyAr = bilingual.BodyAr,
            Audience = audience,
            TargetUserId = targetUserId,
            CreatedAt = DateTime.UtcNow,
            CreatedByAdminId = adminUserId,
            SentCount = 0,
            FailedCount = 0,
            Type = string.IsNullOrWhiteSpace(request.Type) ? "admin_broadcast" : request.Type.Trim()
        };

        await dbContext.AdminPushNotifications.AddAsync(log, cancellationToken);
        await dbContext.SaveChangesAsync(cancellationToken);
        await queue.EnqueueAsync(log.Id, cancellationToken);

        return new
        {
            message = "Notification queued.",
            notificationId = log.Id,
            audience = log.Audience,
            targetUserId = log.TargetUserId
        };
    }

    private static string NormalizeAudience(string audience)
    {
        if (audience.Equals("all", StringComparison.OrdinalIgnoreCase)) return "All";
        if (audience.Equals("suppliers", StringComparison.OrdinalIgnoreCase)) return "Suppliers";
        if (audience.Equals("clients", StringComparison.OrdinalIgnoreCase)) return "Clients";
        if (audience.Equals("shipping", StringComparison.OrdinalIgnoreCase)) return "Shipping";
        if (audience.Equals("singleuser", StringComparison.OrdinalIgnoreCase)) return "SingleUser";
        return audience;
    }
}
