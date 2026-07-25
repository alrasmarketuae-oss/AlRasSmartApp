using BusinessLayer.Caching;
using BusinessLayer.Constants;
using BusinessLayer.Dtos;
using BusinessLayer.Helpers;
using BusinessLayer.Interfaces;
using DataLayer.Interfaces;
using DataLayer.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace BusinessLayer.Services;

public class AdminCompaniesAppService(
    IRasAlSouqDbContext dbContext,
    IEmailService emailService,
    IFcmNotificationService fcmNotificationService,
    IAdminRealtimeNotificationService adminRealtimeNotificationService,
    IAdminAuditLogAppService auditLogAppService,
    IAccountDeletionAppService accountDeletionAppService,
    ILogger<AdminCompaniesAppService> logger) : IAdminCompaniesAppService
{
    public async Task<object> GetPendingCompaniesAsync(CancellationToken cancellationToken = default)
    {
        return await dbContext.Users
            .Include(x => x.CompanyImages)
            .Where(x =>
                !x.IsRejected
                && (
                    ((x.RoleId == RoleIds.Seller || x.RoleId == RoleIds.ShippingCompany) && !x.IsApproved && x.IsVerified)
                    || (x.PendingProfileChanges != null && x.PendingProfileChanges != string.Empty)))
            .Select(x => new
            {
                x.Id,
                x.FullName,
                x.Email,
                x.PhoneNumber,
                x.LandNumber,
                x.LicenseNumber,
                x.LicencePath,
                Images = x.CompanyImages.Select(i => new { i.Id, i.ImagePath, i.IsPrimary })
            })
            .ToListAsync(cancellationToken);
    }

    public async Task<string> ApproveCompanyAsync(string companyUserId, CancellationToken cancellationToken = default)
    {
        if (!Guid.TryParse(companyUserId, out var companyId))
        {
            throw new ArgumentException("Invalid company user id.");
        }

        var company = await dbContext.Users
            .Include(x => x.CompanyImages)
            .FirstOrDefaultAsync(
                x => x.Id == companyId,
                cancellationToken)
            ?? throw new KeyNotFoundException("User not found.");

        var isPendingProfileEdit = !string.IsNullOrWhiteSpace(company.PendingProfileChanges);
        if (!isPendingProfileEdit && !company.IsVerified)
        {
            throw new InvalidOperationException("Company must verify OTP before admin approval.");
        }

        var oldName = company.FullName;
        var pendingSnapshot = company.PendingProfileChanges;
        ApplyPendingCompanyProfileChanges(company);
        var newName = company.FullName;

        company.IsActive = true;
        company.IsApproved = true;
        company.IsVerified = true;
        company.IsRejected = false;
        company.RejectionReason = null;
        company.PendingProfileChanges = null;
        await dbContext.SaveChangesAsync(cancellationToken);
        await adminRealtimeNotificationService.BroadcastCountsAsync(cancellationToken);

        await auditLogAppService.WriteAsync(
            isPendingProfileEdit
                ? AdminAuditActions.CompanyProfileApprove
                : AdminAuditActions.CompanyApprove,
            AdminAuditEntityTypes.Company,
            company.Id.ToString("D"),
            isPendingProfileEdit
                ? $"Approved company profile edit for '{newName}'"
                : $"Approved company '{newName}'",
            new
            {
                oldName,
                newName,
                pendingProfileChanges = pendingSnapshot,
                email = company.Email,
                roleId = company.RoleId
            },
            cancellationToken);

        var preferredLanguage = company.PreferredLanguage;
        var companyEmail = company.Email;
        var fcmToken = company.FcmToken;
        var companyIdText = company.Id.ToString();
        var notificationEn = isPendingProfileEdit
            ? NotificationMessages.CompanyProfileUpdateApproved("en")
            : NotificationMessages.CompanyApproved("en");
        var notificationAr = isPendingProfileEdit
            ? NotificationMessages.CompanyProfileUpdateApproved("ar")
            : NotificationMessages.CompanyApproved("ar");
        var notification = NotificationMessages.IsArabic(preferredLanguage)
            ? notificationAr
            : notificationEn;
        var fcmType = isPendingProfileEdit
            ? (company.RoleId == RoleIds.ShippingCompany
                ? "shipping_company_profile_approved"
                : "company_profile_approved")
            : (company.RoleId == RoleIds.ShippingCompany
                ? "shipping_company_approved"
                : "company_approved");
        var notifyUserId = company.Id;

        try
        {
            await PersistCompanyInboxNotificationAsync(
                notifyUserId,
                fcmType,
                "profile",
                companyIdText,
                notificationEn.FcmTitle,
                notificationEn.FcmBody,
                notificationAr.FcmTitle,
                notificationAr.FcmBody,
                cancellationToken);
        }
        catch (Exception ex)
        {
            logger.LogWarning(ex, "Failed to persist company approval inbox for {CompanyId}", companyId);
        }

        _ = Task.Run(async () =>
        {
            try
            {
                await emailService.SendAsync(
                    companyEmail,
                    notification.EmailSubject,
                    notification.EmailHtml);

                if (!string.IsNullOrWhiteSpace(fcmToken))
                {
                    await fcmNotificationService.SendNotificationAsync(
                        fcmToken,
                        new FcmNotificationPayload
                        {
                            Title = notification.FcmTitle,
                            Body = notification.FcmBody,
                            Type = fcmType,
                            RouteId = "profile",
                            ReferenceId = companyIdText
                        });
                }
            }
            catch (Exception ex)
            {
                logger.LogError(ex, "Failed to send background approval notifications for company {CompanyId}", companyId);
            }
        });

        return isPendingProfileEdit
            ? "Pending profile changes approved successfully."
            : "Company approved successfully.";
    }

    public async Task<string> RejectCompanyAsync(
        string companyUserId,
        AdminRejectCompanyRequest request,
        CancellationToken cancellationToken = default)
    {
        if (!Guid.TryParse(companyUserId, out var companyId))
        {
            throw new ArgumentException("Invalid company user id.");
        }

        if (string.IsNullOrWhiteSpace(request.Reason))
        {
            throw new ArgumentException("Rejection reason is required.");
        }

        var company = await dbContext.Users
            .FirstOrDefaultAsync(
                x => x.Id == companyId,
                cancellationToken)
            ?? throw new KeyNotFoundException("User not found.");

        if (company.IsApproved
            && company.RoleId is RoleIds.Seller or RoleIds.ShippingCompany
            && string.IsNullOrWhiteSpace(company.PendingProfileChanges))
        {
            throw new InvalidOperationException("Company is already approved.");
        }

        var reason = request.Reason.Trim();
        var isPendingProfileEdit = !string.IsNullOrWhiteSpace(company.PendingProfileChanges);
        var companyName = company.FullName;
        var pendingSnapshot = company.PendingProfileChanges;

        // Profile-edit rejection: keep live company fields and restore previous approval.
        company.PendingProfileChanges = null;
        if (isPendingProfileEdit)
        {
            company.IsActive = true;
            company.IsApproved = true;
            company.IsVerified = true;
            company.IsRejected = false;
            company.RejectionReason = null;
            await dbContext.SaveChangesAsync(cancellationToken);
            await adminRealtimeNotificationService.BroadcastCountsAsync(cancellationToken);
        }
        else
        {
            var registrationPreferredLanguage = company.PreferredLanguage;
            var registrationCompanyEmail = company.Email;
            var registrationFcmToken = company.FcmToken;
            var registrationCompanyIdText = company.Id.ToString();
            var registrationRoleId = company.RoleId;
            var registrationNotification = NotificationMessages.CompanyRejected(
                registrationPreferredLanguage,
                reason);

            await auditLogAppService.WriteAsync(
                AdminAuditActions.CompanyReject,
                AdminAuditEntityTypes.Company,
                company.Id.ToString("D"),
                $"Rejected company '{companyName}' and removed registration",
                new
                {
                    companyName,
                    reason,
                    pendingProfileChanges = pendingSnapshot,
                    email = company.Email,
                    roleId = company.RoleId,
                    registrationRemoved = true
                },
                cancellationToken);

            await accountDeletionAppService.DeleteUserByAdminAsync(
                company.Id.ToString(),
                cancellationToken);
            await adminRealtimeNotificationService.BroadcastCountsAsync(cancellationToken);

            _ = Task.Run(async () =>
            {
                try
                {
                    await emailService.SendAsync(
                        registrationCompanyEmail,
                        registrationNotification.EmailSubject,
                        registrationNotification.EmailHtml);

                    if (!string.IsNullOrWhiteSpace(registrationFcmToken))
                    {
                        var isShipping = registrationRoleId == RoleIds.ShippingCompany;
                        await fcmNotificationService.SendNotificationAsync(
                            registrationFcmToken,
                            new FcmNotificationPayload
                            {
                                Title = registrationNotification.FcmTitle,
                                Body = registrationNotification.FcmBody,
                                Type = isShipping ? "shipping_company_rejected" : "company_rejected",
                                RouteId = isShipping ? "shipping-registration" : "company-registration",
                                ReferenceId = registrationCompanyIdText
                            });
                    }
                }
                catch (Exception ex)
                {
                    logger.LogError(
                        ex,
                        "Failed to send background rejection notifications for company {CompanyId}",
                        companyId);
                }
            });

            return "Company rejected, user notified, and registration removed so they can sign up again.";
        }

        await auditLogAppService.WriteAsync(
            AdminAuditActions.CompanyProfileReject,
            AdminAuditEntityTypes.Company,
            company.Id.ToString("D"),
            $"Rejected company profile edit for '{companyName}'",
            new
            {
                companyName,
                reason,
                pendingProfileChanges = pendingSnapshot,
                email = company.Email,
                roleId = company.RoleId
            },
            cancellationToken);

        var preferredLanguage = company.PreferredLanguage;
        var companyEmail = company.Email;
        var fcmToken = company.FcmToken;
        var companyIdText = company.Id.ToString();
        var companyUserIdForNotify = company.Id;
        var notificationEn = NotificationMessages.CompanyProfileUpdateRejected("en", reason);
        var notificationAr = NotificationMessages.CompanyProfileUpdateRejected("ar", reason);
        var notification = NotificationMessages.IsArabic(preferredLanguage)
            ? notificationAr
            : notificationEn;
        var fcmType = company.RoleId == RoleIds.ShippingCompany
            ? "shipping_company_profile_rejected"
            : "company_profile_rejected";

        try
        {
            await PersistCompanyInboxNotificationAsync(
                companyUserIdForNotify,
                fcmType,
                "profile",
                companyIdText,
                notificationEn.FcmTitle,
                notificationEn.FcmBody,
                notificationAr.FcmTitle,
                notificationAr.FcmBody,
                cancellationToken);
        }
        catch (Exception ex)
        {
            logger.LogWarning(ex, "Failed to persist company profile-reject inbox for {CompanyId}", companyId);
        }

        _ = Task.Run(async () =>
        {
            try
            {
                await emailService.SendAsync(
                    companyEmail,
                    notification.EmailSubject,
                    notification.EmailHtml);

                if (!string.IsNullOrWhiteSpace(fcmToken))
                {
                    await fcmNotificationService.SendNotificationAsync(
                        fcmToken,
                        new FcmNotificationPayload
                        {
                            Title = notification.FcmTitle,
                            Body = notification.FcmBody,
                            Type = fcmType,
                            RouteId = "profile",
                            ReferenceId = companyIdText
                        });
                }
            }
            catch (Exception ex)
            {
                logger.LogError(ex, "Failed to send profile-reject notifications for company {CompanyId}", companyId);
            }
        });

        return "Pending profile changes discarded. Company remains on previous approved data.";
    }

    private async Task PersistCompanyInboxNotificationAsync(
        Guid toUserId,
        string typeName,
        string routeName,
        string referenceId,
        string titleEn,
        string bodyEn,
        string titleAr,
        string bodyAr,
        CancellationToken cancellationToken = default)
    {
        var routeId = await GetOrCreateNotificationRouteIdAsync(routeName, cancellationToken);
        var typeId = await GetOrCreateNotificationTypeIdAsync(typeName, cancellationToken);
        await dbContext.Notifications.AddAsync(new Notification
        {
            Id = Guid.NewGuid(),
            Title = TruncateNotify(titleEn, 255),
            TitleAr = TruncateNotifyOrNull(titleAr, 255),
            Body = TruncateNotify(bodyEn, 1000),
            BodyAr = TruncateNotifyOrNull(bodyAr, 1000),
            FromUserId = toUserId,
            ToUserId = toUserId,
            TypeId = typeId,
            RouteId = routeId,
            ReferenceId = referenceId,
            IsRead = false,
            CreatedAt = DateTime.UtcNow,
        }, cancellationToken);
        await dbContext.SaveChangesAsync(cancellationToken);
        NotificationCacheVersions.Bump(toUserId);
    }

    private async Task<Guid> GetOrCreateNotificationRouteIdAsync(
        string name,
        CancellationToken cancellationToken)
    {
        var existing = await dbContext.NotificationRoutes
            .AsNoTracking()
            .FirstOrDefaultAsync(x => x.Name == name, cancellationToken);
        if (existing is not null)
        {
            return existing.Id;
        }

        var route = new NotificationRoute { Id = Guid.NewGuid(), Name = name };
        await dbContext.NotificationRoutes.AddAsync(route, cancellationToken);
        await dbContext.SaveChangesAsync(cancellationToken);
        return route.Id;
    }

    private async Task<byte> GetOrCreateNotificationTypeIdAsync(
        string name,
        CancellationToken cancellationToken)
    {
        var existing = await dbContext.NotificationTypes
            .AsNoTracking()
            .FirstOrDefaultAsync(x => x.Name == name, cancellationToken);
        if (existing is not null)
        {
            return existing.Id;
        }

        var type = new NotificationType { Name = name };
        await dbContext.NotificationTypes.AddAsync(type, cancellationToken);
        await dbContext.SaveChangesAsync(cancellationToken);
        return type.Id;
    }

    private static string TruncateNotify(string? value, int maxLen)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            return string.Empty;
        }

        var trimmed = value.Trim();
        return trimmed.Length <= maxLen ? trimmed : trimmed[..(maxLen - 1)] + "…";
    }

    private static string? TruncateNotifyOrNull(string? value, int maxLen)
    {
        var truncated = TruncateNotify(value, maxLen);
        return string.IsNullOrWhiteSpace(truncated) ? null : truncated;
    }

    private static void ApplyPendingCompanyProfileChanges(User company)
    {
        var pending = PendingCompanyProfileChangeHelper.TryParse(company.PendingProfileChanges);
        PendingCompanyProfileChangeHelper.ApplyToUser(company, pending);
    }
}
