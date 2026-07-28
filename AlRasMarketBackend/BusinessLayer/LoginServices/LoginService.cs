using BusinessLayer.Constants;
using BusinessLayer.Factories;
using BusinessLayer.Helpers;
using BusinessLayer.Interfaces;
using BusinessLayer.Services;
using DataLayer.Interfaces;
using DataLayer.Models;

namespace BusinessLayer.LoginServices;

public class LoginService(
    LoginProviderFactory providerFactory,
    ITokenService tokenService,
    IAdminPermissionService permissionService,
    IUserRepository userRepository,
    ISupplierBalanceService supplierBalanceService) : ILoginService
{
    private readonly LoginProviderFactory _providerFactory = providerFactory;
    private readonly ITokenService _tokenService = tokenService;
    private readonly IAdminPermissionService _permissionService = permissionService;
    private readonly IUserRepository _userRepository = userRepository;

    public async Task<object> LoginAsync(
        string providerName,
        string? email,
        string? password,
        string? token,
        string? fcmToken,
        string? preferredLanguage = null,
        string? fullName = null)
    {
        var provider = _providerFactory.GetProvider(providerName);
        dynamic result = await provider.LoginAsync(email, password, token, fcmToken, fullName);

        User user = result.User ?? throw new InvalidOperationException("Login provider returned invalid result.");

        if (!string.IsNullOrWhiteSpace(preferredLanguage))
        {
            var normalizedLanguage = NotificationMessages.NormalizeLanguage(preferredLanguage);
            if (!string.Equals(user.PreferredLanguage, normalizedLanguage, StringComparison.OrdinalIgnoreCase))
            {
                user.PreferredLanguage = normalizedLanguage;
                await _userRepository.UpdatePreferredLanguageAsync(user.Id, normalizedLanguage);
            }
        }

        LoginAccessHelper.EnsureCanLogin(user);

        IReadOnlyList<string> permissions = [];
        if (_permissionService.IsEmployee(user.RoleId))
        {
            permissions = await _permissionService.GetPermissionKeysAsync(user.Id);
            if (permissions.Count == 0)
            {
                throw new UnauthorizedAccessException(UserMessages.Localize(
                    "Your employee account has no permissions assigned. Contact the administrator.",
                    user.PreferredLanguage));
            }
        }

        var isCompanyAccount = user.RoleId == RoleIds.Seller;
        var isShippingCompanyAccount = user.RoleId == RoleIds.ShippingCompany;
        var isApproved = !RoleIds.RequiresAdminApproval(user.RoleId) || user.IsApproved;
        var authToken = LoginAccessHelper.ShouldIssueToken(user)
            ? _tokenService.CreateToken(user, permissions.Count > 0 ? permissions : null)
            : null;

        decimal? supplierBalance = null;
        if (isCompanyAccount)
        {
            supplierBalance = await supplierBalanceService.GetBalanceAsync(user.Id);
        }

        return new
        {
            Token = authToken,
            Id = user.Id,
            Email = user.Email,
            Name = user.FullName,
            ImgPath = user.ImgPath,
            CompanyName = user.CompanyName,
            RoleName = _tokenService.GetRoleName(user.RoleId),
            Phone = user.PhoneNumber,
            IsCompanyAccount = isCompanyAccount,
            IsShippingCompanyAccount = isShippingCompanyAccount,
            IsApproved = isApproved,
            IsVerified = user.IsVerified,
            IsPendingAdminApproval = RoleIds.RequiresAdminApproval(user.RoleId) && user.IsVerified && !user.IsApproved && !user.IsRejected,
            IsRejected = user.IsRejected,
            RejectionReason = user.RejectionReason,
            IsCustomer = user.IsCustomer ?? false,
            LicenseNumber = user.LicenseNumber,
            LicencePath = user.LicencePath,
            Permissions = permissions,
            Balance = supplierBalance,
            CompanyImages = user.CompanyImages.Select(x => new
            {
                x.Id,
                x.ImagePath,
                x.IsPrimary
            })
        };
    }
}
