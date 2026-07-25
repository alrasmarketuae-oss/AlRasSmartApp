using System.Threading.Channels;
using BusinessLayer.Interfaces;

namespace BusinessLayer.Services;

public sealed class AdminPushNotificationQueue : IAdminPushNotificationQueue
{
    private readonly Channel<Guid> _queue = Channel.CreateUnbounded<Guid>(new UnboundedChannelOptions
    {
        SingleReader = true,
        SingleWriter = false
    });

    public ValueTask EnqueueAsync(Guid notificationId, CancellationToken cancellationToken = default)
    {
        if (notificationId == Guid.Empty)
        {
            return ValueTask.CompletedTask;
        }

        return _queue.Writer.WriteAsync(notificationId, cancellationToken);
    }

    public ValueTask<Guid> DequeueAsync(CancellationToken cancellationToken)
    {
        return _queue.Reader.ReadAsync(cancellationToken);
    }
}
