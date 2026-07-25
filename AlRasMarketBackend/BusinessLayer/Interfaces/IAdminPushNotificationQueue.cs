namespace BusinessLayer.Interfaces;

public interface IAdminPushNotificationQueue
{
    ValueTask EnqueueAsync(Guid notificationId, CancellationToken cancellationToken = default);
    ValueTask<Guid> DequeueAsync(CancellationToken cancellationToken);
}
