using DataLayer.Interfaces;
using DataLayer.Models;
using Microsoft.EntityFrameworkCore;

namespace DataLayer.Repositories;

public class UserRepository(IRasAlSouqDbContext dbContext) : IUserRepository
{
    private readonly IRasAlSouqDbContext _dbContext = dbContext;

    public async Task<User?> GetByEmailAsync(string email)
    {
        return await _dbContext.Users
            .Include(x => x.CompanyImages)
            .FirstOrDefaultAsync(x => x.Email == email);
    }

    public async Task<User?> GetByIdAsync(string id)
    {
        if (!Guid.TryParse(id, out var userId))
        {
            return null;
        }

        return await _dbContext.Users
            .Include(x => x.CompanyImages)
            .FirstOrDefaultAsync(x => x.Id == userId);
    }

    public async Task AddAsync(User user)
    {
        await _dbContext.Users.AddAsync(user);
        await _dbContext.SaveChangesAsync();
    }

    public async Task UpdateFcmTokenAsync(string userId, string? fcmToken)
    {
        if (!Guid.TryParse(userId, out var parsedUserId))
        {
            return;
        }

        var user = await _dbContext.Users.FirstOrDefaultAsync(x => x.Id == parsedUserId);
        if (user is null)
        {
            return;
        }

        if (!string.IsNullOrWhiteSpace(fcmToken))
        {
            var normalizedToken = fcmToken.Trim();
            var staleOwners = await _dbContext.Users
                .Where(x => x.Id != parsedUserId && x.FcmToken == normalizedToken)
                .ToListAsync();
            foreach (var staleOwner in staleOwners)
            {
                staleOwner.FcmToken = null;
            }

            user.FcmToken = normalizedToken;
        }
        else
        {
            user.FcmToken = null;
        }

        await _dbContext.SaveChangesAsync();
    }

    public async Task MarkGoogleLoginReadyAsync(Guid userId, string? fcmToken)
    {
        var user = await _dbContext.Users.FirstOrDefaultAsync(x => x.Id == userId);
        if (user is null)
        {
            return;
        }

        // Google confirms the email identity only — never auto-approve or
        // reactivate accounts that still need admin approval / were rejected.
        user.IsVerified = true;
        var requiresApproval = user.RoleId == 2 || user.RoleId == 5;
        if (!user.IsRejected && (!requiresApproval || user.IsApproved))
        {
            user.IsActive = true;
        }

        if (!string.IsNullOrWhiteSpace(fcmToken))
        {
            user.FcmToken = fcmToken;
        }

        await _dbContext.SaveChangesAsync();
    }

    public async Task UpdatePreferredLanguageAsync(Guid userId, string language)
    {
        var user = await _dbContext.Users.FirstOrDefaultAsync(x => x.Id == userId);
        if (user is null)
        {
            return;
        }

        user.PreferredLanguage = language;
        await _dbContext.SaveChangesAsync();
    }

    public async Task UpdateFullNameAsync(Guid userId, string fullName)
    {
        var user = await _dbContext.Users.FirstOrDefaultAsync(x => x.Id == userId);
        if (user is null || string.IsNullOrWhiteSpace(fullName))
        {
            return;
        }

        user.FullName = fullName.Trim();
        await _dbContext.SaveChangesAsync();
    }
}
