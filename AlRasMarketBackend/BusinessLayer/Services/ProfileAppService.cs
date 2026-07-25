using BusinessLayer.Constants;
using BusinessLayer.Helpers;
using BusinessLayer.Interfaces;
using DataLayer.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace BusinessLayer.Services;

public class ProfileAppService(
    IRasAlSouqDbContext dbContext,
    IAdminRealtimeNotificationService adminRealtimeNotificationService,
    IMediaStorageService mediaStorage) : IProfileAppService
{
    public async Task<object> GetMyProfileAsync(string userId, CancellationToken cancellationToken = default)
    {
        if (!Guid.TryParse(userId, out var parsedUserId))
        {
            throw new ArgumentException("Invalid user id.");
        }

        var user = await dbContext.Users
            .AsNoTracking()
            .Include(x => x.Role)
            .FirstOrDefaultAsync(x => x.Id == parsedUserId, cancellationToken)
            ?? throw new KeyNotFoundException("User not found.");

        return MapProfile(user);
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
            .FirstOrDefaultAsync(x => x.Id == parsedUserId, cancellationToken)
            ?? throw new KeyNotFoundException("User not found.");

        // Birth date can update immediately (not company identity data).
        if (input.BirthDate.HasValue)
        {
            user.BirthDate = input.BirthDate;
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

        return MapProfile(user);
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

        return MapProfile(user);
    }

    private static object MapProfile(DataLayer.Models.User user)
    {
        var pending = PendingCompanyProfileChangeHelper.TryParse(user.PendingProfileChanges);
        return new
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
            isCompanyAccount = user.RoleId == RoleIds.Seller,
            isShippingCompanyAccount = user.RoleId == RoleIds.ShippingCompany,
            isCustomer = user.IsCustomer ?? false,
            isApproved = user.IsApproved,
            isVerified = user.IsVerified,
            isRejected = user.IsRejected,
            rejectionReason = user.RejectionReason,
            hasPendingProfileChanges = pending?.HasAnyChange == true,
            pendingProfileChanges = pending
        };
    }
}
