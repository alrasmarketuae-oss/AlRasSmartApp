using BusinessLayer.Helpers;
using BusinessLayer.Interfaces;
using DataLayer.Interfaces;

namespace BusinessLayer.LoginProviders;

public class LocalProvider(IUserRepository userRepository, IPasswordHasher passwordHasher) : ILoginProvider
{
    private readonly IUserRepository _userRepository = userRepository;
    private readonly IPasswordHasher _passwordHasher = passwordHasher;

    public async Task<object> LoginAsync(
        string? email,
        string? password,
        string? token,
        string? fcmToken,
        string? fullName = null)
    {
        if (string.IsNullOrWhiteSpace(email) || string.IsNullOrWhiteSpace(password))
        {
            throw new ArgumentException("Email and password are required for local login.");
        }

        var user = await _userRepository.GetByEmailAsync(email);
        if (user is null)
        {
            throw new UnauthorizedAccessException("Invalid credentials.");
        }

        if (string.IsNullOrWhiteSpace(user.HashedPassword) || !_passwordHasher.VerifyPassword(password, user.HashedPassword))
        {
            throw new UnauthorizedAccessException(UserMessages.Localize("Invalid credentials.", user.PreferredLanguage));
        }

        if (!string.IsNullOrWhiteSpace(fcmToken))
        {
            await _userRepository.UpdateFcmTokenAsync(user.Id.ToString(), fcmToken);
        }

        return new { User = user };
    }
}
