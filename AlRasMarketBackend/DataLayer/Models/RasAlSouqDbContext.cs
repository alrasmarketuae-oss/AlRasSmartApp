using DataLayer.Interfaces;
using DataLayer.Seeding;
using Microsoft.EntityFrameworkCore;

namespace DataLayer.Models;

public class RasAlSouqDbContext(DbContextOptions<RasAlSouqDbContext> options)
    : DbContext(options), IRasAlSouqDbContext
{
    public DbSet<User> Users => Set<User>();
    public DbSet<Role> Roles => Set<Role>();
    public DbSet<Product> Products => Set<Product>();
    public DbSet<Category> Categories => Set<Category>();
    public DbSet<ProductType> ProductTypes => Set<ProductType>();
    public DbSet<RequestType> RequestTypes => Set<RequestType>();
    public DbSet<BookingPriceType> BookingPriceTypes => Set<BookingPriceType>();
    public DbSet<Unit> Units => Set<Unit>();
    public DbSet<Order> Orders => Set<Order>();
    public DbSet<OrderAdminOfferPrice> OrderAdminOfferPrices => Set<OrderAdminOfferPrice>();
    public DbSet<OrderStatus> OrderStatuses => Set<OrderStatus>();
    public DbSet<OrderVideo> OrderVideos => Set<OrderVideo>();
    public DbSet<OrderImage> OrderImages => Set<OrderImage>();
    public DbSet<OrderStatusHistory> OrderStatusHistories => Set<OrderStatusHistory>();
    public DbSet<InternationalShippingPost> InternationalShippingPosts => Set<InternationalShippingPost>();
    public DbSet<ShipmentStatus> ShipmentStatuses => Set<ShipmentStatus>();
    public DbSet<InternationalShipment> InternationalShipments => Set<InternationalShipment>();
    public DbSet<Cart> Carts => Set<Cart>();
    public DbSet<CartItem> CartItems => Set<CartItem>();
    public DbSet<Country> Countries => Set<Country>();
    public DbSet<City> Cities => Set<City>();
    public DbSet<Port> Ports => Set<Port>();
    public DbSet<Address> Addresses => Set<Address>();
    public DbSet<Notification> Notifications => Set<Notification>();
    public DbSet<NotificationType> NotificationTypes => Set<NotificationType>();
    public DbSet<NotificationRoute> NotificationRoutes => Set<NotificationRoute>();
    public DbSet<AdminPushNotification> AdminPushNotifications => Set<AdminPushNotification>();
    public DbSet<CompanyImage> CompanyImages => Set<CompanyImage>();
    public DbSet<ProductImage> ProductImages => Set<ProductImage>();
    public DbSet<ProductDocument> ProductDocuments => Set<ProductDocument>();
    public DbSet<ProductVideo> ProductVideos => Set<ProductVideo>();
    public DbSet<HomeBanner> HomeBanners => Set<HomeBanner>();
    public DbSet<EmailOtp> EmailOtps => Set<EmailOtp>();
    public DbSet<PasswordResetCode> PasswordResetCodes => Set<PasswordResetCode>();
    public DbSet<PendingOrder> PendingOrders => Set<PendingOrder>();
    public DbSet<PendingOrderItem> PendingOrderItems => Set<PendingOrderItem>();
    public DbSet<PendingPayment> PendingPayments => Set<PendingPayment>();
    public DbSet<SystemSettings> SystemSettings => Set<SystemSettings>();
    public DbSet<ChatMessage> ChatMessages => Set<ChatMessage>();
    public DbSet<ChatUserKey> ChatUserKeys => Set<ChatUserKey>();
    public DbSet<UserAdminPermission> UserAdminPermissions => Set<UserAdminPermission>();
    public DbSet<ChatSupportAssignment> ChatSupportAssignments => Set<ChatSupportAssignment>();
    public DbSet<InternalDomesticShippingRate> InternalDomesticShippingRates => Set<InternalDomesticShippingRate>();
    public DbSet<InternalDomesticShippingConfig> InternalDomesticShippingConfigs => Set<InternalDomesticShippingConfig>();
    public DbSet<AdminAuditLog> AdminAuditLogs => Set<AdminAuditLog>();
    public DbSet<MissedProductSearch> MissedProductSearches => Set<MissedProductSearch>();
    public DbSet<SupportCallbackRequest> SupportCallbackRequests => Set<SupportCallbackRequest>();
    public DbSet<ContentTranslation> ContentTranslations => Set<ContentTranslation>();
    public DbSet<AiKnowledgeIndexState> AiKnowledgeIndexStates => Set<AiKnowledgeIndexState>();
    public DbSet<AiConversation> AiConversations => Set<AiConversation>();
    public DbSet<AiConversationMessage> AiConversationMessages => Set<AiConversationMessage>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<AiKnowledgeIndexState>(entity =>
        {
            entity.ToTable("AiKnowledgeIndexState");
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Id).ValueGeneratedNever();
            entity.Property(x => x.ContentHash).HasMaxLength(64).IsRequired();
            entity.Property(x => x.EmbeddingModel).HasMaxLength(128).IsRequired();
            entity.Property(x => x.ChunkCount);
            entity.Property(x => x.UpdatedAtUtc);
        });

        modelBuilder.Entity<Role>(entity =>
        {
            entity.ToTable("Roles");
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Id).ValueGeneratedOnAdd();
            entity.Property(x => x.RoleName).HasMaxLength(255).IsRequired();
            entity.HasData(
                new Role { Id = 1, RoleName = "Admin" },
                new Role { Id = 2, RoleName = "Seller" },
                new Role { Id = 3, RoleName = "Buyer" },
                new Role { Id = 4, RoleName = "Employee" },
                new Role { Id = 5, RoleName = "ShippingCompany" }
            );
        });

        modelBuilder.Entity<User>(entity =>
        {
            entity.ToTable("Users");
            entity.HasKey(x => x.Id);
            entity.HasIndex(x => x.Email).IsUnique();
            entity.HasIndex(x => x.PhoneNumber).HasFilter("[PhoneNumber] IS NOT NULL");
            entity.Property(x => x.FullName).HasMaxLength(250).IsRequired();
            entity.Property(x => x.Email).HasMaxLength(250).IsRequired();
            entity.Property(x => x.HashedPassword).HasMaxLength(250);
            entity.Property(x => x.LoginProviderName).HasMaxLength(250).HasDefaultValue("Local");
            entity.Property(x => x.ImgPath).HasMaxLength(250);
            entity.Property(x => x.LicencePath).HasMaxLength(255);
            entity.Property(x => x.LicenseNumber).HasMaxLength(100).IsUnicode(false);
            entity.Property(x => x.CompanyName).HasMaxLength(250);
            entity.Property(x => x.BirthDate).HasColumnType("date");
            entity.Property(x => x.CommercialRegister).HasMaxLength(100).IsUnicode(false);
            entity.Property(x => x.TaxNumber).HasMaxLength(100).IsUnicode(false);
            entity.Property(x => x.Website).HasMaxLength(500);
            entity.Property(x => x.IsCustomer);
            entity.Property(x => x.IsApproved).HasDefaultValue(false);
            entity.Property(x => x.PendingProfileChanges).HasColumnType("nvarchar(max)");
            entity.Property(x => x.PhoneNumber).HasMaxLength(255).IsUnicode(false);
            entity.Property(x => x.LandNumber).HasMaxLength(255).IsUnicode(false);
            entity.Property(x => x.FcmToken).HasMaxLength(512).IsUnicode(false);
            entity.Property(x => x.PreferredLanguage).HasMaxLength(10).IsUnicode(false).HasDefaultValue("en");
            entity.Property(x => x.CreatedAt).HasColumnType("datetime").HasDefaultValueSql("(getutcdate())").ValueGeneratedOnAdd();
            entity.Property(x => x.LastSeenAtUtc).HasColumnType("datetime");
            entity.HasOne(x => x.Role).WithMany(x => x.Users).HasForeignKey(x => x.RoleId);
        });

        modelBuilder.Entity<UserAdminPermission>(entity =>
        {
            entity.ToTable("UserAdminPermissions");
            entity.HasKey(x => new { x.UserId, x.PermissionKey });
            entity.Property(x => x.PermissionKey).HasMaxLength(64).IsUnicode(false).IsRequired();
            entity.HasOne(x => x.User).WithMany().HasForeignKey(x => x.UserId).OnDelete(DeleteBehavior.Cascade);
            entity.HasIndex(x => x.PermissionKey);
        });

        modelBuilder.Entity<AdminAuditLog>(entity =>
        {
            entity.ToTable("AdminAuditLogs");
            entity.HasKey(x => x.Id);
            entity.Property(x => x.ActorName).HasMaxLength(200).IsRequired();
            entity.Property(x => x.Action).HasMaxLength(80).IsUnicode(false).IsRequired();
            entity.Property(x => x.EntityType).HasMaxLength(50).IsUnicode(false).IsRequired();
            entity.Property(x => x.EntityId).HasMaxLength(64);
            entity.Property(x => x.Summary).HasMaxLength(500).IsRequired();
            entity.Property(x => x.CreatedAtUtc).HasColumnType("datetime2");
            entity.HasOne(x => x.Actor).WithMany().HasForeignKey(x => x.ActorUserId).OnDelete(DeleteBehavior.Restrict);
            entity.HasIndex(x => x.CreatedAtUtc);
            entity.HasIndex(x => new { x.Action, x.CreatedAtUtc });
            entity.HasIndex(x => new { x.EntityType, x.EntityId });
            entity.HasIndex(x => new { x.ActorUserId, x.CreatedAtUtc });
        });

        modelBuilder.Entity<MissedProductSearch>(entity =>
        {
            entity.ToTable("MissedProductSearches");
            entity.HasKey(x => x.Id);
            entity.Property(x => x.QueryText).HasMaxLength(200).IsRequired();
            entity.Property(x => x.UserDisplayName).HasMaxLength(200);
            entity.Property(x => x.UserEmail).HasMaxLength(256);
            entity.Property(x => x.UserPhone).HasMaxLength(50);
            entity.Property(x => x.Notes).HasMaxLength(500);
            entity.Property(x => x.CreatedAtUtc).HasColumnType("datetime2");
            entity.HasOne(x => x.User).WithMany().HasForeignKey(x => x.UserId).OnDelete(DeleteBehavior.SetNull);
            entity.HasIndex(x => x.CreatedAtUtc);
            entity.HasIndex(x => x.QueryText);
            entity.HasIndex(x => new { x.UserId, x.CreatedAtUtc });
        });

        modelBuilder.Entity<SupportCallbackRequest>(entity =>
        {
            entity.ToTable("SupportCallbackRequests");
            entity.HasKey(x => x.Id);
            entity.Property(x => x.FullName).HasMaxLength(200).IsRequired();
            entity.Property(x => x.Phone).HasMaxLength(50).IsRequired();
            entity.Property(x => x.Email).HasMaxLength(256).IsRequired();
            entity.Property(x => x.Question).HasMaxLength(1000);
            entity.Property(x => x.Language).HasMaxLength(10).IsRequired();
            entity.Property(x => x.Status).HasMaxLength(30).IsRequired();
            entity.Property(x => x.Source).HasMaxLength(80);
            entity.Property(x => x.AiConversationId).HasMaxLength(64);
            entity.Property(x => x.AdminNotes).HasMaxLength(500);
            entity.Property(x => x.CreatedAtUtc).HasColumnType("datetime2");
            entity.Property(x => x.ContactedAtUtc).HasColumnType("datetime2");
            entity.HasOne(x => x.User).WithMany().HasForeignKey(x => x.UserId).OnDelete(DeleteBehavior.SetNull);
            entity.HasIndex(x => x.CreatedAtUtc);
            entity.HasIndex(x => new { x.Status, x.CreatedAtUtc });
            entity.HasIndex(x => new { x.UserId, x.CreatedAtUtc });
        });

        modelBuilder.Entity<ContentTranslation>(entity =>
        {
            entity.ToTable("ContentTranslations");
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Scope).HasMaxLength(20).IsRequired();
            entity.Property(x => x.Field).HasMaxLength(40).IsRequired();
            entity.Property(x => x.SourceLanguage).HasMaxLength(5).IsRequired();
            entity.Property(x => x.SourceHash).HasMaxLength(64).IsRequired();
            entity.Property(x => x.UpdatedAtUtc).HasColumnType("datetime2");
            entity.HasOne(x => x.Product).WithMany().HasForeignKey(x => x.ProductId).OnDelete(DeleteBehavior.Cascade);
            // Restrict: SQL Server rejects Cascade (multiple cascade paths via Orders).
            entity.HasOne(x => x.Order).WithMany().HasForeignKey(x => x.OrderId).OnDelete(DeleteBehavior.Restrict);
            entity.HasIndex(x => new { x.ProductId, x.Field })
                .IsUnique()
                .HasFilter("[ProductId] IS NOT NULL");
            entity.HasIndex(x => new { x.OrderId, x.Field })
                .IsUnique()
                .HasFilter("[OrderId] IS NOT NULL");
            entity.HasIndex(x => x.ProductId);
            entity.HasIndex(x => new { x.Scope, x.Field });
        });

        modelBuilder.Entity<ChatSupportAssignment>(entity =>
        {
            entity.ToTable("ChatSupportAssignments");
            entity.HasKey(x => x.Id);
            entity.Property(x => x.AssignedAtUtc).HasColumnType("datetime");
            entity.Property(x => x.ReleasedAtUtc).HasColumnType("datetime");
            entity.HasOne(x => x.CustomerUser).WithMany().HasForeignKey(x => x.CustomerUserId).OnDelete(DeleteBehavior.Restrict);
            entity.HasOne(x => x.AgentUser).WithMany().HasForeignKey(x => x.AgentUserId).OnDelete(DeleteBehavior.Restrict);
            entity.HasIndex(x => x.CustomerUserId).HasFilter("[ReleasedAtUtc] IS NULL");
            entity.HasIndex(x => x.AgentUserId).HasFilter("[ReleasedAtUtc] IS NULL");
        });

        modelBuilder.Entity<ChatUserKey>(entity =>
        {
            entity.ToTable("ChatUserKeys");
            entity.HasKey(x => x.UserId);
            entity.Property(x => x.PublicKeySpkiBase64).IsRequired();
            entity.Property(x => x.SupportPrivateKeyPkcs8Base64);
            entity.Property(x => x.UpdatedAtUtc).HasColumnType("datetime");
            entity.HasOne(x => x.User).WithMany().HasForeignKey(x => x.UserId).OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<ChatMessage>(entity =>
        {
            entity.ToTable("ChatMessages");
            entity.HasKey(x => x.MessageId);
            entity.Property(x => x.MessageId).HasMaxLength(32).IsUnicode(false).IsRequired();
            entity.Property(x => x.MessageType).HasColumnType("tinyint");
            entity.Property(x => x.Content).IsRequired();
            entity.Property(x => x.SentAtUtc).HasColumnType("datetime");
            entity.Property(x => x.EditedAtUtc).HasColumnType("datetime");
            entity.Property(x => x.SeenAtUtc).HasColumnType("datetime");
            entity.Property(x => x.IsDelivered).HasDefaultValue(false);
            entity.Property(x => x.DeliveredAtUtc).HasColumnType("datetime");
            entity.HasOne(x => x.FromUser).WithMany().HasForeignKey(x => x.FromUserId).OnDelete(DeleteBehavior.Restrict);
            entity.HasOne(x => x.ToUser).WithMany().HasForeignKey(x => x.ToUserId).OnDelete(DeleteBehavior.Restrict);
            entity.HasIndex(x => x.FromUserId);
            entity.HasIndex(x => x.ToUserId);
            entity.HasIndex(x => x.SentAtUtc);
            entity.HasIndex(x => new { x.FromUserId, x.ToUserId, x.SentAtUtc });
            entity.HasIndex(x => new { x.ToUserId, x.FromUserId, x.SentAtUtc });
            entity.HasIndex(x => new { x.ToUserId, x.IsSeen, x.SentAtUtc });
        });

        modelBuilder.Entity<AiConversation>(entity =>
        {
            entity.ToTable("AiConversations");
            entity.HasKey(x => x.Id);
            entity.Property(x => x.ClientSessionId).HasMaxLength(64).IsRequired();
            entity.Property(x => x.TitlePreview).HasMaxLength(200);
            entity.Property(x => x.CreatedAtUtc).HasColumnType("datetime");
            entity.Property(x => x.LastMessageAtUtc).HasColumnType("datetime");
            entity.HasOne(x => x.User).WithMany().HasForeignKey(x => x.UserId).OnDelete(DeleteBehavior.Cascade);
            entity.HasIndex(x => new { x.UserId, x.ClientSessionId }).IsUnique();
            entity.HasIndex(x => new { x.UserId, x.LastMessageAtUtc });
        });

        modelBuilder.Entity<AiConversationMessage>(entity =>
        {
            entity.ToTable("AiConversationMessages");
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Id).ValueGeneratedOnAdd();
            entity.Property(x => x.Role).HasColumnType("tinyint");
            entity.Property(x => x.Content).IsRequired();
            entity.Property(x => x.Language).HasMaxLength(8).IsRequired();
            entity.Property(x => x.CreatedAtUtc).HasColumnType("datetime");
            entity.HasOne(x => x.Conversation).WithMany(x => x.Messages).HasForeignKey(x => x.ConversationId)
                .OnDelete(DeleteBehavior.Cascade);
            entity.HasIndex(x => new { x.ConversationId, x.CreatedAtUtc });
        });

        modelBuilder.Entity<Category>(entity =>
        {
            entity.ToTable("Categories");
            entity.HasKey(x => x.CategoryId);
            entity.Property(x => x.CategoryId).ValueGeneratedOnAdd();
            entity.Property(x => x.NameEn).HasMaxLength(255).IsUnicode(false).IsRequired();
            entity.Property(x => x.NameAr).HasMaxLength(255).IsRequired();
            entity.Property(x => x.ImgPath).HasMaxLength(255).IsRequired();
            entity.Property(x => x.CommissionPercent).HasColumnType("decimal(5,2)").HasDefaultValue(0m);
            entity.Property(x => x.IsHide).HasDefaultValue(false);
            entity.HasData(CanonicalCategories.Seed.Cast<object>().ToArray());
        });

        modelBuilder.Entity<ProductType>(entity =>
        {
            entity.ToTable("ProductTypes");
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Id).ValueGeneratedOnAdd();
            entity.Property(x => x.TypeNameEn).HasMaxLength(255).IsRequired();
            entity.HasData(
                new ProductType { Id = 1, TypeNameEn = "Retail" },
                new ProductType { Id = 2, TypeNameEn = "Booking" },
                new ProductType { Id = 3, TypeNameEn = "Offers" },
                new ProductType { Id = 4, TypeNameEn = "Requests" }
            );
        });

        modelBuilder.Entity<RequestType>(entity =>
        {
            entity.ToTable("RequestTypes");
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Id).ValueGeneratedNever();
            entity.Property(x => x.NameEn).HasMaxLength(50).IsUnicode(false).IsRequired();
            entity.HasData(
                new RequestType { Id = 1, NameEn = "Local" },
                new RequestType { Id = 2, NameEn = "Reexport" }
            );
        });

        modelBuilder.Entity<BookingPriceType>(entity =>
        {
            entity.ToTable("BookingPriceTypes");
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Id).ValueGeneratedNever();
            entity.Property(x => x.NameEn).HasMaxLength(50).IsUnicode(false).IsRequired();
            entity.HasData(
                new BookingPriceType { Id = 1, NameEn = "FOB" },
                new BookingPriceType { Id = 2, NameEn = "CNF" },
                new BookingPriceType { Id = 3, NameEn = "CIF" }
            );
        });

        modelBuilder.Entity<Unit>(entity =>
        {
            entity.ToTable("Units");
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Id).ValueGeneratedOnAdd();
            entity.Property(x => x.UnitNameEn).HasMaxLength(255).IsRequired();
            entity.HasData(
                new Unit { Id = 1, UnitNameEn = "Ton" },
                new Unit { Id = 2, UnitNameEn = "Gram" },
                new Unit { Id = 3, UnitNameEn = "Kilogram" },
                new Unit { Id = 4, UnitNameEn = "Carton" },
                new Unit { Id = 5, UnitNameEn = "Bag" },
                new Unit { Id = 6, UnitNameEn = "Dozen" },
                new Unit { Id = 7, UnitNameEn = "Box" },
                new Unit { Id = 8, UnitNameEn = "Piece" },
                new Unit { Id = 9, UnitNameEn = "Packet" },
                new Unit { Id = 10, UnitNameEn = "Bundle" },
                new Unit { Id = 11, UnitNameEn = "Drum" },
                new Unit { Id = 12, UnitNameEn = "Bottle" },
                new Unit { Id = 13, UnitNameEn = "Tin" },
                new Unit { Id = 14, UnitNameEn = "Sack" },
                new Unit { Id = 15, UnitNameEn = "Case" },
                new Unit { Id = 16, UnitNameEn = "Pallet" },
                new Unit { Id = 17, UnitNameEn = "Liter" },
                new Unit { Id = 18, UnitNameEn = "Ml" },
                new Unit { Id = 19, UnitNameEn = "Jar" }
            );
        });

        modelBuilder.Entity<Product>(entity =>
        {
            entity.ToTable("Products");
            entity.HasKey(x => x.ProductId);
            entity.HasIndex(x => x.IsFeatured);
            entity.HasIndex(x => x.ProductTypeId);
            entity.HasIndex(x => x.OwnerId);
            entity.HasIndex(x => x.CategoryId);
            entity.HasIndex(x => x.CreatedAt);
            entity.HasIndex(x => x.NameEn);
            entity.HasIndex(x => new { x.Status, x.IsApproved, x.CreatedAt });
            entity.HasIndex(x => new { x.IsApproved, x.CreatedAt });
            entity.HasIndex(x => new { x.ProductTypeId, x.Status, x.CreatedAt });
            entity.Property(x => x.NameEn).HasMaxLength(255);
            entity.Property(x => x.ProductCode).HasMaxLength(16);
            entity.Property(x => x.RetailCode).HasMaxLength(16);
            entity.Property(x => x.CreatedLanguage).HasMaxLength(5).IsUnicode(false).HasDefaultValue("en");
            entity.Property(x => x.USDPrice).HasColumnType("decimal(8,2)");
            entity.Property(x => x.RetailPrice).HasColumnType("decimal(8,2)");
            entity.Property(x => x.Currency).HasMaxLength(3).IsUnicode(false).HasDefaultValue("AED");
            entity.Property(x => x.DescriptionEn).HasColumnType("nvarchar(max)");
            entity.Property(x => x.ShippingDescriptionEn).HasMaxLength(255);
            entity.Property(x => x.SupplierNotesEn).HasMaxLength(1000);
            entity.Property(x => x.PackagingDetails).HasMaxLength(255);
            entity.Property(x => x.RetailPackagingDetails).HasMaxLength(255);
            entity.Property(x => x.RetailDescriptionEn).HasColumnType("nvarchar(max)");
            entity.Property(x => x.VideoPath).HasMaxLength(500);
            entity.Property(x => x.ShippingDuration).HasMaxLength(20).IsUnicode(false);
            entity.Property(x => x.OfferDuration).HasMaxLength(20).IsUnicode(false);
            entity.Property(x => x.CreatedAt).HasColumnType("datetime").HasDefaultValueSql("(getutcdate())");
            entity.Property(x => x.UpdatedAt).HasColumnType("datetime");
            entity.Property(x => x.DisplayExpiresAtUtc).HasColumnType("datetime");
            entity.Property(x => x.DiscountDays).HasColumnType("smallint");
            entity.Property(x => x.IsFeatured).HasDefaultValue(false);
            entity.Property(x => x.IsReadyForAdminReview).HasDefaultValue(true);
            entity.Property(x => x.PendingProductChanges).HasColumnType("nvarchar(max)");
            entity.Property(x => x.ViewsCount).HasDefaultValue(0L);
            entity.HasOne(x => x.Category).WithMany(x => x.Products).HasForeignKey(x => x.CategoryId);
            entity.HasOne(x => x.ProductType).WithMany(x => x.Products).HasForeignKey(x => x.ProductTypeId);
            entity.HasOne(x => x.RequestType).WithMany(x => x.Products).HasForeignKey(x => x.RequestTypeId).OnDelete(DeleteBehavior.NoAction);
            entity.HasOne(x => x.BookingPriceType).WithMany(x => x.Products).HasForeignKey(x => x.BookingPriceTypeId).OnDelete(DeleteBehavior.NoAction);
            entity.HasOne(x => x.Unit).WithMany(x => x.Products).HasForeignKey(x => x.UnitId);
            entity.HasOne(x => x.RetailUnit).WithMany().HasForeignKey(x => x.RetailUnitId).OnDelete(DeleteBehavior.NoAction);
            entity.HasOne(x => x.Owner).WithMany(x => x.Products).HasForeignKey(x => x.OwnerId);
            entity.HasOne(x => x.OriginCountry).WithMany().HasForeignKey(x => x.OriginCountryId).OnDelete(DeleteBehavior.NoAction);
            entity.HasOne(x => x.DestinationCountry).WithMany().HasForeignKey(x => x.DestinationCountryId).OnDelete(DeleteBehavior.NoAction);
            entity.HasOne(x => x.LoadingPort).WithMany().HasForeignKey(x => x.LoadingPortId).OnDelete(DeleteBehavior.NoAction);
            entity.HasOne(x => x.ArrivalPort).WithMany().HasForeignKey(x => x.ArrivalPortId).OnDelete(DeleteBehavior.NoAction);
            entity.HasOne(x => x.Address).WithMany().HasForeignKey(x => x.AddressId).OnDelete(DeleteBehavior.NoAction);
            entity.HasIndex(x => x.AddressId);
        });

        modelBuilder.Entity<ProductImage>(entity =>
        {
            entity.ToTable("ProductImages");
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Id).ValueGeneratedOnAdd();
            entity.Property(x => x.ImagePath).HasMaxLength(500).IsRequired();
            entity.Property(x => x.CreatedAt).HasColumnType("datetime").HasDefaultValueSql("(getutcdate())");
            entity.HasOne(x => x.Product)
                .WithMany(x => x.ProductImages)
                .HasForeignKey(x => x.ProductId)
                .OnDelete(DeleteBehavior.Cascade);
            entity.HasIndex(x => x.ProductId);
        });

        modelBuilder.Entity<ProductDocument>(entity =>
        {
            entity.ToTable("ProductDocuments");
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Id).ValueGeneratedOnAdd();
            entity.Property(x => x.DocumentPath).HasMaxLength(500).IsRequired();
            entity.Property(x => x.CreatedAt).HasColumnType("datetime").HasDefaultValueSql("(getutcdate())");
            entity.HasOne(x => x.Product)
                .WithMany(x => x.ProductDocuments)
                .HasForeignKey(x => x.ProductId)
                .OnDelete(DeleteBehavior.Cascade);
            entity.HasIndex(x => x.ProductId);
        });

        modelBuilder.Entity<ProductVideo>(entity =>
        {
            entity.ToTable("ProductVideos");
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Id).ValueGeneratedOnAdd();
            entity.Property(x => x.VideoPath).HasMaxLength(500).IsRequired();
            entity.Property(x => x.IsMuted).HasDefaultValue(true);
            entity.Property(x => x.CreatedAt).HasColumnType("datetime").HasDefaultValueSql("(getutcdate())");
            entity.HasOne(x => x.Product)
                .WithMany(x => x.ProductVideos)
                .HasForeignKey(x => x.ProductId)
                .OnDelete(DeleteBehavior.Cascade);
            entity.HasIndex(x => x.ProductId);
        });

        modelBuilder.Entity<HomeBanner>(entity =>
        {
            entity.ToTable("HomeBanners");
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Id).ValueGeneratedOnAdd();
            entity.Property(x => x.ImagePath).HasMaxLength(500).IsRequired();
            entity.Property(x => x.LinkUrl).HasMaxLength(1000).IsRequired();
            entity.Property(x => x.CreatedAt).HasColumnType("datetime").HasDefaultValueSql("(getutcdate())");
            entity.HasIndex(x => x.DisplayOrder).IsUnique();
        });

        modelBuilder.Entity<OrderStatus>(entity =>
        {
            entity.ToTable("OrderStatus");
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Id).ValueGeneratedOnAdd();
            entity.Property(x => x.Name).HasMaxLength(255).IsRequired();
            entity.HasData(
                new OrderStatus { Id = 1, Name = "Ordered" },
                new OrderStatus { Id = 2, Name = "Approved" },
                new OrderStatus { Id = 3, Name = "Paid" },
                new OrderStatus { Id = 4, Name = "Shipping" },
                new OrderStatus { Id = 5, Name = "Delivered" },
                new OrderStatus { Id = 6, Name = "Cancelled" }
            );
        });

        modelBuilder.Entity<InternationalShippingPost>(entity =>
        {
            entity.ToTable("InternationalShippingPosts");
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Id).ValueGeneratedOnAdd();
            entity.Property(x => x.PriceUsd).HasColumnType("decimal(12,2)");
            entity.Property(x => x.ShippingCostUsd).HasColumnType("decimal(12,2)");
            entity.Property(x => x.Container20ftPriceUsd).HasColumnType("decimal(12,2)");
            entity.Property(x => x.Container40ftPriceUsd).HasColumnType("decimal(12,2)");
            entity.Property(x => x.PhoneNumber).HasMaxLength(50).IsUnicode(false).IsRequired();
            entity.Property(x => x.Details).HasMaxLength(2000);
            entity.Property(x => x.Status).HasDefaultValue((byte)1);
            entity.Property(x => x.IsApproved).HasDefaultValue(false);
            entity.Property(x => x.CreatedAt).HasColumnType("datetime").HasDefaultValueSql("(getutcdate())");
            entity.HasOne(x => x.FromCountry).WithMany().HasForeignKey(x => x.FromCountryId).OnDelete(DeleteBehavior.NoAction);
            entity.HasOne(x => x.FromPort).WithMany().HasForeignKey(x => x.FromPortId).OnDelete(DeleteBehavior.NoAction);
            entity.HasOne(x => x.ToCountry).WithMany().HasForeignKey(x => x.ToCountryId).OnDelete(DeleteBehavior.NoAction);
            entity.HasOne(x => x.ToPort).WithMany().HasForeignKey(x => x.ToPortId).OnDelete(DeleteBehavior.NoAction);
            entity.HasOne(x => x.PublisherUser).WithMany().HasForeignKey(x => x.PublisherUserId).OnDelete(DeleteBehavior.NoAction);
        });

        modelBuilder.Entity<ShipmentStatus>(entity =>
        {
            entity.ToTable("ShipmentStatuses");
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Id).ValueGeneratedNever();
            entity.Property(x => x.NameEn).HasMaxLength(50).IsUnicode(false).IsRequired();
            entity.Property(x => x.NameAr).HasMaxLength(50).IsRequired();
            entity.HasData(
                new ShipmentStatus { Id = 1, NameEn = "Pending", NameAr = "قيد الانتظار" },
                new ShipmentStatus { Id = 2, NameEn = "InDelivery", NameAr = "قيد التوصيل" },
                new ShipmentStatus { Id = 3, NameEn = "Completed", NameAr = "مكتمل" },
                new ShipmentStatus { Id = 4, NameEn = "Late", NameAr = "متأخر" }
            );
        });

        modelBuilder.Entity<InternationalShipment>(entity =>
        {
            entity.ToTable("InternationalShipments");
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Id).ValueGeneratedOnAdd();
            entity.Property(x => x.ShipmentCode).HasMaxLength(20).IsUnicode(false).IsRequired();
            entity.Property(x => x.CreatedAt).HasColumnType("datetime").HasDefaultValueSql("(getutcdate())");
            entity.Property(x => x.UpdatedAt).HasColumnType("datetime");
            entity.HasIndex(x => x.ShipmentCode).IsUnique();
            entity.HasIndex(x => x.ProviderUserId);
            entity.HasIndex(x => x.OrderId);
            entity.HasOne(x => x.Order).WithMany().HasForeignKey(x => x.OrderId).OnDelete(DeleteBehavior.Cascade);
            entity.HasOne(x => x.ProviderUser).WithMany().HasForeignKey(x => x.ProviderUserId).OnDelete(DeleteBehavior.NoAction);
            entity.HasOne(x => x.Status).WithMany(x => x.Shipments).HasForeignKey(x => x.StatusId).OnDelete(DeleteBehavior.NoAction);
        });

        modelBuilder.Entity<Cart>(entity =>
        {
            entity.ToTable("Carts");
            entity.HasKey(x => x.CartId);
            entity.Property(x => x.CreatedAt).HasColumnType("datetime").HasDefaultValueSql("(getutcdate())");
            entity.Property(x => x.UpdatedAt).HasColumnType("datetime");
            entity.HasIndex(x => x.UserId).IsUnique();
            entity.HasOne(x => x.User).WithMany(x => x.Carts).HasForeignKey(x => x.UserId).OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<CartItem>(entity =>
        {
            entity.ToTable("CartItems");
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Id).ValueGeneratedOnAdd();
            entity.Property(x => x.Quantity).HasColumnType("decimal(18,3)");
            entity.Property(x => x.UnitPriceAed).HasColumnType("decimal(12,2)");
            entity.Property(x => x.CreatedAt).HasColumnType("datetime").HasDefaultValueSql("(getutcdate())");
            entity.HasOne(x => x.Cart).WithMany(x => x.CartItems).HasForeignKey(x => x.CartId).OnDelete(DeleteBehavior.Cascade);
            entity.HasOne(x => x.Product).WithMany().HasForeignKey(x => x.ProductId).OnDelete(DeleteBehavior.NoAction);
            entity.HasOne(x => x.Unit).WithMany().HasForeignKey(x => x.UnitId).OnDelete(DeleteBehavior.NoAction);
            entity.HasIndex(x => new { x.CartId, x.ProductId, x.UnitId }).IsUnique();
        });

        modelBuilder.Entity<Order>(entity =>
        {
            entity.ToTable("Orders");
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Id).ValueGeneratedOnAdd();
            entity.Property(x => x.UnitPrice).HasColumnType("decimal(18,2)");
            entity.Property(x => x.TotalPrice).HasColumnType("decimal(18,2)");
            entity.Property(x => x.Quantity).HasColumnType("decimal(18,3)");
            entity.Property(x => x.CreatedAt).HasColumnType("datetime").HasDefaultValueSql("(getutcdate())");
            entity.HasOne(x => x.FromUser).WithMany(x => x.OrdersFrom).HasForeignKey(x => x.FromUserId).OnDelete(DeleteBehavior.NoAction);
            entity.HasOne(x => x.ToUser).WithMany(x => x.OrdersTo).HasForeignKey(x => x.ToUserId).OnDelete(DeleteBehavior.NoAction);
            entity.HasOne(x => x.Product).WithMany(x => x.Orders).HasForeignKey(x => x.ProductId).OnDelete(DeleteBehavior.Cascade);
            entity.HasOne(x => x.Status).WithMany(x => x.Orders).HasForeignKey(x => x.StatusId);
            entity.HasOne(x => x.Unit).WithMany().HasForeignKey(x => x.UnitId).OnDelete(DeleteBehavior.NoAction);
            entity.Property(x => x.StripeSessionId).HasMaxLength(255);
            entity.Property(x => x.Notes).HasMaxLength(2000);
            entity.Property(x => x.CustomStatusNameEn).HasMaxLength(200);
            entity.Property(x => x.CustomStatusNameAr).HasMaxLength(200);
            entity.Property(x => x.IsApproved).HasDefaultValue(false);
            entity.Property(x => x.StockQuantityDeducted).HasDefaultValue(false);
            entity.Property(x => x.IsRetailPurchase).HasDefaultValue(false);
            entity.Property(x => x.VatAed).HasColumnType("decimal(12,2)");
            entity.Property(x => x.ShippingCostAed).HasColumnType("decimal(12,2)");
            entity.Property(x => x.IsSelfPickup).HasDefaultValue(false);
            entity.Property(x => x.DeliveryAddressLine).HasMaxLength(500);
            entity.Property(x => x.DeliveryCityName).HasMaxLength(200);
            entity.Property(x => x.ReturnReason).HasMaxLength(2000);
            entity.Property(x => x.ReturnMediaPathsJson).HasMaxLength(4000);
            entity.Property(x => x.ReturnAdminResponse).HasMaxLength(2000);
            entity.HasOne(x => x.PendingOrder).WithMany().HasForeignKey(x => x.PendingOrderId).OnDelete(DeleteBehavior.NoAction);
            entity.HasOne(x => x.Port).WithMany().HasForeignKey(x => x.PortId).OnDelete(DeleteBehavior.NoAction);
            entity.HasIndex(x => x.CreatedAt);
            entity.HasIndex(x => new { x.StatusId, x.CreatedAt });
            entity.HasIndex(x => x.ProductId);
            entity.HasIndex(x => x.FromUserId);
            entity.HasIndex(x => x.ToUserId);
            entity.HasIndex(x => x.PendingOrderId).HasFilter("[PendingOrderId] IS NOT NULL");
            entity.HasIndex(x => x.OrderGroupId).HasFilter("[OrderGroupId] IS NOT NULL");
            entity.HasOne(x => x.AdminOfferPrice)
                .WithOne(x => x.Order)
                .HasForeignKey<OrderAdminOfferPrice>(x => x.OrderId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<OrderAdminOfferPrice>(entity =>
        {
            entity.ToTable("OrderAdminOfferPrices");
            entity.HasKey(x => x.OrderId);
            entity.Property(x => x.AdminUnitPrice).HasColumnType("decimal(18,2)");
            entity.Property(x => x.AdminTotalPrice).HasColumnType("decimal(18,2)");
            entity.Property(x => x.UpdatedAtUtc).HasColumnType("datetime2").HasDefaultValueSql("(sysutcdatetime())");
        });

        modelBuilder.Entity<OrderVideo>(entity =>
        {
            entity.ToTable("OrderVideos");
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Id).ValueGeneratedOnAdd();
            entity.Property(x => x.VideoPath).HasMaxLength(500).IsRequired();
            entity.Property(x => x.CreatedAt).HasColumnType("datetime").HasDefaultValueSql("(getutcdate())");
            entity.HasOne(x => x.Order).WithMany(x => x.Videos).HasForeignKey(x => x.OrderId).OnDelete(DeleteBehavior.Cascade);
            entity.HasIndex(x => x.OrderId);
        });

        modelBuilder.Entity<OrderImage>(entity =>
        {
            entity.ToTable("OrderImages");
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Id).ValueGeneratedOnAdd();
            entity.Property(x => x.ImagePath).HasMaxLength(500).IsRequired();
            entity.Property(x => x.CreatedAt).HasColumnType("datetime").HasDefaultValueSql("(getutcdate())");
            entity.HasOne(x => x.Order).WithMany(x => x.Images).HasForeignKey(x => x.OrderId).OnDelete(DeleteBehavior.Cascade);
            entity.HasIndex(x => x.OrderId);
        });

        modelBuilder.Entity<OrderStatusHistory>(entity =>
        {
            entity.ToTable("OrderStatusHistories");
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Id).ValueGeneratedOnAdd();
            entity.Property(x => x.StatusNameEn).HasMaxLength(200).IsRequired();
            entity.Property(x => x.StatusNameAr).HasMaxLength(200).IsRequired();
            entity.Property(x => x.CreatedAtUtc).HasColumnType("datetime2").HasDefaultValueSql("(getutcdate())");
            entity.HasOne(x => x.Order).WithMany(x => x.StatusHistories).HasForeignKey(x => x.OrderId)
                .OnDelete(DeleteBehavior.Cascade);
            entity.HasIndex(x => x.OrderId);
            entity.HasIndex(x => new { x.OrderId, x.CreatedAtUtc });
        });

        modelBuilder.Entity<PendingOrder>(entity =>
        {
            entity.ToTable("PendingOrders");
            entity.HasKey(x => x.Id);
            entity.Property(x => x.ShippingCostAed).HasColumnType("decimal(12,2)");
            entity.Property(x => x.TotalPriceUsd).HasColumnType("decimal(12,2)");
            entity.Property(x => x.TotalPriceAed).HasColumnType("decimal(12,2)");
            entity.Property(x => x.CheckoutCurrency).HasMaxLength(3).IsUnicode(false);
            entity.Property(x => x.CheckoutAmount).HasColumnType("decimal(12,2)");
            entity.Property(x => x.StripeSessionId).HasMaxLength(255);
            entity.Property(x => x.PaymentIntentId).HasMaxLength(255);
            entity.Property(x => x.StripeRefundId).HasMaxLength(255);
            entity.Property(x => x.Notes).HasMaxLength(2000);
            entity.Property(x => x.IsSelfPickup).HasDefaultValue(false);
            entity.Property(x => x.DeliveryAddressLine).HasMaxLength(500);
            entity.Property(x => x.DeliveryCityName).HasMaxLength(200);
            entity.Property(x => x.CreatedAt).HasColumnType("datetime").HasDefaultValueSql("(getutcdate())");
            entity.HasIndex(x => x.StripeSessionId)
                .IsUnique()
                .HasFilter("[StripeSessionId] IS NOT NULL");
            entity.HasOne(x => x.FromUser).WithMany().HasForeignKey(x => x.FromUserId).OnDelete(DeleteBehavior.NoAction);
            entity.HasOne(x => x.Address).WithMany().HasForeignKey(x => x.AddressId).OnDelete(DeleteBehavior.NoAction);
        });

        modelBuilder.Entity<PendingOrderItem>(entity =>
        {
            entity.ToTable("PendingOrderItems");
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Id).ValueGeneratedOnAdd();
            entity.Property(x => x.Quantity).HasColumnType("decimal(18,3)");
            entity.Property(x => x.UnitPriceUsd).HasColumnType("decimal(12,2)");
            entity.Property(x => x.UnitPriceAed).HasColumnType("decimal(12,2)");
            entity.Property(x => x.LineTotalAed).HasColumnType("decimal(12,2)");
            entity.HasOne(x => x.PendingOrder).WithMany(x => x.Items).HasForeignKey(x => x.PendingOrderId).OnDelete(DeleteBehavior.Cascade);
            entity.HasOne(x => x.Product).WithMany().HasForeignKey(x => x.ProductId).OnDelete(DeleteBehavior.Cascade);
            entity.HasOne(x => x.ToUser).WithMany().HasForeignKey(x => x.ToUserId).OnDelete(DeleteBehavior.NoAction);
            entity.HasOne(x => x.Unit).WithMany().HasForeignKey(x => x.UnitId).OnDelete(DeleteBehavior.NoAction);
            entity.HasIndex(x => x.PendingOrderId);
        });

        modelBuilder.Entity<PendingPayment>(entity =>
        {
            entity.ToTable("PendingPayments");
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Id).ValueGeneratedOnAdd();
            entity.Property(x => x.StripeSessionId).HasMaxLength(255);
            entity.Property(x => x.PaymentIntentId).HasMaxLength(255);
            entity.Property(x => x.StripeRefundId).HasMaxLength(255);
            entity.Property(x => x.CreatedAt).HasColumnType("datetime").HasDefaultValueSql("(getutcdate())");
            entity.HasIndex(x => x.StripeSessionId).IsUnique();
            entity.HasOne(x => x.Order).WithOne().HasForeignKey<PendingPayment>(x => x.OrderId).OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<Country>(entity =>
        {
            entity.ToTable("Countries");
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Id).ValueGeneratedOnAdd();
            entity.Property(x => x.Iso2Code).HasMaxLength(2).IsUnicode(false).IsRequired();
            entity.HasIndex(x => x.Iso2Code).IsUnique();
            entity.Property(x => x.CountryNameEn).HasMaxLength(255).IsUnicode(false).IsRequired();
            entity.Property(x => x.CountryNameAr).HasMaxLength(255);
        });

        modelBuilder.Entity<City>(entity =>
        {
            entity.ToTable("Cities");
            entity.HasKey(x => x.Id);
            entity.Property(x => x.CityName).HasMaxLength(255).IsRequired();
            entity.HasIndex(x => x.CityName);
            entity.HasOne(x => x.Country).WithMany(x => x.Cities).HasForeignKey(x => x.CountryId);
        });

        modelBuilder.Entity<Port>(entity =>
        {
            entity.ToTable("Ports");
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Id).ValueGeneratedOnAdd();
            entity.Property(x => x.PortNameEn).HasMaxLength(255).IsRequired();
            entity.Property(x => x.PortNameAr).HasMaxLength(255);
            entity.Property(x => x.UnLocode).HasMaxLength(10).IsUnicode(false);
            entity.HasIndex(x => x.UnLocode).IsUnique().HasFilter("[UnLocode] IS NOT NULL");
            entity.HasIndex(x => new { x.CountryId, x.PortNameEn });
            entity.HasOne(x => x.Country).WithMany(x => x.Ports).HasForeignKey(x => x.CountryId);
        });

        modelBuilder.Entity<Address>(entity =>
        {
            entity.ToTable("Addresses");
            entity.HasKey(x => x.Id);
            entity.Property(x => x.AddressLine1).HasMaxLength(255).IsRequired();
            entity.Property(x => x.AddressLine2).HasMaxLength(255);
            entity.HasOne(x => x.User).WithMany(x => x.Addresses).HasForeignKey(x => x.UserId);
            entity.HasOne(x => x.City).WithMany(x => x.Addresses).HasForeignKey(x => x.CityId);
            entity.HasIndex(x => new { x.UserId, x.CityId });
        });

        modelBuilder.Entity<NotificationType>(entity =>
        {
            entity.ToTable("NotificationTypes");
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Id).ValueGeneratedOnAdd();
            entity.Property(x => x.Name).HasMaxLength(255).IsRequired();
        });

        modelBuilder.Entity<NotificationRoute>(entity =>
        {
            entity.ToTable("NotificationRoutes");
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Name).HasMaxLength(255).IsRequired();
        });

        modelBuilder.Entity<Notification>(entity =>
        {
            entity.ToTable("Notifications");
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Title).HasMaxLength(255).IsRequired();
            entity.Property(x => x.TitleAr).HasMaxLength(255);
            entity.Property(x => x.Body).HasMaxLength(1000).IsRequired();
            entity.Property(x => x.BodyAr).HasMaxLength(1000);
            entity.Property(x => x.ReferenceId).HasMaxLength(255).IsRequired();
            entity.Property(x => x.IsRead).HasDefaultValue(false);
            entity.Property(x => x.CreatedAt).HasColumnType("datetime2");
            entity.HasIndex(x => new { x.ToUserId, x.CreatedAt });
            entity.HasIndex(x => new { x.ToUserId, x.IsRead });
            entity.HasOne(x => x.Route).WithMany(x => x.Notifications).HasForeignKey(x => x.RouteId);
            entity.HasOne(x => x.Type).WithMany(x => x.Notifications).HasForeignKey(x => x.TypeId);
            entity.HasOne(x => x.FromUser).WithMany().HasForeignKey(x => x.FromUserId).OnDelete(DeleteBehavior.NoAction);
            entity.HasOne(x => x.ToUser).WithMany().HasForeignKey(x => x.ToUserId).OnDelete(DeleteBehavior.NoAction);
        });

        modelBuilder.Entity<AdminPushNotification>(entity =>
        {
            entity.ToTable("AdminPushNotifications");
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Id).ValueGeneratedNever();
            entity.Property(x => x.Title).HasMaxLength(255).IsRequired();
            entity.Property(x => x.Body).HasMaxLength(1000).IsRequired();
            entity.Property(x => x.TitleAr).HasMaxLength(255);
            entity.Property(x => x.BodyAr).HasMaxLength(1000);
            entity.Property(x => x.Audience).HasMaxLength(50).IsRequired();
            entity.Property(x => x.Type).HasMaxLength(100);
            entity.HasIndex(x => x.CreatedAt);
            entity.HasIndex(x => new { x.Audience, x.CreatedAt });
            entity.HasOne(x => x.TargetUser).WithMany().HasForeignKey(x => x.TargetUserId).OnDelete(DeleteBehavior.SetNull);
        });

        modelBuilder.Entity<CompanyImage>(entity =>
        {
            entity.ToTable("CompanyImages");
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Id).ValueGeneratedOnAdd();
            entity.Property(x => x.ImagePath).HasMaxLength(500).IsRequired();
            entity.Property(x => x.CreatedAt).HasColumnType("datetime").HasDefaultValueSql("(getutcdate())");
            entity.HasOne(x => x.User)
                .WithMany(x => x.CompanyImages)
                .HasForeignKey(x => x.UserId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<EmailOtp>(entity =>
        {
            entity.ToTable("EmailOtps");
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Id).ValueGeneratedOnAdd();
            entity.Property(x => x.Email).HasMaxLength(250).IsRequired();
            entity.Property(x => x.Code).HasMaxLength(10).IsRequired();
            entity.Property(x => x.ExpiresAt).HasColumnType("datetime");
            entity.Property(x => x.CreatedAt).HasColumnType("datetime").HasDefaultValueSql("(getutcdate())");
            entity.HasIndex(x => new { x.Email, x.Code, x.IsUsed });
        });

        modelBuilder.Entity<PasswordResetCode>(entity =>
        {
            entity.ToTable("PasswordResetCodes");
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Id).ValueGeneratedOnAdd();
            entity.Property(x => x.ProviderName).HasMaxLength(20).IsUnicode(false).IsRequired();
            entity.Property(x => x.Destination).HasMaxLength(250).IsRequired();
            entity.Property(x => x.Code).HasMaxLength(10).IsUnicode(false).IsRequired();
            entity.Property(x => x.ExpiresAt).HasColumnType("datetime");
            entity.Property(x => x.CreatedAt).HasColumnType("datetime").HasDefaultValueSql("(getutcdate())");
            entity.HasIndex(x => new { x.ProviderName, x.Destination, x.Code, x.IsUsed });
            entity.HasOne(x => x.User).WithMany().HasForeignKey(x => x.UserId).OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<SystemSettings>(entity =>
        {
            entity.ToTable("SystemSettings");
            entity.HasKey(x => x.Id);
            entity.Property(x => x.RetailCommissionPercent).HasColumnType("decimal(5,2)");
            entity.Property(x => x.BookingCommissionPercent).HasColumnType("decimal(5,2)");
            entity.Property(x => x.RequestsCommissionPercent).HasColumnType("decimal(5,2)");
            entity.Property(x => x.OffersCommissionPercent).HasColumnType("decimal(5,2)");
            entity.Property(x => x.ShippingCommissionPercent).HasColumnType("decimal(5,2)");
            entity.Property(x => x.AppName).HasMaxLength(200).IsRequired();
            entity.Property(x => x.SupportEmail).HasMaxLength(255);
            entity.Property(x => x.PhoneNumber).HasMaxLength(50);
            entity.Property(x => x.LandlineNumber).HasMaxLength(50);
            entity.Property(x => x.Timezone).HasMaxLength(100);
            entity.Property(x => x.Address).HasMaxLength(500);
            entity.Property(x => x.FeaturedAdPriceAed).HasColumnType("decimal(12,2)");
            entity.Property(x => x.UpdatedAt).HasColumnType("datetime").HasDefaultValueSql("(getutcdate())");
        });

        modelBuilder.Entity<InternalDomesticShippingRate>(entity =>
        {
            entity.ToTable("InternalDomesticShipping");
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Id).ValueGeneratedNever();
            entity.Property(x => x.EmirateNameEn).HasMaxLength(100).IsUnicode(false).IsRequired();
            entity.Property(x => x.EmirateNameAr).HasMaxLength(100).IsRequired();
            entity.Property(x => x.PriceAed).HasColumnType("decimal(12,2)");
            entity.Property(x => x.UpdatedAt).HasColumnType("datetime").HasDefaultValueSql("(getutcdate())");
            entity.HasIndex(x => x.EmirateNameEn).IsUnique();
        });

        modelBuilder.Entity<InternalDomesticShippingConfig>(entity =>
        {
            entity.ToTable("InternalDomesticShippingConfig");
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Id).ValueGeneratedNever();
            entity.Property(x => x.UpdatedAt).HasColumnType("datetime").HasDefaultValueSql("(getutcdate())");
        });
    }
}
