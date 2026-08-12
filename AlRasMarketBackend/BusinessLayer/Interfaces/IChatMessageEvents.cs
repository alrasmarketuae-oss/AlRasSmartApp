namespace BusinessLayer.Interfaces;

public sealed record ChatMessageCreatedEvent(
    ChatMessageDto Message,
    Guid FromUserId,
    Guid ToUserId);

public interface IChatMessageCreatedHandler
{
    Task HandleAsync(ChatMessageCreatedEvent evt, CancellationToken cancellationToken = default);
}

public interface IChatMessageEventPublisher
{
    ValueTask PublishMessageCreatedAsync(
        ChatMessageCreatedEvent evt,
        CancellationToken cancellationToken = default);
}
