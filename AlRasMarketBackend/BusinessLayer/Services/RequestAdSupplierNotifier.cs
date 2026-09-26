using BusinessLayer.Caching;
using BusinessLayer.Constants;
using BusinessLayer.Helpers;
using BusinessLayer.Interfaces;
using DataLayer.Interfaces;
using DataLayer.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace BusinessLayer.Services;

/// <summary>
/// Notifies every active supplier (FCM + inbox) about a newly posted Requests ad.
/// Runs only from the background worker — never on the create/submit HTTP path.
/// </summary>
public sealed class RequestAdSupplierNotifier(
    IRasAlSouqDbContext dbContext,
    IProductDataAccess productData,
    IFcmNotificationService fcmNotificationService,
    ILogger<RequestAdSupplierNotifier> logger)
{
    private const int MaxConcurrentSends = 20;

    public async Task NotifySuppliersAsync(
        RequestAdSupplierNotifyEvent evt,
        CancellationToken cancellationToken = default)
    {
        if (evt.ProductId == Guid.Empty)
        {
            return;
        }

        var displayNameEn = CollapseWhitespace(evt.ProductNameEn);
        var displayNameAr = CollapseWhitespace(evt.ProductNameAr);
        if (displayNameEn.Length == 0 && displayNameAr.Length == 0)
        {
            displayNameEn = "a new request";
            displayNameAr = "طلب جديد";
        }
        else if (displayNameEn.Length == 0)
        {
            displayNameEn = displayNameAr;
        }
        else if (displayNameAr.Length == 0)
        {
            displayNameAr = displayNameEn;
        }

        var suppliers = await dbContext.Users
            .AsNoTracking()
            .Where(x =>
                x.IsActive
                && x.RoleId == RoleIds.Seller
                && x.IsCustomer != true
                && (evt.OwnerId == null || x.Id != evt.OwnerId.Value))
            .Select(x => new SupplierRecipient(
                x.Id,
                x.FcmToken,
                x.PreferredLanguage,
                x.IsNotificationsOn))
            .ToListAsync(cancellationToken)
            .ConfigureAwait(false);

        if (suppliers.Count == 0)
        {
            logger.LogInformation(
                "Request-ad supplier notify: no suppliers for product {ProductId}.",
                evt.ProductId);
            return;
        }

        var (titleEn, bodyEn, titleAr, bodyAr) = NotificationMessages.NewRequestAdAvailable(
            string.IsNullOrWhiteSpace(displayNameAr) ? displayNameEn : displayNameAr);

        var productIdText = evt.ProductId.ToString("D");
        byte? typeId = null;
        Guid? routeId = null;

        try
        {
            typeId = await productData
                .GetOrCreateNotificationTypeIdAsync("new_request_ad", cancellationToken)
                .ConfigureAwait(false);
            routeId = await productData
                .GetOrCreateNotificationRouteIdAsync("product-detail", cancellationToken)
                .ConfigureAwait(false);
        }
        catch (Exception ex)
        {
            logger.LogWarning(
                ex,
                "Failed to resolve notification type/route for request ad {ProductId}",
                evt.ProductId);
        }

        using var gate = new SemaphoreSlim(MaxConcurrentSends, MaxConcurrentSends);
        var sent = 0;
        var failed = 0;

        var tasks = suppliers.Select(async supplier =>
        {
            await gate.WaitAsync(cancellationToken).ConfigureAwait(false);
            try
            {
                var ok = await NotifyOneAsync(
                    supplier,
                    titleEn,
                    bodyEn,
                    titleAr,
                    bodyAr,
                    productIdText,
                    typeId,
                    routeId,
                    cancellationToken).ConfigureAwait(false);
                if (ok)
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

        await Task.WhenAll(tasks).ConfigureAwait(false);

        logger.LogInformation(
            "Request-ad supplier notify: product {ProductId} → {SupplierCount} suppliers (sent={Sent}, failed={Failed}).",
            evt.ProductId,
            suppliers.Count,
            sent,
            failed);
    }

    private async Task<bool> NotifyOneAsync(
        SupplierRecipient supplier,
        string titleEn,
        string bodyEn,
        string titleAr,
        string bodyAr,
        string productIdText,
        byte? typeId,
        Guid? routeId,
        CancellationToken cancellationToken)
    {
        var delivered = false;

        if (typeId.HasValue && routeId.HasValue)
        {
            try
            {
                await productData.AddInboxNotificationAsync(
                    new Notification
                    {
                        Id = Guid.NewGuid(),
                        Title = Truncate(titleEn, 255),
                        TitleAr = Truncate(titleAr, 255),
                        Body = Truncate(bodyEn, 1000),
                        BodyAr = Truncate(bodyAr, 1000),
                        FromUserId = supplier.Id,
                        ToUserId = supplier.Id,
                        TypeId = typeId.Value,
                        RouteId = routeId.Value,
                        ReferenceId = productIdText,
                        IsRead = false,
                        CreatedAt = DateTime.UtcNow
                    },
                    cancellationToken).ConfigureAwait(false);

                NotificationCacheVersions.Bump(supplier.Id);
                delivered = true;
            }
            catch (Exception ex)
            {
                logger.LogWarning(
                    ex,
                    "Failed inbox notification for supplier {UserId} request product {ProductId}",
                    supplier.Id,
                    productIdText);
            }
        }

        if (!NotificationDeliveryPrefs.AllowsPushAndEmail(supplier.IsNotificationsOn)
            || string.IsNullOrWhiteSpace(supplier.FcmToken))
        {
            return delivered;
        }

        var (pushTitle, pushBody) = NotificationMessages.PickOptional(
            supplier.PreferredLanguage,
            titleEn,
            bodyEn,
            titleAr,
            bodyAr);

        try
        {
            await fcmNotificationService.SendNotificationAsync(
                supplier.FcmToken!,
                new FcmNotificationPayload
                {
                    Title = pushTitle,
                    Body = pushBody,
                    Type = "new_request_ad",
                    RouteId = "product-detail",
                    ReferenceId = productIdText,
                    Data = new Dictionary<string, string>
                    {
                        ["productId"] = productIdText
                    }
                },
                cancellationToken).ConfigureAwait(false);
            return true;
        }
        catch (Exception ex)
        {
            logger.LogWarning(
                ex,
                "Failed FCM for supplier {UserId} request product {ProductId}",
                supplier.Id,
                productIdText);
            return delivered;
        }
    }

    private static string CollapseWhitespace(string? value)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            return string.Empty;
        }

        return string.Join(' ', value.Split((char[]?)null, StringSplitOptions.RemoveEmptyEntries));
    }

    private static string Truncate(string value, int maxLen)
    {
        if (string.IsNullOrEmpty(value) || value.Length <= maxLen)
        {
            return value;
        }

        return value[..(maxLen - 1)] + "…";
    }

    private sealed record SupplierRecipient(
        Guid Id,
        string? FcmToken,
        string? PreferredLanguage,
        bool IsNotificationsOn);
}
