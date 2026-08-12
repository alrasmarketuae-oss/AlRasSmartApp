using BusinessLayer.Interfaces;

namespace BusinessLayer.Services;

public sealed class InProcessChatMessageEventPublisher(
    IEnumerable<IChatMessageCreatedHandler> handlers) : IChatMessageEventPublisher
{
    public async ValueTask PublishMessageCreatedAsync(
        ChatMessageCreatedEvent evt,
        CancellationToken cancellationToken = default)
    {
        foreach (var handler in handlers)
        {
            await handler.HandleAsync(evt, cancellationToken).ConfigureAwait(false);
        }
    }
}
