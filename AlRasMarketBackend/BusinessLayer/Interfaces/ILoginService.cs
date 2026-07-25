namespace BusinessLayer.Interfaces;

public interface ILoginService
{
    Task<object> LoginAsync(
        string providerName,
        string? email,
        string? password,
        string? token,
        string? fcmToken,
        string? preferredLanguage = null,
        string? fullName = null);
}
