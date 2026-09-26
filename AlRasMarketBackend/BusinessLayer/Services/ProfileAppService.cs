using BusinessLayer.Constants;
using BusinessLayer.Helpers;
using BusinessLayer.Interfaces;
using DataLayer.Interfaces;
using DataLayer.Models;
using Microsoft.EntityFrameworkCore;

namespace BusinessLayer.Services;

public class ProfileAppService(
    IRasAlSouqDbContext dbContext,
    IAdminRealtimeNotificationService adminRealtimeNotificationService,
    IMediaStorageService mediaStorage) : IProfileAppService
{
    private const string PendingCompanyLicencesFolder = "company-licences/pending";
    private const string PendingCompanyImagesFolder = "company-images/pending";

    public async Task<object> GetMyProfileAsync(string userId, CancellationToken cancellationToken = default)
    {
        if (!Guid.TryParse(userId, out var parsedUserId))
        {
            throw new ArgumentException("Invalid user id.");
        }

        var user = await dbContext.Users
            .AsNoTracking()
            .Include(x => x.Role)
            .Include(x => x.CompanyImages)
            .FirstOrDefaultAsync(x => x.Id == parsedUserId, cancellationToken)
            ?? throw new KeyNotFoundException("User not found.");

        return await MapProfileAsync(user, cancellationToken);
    }

    public async Task<object> UpdateMyProfileAsync(
        string userId,
        UpdateProfileInput input,
        CancellationToken cancellationToken = default)
    {
        if (!Guid.TryParse(userId, out var parsedUserId))
        {
            throw new ArgumentException("Invalid user id.");
        }

        var user = await dbContext.Users
            .Include(x => x.Role)
            .Include(x => x.CompanyImages)
            .FirstOrDefaultAsync(x => x.Id == parsedUserId, cancellationToken)
            ?? throw new KeyNotFoundException("User not found.");

        // Birth date can update immediately (not company identity data).
        if (input.BirthDate.HasValue)
        {
            user.BirthDate = input.BirthDate;
        }

        // Unapproved companies update live fields so admin can re-review registration.
        if (LoginAccessHelper.IsPendingCompanyApproval(user))
        {
            var liveChanged = ApplyLiveCompanyProfileFields(user, input);
            if (liveChanged)
            {
                await dbContext.SaveChangesAsync(cancellationToken);
                await adminRealtimeNotificationService.NotifyProfileEditAsync(user, cancellationToken);
            }
            else
            {
                await dbContext.SaveChangesAsync(cancellationToken);
            }

            return await MapProfileAsync(user, cancellationToken);
        }

        // All identity/company fields stay on live row until admin approves pending payload.
        var pending = PendingCompanyProfileChangeHelper.TryParse(user.PendingProfileChanges)
            ?? new PendingCompanyProfileChange();
        var profileDataChanged = false;

        if (!string.IsNullOrWhiteSpace(input.FullName))
        {
            var nextValue = input.FullName.Trim();
            if (!string.Equals(user.FullName?.Trim(), nextValue, StringComparison.Ordinal))
            {
                pending.FullName = nextValue;
                profileDataChanged = true;
            }
        }

        if (input.PhoneNumber is not null)
        {
            var nextValue = string.IsNullOrWhiteSpace(input.PhoneNumber)
                ? string.Empty
                : input.PhoneNumber.Trim();
            var currentValue = user.PhoneNumber?.Trim() ?? string.Empty;
            if (!string.Equals(currentValue, nextValue, StringComparison.Ordinal))
            {
                pending.PhoneNumber = nextValue;
                profileDataChanged = true;
            }
        }

        var canStageCompanyFields =
            user.RoleId == RoleIds.Seller || user.RoleId == RoleIds.ShippingCompany;

        if (canStageCompanyFields)
        {
            if (input.CompanyName is not null)
            {
                var nextValue = string.IsNullOrWhiteSpace(input.CompanyName)
                    ? string.Empty
                    : input.CompanyName.Trim();
                var currentValue = user.CompanyName?.Trim() ?? string.Empty;
                if (!string.Equals(currentValue, nextValue, StringComparison.Ordinal))
                {
                    pending.CompanyName = nextValue;
                    profileDataChanged = true;
                }
            }

            if (input.CommercialRegister is not null)
            {
                var nextValue = string.IsNullOrWhiteSpace(input.CommercialRegister)
                    ? string.Empty
                    : input.CommercialRegister.Trim();
                var currentValue = user.CommercialRegister?.Trim() ?? string.Empty;
                if (!string.Equals(currentValue, nextValue, StringComparison.Ordinal))
                {
                    pending.CommercialRegister = nextValue;
                    profileDataChanged = true;
                }
            }

            if (input.TaxNumber is not null)
            {
                var nextValue = string.IsNullOrWhiteSpace(input.TaxNumber)
                    ? string.Empty
                    : input.TaxNumber.Trim();
                var currentValue = user.TaxNumber?.Trim() ?? string.Empty;
                if (!string.Equals(currentValue, nextValue, StringComparison.Ordinal))
                {
                    pending.TaxNumber = nextValue;
                    profileDataChanged = true;
                }
            }

            if (input.Website is not null)
            {
                var nextValue = string.IsNullOrWhiteSpace(input.Website)
                    ? string.Empty
                    : input.Website.Trim();
                var currentValue = user.Website?.Trim() ?? string.Empty;
                if (!string.Equals(currentValue, nextValue, StringComparison.Ordinal))
                {
                    pending.Website = nextValue;
                    profileDataChanged = true;
                }
            }

            if (input.LandNumber is not null)
            {
                var nextValue = string.IsNullOrWhiteSpace(input.LandNumber)
                    ? string.Empty
                    : input.LandNumber.Trim();
                var currentValue = user.LandNumber?.Trim() ?? string.Empty;
                if (!string.Equals(currentValue, nextValue, StringComparison.Ordinal))
                {
                    pending.LandNumber = nextValue;
                    profileDataChanged = true;
                }
            }
        }

        if (profileDataChanged || pending.HasAnyChange)
        {
            // Keep account fully operational on OLD live data.
            user.PendingProfileChanges = PendingCompanyProfileChangeHelper.Serialize(pending);
            user.IsRejected = false;
            if (user.RejectionReason is not null
                && user.RejectionReason.StartsWith("PROFILE_UPDATE_PENDING", StringComparison.Ordinal))
            {
                user.RejectionReason = null;
            }
        }

        await dbContext.SaveChangesAsync(cancellationToken);

        if (profileDataChanged)
        {
            await adminRealtimeNotificationService.NotifyProfileEditAsync(user, cancellationToken);
        }

        return await MapProfileAsync(user, cancellationToken);
    }

    public async Task<object> UploadMyProfileImageAsync(
        string userId,
        UploadProfileImageInput input,
        CancellationToken cancellationToken = default)
    {
        if (!Guid.TryParse(userId, out var parsedUserId))
        {
            throw new ArgumentException("Invalid user id.");
        }

        if (input.File is null || input.File.Length == 0)
        {
            throw new ArgumentException("File is required.");
        }

        var user = await dbContext.Users
            .Include(x => x.Role)
            .Include(x => x.CompanyImages)
            .FirstOrDefaultAsync(x => x.Id == parsedUserId, cancellationToken)
            ?? throw new KeyNotFoundException("User not found.");

        var fileName = $"{parsedUserId:N}.jpg";
        var previousPath = user.ImgPath;

        user.ImgPath = await mediaStorage.SaveCompressedJpegAsync(
            input.File,
            "images/profiles",
            fileName,
            cancellationToken: cancellationToken);
        await dbContext.SaveChangesAsync(cancellationToken);

        if (!string.Equals(previousPath, user.ImgPath, StringComparison.OrdinalIgnoreCase))
        {
            await mediaStorage.DeleteAsync(previousPath, cancellationToken);
        }

        return await MapProfileAsync(user, cancellationToken);
    }

    public async Task<object> UploadMyCompanyLicenceAsync(
        string userId,
        UploadProfileImageInput input,
        CancellationToken cancellationToken = default)
    {
        if (!Guid.TryParse(userId, out var parsedUserId))
        {
            throw new ArgumentException("Invalid user id.");
        }

        if (input.File is null || input.File.Length == 0)
        {
            throw new ArgumentException("File is required.");
        }

        var user = await dbContext.Users
            .Include(x => x.Role)
            .Include(x => x.CompanyImages)
            .FirstOrDefaultAsync(x => x.Id == parsedUserId, cancellationToken)
            ?? throw new KeyNotFoundException("User not found.");

        EnsureCompanyAccount(user);

        if (LoginAccessHelper.IsPendingCompanyApproval(user))
        {
            var extension = Path.GetExtension(input.File.FileName);
            if (string.IsNullOrWhiteSpace(extension))
            {
                extension = ".jpg";
            }

            var previousPath = user.LicencePath;
            var fileName = $"licence-{parsedUserId:N}-{Guid.NewGuid():N}{extension.ToLowerInvariant()}";
            user.LicencePath = await mediaStorage.SaveFormFileAsync(
                input.File,
                "company-licences",
                fileName,
                cancellationToken: cancellationToken);
            await dbContext.SaveChangesAsync(cancellationToken);

            if (!string.Equals(previousPath, user.LicencePath, StringComparison.OrdinalIgnoreCase))
            {
                await mediaStorage.DeleteAsync(previousPath, cancellationToken);
            }

            await adminRealtimeNotificationService.NotifyProfileEditAsync(user, cancellationToken);
            return await MapProfileAsync(user, cancellationToken);
        }

        var pending = PendingCompanyProfileChangeHelper.TryParse(user.PendingProfileChanges)
            ?? new PendingCompanyProfileChange();

        // Drop previous pending licence file if it was never approved.
        if (!string.IsNullOrWhiteSpace(pending.LicencePath)
            && !string.Equals(pending.LicencePath, user.LicencePath, StringComparison.OrdinalIgnoreCase))
        {
            await mediaStorage.DeleteAsync(pending.LicencePath, cancellationToken);
        }

        var pendingFileName = $"licence-{parsedUserId:N}-{Guid.NewGuid():N}{Path.GetExtension(input.File.FileName).ToLowerInvariant()}";
        if (string.IsNullOrWhiteSpace(Path.GetExtension(input.File.FileName)))
        {
            pendingFileName = $"licence-{parsedUserId:N}-{Guid.NewGuid():N}.jpg";
        }

        pending.LicencePath = await mediaStorage.SaveFormFileAsync(
            input.File,
            PendingCompanyLicencesFolder,
            pendingFileName,
            cancellationToken: cancellationToken);

        user.PendingProfileChanges = PendingCompanyProfileChangeHelper.Serialize(pending);
        user.IsRejected = false;
        if (string.Equals(user.RejectionReason, "PROFILE_UPDATE_PENDING", StringComparison.OrdinalIgnoreCase))
        {
            user.RejectionReason = null;
        }

        await dbContext.SaveChangesAsync(cancellationToken);
        await adminRealtimeNotificationService.NotifyProfileEditAsync(user, cancellationToken);

        return await MapProfileAsync(user, cancellationToken);
    }

    public async Task<object> UploadMyCompanyImageAsync(
        string userId,
        UploadProfileImageInput input,
        CancellationToken cancellationToken = default)
    {
        if (!Guid.TryParse(userId, out var parsedUserId))
        {
            throw new ArgumentException("Invalid user id.");
        }

        if (input.File is null || input.File.Length == 0)
        {
            throw new ArgumentException("File is required.");
        }

        var user = await dbContext.Users
            .Include(x => x.Role)
            .Include(x => x.CompanyImages)
            .FirstOrDefaultAsync(x => x.Id == parsedUserId, cancellationToken)
            ?? throw new KeyNotFoundException("User not found.");

        EnsureCompanyAccount(user);

        if (LoginAccessHelper.IsPendingCompanyApproval(user))
        {
            var liveFileName = $"company-{parsedUserId:N}-{Guid.NewGuid():N}.jpg";
            var liveImagePath = await mediaStorage.SaveCompressedJpegAsync(
                input.File,
                "company-images",
                liveFileName,
                cancellationToken: cancellationToken);

            var isPrimary = user.CompanyImages is null || user.CompanyImages.Count == 0;
            user.CompanyImages ??= [];
            user.CompanyImages.Add(new CompanyImage
            {
                UserId = user.Id,
                ImagePath = liveImagePath,
                IsPrimary = isPrimary,
                CreatedAt = DateTime.UtcNow
            });

            await dbContext.SaveChangesAsync(cancellationToken);
            await adminRealtimeNotificationService.NotifyProfileEditAsync(user, cancellationToken);
            return await MapProfileAsync(user, cancellationToken);
        }

        var pending = PendingCompanyProfileChangeHelper.TryParse(user.PendingProfileChanges)
            ?? new PendingCompanyProfileChange();

        var livePaths = (user.CompanyImages ?? [])
            .OrderByDescending(x => x.IsPrimary)
            .ThenBy(x => x.Id)
            .Select(x => x.ImagePath)
            .Where(x => !string.IsNullOrWhiteSpace(x))
            .ToList();

        var proposed = PendingCompanyProfileChangeHelper.ResolveProposedCompanyImagePaths(
            pending,
            livePaths);

        var fileName = $"company-{parsedUserId:N}-{Guid.NewGuid():N}.jpg";
        var imagePath = await mediaStorage.SaveCompressedJpegAsync(
            input.File,
            PendingCompanyImagesFolder,
            fileName,
            cancellationToken: cancellationToken);

        proposed.Add(imagePath);
        pending.CompanyImagesChanged = true;
        pending.CompanyImagePaths = proposed;

        user.PendingProfileChanges = PendingCompanyProfileChangeHelper.Serialize(pending);
        user.IsRejected = false;
        if (string.Equals(user.RejectionReason, "PROFILE_UPDATE_PENDING", StringComparison.OrdinalIgnoreCase))
        {
            user.RejectionReason = null;
        }

        await dbContext.SaveChangesAsync(cancellationToken);
        await adminRealtimeNotificationService.NotifyProfileEditAsync(user, cancellationToken);

        return await MapProfileAsync(user, cancellationToken);
    }

    public async Task<object> DeleteMyCompanyImageAsync(
        string userId,
        long companyImageId,
        CancellationToken cancellationToken = default)
    {
        if (!Guid.TryParse(userId, out var parsedUserId))
        {
            throw new ArgumentException("Invalid user id.");
        }

        var user = await dbContext.Users
            .Include(x => x.Role)
            .Include(x => x.CompanyImages)
            .FirstOrDefaultAsync(x => x.Id == parsedUserId, cancellationToken)
            ?? throw new KeyNotFoundException("User not found.");

        EnsureCompanyAccount(user);

        var pending = PendingCompanyProfileChangeHelper.TryParse(user.PendingProfileChanges)
            ?? new PendingCompanyProfileChange();

        var livePaths = (user.CompanyImages ?? [])
            .OrderByDescending(x => x.IsPrimary)
            .ThenBy(x => x.Id)
            .Select(x => x.ImagePath)
            .Where(x => !string.IsNullOrWhiteSpace(x))
            .ToList();

        var proposed = PendingCompanyProfileChangeHelper.ResolveProposedCompanyImagePaths(
            pending,
            livePaths);

        var liveImage = user.CompanyImages.FirstOrDefault(x => x.Id == companyImageId);
        string? pathToRemove = liveImage?.ImagePath;

        // Allow removing a newly uploaded pending path by matching virtual negative ids
        // is not used; mobile sends live ids only. If path not found in live, try by index in pending.
        if (string.IsNullOrWhiteSpace(pathToRemove))
        {
            throw new KeyNotFoundException("Company image not found.");
        }

        var removedPendingOnly = !livePaths.Contains(pathToRemove, StringComparer.OrdinalIgnoreCase)
            && proposed.Contains(pathToRemove, StringComparer.OrdinalIgnoreCase);

        proposed.RemoveAll(x => string.Equals(x, pathToRemove, StringComparison.OrdinalIgnoreCase));

        if (removedPendingOnly)
        {
            await mediaStorage.DeleteAsync(pathToRemove, cancellationToken);
        }

        pending.CompanyImagesChanged = true;
        pending.CompanyImagePaths = proposed;

        user.PendingProfileChanges = PendingCompanyProfileChangeHelper.Serialize(pending);
        user.IsRejected = false;
        if (string.Equals(user.RejectionReason, "PROFILE_UPDATE_PENDING", StringComparison.OrdinalIgnoreCase))
        {
            user.RejectionReason = null;
        }

        await dbContext.SaveChangesAsync(cancellationToken);
        await adminRealtimeNotificationService.NotifyProfileEditAsync(user, cancellationToken);

        return await MapProfileAsync(user, cancellationToken);
    }

    /// <summary>
    /// Stages removal of a pending (not-yet-approved) company image by path.
    /// </summary>
    public async Task<object> DeleteMyPendingCompanyImageByPathAsync(
        string userId,
        string imagePath,
        CancellationToken cancellationToken = default)
    {
        if (!Guid.TryParse(userId, out var parsedUserId))
        {
            throw new ArgumentException("Invalid user id.");
        }

        if (string.IsNullOrWhiteSpace(imagePath))
        {
            throw new ArgumentException("Image path is required.");
        }

        var user = await dbContext.Users
            .Include(x => x.Role)
            .Include(x => x.CompanyImages)
            .FirstOrDefaultAsync(x => x.Id == parsedUserId, cancellationToken)
            ?? throw new KeyNotFoundException("User not found.");

        EnsureCompanyAccount(user);

        var pending = PendingCompanyProfileChangeHelper.TryParse(user.PendingProfileChanges)
            ?? new PendingCompanyProfileChange();

        var livePaths = (user.CompanyImages ?? [])
            .Select(x => x.ImagePath)
            .Where(x => !string.IsNullOrWhiteSpace(x))
            .ToList();

        var proposed = PendingCompanyProfileChangeHelper.ResolveProposedCompanyImagePaths(
            pending,
            livePaths);

        var target = imagePath.Trim();
        if (!proposed.Any(x => string.Equals(x, target, StringComparison.OrdinalIgnoreCase)))
        {
            throw new KeyNotFoundException("Pending company image not found.");
        }

        proposed.RemoveAll(x => string.Equals(x, target, StringComparison.OrdinalIgnoreCase));

        if (!livePaths.Contains(target, StringComparer.OrdinalIgnoreCase))
        {
            await mediaStorage.DeleteAsync(target, cancellationToken);
        }

        pending.CompanyImagesChanged = true;
        pending.CompanyImagePaths = proposed;
        if (!pending.HasAnyChange)
        {
            user.PendingProfileChanges = null;
        }
        else
        {
            user.PendingProfileChanges = PendingCompanyProfileChangeHelper.Serialize(pending);
        }

        await dbContext.SaveChangesAsync(cancellationToken);
        if (user.PendingProfileChanges is not null)
        {
            await adminRealtimeNotificationService.NotifyProfileEditAsync(user, cancellationToken);
        }
        else
        {
            await adminRealtimeNotificationService.BroadcastCountsAsync(cancellationToken);
        }

        return await MapProfileAsync(user, cancellationToken);
    }

    private static bool ApplyLiveCompanyProfileFields(User user, UpdateProfileInput input)
    {
        var changed = false;

        if (!string.IsNullOrWhiteSpace(input.FullName))
        {
            var nextValue = input.FullName.Trim();
            if (!string.Equals(user.FullName?.Trim(), nextValue, StringComparison.Ordinal))
            {
                user.FullName = nextValue;
                changed = true;
            }
        }

        if (input.PhoneNumber is not null)
        {
            var nextValue = string.IsNullOrWhiteSpace(input.PhoneNumber)
                ? string.Empty
                : input.PhoneNumber.Trim();
            var currentValue = user.PhoneNumber?.Trim() ?? string.Empty;
            if (!string.Equals(currentValue, nextValue, StringComparison.Ordinal))
            {
                user.PhoneNumber = nextValue;
                changed = true;
            }
        }

        if (user.RoleId is RoleIds.Seller or RoleIds.ShippingCompany)
        {
            if (input.CompanyName is not null)
            {
                var nextValue = string.IsNullOrWhiteSpace(input.CompanyName)
                    ? string.Empty
                    : input.CompanyName.Trim();
                var currentValue = user.CompanyName?.Trim() ?? string.Empty;
                if (!string.Equals(currentValue, nextValue, StringComparison.Ordinal))
                {
                    user.CompanyName = nextValue;
                    changed = true;
                }
            }

            if (input.CommercialRegister is not null)
            {
                var nextValue = string.IsNullOrWhiteSpace(input.CommercialRegister)
                    ? string.Empty
                    : input.CommercialRegister.Trim();
                var currentValue = user.CommercialRegister?.Trim() ?? string.Empty;
                if (!string.Equals(currentValue, nextValue, StringComparison.Ordinal))
                {
                    user.CommercialRegister = nextValue;
                    changed = true;
                }
            }

            if (input.TaxNumber is not null)
            {
                var nextValue = string.IsNullOrWhiteSpace(input.TaxNumber)
                    ? string.Empty
                    : input.TaxNumber.Trim();
                var currentValue = user.TaxNumber?.Trim() ?? string.Empty;
                if (!string.Equals(currentValue, nextValue, StringComparison.Ordinal))
                {
                    user.TaxNumber = nextValue;
                    changed = true;
                }
            }

            if (input.Website is not null)
            {
                var nextValue = string.IsNullOrWhiteSpace(input.Website)
                    ? string.Empty
                    : input.Website.Trim();
                var currentValue = user.Website?.Trim() ?? string.Empty;
                if (!string.Equals(currentValue, nextValue, StringComparison.Ordinal))
                {
                    user.Website = nextValue;
                    changed = true;
                }
            }

            if (input.LandNumber is not null)
            {
                var nextValue = string.IsNullOrWhiteSpace(input.LandNumber)
                    ? string.Empty
                    : input.LandNumber.Trim();
                var currentValue = user.LandNumber?.Trim() ?? string.Empty;
                if (!string.Equals(currentValue, nextValue, StringComparison.Ordinal))
                {
                    user.LandNumber = nextValue;
                    changed = true;
                }
            }
        }

        return changed;
    }

    private static void EnsureCompanyAccount(User user)
    {
        if (user.RoleId is not (RoleIds.Seller or RoleIds.ShippingCompany))
        {
            throw new ArgumentException("Only company accounts can manage licence and company images.");
        }
    }

    private Task<object> MapProfileAsync(
        User user,
        CancellationToken cancellationToken)
    {
        _ = cancellationToken;
        var pending = PendingCompanyProfileChangeHelper.TryParse(user.PendingProfileChanges);
        var registrationCompletion =
            RegistrationCompletionRequestHelper.TryParse(user.RegistrationCompletionRequest);
        var isCompanyAccount = user.RoleId == RoleIds.Seller;
        var companyImages = (user.CompanyImages ?? [])
            .OrderByDescending(x => x.IsPrimary)
            .ThenBy(x => x.Id)
            .Select(x => new
            {
                id = x.Id,
                imagePath = x.ImagePath,
                isPrimary = x.IsPrimary
            })
            .ToList();

        return Task.FromResult<object>(new
        {
            id = user.Id,
            fullName = user.FullName,
            email = user.Email,
            phoneNumber = user.PhoneNumber,
            landNumber = user.LandNumber,
            imgPath = user.ImgPath,
            roleId = user.RoleId,
            roleName = user.Role?.RoleName ?? string.Empty,
            companyName = user.CompanyName,
            birthDate = user.BirthDate,
            commercialRegister = user.CommercialRegister,
            taxNumber = user.TaxNumber,
            website = user.Website,
            licenseNumber = user.LicenseNumber,
            licencePath = user.LicencePath,
            companyImages,
            isCompanyAccount = isCompanyAccount,
            isShippingCompanyAccount = user.RoleId == RoleIds.ShippingCompany,
            isCustomer = user.IsCustomer ?? false,
            isApproved = user.IsApproved,
            isVerified = user.IsVerified,
            isRejected = user.IsRejected,
            rejectionReason = user.RejectionReason,
            loginProviderName = user.LoginProviderName,
            // Social accounts have no hash, so the app hides the current-password field.
            hasPassword = !string.IsNullOrWhiteSpace(user.HashedPassword),
            hasPendingProfileChanges = pending?.HasAnyChange == true,
            pendingProfileChanges = pending,
            needsRegistrationCompletion = registrationCompletion?.HasAnyMissing == true,
            registrationCompletionRequest = registrationCompletion,
            isNotificationsOn = user.IsNotificationsOn,
        });
    }
}
