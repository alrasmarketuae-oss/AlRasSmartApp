using System.Security.Claims;
using BusinessLayer.Auth;
using BusinessLayer.Interfaces;
using DataLayer.Interfaces;
using DataLayer.Models;
using Microsoft.Extensions.Configuration;

namespace BusinessLayer.LoginProviders;

public class AppleProvider(
    IUserRepository userRepository,
    IConfiguration configuration,
    IHttpClientFactory httpClientFactory) : ILoginProvider
{
    private readonly IUserRepository _userRepository = userRepository;
    private readonly IHttpClientFactory _httpClientFactory = httpClientFactory;
    private readonly string[] _clientIds = (configuration["ExternalAuth:Apple:ClientIds"] ?? string.Empty)
        .Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries);

    public async Task<object> LoginAsync(
        string? email,
        string? password,
        string? token,
        string? fcmToken,
        string? fullName = null)
    {
        if (string.IsNullOrWhiteSpace(token))
        {
            throw new ArgumentException("Apple token is required.");
        }

        if (_clientIds.Length == 0)
        {
            throw new InvalidOperationException("Apple ClientIds are not configured.");
        }

        var httpClient = _httpClientFactory.CreateClient();
        var principal = await AppleIdentityTokenValidator.ValidateAsync(token, _clientIds, httpClient);
        var tokenEmail = principal.FindFirst("email")?.Value
            ?? principal.FindFirst(ClaimTypes.Email)?.Value
            ?? email;

        if (string.IsNullOrWhiteSpace(tokenEmail))
        {
            throw new UnauthorizedAccessException(
                "Apple did not provide an email. Sign in with Apple again and share your email, or use another login method.");
        }

        var displayName = ResolveDisplayName(fullName, tokenEmail);
        var user = await _userRepository.GetByEmailAsync(tokenEmail);
        if (user is null)
        {
            user = new User
            {
                Id = Guid.NewGuid(),
                FullName = displayName,
                Email = tokenEmail,
                RoleId = 3,
                LoginProviderName = "Apple",
                IsActive = true,
                IsVerified = true,
                FcmToken = fcmToken,
                PreferredLanguage = "en"
            };
            await _userRepository.AddAsync(user);
        }
        else
        {
            if (!string.IsNullOrWhiteSpace(fullName) &&
                (string.IsNullOrWhiteSpace(user.FullName) ||
                 string.Equals(user.FullName, tokenEmail.Split('@')[0], StringComparison.OrdinalIgnoreCase)))
            {
                await _userRepository.UpdateFullNameAsync(user.Id, displayName);
                user.FullName = displayName;
            }

            if (!string.IsNullOrWhiteSpace(fcmToken))
            {
                await _userRepository.UpdateFcmTokenAsync(user.Id.ToString(), fcmToken);
            }
        }

        return new { User = user };
    }

    private static string ResolveDisplayName(string? fullName, string email)
    {
        if (!string.IsNullOrWhiteSpace(fullName))
        {
            return fullName.Trim();
        }

        return email.Split('@')[0];
    }
}
