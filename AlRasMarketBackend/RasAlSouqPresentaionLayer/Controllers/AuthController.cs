using BusinessLayer.Interfaces;
using BusinessLayer.LoginServices.Dtos;
using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace RasAlSouqPresentaionLayer.Controllers;

/// <summary>
/// Authentication, registration, and email OTP endpoints.
/// </summary>
[Route("api/[controller]")]
[ApiController]
public class AuthController(
    IAuthAppService authAppService,
    IAccountDeletionAppService accountDeletionAppService) : ControllerBase
{
    private readonly IAuthAppService _authAppService = authAppService;
    private readonly IAccountDeletionAppService _accountDeletionAppService = accountDeletionAppService;

    /// <summary>
    /// Registers a buyer account using email and password.
    /// </summary>
    /// <param name="request">Buyer registration payload.</param>
    /// <returns>Created user id and status message.</returns>
    [HttpPost("register-person")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    public async Task<IActionResult> RegisterPerson([FromBody] RegisterPersonRequest request)
    {
        try
        {
            var result = await _authAppService.RegisterPersonAsync(new BusinessLayer.Dtos.RegisterPersonInput
            {
                FullName = request.FullName,
                Email = request.Email,
                Password = request.Password,
                PhoneNumber = request.PhoneNumber,
                FcmToken = request.FcmToken,
                PreferredLanguage = request.PreferredLanguage
            });
            return Ok(new { message = result.message, userId = result.userId, imgPath = result.imgPath });
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (InvalidOperationException ex)
        {
            return Conflict(new { message = ex.Message });
        }
    }

    /// <summary>
    /// Registers a company account (seller) pending admin approval.
    /// </summary>
    /// <param name="request">Company registration payload including licence and optional image paths.</param>
    /// <returns>Created user id and pending-approval message.</returns>
    [HttpPost("register-company")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    public async Task<IActionResult> RegisterCompany([FromBody] RegisterCompanyRequest request)
    {
        try
        {
            var result = await _authAppService.RegisterCompanyAsync(new BusinessLayer.Dtos.RegisterCompanyInput
            {
                FullName = request.FullName,
                CompanyName = request.CompanyName,
                Email = request.Email,
                Password = request.Password,
                PhoneNumber = request.PhoneNumber,
                LandNumber = request.LandNumber,
                LicenseNumber = request.LicenseNumber,
                FcmToken = request.FcmToken,
                LicencePath = request.LicencePath??null,
                CompanyImagePaths = request.CompanyImagePaths??null,
                BirthDate = request.BirthDate,
                CommercialRegister = request.CommercialRegister,
                TaxNumber = request.TaxNumber,
                Website = request.Website,
                IsCustomer = request.IsCustomer,
                PreferredLanguage = request.PreferredLanguage
            });
            return Ok(new { message = result.message, userId = result.userId, imgPath = result.imgPath, isCustomer = result.isCustomer });
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (InvalidOperationException ex)
        {
            return Conflict(new { message = ex.Message });
        }
    }

    /// <summary>
    /// Registers a shipping company account pending admin approval.
    /// </summary>
    [HttpPost("register-shipping-company")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    public async Task<IActionResult> RegisterShippingCompany([FromBody] RegisterShippingCompanyRequest request)
    {
        try
        {
            var result = await _authAppService.RegisterShippingCompanyAsync(new BusinessLayer.Dtos.RegisterShippingCompanyInput
            {
                CompanyName = request.CompanyName,
                Email = request.Email,
                Password = request.Password,
                PhoneNumber = request.PhoneNumber,
                LandNumber = request.LandNumber,
                CommercialRegister = request.CommercialRegister,
                TaxNumber = request.TaxNumber,
                Website = request.Website,
                FcmToken = request.FcmToken,
                PreferredLanguage = request.PreferredLanguage
            });
            return Ok(new { message = result.message, userId = result.userId, imgPath = result.imgPath });
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (InvalidOperationException ex)
        {
            return Conflict(new { message = ex.Message });
        }
    }

    /// <summary>
    /// Authenticates user via Local, Google, Apple, or Facebook provider.
    /// </summary>
    /// <param name="request">Login payload with provider-specific fields and optional FCM token.</param>
    /// <param name="cancellationToken">Cancellation token.</param>
    /// <returns>JWT token and basic profile details.</returns>
    [HttpPost("login")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> Login([FromBody] LoginDtos.LoginRequest request, CancellationToken cancellationToken)
    {
        if (request is null || string.IsNullOrWhiteSpace(request.LoginProviderName))
        {
            return BadRequest(new { message = "LoginProviderName is required." });
        }

        try
        {
            var result = await _authAppService.LoginAsync(request, cancellationToken);
            return Ok(result);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (UnauthorizedAccessException ex)
        {
            return Unauthorized(new { message = ex.Message });
        }
    }

    /// <summary>
    /// Registers the device FCM token for the authenticated user. The app calls this after
    /// every login and whenever Firebase rotates the token.
    /// </summary>
    [HttpPost("fcm-token")]
    [Authorize]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> UpdateFcmToken(
        [FromBody] UpdateFcmTokenRequest request,
        CancellationToken cancellationToken = default)
    {
        var userId = User.FindFirst("EntityId")?.Value ?? User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrWhiteSpace(userId))
        {
            return Unauthorized(new { message = "Invalid token." });
        }

        try
        {
            await _authAppService.UpdateFcmTokenAsync(userId, request.FcmToken, cancellationToken);
            return Ok(new { message = "FCM token updated." });
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    /// <summary>
    /// Clears the authenticated user's FCM token on logout (same device, different accounts).
    /// </summary>
    [HttpPost("clear-fcm-token")]
    [Authorize]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> ClearFcmToken(CancellationToken cancellationToken = default)
    {
        var userId = User.FindFirst("EntityId")?.Value ?? User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrWhiteSpace(userId))
        {
            return Unauthorized(new { message = "Invalid token." });
        }

        await _authAppService.ClearFcmTokenAsync(userId, cancellationToken);
        return Ok(new { message = "FCM token cleared." });
    }

    /// <summary>
    /// Checks whether an account has been approved by admin (Flutter polling).
    /// </summary>
    /// <param name="email">Account email.</param>
    /// <param name="cancellationToken">Cancellation token.</param>
    /// <returns>Approval status payload.</returns>
    [HttpGet("account-approval-status")]
    [AllowAnonymous]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> AccountApprovalStatus(
        [FromQuery] string email,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(email))
        {
            return BadRequest(new { message = "Email is required." });
        }

        try
        {
            var result = await _authAppService.GetAccountApprovalStatusAsync(email, cancellationToken);
            return Ok(result);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    /// <summary>
    /// Checks whether a company account has been activated by admin.
    /// </summary>
    /// <param name="email">Company account email.</param>
    /// <param name="cancellationToken">Cancellation token.</param>
    /// <returns>Activation status payload.</returns>
    [HttpGet("company-activation-status")]
    [AllowAnonymous]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> CompanyActivationStatus(
        [FromQuery] string email,
        [FromQuery] string? fcmToken = null,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(email))
        {
            return BadRequest(new { message = "Email is required." });
        }

        try
        {
            var result = await _authAppService.GetCompanyActivationStatusAsync(email, fcmToken, cancellationToken);
            return Ok(result);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }



    /// <summary>
    /// Sends an OTP code to the given email.
    /// </summary>
    /// <param name="request">Target email payload.</param>
    /// <param name="cancellationToken">Cancellation token.</param>
    /// <returns>Operation status message.</returns>
    [HttpPost("send-email-otp")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> SendEmailOtp([FromBody] SendEmailOtpRequest request, CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(request.Email))
        {
            return BadRequest(new { message = "Email is required." });
        }

        try
        {
            await _authAppService.SendEmailOtpAsync(request.Email, cancellationToken);
            return Ok(new { message = "OTP sent successfully." });
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
    }

    /// <summary>
    /// Verifies the submitted OTP for the given email.
    /// </summary>
    /// <param name="request">Email and OTP payload.</param>
    /// <param name="cancellationToken">Cancellation token.</param>
    /// <returns>Verification result message.</returns>
    [HttpPost("verify-email-otp")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> VerifyEmailOtp([FromBody] VerifyEmailOtpRequest request, CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(request.Email) || string.IsNullOrWhiteSpace(request.Otp))
        {
            return BadRequest(new { message = "Email and OTP are required." });
        }

        try
        {
            var result = await _authAppService.VerifyEmailOtpAndLoginAsync(
                request.Email,
                request.Otp,
                request.FcmToken,
                cancellationToken);
            return Ok(result);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (UnauthorizedAccessException ex)
        {
            return Unauthorized(new { message = ex.Message });
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
    }

    /// <summary>
    /// Changes account password using current password.
    /// </summary>
    /// <param name="request">Current and new password payload.</param>
    /// <param name="cancellationToken">Cancellation token.</param>
    /// <returns>Operation status message.</returns>
    [HttpPost("change-password")]
    [Authorize]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> ChangePassword([FromBody] ChangePasswordRequest request, CancellationToken cancellationToken)
    {
        var userId = User.FindFirst("EntityId")?.Value ?? User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrWhiteSpace(userId))
        {
            return Unauthorized(new { message = "Invalid token." });
        }

        try
        {
            var message = await _authAppService.ChangePasswordAsync(userId, request.CurrentPassword, request.NewPassword, cancellationToken);
            return Ok(new { message });
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (UnauthorizedAccessException ex)
        {
            return Unauthorized(new { message = ex.Message });
        }
    }

    /// <summary>
    /// Verifies the current password for sensitive in-app gates. Does not issue a new token.
    /// </summary>
    [HttpPost("verify-password")]
    [Authorize]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> VerifyPassword(
        [FromBody] VerifyPasswordRequest request,
        CancellationToken cancellationToken)
    {
        var userId = User.FindFirst("EntityId")?.Value ?? User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrWhiteSpace(userId))
        {
            return Unauthorized(new { message = "Invalid token." });
        }

        try
        {
            await _authAppService.VerifyPasswordAsync(userId, request.Password, cancellationToken);
            return Ok(new { ok = true });
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (UnauthorizedAccessException ex)
        {
            return Unauthorized(new { message = ex.Message });
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
    }

    /// <summary>
    /// Permanently deletes the authenticated user's account and all related data.
    /// </summary>
    [HttpPost("delete-account")]
    [Authorize]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> DeleteAccount(
        [FromBody] DeleteAccountRequest request,
        CancellationToken cancellationToken)
    {
        var userId = User.FindFirst("EntityId")?.Value ?? User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrWhiteSpace(userId))
        {
            return Unauthorized(new { message = "Invalid token." });
        }

        try
        {
            var message = await _accountDeletionAppService.DeleteAccountAsync(
                userId,
                request.Password,
                cancellationToken);
            return Ok(new { message });
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (UnauthorizedAccessException ex)
        {
            return Unauthorized(new { message = ex.Message });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
        catch (Exception ex)
        {
            return StatusCode(StatusCodes.Status500InternalServerError, new
            {
                message = "Could not delete account. Please try again or contact support.",
                detail = ex.Message
            });
        }
    }

    /// <summary>
    /// Sends password reset code using selected provider (Email or Phone).
    /// </summary>
    /// <param name="request">Provider and destination payload.</param>
    /// <param name="cancellationToken">Cancellation token.</param>
    /// <returns>Operation status message.</returns>
    [HttpPost("forgot-password/request")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> ForgotPasswordRequest([FromBody] ForgotPasswordRequest request, CancellationToken cancellationToken)
    {
        try
        {
            var message = await _authAppService.ForgotPasswordRequestAsync(request.ProviderName, request.Destination, cancellationToken);
            return Ok(new { message });
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    /// <summary>
    /// Resets password using verification code sent by forgot-password request endpoint.
    /// </summary>
    /// <param name="request">Provider, destination, code, and new password payload.</param>
    /// <param name="cancellationToken">Cancellation token.</param>
    /// <returns>Operation status message.</returns>
    [HttpPost("forgot-password/reset")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> ForgotPasswordReset([FromBody] ForgotPasswordResetRequest request, CancellationToken cancellationToken)
    {
        try
        {
            var message = await _authAppService.ForgotPasswordResetAsync(request.ProviderName, request.Destination, request.Code, request.NewPassword, cancellationToken);
            return Ok(new { message });
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (UnauthorizedAccessException ex)
        {
            return Unauthorized(new { message = ex.Message });
        }
    }
}

/// <summary>
/// Buyer registration request payload.
/// </summary>
public sealed class RegisterPersonRequest
{
    /// <summary>
    /// Full name of the buyer account.
    /// </summary>
    public string FullName { get; set; } = string.Empty;
    /// <summary>
    /// Email address used for login and OTP verification.
    /// </summary>
    public string Email { get; set; } = string.Empty;
    /// <summary>
    /// Plain password (will be hashed server-side).
    /// </summary>
    public string Password { get; set; } = string.Empty;
    /// <summary>
    /// Optional FCM token used for push notifications.
    /// </summary>
    public string? FcmToken { get; set; }
    /// <summary>
    /// Optional phone number.
    /// </summary>
    public string? PhoneNumber { get; set; }
    /// <summary>
    /// App language code: en or ar.
    /// </summary>
    public string? PreferredLanguage { get; set; }
}

/// <summary>
/// Company (seller) registration request payload.
/// </summary>
public sealed class RegisterCompanyRequest
{
    /// <summary>
    /// Company owner full name.
    /// </summary>
    public string FullName { get; set; } = string.Empty;
    /// <summary>
    /// Optional company display name.
    /// </summary>
    public string? CompanyName { get; set; }
    /// <summary>
    /// Company login email.
    /// </summary>
    public string Email { get; set; } = string.Empty;
    /// <summary>
    /// Plain password (will be hashed server-side).
    /// </summary>
    public string Password { get; set; } = string.Empty;
    /// <summary>
    /// Optional phone number.
    /// </summary>
    public string? PhoneNumber { get; set; }
    /// <summary>
    /// Optional landline number.
    /// </summary>
    public string? LandNumber { get; set; }
    /// <summary>
    /// Optional commercial license number.
    /// </summary>
    public string? LicenseNumber { get; set; }
    /// <summary>
    /// Optional FCM token used for push notifications.
    /// </summary>
    public string? FcmToken { get; set; }
    /// <summary>
    /// Licence image/file path.
    /// </summary>
    public string? LicencePath { get; set; } = null;
    /// <summary>
    /// Optional initial company image paths.
    /// </summary>
    public List<string>? CompanyImagePaths { get; set; }
    /// <summary>
    /// Optional birth date.
    /// </summary>
    public DateTime? BirthDate { get; set; }
    /// <summary>
    /// Optional commercial register number.
    /// </summary>
    public string? CommercialRegister { get; set; }
    /// <summary>
    /// Optional tax number.
    /// </summary>
    public string? TaxNumber { get; set; }
    /// <summary>
    /// Optional company website URL.
    /// </summary>
    public string? Website { get; set; }
    /// <summary>
    /// Whether the supplier also acts as a customer (buyer).
    /// </summary>
    public bool? IsCustomer { get; set; }
    /// <summary>
    /// App language code: en or ar.
    /// </summary>
    public string? PreferredLanguage { get; set; }
}

/// <summary>
/// Shipping company registration request payload.
/// </summary>
public sealed class RegisterShippingCompanyRequest
{
    public string CompanyName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string Password { get; set; } = string.Empty;
    public string PhoneNumber { get; set; } = string.Empty;
    public string? LandNumber { get; set; }
    public string? CommercialRegister { get; set; }
    public string? TaxNumber { get; set; }
    public string? Website { get; set; }
    public string? FcmToken { get; set; }
    public string? PreferredLanguage { get; set; }
}

/// <summary>
/// Send email OTP request payload.
/// </summary>
public sealed class SendEmailOtpRequest
{
    /// <summary>
    /// Target account email.
    /// </summary>
    public string Email { get; set; } = string.Empty;
}

/// <summary>
/// Verify OTP request payload.
/// </summary>
public sealed class VerifyEmailOtpRequest
{
    /// <summary>
    /// Target account email.
    /// </summary>
    public string Email { get; set; } = string.Empty;
    /// <summary>
    /// One-time password sent to email.
    /// </summary>
    public string Otp { get; set; } = string.Empty;
    /// <summary>
    /// Optional FCM token used for push notifications.
    /// </summary>
    public string? FcmToken { get; set; }
}

/// <summary>
/// Request body for changing account password.
/// </summary>
public sealed class ChangePasswordRequest
{
    /// <summary>
    /// Current account password. Optional for Google/Apple accounts that never had one.
    /// </summary>
    public string CurrentPassword { get; set; } = string.Empty;
    /// <summary>
    /// New account password.
    /// </summary>
    public string NewPassword { get; set; } = string.Empty;
}

/// <summary>
/// Request body for verifying the current password without changing it.
/// </summary>
public sealed class VerifyPasswordRequest
{
    public string Password { get; set; } = string.Empty;
}

/// <summary>
/// Request body for registering the device push token against the signed-in account.
/// </summary>
public sealed class UpdateFcmTokenRequest
{
    /// <summary>
    /// Firebase Cloud Messaging device token.
    /// </summary>
    public string FcmToken { get; set; } = string.Empty;
}

/// <summary>
/// Request body for permanently deleting the authenticated account.
/// </summary>
public sealed class DeleteAccountRequest
{
    /// <summary>
    /// Current account password used to confirm deletion.
    /// </summary>
    public string Password { get; set; } = string.Empty;
}

/// <summary>
/// Request body for sending forgot-password code.
/// </summary>
public sealed class ForgotPasswordRequest
{
    /// <summary>
    /// Notification provider name. Supported values: Email, Phone.
    /// </summary>
    public string ProviderName { get; set; } = string.Empty;
    /// <summary>
    /// Provider destination value (email address or phone number).
    /// </summary>
    public string Destination { get; set; } = string.Empty;
}

/// <summary>
/// Request body for resetting password using verification code.
/// </summary>
public sealed class ForgotPasswordResetRequest
{
    /// <summary>
    /// Notification provider name. Supported values: Email, Phone.
    /// </summary>
    public string ProviderName { get; set; } = string.Empty;
    /// <summary>
    /// Provider destination value (email address or phone number).
    /// </summary>
    public string Destination { get; set; } = string.Empty;
    /// <summary>
    /// One-time verification code.
    /// </summary>
    public string Code { get; set; } = string.Empty;
    /// <summary>
    /// New account password.
    /// </summary>
    public string NewPassword { get; set; } = string.Empty;
}
