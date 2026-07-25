namespace BusinessLayer.Interfaces;

public interface ILoginProvider
{
    Task<object> LoginAsync(
        string? email,
        string? password,
        string? token,
        string? fcmToken,
        string? fullName = null);
}
