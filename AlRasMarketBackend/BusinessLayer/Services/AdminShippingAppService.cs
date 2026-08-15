using BusinessLayer.Constants;
using BusinessLayer.Dtos;
using BusinessLayer.Helpers;
using BusinessLayer.Interfaces;
using DataLayer.Interfaces;
using DataLayer.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;

namespace BusinessLayer.Services;

public class AdminShippingAppService(
    IRasAlSouqDbContext dbContext,
    IPasswordHasher passwordHasher,
    IStaticReferenceCache staticReferenceCache,
    IAdminRealtimeNotificationService adminRealtimeNotificationService,
    IAdminAuditLogAppService auditLogAppService,
    IMemoryCache cache,
    IMediaStorageService mediaStorage) : IAdminShippingAppService
{
    private const string ShippingProviderImagesFolder = "images/shipping-providers";
    public async Task<object> GetProvidersAsync(
        int page,
        int pageSize,
        string? search,
        CancellationToken cancellationToken = default)
    {
        page = page < 1 ? 1 : page;
        pageSize = pageSize is < 1 or > 100 ? 20 : pageSize;

        var providerIds = dbContext.InternationalShippingPosts
            .Select(x => x.PublisherUserId)
            .Distinct();

        var query = dbContext.Users
            .Where(x => providerIds.Contains(x.Id))
            .AsQueryable();

        if (!string.IsNullOrWhiteSpace(search))
        {
            var term = search.Trim().ToLower();
            query = query.Where(x =>
                x.FullName.ToLower().Contains(term) ||
                (x.CompanyName != null && x.CompanyName.ToLower().Contains(term)) ||
                x.Email.ToLower().Contains(term));
        }

        var totalCount = await query.CountAsync(cancellationToken);
        var users = await query
            .OrderByDescending(x => x.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync(cancellationToken);

        var userIds = users.Select(x => x.Id).ToList();
        var postCounts = await dbContext.InternationalShippingPosts
            .Where(x => userIds.Contains(x.PublisherUserId))
            .GroupBy(x => x.PublisherUserId)
            .Select(g => new { ProviderUserId = g.Key, Count = g.Count() })
            .ToDictionaryAsync(x => x.ProviderUserId, x => x.Count, cancellationToken);

        var latestPosts = await dbContext.InternationalShippingPosts
            .AsNoTracking()
            .Include(x => x.FromCountry)
            .Include(x => x.FromPort)
            .Include(x => x.ToCountry)
            .Include(x => x.ToPort)
            .Where(x => userIds.Contains(x.PublisherUserId))
            .OrderByDescending(x => x.CreatedAt)
            .ToListAsync(cancellationToken);

        var latestPostByUser = latestPosts
            .GroupBy(x => x.PublisherUserId)
            .ToDictionary(g => g.Key, g => g.First());

        await staticReferenceCache.EnsureLoadedAsync(cancellationToken);

        var shipmentCounts = await dbContext.InternationalShipments
            .Where(x => userIds.Contains(x.ProviderUserId))
            .GroupBy(x => x.ProviderUserId)
            .Select(g => new { ProviderUserId = g.Key, Count = g.Count() })
            .ToDictionaryAsync(x => x.ProviderUserId, x => x.Count, cancellationToken);

        var cities = await GetCityNamesByUserIdsAsync(userIds, cancellationToken);

        var items = users.Select(user =>
        {
            latestPostByUser.TryGetValue(user.Id, out var latestPost);
            var route = latestPost is null
                ? null
                : AdminShippingRouteHelper.Resolve(latestPost, staticReferenceCache);

            return new AdminShippingProviderListItemDto
            {
                Id = user.Id,
                CompanyName = user.CompanyName ?? user.FullName,
                ImgPath = user.ImgPath,
                Email = user.Email,
                PhoneNumber = user.PhoneNumber,
                CityName = cities.GetValueOrDefault(user.Id),
                IsActive = user.IsActive,
                TotalShipments = shipmentCounts.GetValueOrDefault(user.Id),
                PostCount = postCounts.GetValueOrDefault(user.Id),
                RegistrationDate = user.CreatedAt,
                FromCountryName = route?.FromCountryName ?? string.Empty,
                FromPortName = route?.FromPortName ?? string.Empty,
                ToCountryName = route?.ToCountryName ?? string.Empty,
                ToPortName = route?.ToPortName ?? string.Empty,
                RouteSummary = route?.RouteSummaryEn ?? string.Empty
            };
        }).ToList();

        return new AdminPagedResult<AdminShippingProviderListItemDto>
        {
            Page = page,
            PageSize = pageSize,
            TotalCount = totalCount,
            TotalPages = (int)Math.Ceiling(totalCount / (double)pageSize),
            Items = items
        };
    }

    public async Task<object> GetProviderDetailAsync(
        string providerUserId,
        CancellationToken cancellationToken = default)
    {
        if (!Guid.TryParse(providerUserId, out var userId))
        {
            throw new ArgumentException("Invalid provider user id.");
        }

        var user = await dbContext.Users.FindAsync([userId], cancellationToken)
            ?? throw new KeyNotFoundException("Shipping provider not found.");

        var latestPost = await dbContext.InternationalShippingPosts
            .AsNoTracking()
            .Include(x => x.FromCountry)
            .Include(x => x.FromPort)
            .Include(x => x.ToCountry)
            .Include(x => x.ToPort)
            .Where(x => x.PublisherUserId == userId)
            .OrderByDescending(x => x.CreatedAt)
            .FirstOrDefaultAsync(cancellationToken);

        if (latestPost is null)
        {
            throw new KeyNotFoundException("Shipping provider not found.");
        }

        await staticReferenceCache.EnsureLoadedAsync(cancellationToken);
        var route = AdminShippingRouteHelper.Resolve(latestPost, staticReferenceCache);

        var cityName = await GetCityNameAsync(userId, cancellationToken);

        var shipmentRows = await dbContext.InternationalShipments
            .Where(x => x.ProviderUserId == userId)
            .Select(x => x.StatusId)
            .ToListAsync(cancellationToken);

        var stats = BuildStats(shipmentRows);

        var shipments = await dbContext.InternationalShipments
            .Include(x => x.Status)
            .Where(x => x.ProviderUserId == userId)
            .OrderByDescending(x => x.CreatedAt)
            .Take(50)
            .Select(x => new AdminShipmentLogItemDto
            {
                Id = x.Id,
                ShipmentCode = x.ShipmentCode,
                OrderId = x.OrderId,
                StatusId = x.StatusId,
                StatusName = x.Status != null ? x.Status.NameEn : ShipmentStatusCodes.GetNameEn(x.StatusId),
                StatusLabelAr = x.Status != null ? x.Status.NameAr : ShipmentStatusCodes.GetNameAr(x.StatusId),
                CreatedAt = x.CreatedAt
            })
            .ToListAsync(cancellationToken);

        return new AdminShippingProviderDetailDto
        {
            Id = user.Id,
            CompanyName = user.CompanyName ?? user.FullName,
            ImgPath = user.ImgPath,
            FullName = user.FullName,
            Email = user.Email,
            PhoneNumber = latestPost.PhoneNumber ?? user.PhoneNumber,
            LandNumber = user.LandNumber,
            CommercialRegister = user.CommercialRegister,
            TaxNumber = user.TaxNumber,
            CityName = cityName,
            FromCountryId = route.FromCountryId,
            FromPortId = route.FromPortId,
            ToCountryId = route.ToCountryId,
            ToPortId = route.ToPortId,
            FromCountryName = route.FromCountryName,
            FromCountryNameAr = route.FromCountryNameAr,
            FromPortName = route.FromPortName,
            FromPortUnLocode = route.FromPortUnLocode,
            ToCountryName = route.ToCountryName,
            ToCountryNameAr = route.ToCountryNameAr,
            ToPortName = route.ToPortName,
            ToPortUnLocode = route.ToPortUnLocode,
            RouteSummary = route.RouteSummaryEn,
            RouteSummaryAr = route.RouteSummaryAr,
            Container20ftPriceUsd = latestPost.Container20ftPriceUsd,
            Container40ftPriceUsd = latestPost.Container40ftPriceUsd,
            Container20ftPriceFormatted = FormatUsd(latestPost.Container20ftPriceUsd),
            Container40ftPriceFormatted = FormatUsd(latestPost.Container40ftPriceUsd),
            LatestPostId = latestPost.Id,
            PostStatus = latestPost.Status,
            PostStatusLabelAr = AdminMappings.GetProductStatusLabelAr(
                latestPost.Status,
                latestPost.IsApproved),
            IsPostApproved = latestPost.IsApproved,
            CanApprovePost = ProductStatusCodes.IsPendingReview(latestPost.Status, latestPost.IsApproved),
            IsActive = user.IsActive,
            RegistrationLinkSent = user.IsVerified,
            RegistrationDate = user.CreatedAt,
            Stats = stats,
            Shipments = shipments
        };
    }

    public async Task<object> SetProviderActiveAsync(
        string providerUserId,
        bool isActive,
        CancellationToken cancellationToken = default)
    {
        if (!Guid.TryParse(providerUserId, out var userId))
        {
            throw new ArgumentException("Invalid provider user id.");
        }

        var user = await dbContext.Users.FindAsync([userId], cancellationToken)
            ?? throw new KeyNotFoundException("Shipping provider not found.");

        var hasPosts = await dbContext.InternationalShippingPosts
            .AnyAsync(x => x.PublisherUserId == userId, cancellationToken);

        if (!hasPosts)
        {
            throw new KeyNotFoundException("Shipping provider not found.");
        }

        user.IsActive = isActive;
        await dbContext.SaveChangesAsync(cancellationToken);

        await auditLogAppService.WriteAsync(
            AdminAuditActions.ShippingProviderSetActive,
            AdminAuditEntityTypes.Shipping,
            user.Id.ToString("D"),
            isActive
                ? $"Activated shipping provider '{user.CompanyName ?? user.FullName}'"
                : $"Disabled shipping provider '{user.CompanyName ?? user.FullName}'",
            new { isActive, email = user.Email },
            cancellationToken);

        return new
        {
            message = isActive ? "Shipping provider activated." : "Shipping provider disabled.",
            isActive
        };
    }

    public async Task<object> CreateProviderAsync(
        AdminCreateShippingProviderInput input,
        CancellationToken cancellationToken = default)
    {
        ValidateCreateInput(input);

        var normalizedEmail = input.Email.Trim().ToLowerInvariant();
        var emailTaken = await dbContext.Users
            .AnyAsync(x => x.Email.ToLower() == normalizedEmail, cancellationToken);

        if (emailTaken)
        {
            throw new InvalidOperationException("Email already exists.");
        }

        await staticReferenceCache.EnsureLoadedAsync(cancellationToken);

        var fromCountry = staticReferenceCache.FindCountryByEnglishName(input.FromCountryName.Trim())
            ?? throw new KeyNotFoundException($"From country '{input.FromCountryName}' was not found.");

        var toCountry = staticReferenceCache.FindCountryByEnglishName(input.ToCountryName.Trim())
            ?? throw new KeyNotFoundException($"To country '{input.ToCountryName}' was not found.");

        var fromPort = staticReferenceCache.FindPortByEnglishName(input.FromPortName.Trim(), fromCountry.Id)
            ?? throw new KeyNotFoundException($"From port '{input.FromPortName}' was not found for country '{input.FromCountryName}'.");

        var toPort = staticReferenceCache.FindPortByEnglishName(input.ToPortName.Trim(), toCountry.Id)
            ?? throw new KeyNotFoundException($"To port '{input.ToPortName}' was not found for country '{input.ToCountryName}'.");

        var user = new User
        {
            Id = Guid.NewGuid(),
            FullName = input.FullName.Trim(),
            CompanyName = input.CompanyName.Trim(),
            Email = normalizedEmail,
            HashedPassword = passwordHasher.HashPassword(Guid.NewGuid().ToString("N")),
            RoleId = RoleIds.ShippingCompany,
            LoginProviderName = "Local",
            IsActive = true,
            IsVerified = true,
            PhoneNumber = input.PhoneNumber.Trim(),
            CreatedAt = DateTime.UtcNow
        };

        var post = new InternationalShippingPost
        {
            PublisherUserId = user.Id,
            FromCountryId = fromCountry.Id,
            FromPortId = fromPort.Id,
            ToCountryId = toCountry.Id,
            ToPortId = toPort.Id,
            PriceUsd = CustomerPriceCalculator.ResolveShippingListPrice(
                input.Container20ftPriceUsd,
                input.Container40ftPriceUsd),
            ShippingCostUsd = 0,
            PhoneNumber = input.PhoneNumber.Trim(),
            Container20ftPriceUsd = input.Container20ftPriceUsd,
            Container40ftPriceUsd = input.Container40ftPriceUsd,
            Status = ProductStatusCodes.Active,
            IsApproved = true,
            CreatedAt = DateTime.UtcNow
        };

        await dbContext.Users.AddAsync(user, cancellationToken);
        await dbContext.InternationalShippingPosts.AddAsync(post, cancellationToken);

        await dbContext.SaveChangesAsync(cancellationToken);

        await auditLogAppService.WriteAsync(
            AdminAuditActions.ShippingProviderCreate,
            AdminAuditEntityTypes.Shipping,
            user.Id.ToString("D"),
            $"Created shipping provider '{user.CompanyName ?? user.FullName}'",
            new
            {
                email = user.Email,
                fromCountry = input.FromCountryName,
                toCountry = input.ToCountryName,
                postId = post.Id
            },
            cancellationToken);

        return new AdminShippingProviderListItemDto
        {
            Id = user.Id,
            CompanyName = user.CompanyName ?? user.FullName,
            ImgPath = user.ImgPath,
            Email = user.Email,
            PhoneNumber = user.PhoneNumber,
            IsActive = user.IsActive,
            TotalShipments = 0,
            PostCount = 1,
            RegistrationDate = user.CreatedAt
        };
    }

    private static void ValidateCreateInput(AdminCreateShippingProviderInput input)
    {
        if (string.IsNullOrWhiteSpace(input.CompanyName))
        {
            throw new ArgumentException("CompanyName is required.");
        }

        if (string.IsNullOrWhiteSpace(input.FullName))
        {
            throw new ArgumentException("FullName is required.");
        }

        if (string.IsNullOrWhiteSpace(input.Email))
        {
            throw new ArgumentException("Email is required.");
        }

        if (string.IsNullOrWhiteSpace(input.PhoneNumber))
        {
            throw new ArgumentException("PhoneNumber is required.");
        }

        if (string.IsNullOrWhiteSpace(input.FromCountryName) ||
            string.IsNullOrWhiteSpace(input.FromPortName) ||
            string.IsNullOrWhiteSpace(input.ToCountryName) ||
            string.IsNullOrWhiteSpace(input.ToPortName))
        {
            throw new ArgumentException("From/To country and port names are required.");
        }

        input.Container20ftPriceUsd =
            CustomerPriceCalculator.NormalizeOptionalContainerPrice(input.Container20ftPriceUsd);
        input.Container40ftPriceUsd =
            CustomerPriceCalculator.NormalizeOptionalContainerPrice(input.Container40ftPriceUsd);
    }

    public async Task<object> UpdateProviderAsync(
        string providerUserId,
        AdminUpdateShippingProviderInput input,
        CancellationToken cancellationToken = default)
    {
        ValidateUpdateInput(input);

        if (!Guid.TryParse(providerUserId, out var userId))
        {
            throw new ArgumentException("Invalid provider user id.");
        }

        var user = await dbContext.Users.FindAsync([userId], cancellationToken)
            ?? throw new KeyNotFoundException("Shipping provider not found.");

        var latestPost = await dbContext.InternationalShippingPosts
            .Where(x => x.PublisherUserId == userId)
            .OrderByDescending(x => x.CreatedAt)
            .FirstOrDefaultAsync(cancellationToken)
            ?? throw new KeyNotFoundException("Shipping provider not found.");

        var normalizedEmail = input.Email.Trim().ToLowerInvariant();
        var emailTaken = await dbContext.Users
            .AnyAsync(x => x.Email.ToLower() == normalizedEmail && x.Id != userId, cancellationToken);

        if (emailTaken)
        {
            throw new InvalidOperationException("Email already exists.");
        }

        await staticReferenceCache.EnsureLoadedAsync(cancellationToken);

        var fromCountry = staticReferenceCache.FindCountryByEnglishName(input.FromCountryName.Trim())
            ?? throw new KeyNotFoundException($"From country '{input.FromCountryName}' was not found.");

        var toCountry = staticReferenceCache.FindCountryByEnglishName(input.ToCountryName.Trim())
            ?? throw new KeyNotFoundException($"To country '{input.ToCountryName}' was not found.");

        var fromPort = staticReferenceCache.FindPortByEnglishName(input.FromPortName.Trim(), fromCountry.Id)
            ?? throw new KeyNotFoundException($"From port '{input.FromPortName}' was not found for country '{input.FromCountryName}'.");

        var toPort = staticReferenceCache.FindPortByEnglishName(input.ToPortName.Trim(), toCountry.Id)
            ?? throw new KeyNotFoundException($"To port '{input.ToPortName}' was not found for country '{input.ToCountryName}'.");

        user.FullName = input.FullName.Trim();
        user.CompanyName = input.CompanyName.Trim();
        user.Email = normalizedEmail;
        user.PhoneNumber = input.PhoneNumber.Trim();

        latestPost.FromCountryId = fromCountry.Id;
        latestPost.FromPortId = fromPort.Id;
        latestPost.ToCountryId = toCountry.Id;
        latestPost.ToPortId = toPort.Id;
        latestPost.PriceUsd = CustomerPriceCalculator.ResolveShippingListPrice(
            input.Container20ftPriceUsd,
            input.Container40ftPriceUsd);
        latestPost.ShippingCostUsd = 0;
        latestPost.PhoneNumber = input.PhoneNumber.Trim();
        latestPost.Container20ftPriceUsd =
            CustomerPriceCalculator.NormalizeOptionalContainerPrice(input.Container20ftPriceUsd);
        latestPost.Container40ftPriceUsd =
            CustomerPriceCalculator.NormalizeOptionalContainerPrice(input.Container40ftPriceUsd);

        await dbContext.SaveChangesAsync(cancellationToken);

        await auditLogAppService.WriteAsync(
            AdminAuditActions.ShippingProviderUpdate,
            AdminAuditEntityTypes.Shipping,
            user.Id.ToString("D"),
            $"Updated shipping provider '{user.CompanyName ?? user.FullName}'",
            new
            {
                email = user.Email,
                fromCountry = input.FromCountryName,
                toCountry = input.ToCountryName,
                postId = latestPost.Id
            },
            cancellationToken);

        return await GetProviderDetailAsync(providerUserId, cancellationToken);
    }

    public async Task<object> UploadProviderImageAsync(
        AdminUploadShippingProviderImageInput input,
        CancellationToken cancellationToken = default)
    {
        if (input.File is null || input.File.Length == 0)
        {
            throw new ArgumentException("File is required.");
        }

        if (!Guid.TryParse(input.ProviderUserId, out var userId))
        {
            throw new ArgumentException("Invalid provider user id.");
        }

        var isProvider = await dbContext.InternationalShippingPosts
            .AnyAsync(x => x.PublisherUserId == userId, cancellationToken);

        if (!isProvider)
        {
            throw new KeyNotFoundException("Shipping provider not found.");
        }

        var user = await dbContext.Users.FindAsync([userId], cancellationToken)
            ?? throw new KeyNotFoundException("Shipping provider not found.");

        var fileName = $"{userId:N}.jpg";
        var previousPath = user.ImgPath;

        user.ImgPath = await mediaStorage.SaveCompressedJpegAsync(
            input.File,
            ShippingProviderImagesFolder,
            fileName,
            cancellationToken: cancellationToken);
        await dbContext.SaveChangesAsync(cancellationToken);

        if (!string.Equals(previousPath, user.ImgPath, StringComparison.OrdinalIgnoreCase))
        {
            await mediaStorage.DeleteAsync(previousPath, cancellationToken);
        }

        await auditLogAppService.WriteAsync(
            AdminAuditActions.ShippingProviderUpdate,
            AdminAuditEntityTypes.Shipping,
            user.Id.ToString("D"),
            $"Updated shipping provider image for '{user.CompanyName ?? user.FullName}'",
            new { imgPath = user.ImgPath },
            cancellationToken);

        return new
        {
            user.Id,
            user.CompanyName,
            imgPath = user.ImgPath
        };
    }

    private static void ValidateUpdateInput(AdminUpdateShippingProviderInput input)
    {
        if (string.IsNullOrWhiteSpace(input.CompanyName))
        {
            throw new ArgumentException("CompanyName is required.");
        }

        if (string.IsNullOrWhiteSpace(input.FullName))
        {
            throw new ArgumentException("FullName is required.");
        }

        if (string.IsNullOrWhiteSpace(input.Email))
        {
            throw new ArgumentException("Email is required.");
        }

        if (string.IsNullOrWhiteSpace(input.PhoneNumber))
        {
            throw new ArgumentException("PhoneNumber is required.");
        }

        if (string.IsNullOrWhiteSpace(input.FromCountryName) ||
            string.IsNullOrWhiteSpace(input.FromPortName) ||
            string.IsNullOrWhiteSpace(input.ToCountryName) ||
            string.IsNullOrWhiteSpace(input.ToPortName))
        {
            throw new ArgumentException("From/To country and port names are required.");
        }

        input.Container20ftPriceUsd =
            CustomerPriceCalculator.NormalizeOptionalContainerPrice(input.Container20ftPriceUsd);
        input.Container40ftPriceUsd =
            CustomerPriceCalculator.NormalizeOptionalContainerPrice(input.Container40ftPriceUsd);
    }

    public async Task<object> DeleteProviderAsync(
        string providerUserId,
        CancellationToken cancellationToken = default)
    {
        if (!Guid.TryParse(providerUserId, out var userId))
        {
            throw new ArgumentException("Invalid provider user id.");
        }

        var user = await dbContext.Users.FindAsync([userId], cancellationToken)
            ?? throw new KeyNotFoundException("Shipping provider not found.");

        var hasPosts = await dbContext.InternationalShippingPosts
            .AnyAsync(x => x.PublisherUserId == userId, cancellationToken);

        if (!hasPosts)
        {
            throw new KeyNotFoundException("Shipping provider not found.");
        }

        var hasShipments = await dbContext.InternationalShipments
            .AnyAsync(x => x.ProviderUserId == userId, cancellationToken);

        if (hasShipments)
        {
            throw new InvalidOperationException("Cannot delete a shipping company that has shipments.");
        }

        var hasProducts = await dbContext.Products
            .AnyAsync(x => x.OwnerId == userId, cancellationToken);

        if (hasProducts)
        {
            throw new InvalidOperationException("Cannot delete a shipping company linked to product listings.");
        }

        var posts = await dbContext.InternationalShippingPosts
            .Where(x => x.PublisherUserId == userId)
            .ToListAsync(cancellationToken);
        dbContext.InternationalShippingPosts.RemoveRange(posts);

        var addresses = await dbContext.Addresses
            .Where(x => x.UserId == userId)
            .ToListAsync(cancellationToken);
        dbContext.Addresses.RemoveRange(addresses);

        var companyName = user.CompanyName ?? user.FullName;
        var email = user.Email;

        dbContext.Users.Remove(user);
        await dbContext.SaveChangesAsync(cancellationToken);

        await auditLogAppService.WriteAsync(
            AdminAuditActions.ShippingProviderDelete,
            AdminAuditEntityTypes.Shipping,
            userId.ToString("D"),
            $"Deleted shipping provider '{companyName}'",
            new { email },
            cancellationToken);

        return new { message = "Shipping provider deleted." };
    }

    public async Task<string> ApprovePostAsync(long postId, CancellationToken cancellationToken = default)
    {
        var post = await dbContext.InternationalShippingPosts
            .FirstOrDefaultAsync(x => x.Id == postId, cancellationToken)
            ?? throw new KeyNotFoundException("Shipping post not found.");

        if (post.IsApproved && post.Status == ProductStatusCodes.Active)
        {
            throw new InvalidOperationException("Shipping post is already approved.");
        }

        post.IsApproved = true;
        post.Status = ProductStatusCodes.Active;
        await dbContext.SaveChangesAsync(cancellationToken);
        InvalidateSearchCache();
        await adminRealtimeNotificationService.BroadcastCountsAsync(cancellationToken);

        await auditLogAppService.WriteAsync(
            AdminAuditActions.ShippingPostApprove,
            AdminAuditEntityTypes.Shipping,
            postId.ToString(),
            $"Approved shipping post #{postId}",
            new { publisherUserId = post.PublisherUserId },
            cancellationToken);

        return "Shipping post approved successfully.";
    }

    public async Task<string> RejectPostAsync(
        long postId,
        string? reason,
        CancellationToken cancellationToken = default)
    {
        var post = await dbContext.InternationalShippingPosts
            .FirstOrDefaultAsync(x => x.Id == postId, cancellationToken)
            ?? throw new KeyNotFoundException("Shipping post not found.");

        if (post.IsApproved && post.Status == ProductStatusCodes.Active)
        {
            throw new InvalidOperationException("Approved shipping posts cannot be rejected.");
        }

        post.IsApproved = false;
        post.Status = ProductStatusCodes.Rejected;
        if (!string.IsNullOrWhiteSpace(reason))
        {
            post.Details = string.IsNullOrWhiteSpace(post.Details)
                ? $"Rejected: {reason.Trim()}"
                : $"{post.Details}\nRejected: {reason.Trim()}";
        }

        await dbContext.SaveChangesAsync(cancellationToken);
        InvalidateSearchCache();
        await adminRealtimeNotificationService.BroadcastCountsAsync(cancellationToken);

        await auditLogAppService.WriteAsync(
            AdminAuditActions.ShippingPostReject,
            AdminAuditEntityTypes.Shipping,
            postId.ToString(),
            $"Rejected shipping post #{postId}",
            new { publisherUserId = post.PublisherUserId, reason },
            cancellationToken);

        return "Shipping post rejected.";
    }

    private void InvalidateSearchCache()
    {
        if (cache is MemoryCache memoryCache)
        {
            memoryCache.Compact(1.0);
        }
    }

    private static AdminShippingStatsDto BuildStats(IReadOnlyList<byte> statusIds)
    {
        var total = statusIds.Count;
        var completed = statusIds.Count(x => x == ShipmentStatusCodes.Completed);
        var inDelivery = statusIds.Count(x => x == ShipmentStatusCodes.InDelivery);
        var late = statusIds.Count(x => x == ShipmentStatusCodes.Late);

        return new AdminShippingStatsDto
        {
            TotalShipments = total,
            Completed = completed,
            InDelivery = inDelivery,
            Late = late,
            SuccessRate = total == 0
                ? 0
                : decimal.Round(completed * 100m / total, 1, MidpointRounding.AwayFromZero)
        };
    }

    private async Task<string?> GetCityNameAsync(Guid userId, CancellationToken cancellationToken)
    {
        return await dbContext.Addresses
            .Include(x => x.City)
            .Where(x => x.UserId == userId)
            .OrderBy(x => x.Id)
            .Select(x => x.City!.CityName)
            .FirstOrDefaultAsync(cancellationToken);
    }

    private async Task<Dictionary<Guid, string>> GetCityNamesByUserIdsAsync(
        IReadOnlyList<Guid> userIds,
        CancellationToken cancellationToken)
    {
        if (userIds.Count == 0)
        {
            return [];
        }

        var rows = await dbContext.Addresses
            .Include(x => x.City)
            .Where(x => userIds.Contains(x.UserId))
            .OrderBy(x => x.Id)
            .Select(x => new { x.UserId, CityName = x.City!.CityName })
            .ToListAsync(cancellationToken);

        return rows
            .GroupBy(x => x.UserId)
            .ToDictionary(g => g.Key, g => g.First().CityName);
    }

    private static string FormatUsd(decimal? value) =>
        value is > 0 ? $"${value.Value:N0}" : "—";
}
