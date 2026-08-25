using BusinessLayer.Helpers;
using BusinessLayer.Interfaces;
using DataLayer.Interfaces;
using DataLayer.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

namespace RasAlSouqPresentaionLayer.Services;

public sealed class AdminPushNotificationWorker(
    IServiceScopeFactory scopeFactory,
    IAdminPushNotificationQueue queue,
    ILogger<AdminPushNotificationWorker> logger) : BackgroundService
{
    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        while (!stoppingToken.IsCancellationRequested)
        {
            Guid notificationId;
            try
            {
                notificationId = await queue.DequeueAsync(stoppingToken);
            }
            catch (OperationCanceledException)
            {
                break;
            }
            catch (Exception ex)
            {
                logger.LogError(ex, "Failed to dequeue admin push notification job.");
                await Task.Delay(500, stoppingToken);
                continue;
            }

            try
            {
                await ProcessAsync(notificationId, stoppingToken);
            }
            catch (Exception ex)
            {
                logger.LogError(ex, "Failed to process admin push notification {NotificationId}", notificationId);
            }
        }
    }

    private async Task ProcessAsync(Guid notificationId, CancellationToken cancellationToken)
    {
        using var scope = scopeFactory.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<IRasAlSouqDbContext>();
        var fcm = scope.ServiceProvider.GetRequiredService<IFcmNotificationService>();
        var email = scope.ServiceProvider.GetRequiredService<IEmailService>();

        var log = await db.AdminPushNotifications
            .FirstOrDefaultAsync(x => x.Id == notificationId, cancellationToken);

        if (log is null)
        {
            logger.LogWarning("AdminPushNotification not found: {NotificationId}", notificationId);
            return;
        }

        var recipients = await CollectRecipientsAsync(db, log.Audience, log.TargetUserId, cancellationToken);
        var (sent, failed) = await SendToRecipientsAsync(
            db,
            fcm,
            email,
            recipients,
            log.Title,
            log.Body,
            log.TitleAr,
            log.BodyAr,
            log.Type,
            log.Id.ToString(),
            log.CreatedByAdminId,
            cancellationToken);

        log.SentCount = sent;
        log.FailedCount = failed;
        await db.SaveChangesAsync(cancellationToken);
    }

    private static async Task<List<PushRecipient>> CollectRecipientsAsync(
        IRasAlSouqDbContext db,
        string audience,
        Guid? targetUserId,
        CancellationToken cancellationToken)
    {
        if (targetUserId.HasValue)
        {
            // Single user: allow email-only recipients (no FCM required).
            var user = await db.Users
                .Where(x => x.Id == targetUserId.Value)
                .Select(x => new PushRecipient(
                    x.Id,
                    x.FcmToken ?? string.Empty,
                    x.Email ?? string.Empty,
                    x.PreferredLanguage ?? string.Empty,
                    x.IsNotificationsOn))
                .FirstOrDefaultAsync(cancellationToken);

            if (user is null)
            {
                return [];
            }

            if (string.IsNullOrWhiteSpace(user.Token) && string.IsNullOrWhiteSpace(user.Email))
            {
                return [];
            }

            return [user];
        }

        IQueryable<User> query = db.Users.Where(x => x.IsActive);

        if (audience.Equals("Shipping", StringComparison.OrdinalIgnoreCase))
        {
            var providerIds = db.InternationalShippingPosts
                .Select(x => x.PublisherUserId)
                .Distinct();

            query = query.Where(x => providerIds.Contains(x.Id));
        }
        else if (audience.Equals("Suppliers", StringComparison.OrdinalIgnoreCase))
        {
            query = query.Where(x => x.RoleId == 2);
        }
        else if (audience.Equals("Clients", StringComparison.OrdinalIgnoreCase))
        {
            query = query.Where(x => x.RoleId == 3);
        }
        else
        {
            query = query.Where(x => x.RoleId == 2 || x.RoleId == 3);
        }

        // Broadcast audiences: prefer users that can receive at least one channel.
        return await query
            .Where(x =>
                (x.FcmToken != null && x.FcmToken != "") ||
                (x.Email != null && x.Email != ""))
            .Select(x => new PushRecipient(
                x.Id,
                x.FcmToken ?? string.Empty,
                x.Email ?? string.Empty,
                x.PreferredLanguage ?? string.Empty,
                x.IsNotificationsOn))
            .ToListAsync(cancellationToken);
    }

    private async Task<(int sent, int failed)> SendToRecipientsAsync(
        IRasAlSouqDbContext db,
        IFcmNotificationService fcm,
        IEmailService emailService,
        List<PushRecipient> recipients,
        string titleEn,
        string bodyEn,
        string? titleAr,
        string? bodyAr,
        string? type,
        string referenceId,
        Guid? fromAdminId,
        CancellationToken cancellationToken)
    {
        var uniqueRecipients = recipients
            .GroupBy(x => x.UserId)
            .Select(g => g.First())
            .Where(x => !string.IsNullOrWhiteSpace(x.Token) || !string.IsNullOrWhiteSpace(x.Email))
            .ToList();

        if (uniqueRecipients.Count == 0)
        {
            return (0, 0);
        }

        var routeId = await GetOrCreateRouteIdAsync(db, "orders", cancellationToken);
        var typeId = await GetOrCreateTypeIdAsync(
            db,
            string.IsNullOrWhiteSpace(type) ? "admin_message" : type.Trim(),
            cancellationToken);
        var fromUserId = fromAdminId ?? Guid.Empty;

        var sent = 0;
        var failed = 0;
        using var gate = new SemaphoreSlim(20, 20);

        var tasks = uniqueRecipients.Select(async recipient =>
        {
            var (title, body) = NotificationMessages.PickOptional(
                recipient.PreferredLanguage,
                titleEn,
                bodyEn,
                titleAr,
                bodyAr);

            var deliveredAny = false;

            await gate.WaitAsync(cancellationToken);
            try
            {
                try
                {
                    var titleEnStore = titleEn.Length > 255 ? titleEn[..255] : titleEn;
                    var bodyEnStore = bodyEn.Length > 1000 ? bodyEn[..999] + "…" : bodyEn;
                    var titleArStore = string.IsNullOrWhiteSpace(titleAr)
                        ? null
                        : (titleAr.Length > 255 ? titleAr[..255] : titleAr.Trim());
                    var bodyArStore = string.IsNullOrWhiteSpace(bodyAr)
                        ? null
                        : (bodyAr.Length > 1000 ? bodyAr.Trim()[..999] + "…" : bodyAr.Trim());
                    await db.Notifications.AddAsync(new Notification
                    {
                        Id = Guid.NewGuid(),
                        Title = titleEnStore,
                        TitleAr = titleArStore,
                        Body = bodyEnStore,
                        BodyAr = bodyArStore,
                        FromUserId = fromUserId == Guid.Empty ? recipient.UserId : fromUserId,
                        ToUserId = recipient.UserId,
                        TypeId = typeId,
                        RouteId = routeId,
                        ReferenceId = referenceId,
                        IsRead = false,
                        CreatedAt = DateTime.UtcNow,
                    }, cancellationToken);
                    await db.SaveChangesAsync(cancellationToken);
                    deliveredAny = true;
                }
                catch (Exception ex)
                {
                    logger.LogWarning(ex, "Failed to store in-app notification for {UserId}", recipient.UserId);
                }

                if (NotificationDeliveryPrefs.AllowsPushAndEmail(recipient.IsNotificationsOn)
                    && !string.IsNullOrWhiteSpace(recipient.Email))
                {
                    try
                    {
                        await emailService.SendAsync(
                            recipient.Email,
                            title,
                            BrandEmailLayout.Headline(title) + BrandEmailLayout.Paragraph(body));
                        deliveredAny = true;
                    }
                    catch (Exception ex)
                    {
                        logger.LogWarning(ex, "Failed to email admin notification to {Email}", recipient.Email);
                    }
                }

                if (NotificationDeliveryPrefs.AllowsPushAndEmail(recipient.IsNotificationsOn)
                    && !string.IsNullOrWhiteSpace(recipient.Token))
                {
                    try
                    {
                        await fcm.SendNotificationAsync(
                            recipient.Token,
                            new FcmNotificationPayload
                            {
                                Title = title,
                                Body = body,
                                Type = string.IsNullOrWhiteSpace(type) ? "admin_broadcast" : type,
                                RouteId = "orders",
                                ReferenceId = referenceId
                            },
                            cancellationToken);
                        deliveredAny = true;
                    }
                    catch (Exception ex)
                    {
                        logger.LogWarning(ex, "Failed FCM admin notification for {UserId}", recipient.UserId);
                    }
                }

                if (deliveredAny)
                {
                    Interlocked.Increment(ref sent);
                }
                else
                {
                    Interlocked.Increment(ref failed);
                }
            }
            finally
            {
                gate.Release();
            }
        });

        await Task.WhenAll(tasks);
        return (sent, failed);
    }

    private static async Task<Guid> GetOrCreateRouteIdAsync(
        IRasAlSouqDbContext db,
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

    private static async Task<byte> GetOrCreateTypeIdAsync(
        IRasAlSouqDbContext db,
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

    private sealed record PushRecipient(
        Guid UserId,
        string Token,
        string Email,
        string PreferredLanguage,
        bool IsNotificationsOn);
}
