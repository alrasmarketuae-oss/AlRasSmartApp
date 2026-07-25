using BusinessLayer.Interfaces;
using DataLayer.Interfaces;
using DataLayer.Models;
using Google.Apis.Auth;
using Microsoft.Extensions.Configuration;

namespace BusinessLayer.LoginProviders;

public class GoogleProvider(IUserRepository userRepository, IConfiguration configuration) : ILoginProvider
{
    private readonly IUserRepository _userRepository = userRepository;
    private readonly string[] _clientIds = (configuration["ExternalAuth:Google:ClientIds"] ?? string.Empty)
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
            throw new ArgumentException("Google token is required.");
        }

        if (_clientIds.Length == 0)
        {
            throw new InvalidOperationException("Google ClientIds are not configured.");
        }

        GoogleJsonWebSignature.Payload payload;
        try
        {
            payload = await GoogleJsonWebSignature.ValidateAsync(token, new GoogleJsonWebSignature.ValidationSettings
            {
                Audience = _clientIds
            });
        }
        catch
        {
            throw new UnauthorizedAccessException("Google token is invalid.");
        }

        var tokenEmail = payload.Email ?? throw new UnauthorizedAccessException("Google token does not contain an email.");
        var user = await _userRepository.GetByEmailAsync(tokenEmail);
        if (user is null)
        {
            user = new User
            {
                Id = Guid.NewGuid(),
                FullName = payload.Name ?? tokenEmail.Split('@')[0],
                Email = tokenEmail,
                RoleId = 3,
                LoginProviderName = "Google",
                IsActive = true,
                IsVerified = true,
                FcmToken = fcmToken,
                PreferredLanguage = "en"
            };
            await _userRepository.AddAsync(user);
        }
        else
        {
            await _userRepository.MarkGoogleLoginReadyAsync(user.Id, fcmToken);
            user.IsVerified = true;
            user.IsActive = true;
            if (!string.IsNullOrWhiteSpace(fcmToken))
            {
                user.FcmToken = fcmToken;
            }
        }

        return new { User = user };
    }
}
