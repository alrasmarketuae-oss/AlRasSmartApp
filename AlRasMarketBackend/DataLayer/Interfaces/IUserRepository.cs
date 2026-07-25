using DataLayer.Models;

namespace DataLayer.Interfaces;

public interface IUserRepository
{
    Task<User?> GetByEmailAsync(string email);
    Task<User?> GetByIdAsync(string id);
    Task AddAsync(User user);
    Task UpdateFcmTokenAsync(string userId, string? fcmToken);
    Task MarkGoogleLoginReadyAsync(Guid userId, string? fcmToken);
    Task UpdatePreferredLanguageAsync(Guid userId, string language);
    Task UpdateFullNameAsync(Guid userId, string fullName);
}
