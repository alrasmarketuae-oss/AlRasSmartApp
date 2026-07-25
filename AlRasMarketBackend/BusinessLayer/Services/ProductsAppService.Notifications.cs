using BusinessLayer.Caching;
using BusinessLayer.Helpers;
using BusinessLayer.Interfaces;
using DataLayer.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;

namespace BusinessLayer.Services;

public partial class ProductsAppService
{
    private void QueueOwnerNotification(
        User? owner,
        string subject,
        string emailHtml,
        string fcmTitle,
        string fcmBody,
        string fcmType,
        string referenceId,
        string logContext,
        string? titleEn = null,
        string? bodyEn = null,
        string? titleAr = null,
        string? bodyAr = null)
    {
        if (owner is null)
        {
            return;
        }

        var ownerId = owner.Id;
        var ownerEmail = owner.Email;
        var fcmToken = owner.FcmToken;
        var preferredLanguage = owner.PreferredLanguage;

        var storeTitleEn = TruncateNotificationText(titleEn ?? fcmTitle, 255);
        var storeBodyEn = TruncateNotificationText(bodyEn ?? fcmBody, 1000);
        var storeTitleArRaw = TruncateNotificationText(titleAr, 255);
        var storeBodyArRaw = TruncateNotificationText(bodyAr, 1000);
        var storeTitleAr = string.IsNullOrWhiteSpace(storeTitleArRaw) ? null : storeTitleArRaw;
        var storeBodyAr = string.IsNullOrWhiteSpace(storeBodyArRaw) ? null : storeBodyArRaw;

        _ = Task.Run(async () =>
        {
            try
            {
                using var scope = scopeFactory.CreateScope();
                var emailService = scope.ServiceProvider.GetRequiredService<IEmailService>();
                var fcmService = scope.ServiceProvider.GetRequiredService<IFcmNotificationService>();
                var db = scope.ServiceProvider.GetRequiredService<DataLayer.Interfaces.IRasAlSouqDbContext>();

                try
                {
                    var routeId = await GetOrCreateNotificationRouteIdAsync(db, "product-detail", CancellationToken.None);
                    var typeId = await GetOrCreateNotificationTypeIdAsync(db, fcmType, CancellationToken.None);
                    await db.Notifications.AddAsync(new Notification
                    {
                        Id = Guid.NewGuid(),
                        Title = storeTitleEn,
                        TitleAr = storeTitleAr,
                        Body = storeBodyEn,
                        BodyAr = storeBodyAr,
                        FromUserId = ownerId,
                        ToUserId = ownerId,
                        TypeId = typeId,
                        RouteId = routeId,
                        ReferenceId = referenceId,
                        IsRead = false,
                        CreatedAt = DateTime.UtcNow,
                    });
                    await db.SaveChangesAsync();
                    NotificationCacheVersions.Bump(ownerId);
                }
                catch (Exception ex)
                {
                    logger.LogWarning(ex, "Failed to persist inbox notification for {LogContext}", logContext);
                }

                if (!string.IsNullOrWhiteSpace(ownerEmail))
                {
                    await emailService.SendAsync(ownerEmail, subject, emailHtml);
                }

                if (!string.IsNullOrWhiteSpace(fcmToken))
                {
                    var (pushTitle, pushBody) = NotificationMessages.PickOptional(
                        preferredLanguage,
                        storeTitleEn,
                        storeBodyEn,
                        storeTitleAr,
                        storeBodyAr);
                    await fcmService.SendNotificationAsync(
                        fcmToken,
                        new FcmNotificationPayload
                        {
                            Title = pushTitle,
                            Body = pushBody,
                            Type = fcmType,
                            RouteId = "product-detail",
                            ReferenceId = referenceId
                        });
                }
            }
            catch (Exception ex)
            {
                logger.LogError(ex, "Failed to send {LogContext}", logContext);
            }
        });
    }

    private static string TruncateNotificationText(string? value, int maxLen)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            return string.Empty;
        }

        var trimmed = value.Trim();
        if (trimmed.Length <= maxLen)
        {
            return trimmed;
        }

        return trimmed[..(maxLen - 1)] + "…";
    }

    private static async Task<Guid> GetOrCreateNotificationRouteIdAsync(
        DataLayer.Interfaces.IRasAlSouqDbContext db,
        string name,
        CancellationToken cancellationToken)
    {
        var existing = await db.NotificationRoutes
            .AsNoTracking()
            .FirstOrDefaultAsync(x => x.Name == name, cancellationToken);
        if (existing is not null)
        {
            return existing.Id;
        }

        var route = new NotificationRoute { Id = Guid.NewGuid(), Name = name };
        await db.NotificationRoutes.AddAsync(route, cancellationToken);
        await db.SaveChangesAsync(cancellationToken);
        return route.Id;
    }

    private static async Task<byte> GetOrCreateNotificationTypeIdAsync(
        DataLayer.Interfaces.IRasAlSouqDbContext db,
        string name,
        CancellationToken cancellationToken)
    {
        var existing = await db.NotificationTypes
            .AsNoTracking()
            .FirstOrDefaultAsync(x => x.Name == name, cancellationToken);
        if (existing is not null)
        {
            return existing.Id;
        }

        var type = new NotificationType { Name = name };
        await db.NotificationTypes.AddAsync(type, cancellationToken);
        await db.SaveChangesAsync(cancellationToken);
        return type.Id;
    }
}
