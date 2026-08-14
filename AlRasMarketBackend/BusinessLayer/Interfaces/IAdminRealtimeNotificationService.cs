using BusinessLayer.Dtos;
using DataLayer.Models;

namespace BusinessLayer.Interfaces;

public interface IAdminRealtimeNotificationService
{
    Task<AdminLiveCountsDto> GetLiveCountsAsync(CancellationToken cancellationToken = default);

    Task NotifyNewUserAsync(User user, CancellationToken cancellationToken = default);

    Task NotifyProfileEditAsync(User user, CancellationToken cancellationToken = default);

    Task NotifyNewProductAsync(Product product, CancellationToken cancellationToken = default);

    Task NotifyProductEditAsync(Product product, CancellationToken cancellationToken = default);

    Task NotifyNewOrderAsync(Order order, CancellationToken cancellationToken = default);

    Task NotifyNewShippingPostAsync(
        InternationalShippingPost post,
        string? displayName,
        string? providerUserId,
        CancellationToken cancellationToken = default);

    Task NotifyAdminChatMessageAsync(
        string recipientUserId,
        string senderUserId,
        CancellationToken cancellationToken = default);

    Task NotifySupportCallbackAsync(
        SupportCallbackRequest request,
        CancellationToken cancellationToken = default);

    Task NotifyUserFeedbackAsync(
        UserFeedbackSubmission submission,
        CancellationToken cancellationToken = default);

    Task BroadcastCountsAsync(CancellationToken cancellationToken = default);
}
