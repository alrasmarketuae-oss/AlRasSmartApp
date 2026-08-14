using System.Net.Mail;
using BusinessLayer.Constants;
using BusinessLayer.Dtos;
using BusinessLayer.Factories;
using BusinessLayer.Helpers;
using BusinessLayer.Interfaces;
using BusinessLayer.LoginServices.Dtos;
using DataLayer.Interfaces;
using DataLayer.Models;
using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;

namespace BusinessLayer.Services;

public class AuthAppService(
    ILoginService loginService,
    ITokenService tokenService,
    IUserRepository userRepository,
    IPasswordHasher passwordHasher,
    IRasAlSouqDbContext dbContext,
    IAccountDeletionAppService accountDeletionAppService,
    PasswordResetNotifierFactory passwordResetNotifierFactory,
    IServiceScopeFactory scopeFactory,
    IEmailOtpService emailOtpService,
    UserNameTranslationQueue userNameTranslationQueue,
    IAdminRealtimeNotificationService adminRealtimeNotificationService,
    ITurnstileVerifier turnstileVerifier,
    IHttpContextAccessor httpContextAccessor,
    ILogger<AuthAppService> logger) : IAuthAppService
{
    public async Task<(string message, string userId, string? imgPath)> RegisterPersonAsync(RegisterPersonInput input, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(input.Email) || string.IsNullOrWhiteSpace(input.Password))
        {
            throw new ArgumentException("Email and password are required.");
        }

        var email = NormalizeAndValidateEmail(input.Email);

        await EnsureEmailAvailableForRegistrationAsync(
            email,
            allowReplacingRejectedCompanyRegistration: false,
            cancellationToken);

        var user = new User
        {
            Id = Guid.NewGuid(),
            FullName = input.FullName,
            Email = email,
            HashedPassword = passwordHasher.HashPassword(input.Password),
            RoleId = 3,
            LoginProviderName = "Local",
            IsActive = true,
            IsApproved = true,
            IsVerified = false,
            PhoneNumber = input.PhoneNumber,
            FcmToken = input.FcmToken,
            PreferredLanguage = NotificationMessages.NormalizeLanguage(input.PreferredLanguage)
        };

        await userRepository.AddAsync(user);
        userNameTranslationQueue.Enqueue(user.Id, user.FullName, null, user.PreferredLanguage);
        await SendRegistrationOtpOrRollbackAsync(user.Id, email, cancellationToken);
        await adminRealtimeNotificationService.NotifyNewUserAsync(user, cancellationToken);
        return ("Person account created successfully. OTP has been sent to your email.", user.Id.ToString(), user.ImgPath);
    }

    public async Task<(string message, string userId, string? imgPath, bool isCustomer)> RegisterCompanyAsync(RegisterCompanyInput input, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(input.Email) || string.IsNullOrWhiteSpace(input.Password))
        {
            throw new ArgumentException("Email and password are required.");
        }

        var email = NormalizeAndValidateEmail(input.Email);

        await EnsureEmailAvailableForRegistrationAsync(
            email,
            allowReplacingRejectedCompanyRegistration: true,
            cancellationToken);

        var user = new User
        {
            Id = Guid.NewGuid(),
            FullName = input.FullName,
            CompanyName = input.CompanyName,
            Email = email,
            HashedPassword = passwordHasher.HashPassword(input.Password),
            RoleId = 2,
            LoginProviderName = "Local",
            IsActive = false,
            IsApproved = false,
            IsVerified = false,
            PhoneNumber = input.PhoneNumber,
            LandNumber = input.LandNumber,
            LicenseNumber = input.LicenseNumber,
            BirthDate = input.BirthDate,
            CommercialRegister = input.CommercialRegister,
            TaxNumber = input.TaxNumber,
            Website = NormalizeOptionalWebsite(input.Website),
            FcmToken = input.FcmToken,
            IsCustomer = input.IsCustomer,
            PreferredLanguage = NotificationMessages.NormalizeLanguage(input.PreferredLanguage),
            LicencePath = string.IsNullOrWhiteSpace(input.LicencePath)
                ? null
                : WebRootFileHelper.NormalizeStoredPath(input.LicencePath)
        };

        await dbContext.Users.AddAsync(user, cancellationToken);
        if (input.CompanyImagePaths is not null)
        {
            for (var i = 0; i < input.CompanyImagePaths.Count; i++)
            {
                var path = WebRootFileHelper.NormalizeStoredPath(input.CompanyImagePaths[i]);
                if (string.IsNullOrWhiteSpace(path))
                {
                    continue;
                }

                await dbContext.CompanyImages.AddAsync(new CompanyImage
                {
                    UserId = user.Id,
                    ImagePath = path,
                    IsPrimary = i == 0
                }, cancellationToken);
            }
        }

        await dbContext.SaveChangesAsync(cancellationToken);
        userNameTranslationQueue.Enqueue(
            user.Id,
            user.FullName,
            user.CompanyName,
            user.PreferredLanguage);
        await SendRegistrationOtpOrRollbackAsync(user.Id, email, cancellationToken);
        await adminRealtimeNotificationService.NotifyNewUserAsync(user, cancellationToken);
        return ("Company account created and pending admin approval. OTP has been sent to your email.", user.Id.ToString(), user.ImgPath, user.IsCustomer ?? false);
    }

    public async Task<(string message, string userId, string? imgPath)> RegisterShippingCompanyAsync(
        RegisterShippingCompanyInput input,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(input.Email) || string.IsNullOrWhiteSpace(input.Password))
        {
            throw new ArgumentException("Email and password are required.");
        }

        if (string.IsNullOrWhiteSpace(input.CompanyName))
        {
            throw new ArgumentException("Company name is required.");
        }

        if (string.IsNullOrWhiteSpace(input.PhoneNumber))
        {
            throw new ArgumentException("Phone number is required.");
        }

        var email = NormalizeAndValidateEmail(input.Email);

        await EnsureEmailAvailableForRegistrationAsync(
            email,
            allowReplacingRejectedCompanyRegistration: true,
            cancellationToken);

        var companyName = input.CompanyName.Trim();
        var user = new User
        {
            Id = Guid.NewGuid(),
            FullName = companyName,
            CompanyName = companyName,
            Email = email,
            HashedPassword = passwordHasher.HashPassword(input.Password),
            RoleId = RoleIds.ShippingCompany,
            LoginProviderName = "Local",
            IsActive = false,
            IsApproved = false,
            IsVerified = false,
            PhoneNumber = input.PhoneNumber.Trim(),
            LandNumber = string.IsNullOrWhiteSpace(input.LandNumber)
                ? null
                : input.LandNumber.Trim(),
            CommercialRegister = string.IsNullOrWhiteSpace(input.CommercialRegister)
                ? null
                : input.CommercialRegister.Trim(),
            TaxNumber = string.IsNullOrWhiteSpace(input.TaxNumber)
                ? null
                : input.TaxNumber.Trim(),
            Website = NormalizeOptionalWebsite(input.Website),
            FcmToken = input.FcmToken,
            PreferredLanguage = NotificationMessages.NormalizeLanguage(input.PreferredLanguage)
        };

        await dbContext.Users.AddAsync(user, cancellationToken);
        await dbContext.SaveChangesAsync(cancellationToken);
        userNameTranslationQueue.Enqueue(
            user.Id,
            user.FullName,
            user.CompanyName,
            user.PreferredLanguage);
        await SendRegistrationOtpOrRollbackAsync(user.Id, email, cancellationToken);
        await adminRealtimeNotificationService.NotifyNewUserAsync(user, cancellationToken);
        return ("Shipping company account created and pending admin approval. OTP has been sent to your email.", user.Id.ToString(), user.ImgPath);
    }

    public async Task<object> LoginAsync(LoginDtos.LoginRequest request, CancellationToken cancellationToken = default)
    {
        var isAdminDashboard = string.Equals(
            request.ClientApp?.Trim(),
            "AdminDashboard",
            StringComparison.OrdinalIgnoreCase);

        if (isAdminDashboard)
        {
            var remoteIp = httpContextAccessor.HttpContext?.Connection.RemoteIpAddress?.ToString();
            await turnstileVerifier.EnsureValidAsync(
                request.TurnstileToken,
                remoteIp,
                cancellationToken);
        }

        return await loginService.LoginAsync(
            request.LoginProviderName,
            request.Email,
            request.Password,
            request.Token,
            request.FcmToken,
            request.PreferredLanguage,
            request.FullName);
    }

    /// <summary>
    /// Re-points the device token at the signed-in account. Called after every login and on
    /// token refresh, so the token always follows the account currently using the device.
    /// </summary>
    public async Task UpdateFcmTokenAsync(string userId, string fcmToken, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(userId))
        {
            throw new ArgumentException("User id is required.");
        }

        if (string.IsNullOrWhiteSpace(fcmToken))
        {
            throw new ArgumentException("FCM token is required.");
        }

        await userRepository.UpdateFcmTokenAsync(userId, fcmToken.Trim());
    }

    public async Task ClearFcmTokenAsync(string userId, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(userId))
        {
            throw new ArgumentException("User id is required.");
        }

        await userRepository.UpdateFcmTokenAsync(userId, null);
    }

    public async Task<object> GetCompanyActivationStatusAsync(string email, string? fcmToken = null, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(email))
        {
            throw new ArgumentException("Email is required.");
        }

        var normalizedEmail = email.Trim().ToLowerInvariant();
        var user = await dbContext.Users
            .Include(x => x.CompanyImages)
            .FirstOrDefaultAsync(x => x.Email == normalizedEmail, cancellationToken);
        if (user is null)
        {
            return new
            {
                exists = false,
                isCompanyAccount = false,
                isActivatedByAdmin = false,
                isVerified = false,
                isPendingAdminApproval = false,
                message = "Account not found."
            };
        }

        if (!string.IsNullOrWhiteSpace(fcmToken))
        {
            await userRepository.UpdateFcmTokenAsync(user.Id.ToString(), fcmToken);
        }

        var isSellerAccount = user.RoleId == RoleIds.Seller;
        var isShippingCompanyAccount = user.RoleId == RoleIds.ShippingCompany;
        var requiresAdminApproval = RoleIds.RequiresAdminApproval(user.RoleId);
        var isApproved = !requiresAdminApproval || user.IsApproved;
        var isActivated = requiresAdminApproval && user.IsApproved && user.IsActive;
        var isPendingAdminApproval =
            requiresAdminApproval && user.IsVerified && !user.IsApproved && !user.IsRejected;

        if (isActivated && user.IsVerified)
        {
            return new
            {
                exists = true,
                isCompanyAccount = isSellerAccount,
                isShippingCompanyAccount,
                isApproved,
                isActivatedByAdmin = true,
                isVerified = user.IsVerified,
                isPendingAdminApproval = false,
                message = "Company account is active.",
                Token = tokenService.CreateToken(user),
                Email = user.Email,
                Name = user.FullName,
                ImgPath = user.ImgPath,
                CompanyName = user.CompanyName,
                RoleName = tokenService.GetRoleName(user.RoleId),
                Phone = user.PhoneNumber,
                IsCompanyAccount = isSellerAccount,
                IsShippingCompanyAccount = isShippingCompanyAccount,
                IsCustomer = user.IsCustomer ?? false,
                LicenseNumber = user.LicenseNumber,
                LicencePath = user.LicencePath,
                CompanyImages = user.CompanyImages.Select(x => new
                {
                    x.Id,
                    x.ImagePath,
                    x.IsPrimary
                })
            };
        }

        return new
        {
            exists = true,
            isCompanyAccount = isSellerAccount,
            isShippingCompanyAccount,
            isApproved,
            isActivatedByAdmin = false,
            isVerified = user.IsVerified,
            isPendingAdminApproval,
            message = requiresAdminApproval
                ? (isPendingAdminApproval
                    ? "Your company account has not been approved yet."
                    : "Company account is not verified yet.")
                : "Account is not a company account."
        };
    }

    public async Task<object> GetAccountApprovalStatusAsync(
        string email,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(email))
        {
            throw new ArgumentException("Email is required.");
        }

        var normalizedEmail = email.Trim().ToLowerInvariant();
        var user = await dbContext.Users
            .AsNoTracking()
            .FirstOrDefaultAsync(x => x.Email == normalizedEmail, cancellationToken);

        if (user is null)
        {
            return new
            {
                exists = false,
                isApproved = false,
                isCompanyAccount = false,
                message = "Account not found."
            };
        }

        var isSellerAccount = user.RoleId == RoleIds.Seller;
        var isShippingCompanyAccount = user.RoleId == RoleIds.ShippingCompany;
        var requiresAdminApproval = RoleIds.RequiresAdminApproval(user.RoleId);
        var isApproved = !requiresAdminApproval || user.IsApproved;
        var isPendingAdminApproval =
            requiresAdminApproval && user.IsVerified && !user.IsApproved && !user.IsRejected;

        // When admin approves, return a fresh token so the mobile session is valid.
        string? token = null;
        if (requiresAdminApproval && isApproved && user.IsVerified && !user.IsRejected && user.IsActive)
        {
            token = tokenService.CreateToken(user);
        }

        return new
        {
            exists = true,
            email = user.Email,
            id = user.Id,
            name = user.FullName,
            phone = user.PhoneNumber,
            roleName = tokenService.GetRoleName(user.RoleId),
            isCompanyAccount = isSellerAccount,
            isShippingCompanyAccount,
            isApproved,
            isVerified = user.IsVerified,
            isRejected = user.IsRejected,
            rejectionReason = user.RejectionReason,
            isPendingAdminApproval,
            isCustomer = user.IsCustomer ?? false,
            token,
            message = user.IsRejected
                ? "Account registration was rejected."
                : isApproved
                    ? "Account is approved."
                    : requiresAdminApproval
                        ? "Account is pending admin approval."
                        : "Account is not approved."
        };
    }

    public async Task SendEmailOtpAsync(string email, CancellationToken cancellationToken = default)
    {
        var user = await userRepository.GetByEmailAsync(email.Trim().ToLowerInvariant());
        if (user is null)
        {
            throw new KeyNotFoundException("No account found for this email.");
        }

        using var scope = scopeFactory.CreateScope();
        var scopedOtpService = scope.ServiceProvider.GetRequiredService<IEmailOtpService>();
        await scopedOtpService.SendOtpAsync(email, cancellationToken);
    }

    public async Task<OtpVerificationStatus> VerifyEmailOtpAsync(string email, string otp, CancellationToken cancellationToken = default)
    {
        using var scope = scopeFactory.CreateScope();
        var scopedOtpService = scope.ServiceProvider.GetRequiredService<IEmailOtpService>();
        return await scopedOtpService.VerifyOtpAsync(email, otp, cancellationToken);
    }

    public async Task<object> VerifyEmailOtpAndLoginAsync(string email, string otp, string? fcmToken = null, CancellationToken cancellationToken = default)
    {
        var status = await VerifyEmailOtpAsync(email, otp, cancellationToken);
        if (status == OtpVerificationStatus.Expired)
        {
            throw new ArgumentException("OTP expired.");
        }

        if (status == OtpVerificationStatus.Invalid)
        {
            throw new ArgumentException("Invalid OTP.");
        }

        var normalizedEmail = email.Trim().ToLowerInvariant();
        var user = await dbContext.Users
            .Include(x => x.CompanyImages)
            .FirstOrDefaultAsync(x => x.Email == normalizedEmail, cancellationToken)
            ?? throw new KeyNotFoundException("User not found.");

        if (!string.IsNullOrWhiteSpace(fcmToken))
        {
            await userRepository.UpdateFcmTokenAsync(user.Id.ToString(), fcmToken);
            user.FcmToken = fcmToken;
        }

        var isCompanyAccount = user.RoleId == RoleIds.Seller;
        var isShippingCompanyAccount = user.RoleId == RoleIds.ShippingCompany;
        var requiresAdminApproval = RoleIds.RequiresAdminApproval(user.RoleId);
        var isPendingAdminApproval =
            requiresAdminApproval && !user.IsApproved && !user.IsRejected;

        if (isPendingAdminApproval)
        {
            // Email is verified, but do NOT issue an API token until admin approves.
            return new
            {
                Message = "Email verified. Your company account is pending admin approval.",
                Token = (string?)null,
                Id = user.Id,
                Email = user.Email,
                Name = user.FullName,
                ImgPath = user.ImgPath,
                CompanyName = user.CompanyName,
                RoleName = tokenService.GetRoleName(user.RoleId),
                Phone = user.PhoneNumber,
                IsCompanyAccount = isCompanyAccount,
                IsShippingCompanyAccount = isShippingCompanyAccount,
                IsApproved = false,
                IsPendingAdminApproval = true,
                IsVerified = true,
                IsCustomer = user.IsCustomer ?? false,
                LicenseNumber = user.LicenseNumber,
                LicencePath = user.LicencePath,
                CompanyImages = user.CompanyImages.Select(x => new
                {
                    x.Id,
                    x.ImagePath,
                    x.IsPrimary
                })
            };
        }

        LoginAccessHelper.EnsureCanAuthenticate(user);

        return new
        {
            Message = "Email verified successfully.",
            Token = tokenService.CreateToken(user),
            Id = user.Id,
            Email = user.Email,
            Name = user.FullName,
            ImgPath = user.ImgPath,
            CompanyName = user.CompanyName,
            RoleName = tokenService.GetRoleName(user.RoleId),
            Phone = user.PhoneNumber,
            IsCompanyAccount = isCompanyAccount,
            IsShippingCompanyAccount = isShippingCompanyAccount,
            IsApproved = !requiresAdminApproval || user.IsApproved,
            IsPendingAdminApproval = false,
            IsVerified = true,
            IsCustomer = user.IsCustomer ?? false,
            LicenseNumber = user.LicenseNumber,
            LicencePath = user.LicencePath,
            CompanyImages = user.CompanyImages.Select(x => new
            {
                x.Id,
                x.ImagePath,
                x.IsPrimary
            })
        };
    }

    public async Task<string> ChangePasswordAsync(string userId, string currentPassword, string newPassword, CancellationToken cancellationToken = default)
    {
        if (!Guid.TryParse(userId, out var parsedUserId))
        {
            throw new ArgumentException("Invalid user id.");
        }

        if (string.IsNullOrWhiteSpace(newPassword))
        {
            throw new ArgumentException("New password is required.");
        }

        var user = await dbContext.Users.FindAsync([parsedUserId], cancellationToken)
            ?? throw new KeyNotFoundException("User not found.");

        // Google/Apple accounts are created without a password hash, so the first
        // password they set has no current password to verify against.
        if (!string.IsNullOrWhiteSpace(user.HashedPassword))
        {
            if (string.IsNullOrWhiteSpace(currentPassword)
                || !passwordHasher.VerifyPassword(currentPassword, user.HashedPassword))
            {
                throw new UnauthorizedAccessException("Current password is incorrect.");
            }
        }

        user.HashedPassword = passwordHasher.HashPassword(newPassword);
        await dbContext.SaveChangesAsync(cancellationToken);
        return "Password changed successfully.";
    }

    public async Task VerifyPasswordAsync(string userId, string password, CancellationToken cancellationToken = default)
    {
        if (!Guid.TryParse(userId, out var parsedUserId))
        {
            throw new ArgumentException("Invalid user id.");
        }

        if (string.IsNullOrWhiteSpace(password))
        {
            throw new ArgumentException("Password is required.");
        }

        var user = await dbContext.Users.AsNoTracking()
            .FirstOrDefaultAsync(x => x.Id == parsedUserId, cancellationToken)
            ?? throw new KeyNotFoundException("User not found.");

        if (string.IsNullOrWhiteSpace(user.HashedPassword))
        {
            throw new InvalidOperationException(
                "This account has no password. Use biometric unlock, or set a password first from Change Password.");
        }

        if (!passwordHasher.VerifyPassword(password, user.HashedPassword))
        {
            throw new UnauthorizedAccessException("Password is incorrect.");
        }
    }

    public async Task<string> ForgotPasswordRequestAsync(string providerName, string destination, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(providerName) || string.IsNullOrWhiteSpace(destination))
        {
            throw new ArgumentException("ProviderName and destination are required.");
        }

        var provider = passwordResetNotifierFactory.GetProvider(providerName);

        User? user;
        if (string.Equals(provider.ProviderName, "Email", StringComparison.OrdinalIgnoreCase))
        {
            user = await dbContext.Users.FirstOrDefaultAsync(x => x.Email == destination, cancellationToken);
        }
        else
        {
            user = await dbContext.Users.FirstOrDefaultAsync(x => x.PhoneNumber == destination, cancellationToken);
        }

        if (user is null)
        {
            throw new KeyNotFoundException("User not found for provided destination.");
        }

        var code = Random.Shared.Next(100000, 999999).ToString();
        await dbContext.PasswordResetCodes.AddAsync(new PasswordResetCode
        {
            UserId = user.Id,
            ProviderName = provider.ProviderName,
            Destination = destination,
            Code = code,
            ExpiresAt = DateTime.UtcNow.AddMinutes(10),
            IsUsed = false
        }, cancellationToken);
        await dbContext.SaveChangesAsync(cancellationToken);

        await provider.SendCodeAsync(user, destination, code, cancellationToken);
        return "Password reset code sent successfully.";
    }

    public async Task<string> ForgotPasswordResetAsync(string providerName, string destination, string code, string newPassword, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(providerName) || string.IsNullOrWhiteSpace(destination) || string.IsNullOrWhiteSpace(code) || string.IsNullOrWhiteSpace(newPassword))
        {
            throw new ArgumentException("ProviderName, destination, code and new password are required.");
        }

        var row = await dbContext.PasswordResetCodes
            .Where(x => x.ProviderName == providerName && x.Destination == destination && x.Code == code && !x.IsUsed)
            .OrderByDescending(x => x.Id)
            .FirstOrDefaultAsync(cancellationToken)
            ?? throw new UnauthorizedAccessException("Invalid reset code.");

        if (row.ExpiresAt < DateTime.UtcNow)
        {
            throw new UnauthorizedAccessException("Reset code expired.");
        }

        var user = await dbContext.Users.FindAsync([row.UserId], cancellationToken)
            ?? throw new KeyNotFoundException("User not found.");

        user.HashedPassword = passwordHasher.HashPassword(newPassword);
        row.IsUsed = true;
        await dbContext.SaveChangesAsync(cancellationToken);
        return "Password reset successfully.";
    }

    private static string NormalizeAndValidateEmail(string email)
    {
        var normalized = email.Trim().ToLowerInvariant();
        try
        {
            var address = new MailAddress(normalized);
            if (!string.Equals(address.Address, normalized, StringComparison.OrdinalIgnoreCase)
                || address.Host.IndexOf('.') < 0
                || address.User.Length == 0)
            {
                throw new ArgumentException("Invalid email address.");
            }
        }
        catch (FormatException)
        {
            throw new ArgumentException("Invalid email address.");
        }

        return normalized;
    }

    /// <summary>Optional website; empty → null. Adds https:// when scheme is missing.</summary>
    private static string? NormalizeOptionalWebsite(string? website)
    {
        if (string.IsNullOrWhiteSpace(website))
        {
            return null;
        }

        var trimmed = website.Trim();
        if (trimmed is "https://" or "http://")
        {
            return null;
        }

        if (!trimmed.StartsWith("http://", StringComparison.OrdinalIgnoreCase)
            && !trimmed.StartsWith("https://", StringComparison.OrdinalIgnoreCase))
        {
            trimmed = "https://" + trimmed;
        }

        if (trimmed.Length > 500)
        {
            throw new ArgumentException("Website must be at most 500 characters.");
        }

        return trimmed;
    }

    private async Task SendRegistrationOtpOrRollbackAsync(
        Guid userId,
        string email,
        CancellationToken cancellationToken)
    {
        try
        {
            await emailOtpService.SendOtpAsync(email, cancellationToken);
        }
        catch (ArgumentException)
        {
            await RollbackFailedRegistrationAsync(userId, email, cancellationToken);
            throw;
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Failed to send register OTP for email {Email}", email);
            await RollbackFailedRegistrationAsync(userId, email, cancellationToken);
            throw new ArgumentException(
                "Failed to send verification email. Please check the email address and try again.");
        }
    }

    private async Task RollbackFailedRegistrationAsync(
        Guid userId,
        string email,
        CancellationToken cancellationToken)
    {
        var normalizedEmail = email.Trim().ToLowerInvariant();

        var companyImages = await dbContext.CompanyImages
            .Where(x => x.UserId == userId)
            .ToListAsync(cancellationToken);
        if (companyImages.Count > 0)
        {
            dbContext.CompanyImages.RemoveRange(companyImages);
        }

        var otps = await dbContext.EmailOtps
            .Where(x => x.Email == normalizedEmail)
            .ToListAsync(cancellationToken);
        if (otps.Count > 0)
        {
            dbContext.EmailOtps.RemoveRange(otps);
        }

        var user = await dbContext.Users.FirstOrDefaultAsync(x => x.Id == userId, cancellationToken);
        if (user is not null)
        {
            dbContext.Users.Remove(user);
        }

        await dbContext.SaveChangesAsync(cancellationToken);
    }

    private async Task EnsureEmailAvailableForRegistrationAsync(
        string email,
        bool allowReplacingRejectedCompanyRegistration,
        CancellationToken cancellationToken)
    {
        var existing = await userRepository.GetByEmailAsync(email);
        if (existing is null)
        {
            return;
        }

        if (allowReplacingRejectedCompanyRegistration
            && existing.RoleId != RoleIds.Admin
            && !existing.IsApproved
            && RoleIds.RequiresAdminApproval(existing.RoleId)
            && (existing.IsRejected || !existing.IsActive))
        {
            await accountDeletionAppService.DeleteUserByAdminAsync(
                existing.Id.ToString(),
                cancellationToken);
            return;
        }

        throw new InvalidOperationException("Email already exists.");
    }
}
