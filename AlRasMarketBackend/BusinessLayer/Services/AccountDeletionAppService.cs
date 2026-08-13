using System.Text.Json;
using BusinessLayer.Constants;
using BusinessLayer.Helpers;
using BusinessLayer.Interfaces;
using DataLayer.Interfaces;
using DataLayer.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace BusinessLayer.Services;

/// <summary>
/// Deletes a user and every related row according to DataLayer FK relationships.
/// Order: dependents first, then the Users row. Media files are removed after commit.
/// </summary>
public class AccountDeletionAppService(
    IRasAlSouqDbContext dbContext,
    IPasswordHasher passwordHasher,
    IMediaStorageService mediaStorage,
    IProductImageVectorIndex productImageVectorIndex,
    ILogger<AccountDeletionAppService> logger) : IAccountDeletionAppService
{
    public async Task<string> DeleteAccountAsync(
        string userId,
        string password,
        CancellationToken cancellationToken = default)
    {
        if (!Guid.TryParse(userId, out var userGuid))
        {
            throw new ArgumentException("Invalid user id.");
        }

        var user = await dbContext.Users.FirstOrDefaultAsync(x => x.Id == userGuid, cancellationToken)
            ?? throw new KeyNotFoundException("User not found.");

        if (user.RoleId == RoleIds.Admin)
        {
            throw new InvalidOperationException("Admin accounts cannot be deleted from the app.");
        }

        // OAuth accounts (Google/Apple) may not have a local password hash.
        if (!string.IsNullOrWhiteSpace(user.HashedPassword))
        {
            if (string.IsNullOrWhiteSpace(password)
                || !passwordHasher.VerifyPassword(password, user.HashedPassword))
            {
                throw new UnauthorizedAccessException("Password is incorrect.");
            }
        }

        await DeleteUserDataAsync(user, cancellationToken);
        return "Account deleted successfully.";
    }

    public async Task<string> DeleteUserByAdminAsync(
        string userId,
        CancellationToken cancellationToken = default)
    {
        if (!Guid.TryParse(userId, out var userGuid))
        {
            throw new ArgumentException("Invalid user id.");
        }

        var user = await dbContext.Users.FirstOrDefaultAsync(x => x.Id == userGuid, cancellationToken)
            ?? throw new KeyNotFoundException("User not found.");

        if (user.RoleId == RoleIds.Admin)
        {
            throw new InvalidOperationException("Admin accounts cannot be deleted.");
        }

        await DeleteUserDataAsync(user, cancellationToken);
        return "User account and files deleted successfully.";
    }

    private async Task DeleteUserDataAsync(User user, CancellationToken cancellationToken)
    {
        if (dbContext is not DbContext efContext)
        {
            throw new InvalidOperationException("Database context must support transactions.");
        }

        var userId = user.Id;

        var ownedProductIds = await dbContext.Products
            .AsNoTracking()
            .Where(x => x.OwnerId == userId)
            .Select(x => x.ProductId)
            .ToListAsync(cancellationToken);

        var orderIds = await dbContext.Orders
            .AsNoTracking()
            .Where(x => x.FromUserId == userId
                || x.ToUserId == userId
                || (ownedProductIds.Count > 0 && ownedProductIds.Contains(x.ProductId)))
            .Select(x => x.Id)
            .Distinct()
            .ToListAsync(cancellationToken);

        var filePaths = await CollectUserFilePathsAsync(
            user,
            ownedProductIds,
            orderIds,
            cancellationToken);

        await using var transaction = await efContext.Database.BeginTransactionAsync(cancellationToken);
        try
        {
            var addressIds = await dbContext.Addresses
                .AsNoTracking()
                .Where(x => x.UserId == userId)
                .Select(x => x.Id)
                .ToListAsync(cancellationToken);

            // 1) Chat
            await RemoveRangeAsync(
                dbContext.ChatSupportAssignments.Where(x =>
                    x.CustomerUserId == userId || x.AgentUserId == userId),
                cancellationToken);

            await RemoveRangeAsync(
                dbContext.ChatMessages.Where(x =>
                    x.FromUserId == userId || x.ToUserId == userId),
                cancellationToken);

            // 2) Notifications
            await RemoveRangeAsync(
                dbContext.Notifications.Where(x =>
                    x.FromUserId == userId || x.ToUserId == userId),
                cancellationToken);

            // AdminPushNotifications.TargetUserId is SetNull — clear before user delete.
            var adminPushes = await dbContext.AdminPushNotifications
                .Where(x => x.TargetUserId == userId)
                .ToListAsync(cancellationToken);
            foreach (var push in adminPushes)
            {
                push.TargetUserId = null;
            }

            // 3) Shipments tied to user or their orders
            await RemoveRangeAsync(
                dbContext.InternationalShipments.Where(x =>
                    x.ProviderUserId == userId
                    || (orderIds.Count > 0 && orderIds.Contains(x.OrderId))),
                cancellationToken);

            // 4b) Translations that Restrict on Order/User (must clear before Orders/Users)
            if (orderIds.Count > 0 || ownedProductIds.Count > 0)
            {
                await RemoveRangeAsync(
                    dbContext.ContentTranslations.Where(x =>
                        (orderIds.Count > 0 && x.OrderId != null && orderIds.Contains(x.OrderId.Value))
                        || (ownedProductIds.Count > 0
                            && x.ProductId != null
                            && ownedProductIds.Contains(x.ProductId.Value))),
                    cancellationToken);
            }

            // 5) Orders and order children (must run before PendingOrders / Products)
            if (orderIds.Count > 0)
            {
                await RemoveRangeAsync(
                    dbContext.OrderStatusHistories.Where(x => orderIds.Contains(x.OrderId)),
                    cancellationToken);

                await RemoveRangeAsync(
                    dbContext.PendingPayments.Where(x => orderIds.Contains(x.OrderId)),
                    cancellationToken);

                await RemoveRangeAsync(
                    dbContext.OrderVideos.Where(x => orderIds.Contains(x.OrderId)),
                    cancellationToken);

                await RemoveRangeAsync(
                    dbContext.OrderImages.Where(x => orderIds.Contains(x.OrderId)),
                    cancellationToken);

                await RemoveRangeAsync(
                    dbContext.Orders.Where(x => orderIds.Contains(x.Id)),
                    cancellationToken);
            }

            // 6) Pending checkout (items first when user is seller on someone else's cart checkout)
            await RemoveRangeAsync(
                dbContext.PendingOrderItems.Where(x =>
                    x.ToUserId == userId
                    || (ownedProductIds.Count > 0 && ownedProductIds.Contains(x.ProductId))),
                cancellationToken);

            var userPendingOrderIds = await dbContext.PendingOrders
                .AsNoTracking()
                .Where(x => x.FromUserId == userId)
                .Select(x => x.Id)
                .ToListAsync(cancellationToken);

            if (userPendingOrderIds.Count > 0)
            {
                await RemoveRangeAsync(
                    dbContext.PendingOrderItems.Where(x => userPendingOrderIds.Contains(x.PendingOrderId)),
                    cancellationToken);

                await RemoveRangeAsync(
                    dbContext.PendingOrders.Where(x => userPendingOrderIds.Contains(x.Id)),
                    cancellationToken);
            }

            // 7) Shipping posts published by user
            await RemoveRangeAsync(
                dbContext.InternationalShippingPosts.Where(x => x.PublisherUserId == userId),
                cancellationToken);

            // 8) Products owned by user (cart lines on those products first)
            if (ownedProductIds.Count > 0)
            {
                await RemoveRangeAsync(
                    dbContext.CartItems.Where(x => ownedProductIds.Contains(x.ProductId)),
                    cancellationToken);

                await RemoveRangeAsync(
                    dbContext.ProductVideos.Where(x => ownedProductIds.Contains(x.ProductId)),
                    cancellationToken);

                await RemoveRangeAsync(
                    dbContext.ProductImages.Where(x => ownedProductIds.Contains(x.ProductId)),
                    cancellationToken);

                await RemoveRangeAsync(
                    dbContext.ProductDocuments.Where(x => ownedProductIds.Contains(x.ProductId)),
                    cancellationToken);

                await RemoveRangeAsync(
                    dbContext.Products.Where(x => ownedProductIds.Contains(x.ProductId)),
                    cancellationToken);
            }

            // 9) Addresses (clear FKs that point at them, then delete)
            if (addressIds.Count > 0)
            {
                var productsUsingAddresses = await dbContext.Products
                    .Where(x => x.AddressId != null && addressIds.Contains(x.AddressId.Value))
                    .ToListAsync(cancellationToken);
                foreach (var product in productsUsingAddresses)
                {
                    product.AddressId = null;
                }

                var pendingOrdersUsingAddresses = await dbContext.PendingOrders
                    .Where(x => x.AddressId != null && addressIds.Contains(x.AddressId.Value))
                    .ToListAsync(cancellationToken);
                foreach (var pendingOrder in pendingOrdersUsingAddresses)
                {
                    pendingOrder.AddressId = null;
                }

                await RemoveRangeAsync(
                    dbContext.Addresses.Where(x => addressIds.Contains(x.Id)),
                    cancellationToken);
            }

            // 10) User cart
            var userCartIds = await dbContext.Carts
                .AsNoTracking()
                .Where(x => x.UserId == userId)
                .Select(x => x.CartId)
                .ToListAsync(cancellationToken);

            if (userCartIds.Count > 0)
            {
                await RemoveRangeAsync(
                    dbContext.CartItems.Where(x => userCartIds.Contains(x.CartId)),
                    cancellationToken);

                await RemoveRangeAsync(
                    dbContext.Carts.Where(x => userCartIds.Contains(x.CartId)),
                    cancellationToken);
            }

            // 11) Company / auth side tables
            await RemoveRangeAsync(
                dbContext.CompanyImages.Where(x => x.UserId == userId),
                cancellationToken);

            await RemoveRangeAsync(
                dbContext.PasswordResetCodes.Where(x => x.UserId == userId),
                cancellationToken);

            await RemoveRangeAsync(
                dbContext.UserAdminPermissions.Where(x => x.UserId == userId),
                cancellationToken);

            await RemoveRangeAsync(
                dbContext.ChatUserKeys.Where(x => x.UserId == userId),
                cancellationToken);

            await RemoveRangeAsync(
                dbContext.MissedProductSearches.Where(x => x.UserId == userId),
                cancellationToken);

            await RemoveRangeAsync(
                dbContext.SupportCallbackRequests.Where(x => x.UserId == userId),
                cancellationToken);

            // Admin audit rows Restrict on ActorUserId — remove before Users delete.
            await RemoveRangeAsync(
                dbContext.AdminAuditLogs.Where(x => x.ActorUserId == userId),
                cancellationToken);

            if (!string.IsNullOrWhiteSpace(user.Email))
            {
                var normalizedEmail = user.Email.Trim().ToLowerInvariant();
                await RemoveRangeAsync(
                    dbContext.EmailOtps.Where(x =>
                        x.Email == normalizedEmail || x.Email == user.Email),
                    cancellationToken);
            }

            // Flush dependents, then user row.
            await dbContext.SaveChangesAsync(cancellationToken);

            dbContext.Users.Remove(user);
            await dbContext.SaveChangesAsync(cancellationToken);
            await transaction.CommitAsync(cancellationToken);
        }
        catch
        {
            await transaction.RollbackAsync(cancellationToken);
            throw;
        }

        if (ownedProductIds.Count > 0)
        {
            ProductsAppService.InvalidateListingCaches();
        }

        await DeletePhysicalFilesAsync(filePaths, cancellationToken);
        await DeleteProductVectorsAsync(ownedProductIds, cancellationToken);
    }

    private async Task DeleteProductVectorsAsync(
        IReadOnlyList<Guid> productIds,
        CancellationToken cancellationToken)
    {
        foreach (var productId in productIds)
        {
            try
            {
                await productImageVectorIndex.DeleteByProductIdAsync(productId, cancellationToken);
            }
            catch (Exception ex)
            {
                logger.LogWarning(
                    ex,
                    "Failed removing Qdrant vectors for product {ProductId} during account deletion",
                    productId);
            }
        }
    }

    private async Task<HashSet<string>> CollectUserFilePathsAsync(
        User user,
        IReadOnlyList<Guid> ownedProductIds,
        IReadOnlyList<long> orderIds,
        CancellationToken cancellationToken)
    {
        var paths = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        void Add(string? path)
        {
            var normalized = WebRootFileHelper.NormalizeStoredPath(path);
            if (!string.IsNullOrWhiteSpace(normalized))
            {
                paths.Add(normalized);
            }
        }

        Add(user.ImgPath);
        Add(user.LicencePath);

        var companyImages = await dbContext.CompanyImages
            .AsNoTracking()
            .Where(x => x.UserId == user.Id)
            .Select(x => x.ImagePath)
            .ToListAsync(cancellationToken);
        foreach (var path in companyImages)
        {
            Add(path);
        }

        if (ownedProductIds.Count > 0)
        {
            var productVideoPaths = await dbContext.Products
                .AsNoTracking()
                .Where(x => ownedProductIds.Contains(x.ProductId))
                .Select(x => x.VideoPath)
                .ToListAsync(cancellationToken);
            foreach (var path in productVideoPaths)
            {
                Add(path);
            }

            var imagePaths = await dbContext.ProductImages
                .AsNoTracking()
                .Where(x => ownedProductIds.Contains(x.ProductId))
                .Select(x => x.ImagePath)
                .ToListAsync(cancellationToken);
            foreach (var path in imagePaths)
            {
                Add(path);
            }

            var documentPaths = await dbContext.ProductDocuments
                .AsNoTracking()
                .Where(x => ownedProductIds.Contains(x.ProductId))
                .Select(x => x.DocumentPath)
                .ToListAsync(cancellationToken);
            foreach (var path in documentPaths)
            {
                Add(path);
            }

            var extraVideoPaths = await dbContext.ProductVideos
                .AsNoTracking()
                .Where(x => ownedProductIds.Contains(x.ProductId))
                .Select(x => x.VideoPath)
                .ToListAsync(cancellationToken);
            foreach (var path in extraVideoPaths)
            {
                Add(path);
            }
        }

        if (orderIds.Count > 0)
        {
            var orderImagePaths = await dbContext.OrderImages
                .AsNoTracking()
                .Where(x => orderIds.Contains(x.OrderId))
                .Select(x => x.ImagePath)
                .ToListAsync(cancellationToken);
            foreach (var path in orderImagePaths)
            {
                Add(path);
            }

            var orderVideoPaths = await dbContext.OrderVideos
                .AsNoTracking()
                .Where(x => orderIds.Contains(x.OrderId))
                .Select(x => x.VideoPath)
                .ToListAsync(cancellationToken);
            foreach (var path in orderVideoPaths)
            {
                Add(path);
            }

            var returnMediaJsonRows = await dbContext.Orders
                .AsNoTracking()
                .Where(x => orderIds.Contains(x.Id) && x.ReturnMediaPathsJson != null)
                .Select(x => x.ReturnMediaPathsJson!)
                .ToListAsync(cancellationToken);
            foreach (var json in returnMediaJsonRows)
            {
                foreach (var path in ParseReturnMediaPaths(json))
                {
                    Add(path);
                }
            }
        }

        var chatMediaPaths = await dbContext.ChatMessages
            .AsNoTracking()
            .Where(x =>
                (x.FromUserId == user.Id || x.ToUserId == user.Id)
                && (x.MessageType == ChatMessageType.Image
                    || x.MessageType == ChatMessageType.Voice
                    || x.MessageType == ChatMessageType.Video))
            .Select(x => x.Content)
            .ToListAsync(cancellationToken);
        foreach (var path in chatMediaPaths)
        {
            Add(path);
        }

        // File messages store JSON (path + original name), so the path has to be parsed out.
        var chatFileContents = await dbContext.ChatMessages
            .AsNoTracking()
            .Where(x =>
                (x.FromUserId == user.Id || x.ToUserId == user.Id)
                && x.MessageType == ChatMessageType.File)
            .Select(x => x.Content)
            .ToListAsync(cancellationToken);
        foreach (var content in chatFileContents)
        {
            if (ChatFileContentHelper.TryParse(content, out var fileContent))
            {
                Add(fileContent.Path);
            }
        }

        return paths;
    }

    private static IEnumerable<string> ParseReturnMediaPaths(string json)
    {
        try
        {
            var paths = JsonSerializer.Deserialize<List<string>>(json);
            return paths ?? [];
        }
        catch
        {
            return [];
        }
    }

    private async Task DeletePhysicalFilesAsync(
        IReadOnlyCollection<string> paths,
        CancellationToken cancellationToken)
    {
        foreach (var path in paths)
        {
            await mediaStorage.DeleteAsync(path, cancellationToken);
        }
    }

    private async Task RemoveRangeAsync<TEntity>(
        IQueryable<TEntity> query,
        CancellationToken cancellationToken)
        where TEntity : class
    {
        var items = await query.ToListAsync(cancellationToken);
        if (items.Count == 0)
        {
            return;
        }

        if (dbContext is not DbContext efContext)
        {
            throw new InvalidOperationException("Database context must support entity sets.");
        }

        efContext.Set<TEntity>().RemoveRange(items);
    }
}
