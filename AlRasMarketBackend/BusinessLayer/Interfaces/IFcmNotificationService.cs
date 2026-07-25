namespace BusinessLayer.Interfaces;

public interface IFcmNotificationService
{
    Task SendNotificationAsync(string fcmToken, FcmNotificationPayload payload, CancellationToken ct = default);
}

public sealed class FcmNotificationPayload
{
    public string Title { get; set; } = string.Empty;
    public string Body { get; set; } = string.Empty;
    public string? Type { get; set; }
    public string? RouteId { get; set; }
    public string? ReferenceId { get; set; }
    public Dictionary<string, string>? Data { get; set; }
}
