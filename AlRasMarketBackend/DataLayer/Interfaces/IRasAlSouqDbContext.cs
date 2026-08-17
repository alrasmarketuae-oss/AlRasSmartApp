using DataLayer.Models;
using Microsoft.EntityFrameworkCore;

namespace DataLayer.Interfaces;

public interface IRasAlSouqDbContext
{
    DbSet<User> Users { get; }
    DbSet<Role> Roles { get; }
    DbSet<Product> Products { get; }
    DbSet<Category> Categories { get; }
    DbSet<ProductType> ProductTypes { get; }
    DbSet<RequestType> RequestTypes { get; }
    DbSet<BookingPriceType> BookingPriceTypes { get; }
    DbSet<AddressType> AddressTypes { get; }
    DbSet<Unit> Units { get; }
    DbSet<Order> Orders { get; }
    DbSet<OrderAdminOfferPrice> OrderAdminOfferPrices { get; }
    DbSet<OrderStatus> OrderStatuses { get; }
    DbSet<OrderVideo> OrderVideos { get; }
    DbSet<OrderImage> OrderImages { get; }
    DbSet<OrderStatusHistory> OrderStatusHistories { get; }
    DbSet<OrderCancellationReason> OrderCancellationReasons { get; }
    DbSet<InternationalShippingPost> InternationalShippingPosts { get; }
    DbSet<ShipmentStatus> ShipmentStatuses { get; }
    DbSet<InternationalShipment> InternationalShipments { get; }
    DbSet<Cart> Carts { get; }
    DbSet<CartItem> CartItems { get; }
    DbSet<Country> Countries { get; }
    DbSet<City> Cities { get; }
    DbSet<Port> Ports { get; }
    DbSet<Address> Addresses { get; }
    DbSet<Notification> Notifications { get; }
    DbSet<NotificationType> NotificationTypes { get; }
    DbSet<NotificationRoute> NotificationRoutes { get; }
    DbSet<AdminPushNotification> AdminPushNotifications { get; }
    DbSet<CompanyImage> CompanyImages { get; }
    DbSet<ProductImage> ProductImages { get; }
    DbSet<ProductDocument> ProductDocuments { get; }
    DbSet<ProductVideo> ProductVideos { get; }
    DbSet<HomeBanner> HomeBanners { get; }
    DbSet<EmailOtp> EmailOtps { get; }
    DbSet<PasswordResetCode> PasswordResetCodes { get; }
    DbSet<PendingOrder> PendingOrders { get; }
    DbSet<PendingOrderItem> PendingOrderItems { get; }
    DbSet<PendingPayment> PendingPayments { get; }
    DbSet<SystemSettings> SystemSettings { get; }
    DbSet<ChatMessage> ChatMessages { get; }
    DbSet<ChatUserKey> ChatUserKeys { get; }
    DbSet<UserAdminPermission> UserAdminPermissions { get; }
    DbSet<ChatSupportAssignment> ChatSupportAssignments { get; }
    DbSet<InternalDomesticShippingRate> InternalDomesticShippingRates { get; }
    DbSet<InternalDomesticShippingConfig> InternalDomesticShippingConfigs { get; }
    DbSet<AdminAuditLog> AdminAuditLogs { get; }
    DbSet<MissedProductSearch> MissedProductSearches { get; }
    DbSet<SupportCallbackRequest> SupportCallbackRequests { get; }
    DbSet<UserFeedbackSubmission> UserFeedbackSubmissions { get; }
    DbSet<ClipReferenceImage> ClipReferenceImages { get; }
    DbSet<ContentTranslation> ContentTranslations { get; }
    DbSet<AiKnowledgeIndexState> AiKnowledgeIndexStates { get; }
    DbSet<AiConversation> AiConversations { get; }
    DbSet<AiConversationMessage> AiConversationMessages { get; }
    Task<int> SaveChangesAsync(CancellationToken cancellationToken = default);
}
