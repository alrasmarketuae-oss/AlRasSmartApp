using BusinessLayer.Caching;
using BusinessLayer.Dtos;
using BusinessLayer.Helpers;
using BusinessLayer.Interfaces;
using DataLayer.Interfaces;
using DataLayer.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace BusinessLayer.Services;

public class NotificationsAppService(
    IFcmNotificationService fcmNotificationService,
    IEmailService emailService,
    IUserRepository userRepository,
    IRasAlSouqDbContext dbContext,
    ITieredCache cache,
    IUserLanguageResolver languageResolver,
    ILogger<NotificationsAppService> logger) : INotificationsAppService
{
    private static readonly TimeSpan MineTtl = TimeSpan.FromSeconds(60);
    private static readonly TimeSpan UnreadTtl = TimeSpan.FromSeconds(30);

    public async Task<string> SendAsync(SendNotificationInput input, CancellationToken cancellationToken = default)
    {
        var toUser = await userRepository.GetByIdAsync(input.ToUserId);
        if (toUser is null || string.IsNullOrWhiteSpace(toUser.FcmToken))
        {
            throw new InvalidOperationException("Target user has no FCM token.");
        }

        if (!Guid.TryParse(input.FromUserId, out var fromUserId))
        {
            throw new InvalidOperationException("Invalid from user id.");
        }

        if (!Guid.TryParse(input.ToUserId, out var toUserId))
        {
            throw new InvalidOperationException("Invalid to user id.");
        }

        if (!Guid.TryParse(input.RouteId, out var routeId))
        {
            throw new InvalidOperationException("Invalid route id.");
        }

        var titleEn = (input.Title ?? string.Empty).Trim();
        var bodyEn = (input.Body ?? string.Empty).Trim();
        var titleAr = string.IsNullOrWhiteSpace(input.TitleAr) ? null : input.TitleAr.Trim();
        var bodyAr = string.IsNullOrWhiteSpace(input.BodyAr) ? null : input.BodyAr.Trim();

        var (localizedTitle, localizedBody) = NotificationMessages.PickOptional(
            toUser.PreferredLanguage,
            titleEn,
            bodyEn,
            titleAr,
            bodyAr);

        await dbContext.Notifications.AddAsync(new Notification
        {
            Id = Guid.NewGuid(),
            Title = titleEn,
            TitleAr = titleAr,
            Body = bodyEn,
            BodyAr = bodyAr,
            FromUserId = fromUserId,
            ToUserId = toUserId,
            TypeId = input.TypeId,
            RouteId = routeId,
            ReferenceId = input.ReferenceId ?? string.Empty,
            IsRead = false,
            CreatedAt = DateTime.UtcNow,
        }, cancellationToken);

        await dbContext.SaveChangesAsync(cancellationToken);
        NotificationCacheVersions.Bump(toUserId);

        var fcmToken = toUser.FcmToken;
        var recipientEmail = toUser.Email;
        var type = input.Type;
        var routeIdText = input.RouteId;
        var referenceId = input.ReferenceId;

        _ = Task.Run(async () =>
        {
            try
            {
                if (!string.IsNullOrWhiteSpace(recipientEmail))
                {
                    await emailService.SendAsync(
                        recipientEmail,
                        localizedTitle,
                        BrandEmailLayout.Headline(localizedTitle) + BrandEmailLayout.Paragraph(localizedBody));
                }

                await fcmNotificationService.SendNotificationAsync(
                    fcmToken!,
                    new FcmNotificationPayload
                    {
                        Title = localizedTitle,
                        Body = localizedBody,
                        Type = type,
                        RouteId = routeIdText,
                        ReferenceId = referenceId
                    });
            }
            catch (Exception ex)
            {
                logger.LogError(
                    ex,
                    "Background notification send failed. ToUserId={ToUserId}, RouteId={RouteId}",
                    input.ToUserId,
                    input.RouteId);
            }
        });

        return UserMessages.Localize("Notification sent successfully.", toUser.PreferredLanguage);
    }

    public async Task<object> GetMineAsync(
        string userId,
        int page,
        int pageSize,
        CancellationToken cancellationToken = default)
    {
        if (!Guid.TryParse(userId, out var parsedUserId))
        {
            throw new ArgumentException("Invalid user id.");
        }

        page = Math.Max(1, page);
        pageSize = Math.Clamp(pageSize, 1, 100);

        var language = await languageResolver.ResolveAsync(userId, cancellationToken: cancellationToken);
        var version = NotificationCacheVersions.Get(parsedUserId);
        var cacheKey = $"notifications:mine:v{version}:{parsedUserId:N}:p{page}:s{pageSize}:l{language}";
        var cached = await cache.GetAsync(cacheKey, cancellationToken);
        if (cached is not null)
        {
            return cached;
        }

        var query = dbContext.Notifications
            .AsNoTracking()
            .Where(x => x.ToUserId == parsedUserId);

        var totalCount = await query.CountAsync(cancellationToken);
        var unreadCount = await query.CountAsync(x => !x.IsRead, cancellationToken);
        var rows = await query
            .OrderByDescending(x => x.CreatedAt)
            .ThenByDescending(x => x.Id)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(x => new
            {
                x.Id,
                x.Title,
                x.TitleAr,
                x.Body,
                x.BodyAr,
                x.TypeId,
                typeName = x.Type != null ? x.Type.Name : string.Empty,
                x.RouteId,
                routeName = x.Route != null ? x.Route.Name : string.Empty,
                x.ReferenceId,
                x.FromUserId,
                x.IsRead,
                x.CreatedAt,
            })
            .ToListAsync(cancellationToken);

        var items = rows.Select(x =>
        {
            var (title, body) = NotificationMessages.PickOptional(
                language,
                x.Title,
                x.Body,
                x.TitleAr,
                x.BodyAr);
            return new
            {
                id = x.Id,
                title,
                body,
                typeId = x.TypeId,
                typeName = x.typeName,
                routeId = x.RouteId,
                routeName = x.routeName,
                referenceId = x.ReferenceId,
                fromUserId = x.FromUserId,
                isRead = x.IsRead,
                createdAt = UtcDateTimeHelper.FormatApiDateTime(x.CreatedAt),
            };
        }).ToList();

        var result = new
        {
            page,
            pageSize,
            totalCount,
            unreadCount,
            items,
        };

        await cache.SetAsync(cacheKey, result, MineTtl, cancellationToken);
        return result;
    }

    public async Task<object> GetUnreadCountAsync(
        string userId,
        CancellationToken cancellationToken = default)
    {
        if (!Guid.TryParse(userId, out var parsedUserId))
        {
            throw new ArgumentException("Invalid user id.");
        }

        var version = NotificationCacheVersions.Get(parsedUserId);
        var cacheKey = $"notifications:unread:v{version}:{parsedUserId:N}";
        var cached = await cache.GetAsync(cacheKey, cancellationToken);
        if (cached is not null)
        {
            return cached;
        }

        var unreadCount = await dbContext.Notifications
            .AsNoTracking()
            .CountAsync(x => x.ToUserId == parsedUserId && !x.IsRead, cancellationToken);

        var result = new { unreadCount };
        await cache.SetAsync(cacheKey, result, UnreadTtl, cancellationToken);
        return result;
    }

    public async Task<object> MarkReadAsync(
        string userId,
        string notificationId,
        CancellationToken cancellationToken = default)
    {
        if (!Guid.TryParse(userId, out var parsedUserId))
        {
            throw new ArgumentException("Invalid user id.");
        }

        if (!Guid.TryParse(notificationId, out var parsedNotificationId))
        {
            throw new ArgumentException("Invalid notification id.");
        }

        var item = await dbContext.Notifications
            .FirstOrDefaultAsync(
                x => x.Id == parsedNotificationId && x.ToUserId == parsedUserId,
                cancellationToken)
            ?? throw new KeyNotFoundException("Notification not found.");

        if (!item.IsRead)
        {
            item.IsRead = true;
            await dbContext.SaveChangesAsync(cancellationToken);
            NotificationCacheVersions.Bump(parsedUserId);
        }

        return new { id = item.Id, isRead = true };
    }

    public async Task<object> MarkAllReadAsync(
        string userId,
        CancellationToken cancellationToken = default)
    {
        if (!Guid.TryParse(userId, out var parsedUserId))
        {
            throw new ArgumentException("Invalid user id.");
        }

        var unread = await dbContext.Notifications
            .Where(x => x.ToUserId == parsedUserId && !x.IsRead)
            .ToListAsync(cancellationToken);

        foreach (var item in unread)
        {
            item.IsRead = true;
        }

        if (unread.Count > 0)
        {
            await dbContext.SaveChangesAsync(cancellationToken);
            NotificationCacheVersions.Bump(parsedUserId);
        }

        return new { markedCount = unread.Count };
    }
}
