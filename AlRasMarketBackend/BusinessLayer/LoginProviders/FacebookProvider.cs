using System.Text.Json;
using BusinessLayer.Interfaces;
using DataLayer.Interfaces;
using DataLayer.Models;

namespace BusinessLayer.LoginProviders;

public class FacebookProvider(IUserRepository userRepository, IHttpClientFactory httpClientFactory) : ILoginProvider
{
    private readonly IUserRepository _userRepository = userRepository;
    private readonly IHttpClientFactory _httpClientFactory = httpClientFactory;

    public async Task<object> LoginAsync(
        string? email,
        string? password,
        string? token,
        string? fcmToken,
        string? fullName = null)
    {
        if (string.IsNullOrWhiteSpace(token))
        {
            throw new ArgumentException("Facebook token is required.");
        }

        var client = _httpClientFactory.CreateClient();
        var url = $"https://graph.facebook.com/me?fields=id,name,email&access_token={Uri.EscapeDataString(token)}";
        var response = await client.GetAsync(url);
        if (!response.IsSuccessStatusCode)
        {
            throw new UnauthorizedAccessException("Facebook token is invalid.");
        }

        var json = await response.Content.ReadAsStringAsync();
        using var doc = JsonDocument.Parse(json);
        var root = doc.RootElement;

        var tokenEmail = root.TryGetProperty("email", out var emailElement)
            ? emailElement.GetString()
            : null;

        if (string.IsNullOrWhiteSpace(tokenEmail))
        {
            throw new UnauthorizedAccessException("Facebook account email is required but not provided by token.");
        }

        var tokenName = root.TryGetProperty("name", out var nameElement)
            ? nameElement.GetString()
            : null;

        var user = await _userRepository.GetByEmailAsync(tokenEmail);
        if (user is null)
        {
            user = new User
            {
                Id = Guid.NewGuid(),
                FullName = string.IsNullOrWhiteSpace(tokenName) ? tokenEmail.Split('@')[0] : tokenName,
                Email = tokenEmail,
                RoleId = 3, // Buyer
                LoginProviderName = "Facebook",
                IsActive = true,
                IsVerified = true,
                FcmToken = fcmToken
            };
            await _userRepository.AddAsync(user);
        }
        else if (!string.IsNullOrWhiteSpace(fcmToken))
        {
            await _userRepository.UpdateFcmTokenAsync(user.Id.ToString(), fcmToken);
        }

        return new { User = user };
    }
}
