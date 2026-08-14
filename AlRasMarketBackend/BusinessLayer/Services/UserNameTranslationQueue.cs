using BusinessLayer.Interfaces;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;

namespace BusinessLayer.Services;

/// <summary>
/// Fire-and-forget OpenAI name translation on register/login without blocking auth.
/// </summary>
public class UserNameTranslationQueue(
    IServiceScopeFactory scopeFactory,
    ILogger<UserNameTranslationQueue> logger)
{
    public void Enqueue(
        Guid userId,
        string? fullName,
        string? companyName = null,
        string? preferredLanguageHint = null)
    {
        if (string.IsNullOrWhiteSpace(fullName) && string.IsNullOrWhiteSpace(companyName))
        {
            return;
        }

        _ = Task.Run(async () =>
        {
            try
            {
                using var scope = scopeFactory.CreateScope();
                var translation = scope.ServiceProvider.GetRequiredService<IContentTranslationService>();
                await translation.UpsertUserFieldsAsync(
                    userId,
                    fullName,
                    companyName,
                    preferredLanguageHint,
                    CancellationToken.None);
            }
            catch (Exception ex)
            {
                logger.LogWarning(ex, "Failed to translate user name fields for {UserId}", userId);
            }
        });
    }
}
