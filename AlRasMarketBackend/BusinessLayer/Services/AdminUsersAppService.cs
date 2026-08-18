using BusinessLayer.Constants;
using BusinessLayer.Dtos;
using BusinessLayer.Helpers;
using BusinessLayer.Interfaces;
using DataLayer.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace BusinessLayer.Services;

public class AdminUsersAppService(
    IRasAlSouqDbContext dbContext,
    IAccountDeletionAppService accountDeletionAppService,
    IContentTranslationService contentTranslationService) : IAdminUsersAppService
{
    public async Task<object> GetUsersAsync(
        int page,
        int pageSize,
        byte? roleId,
        string? search,
        string? status,
        DateTime? joinedFrom,
        DateTime? joinedTo,
        CancellationToken cancellationToken = default,
        bool companiesOnly = false)
    {
        page = page < 1 ? 1 : page;
        pageSize = pageSize is < 1 or > 100 ? 20 : pageSize;

        var query = dbContext.Users.AsNoTracking().Include(x => x.Role).AsQueryable();

        if (companiesOnly)
        {
            query = query.Where(x =>
                x.RoleId == RoleIds.Seller || x.RoleId == RoleIds.ShippingCompany);
        }
        else if (roleId.HasValue)
        {
            query = query.Where(x => x.RoleId == roleId.Value);
        }

        if (!string.IsNullOrWhiteSpace(search))
        {
            var term = search.Trim().ToLowerInvariant();
            query = query.Where(x =>
                x.FullName.ToLower().Contains(term)
                || x.Email.ToLower().Contains(term)
                || (x.CompanyName != null && x.CompanyName.ToLower().Contains(term)));
        }

        if (!string.IsNullOrWhiteSpace(status))
        {
            query = status.Trim().ToLowerInvariant() switch
            {
                "complete" or "مكتمل" => query.Where(x =>
                    x.IsActive
                    && x.IsVerified
                    && !x.IsRejected
                    && (x.PendingProfileChanges == null || x.PendingProfileChanges == string.Empty)),
                "incomplete" or "غير مكتمل" => query.Where(x =>
                    x.IsActive
                    && !x.IsVerified
                    && !x.IsRejected
                    && (x.PendingProfileChanges == null || x.PendingProfileChanges == string.Empty)),
                "pending" or "بانتظار الموافقة" => query.Where(x =>
                    !x.IsRejected
                    && (
                        ((x.RoleId == RoleIds.Seller || x.RoleId == RoleIds.ShippingCompany) && !x.IsApproved && x.IsVerified)
                        || (x.PendingProfileChanges != null && x.PendingProfileChanges != string.Empty))),
                "rejected" or "مرفوض" => query.Where(x => x.IsRejected),
                "suspended" or "موقوف" => query.Where(x =>
                    !x.IsActive && !x.IsRejected &&
                    (x.RoleId != RoleIds.Seller && x.RoleId != RoleIds.ShippingCompany || x.IsApproved)
                    && (x.PendingProfileChanges == null || x.PendingProfileChanges == string.Empty)),
                _ => query
            };
        }

        if (joinedFrom.HasValue)
        {
            var from = DateTime.SpecifyKind(joinedFrom.Value.Date, DateTimeKind.Utc);
            query = query.Where(x => x.CreatedAt >= from);
        }

        if (joinedTo.HasValue)
        {
            var to = DateTime.SpecifyKind(joinedTo.Value.Date.AddDays(1), DateTimeKind.Utc);
            query = query.Where(x => x.CreatedAt < to);
        }

        var totalCount = await query.CountAsync(cancellationToken);
        var items = await query
            // New registrations first; company profile-edit reviews last.
            .OrderBy(x =>
                x.PendingProfileChanges != null && x.PendingProfileChanges != string.Empty)
            .ThenByDescending(x => x.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(x => new AdminUserListItemDto
            {
                Id = x.Id,
                FullName = x.FullName,
                Email = x.Email,
                PhoneNumber = x.PhoneNumber,
                RoleId = x.RoleId,
                RoleName = AdminMappings.GetRoleName(x.RoleId, x.IsCustomer),
                RoleLabelAr = AdminMappings.GetRoleLabelAr(x.RoleId, x.IsCustomer),
                TypeLabelAr = AdminMappings.GetUserTypeLabelAr(x.RoleId, x.IsCustomer),
                IsCustomer = x.IsCustomer == true,
                HasPendingProfileChanges =
                    x.PendingProfileChanges != null && x.PendingProfileChanges != string.Empty,
                CanApprove = !x.IsRejected
                    && (
                        ((x.RoleId == RoleIds.Seller || x.RoleId == RoleIds.ShippingCompany) && !x.IsApproved && x.IsVerified)
                        || (x.PendingProfileChanges != null && x.PendingProfileChanges != string.Empty)),
                StatusLabelAr = AdminMappings.GetUserStatusLabelAr(
                    x.IsActive,
                    x.IsVerified,
                    x.RoleId,
                    x.IsRejected,
                    x.IsApproved,
                    x.PendingProfileChanges != null && x.PendingProfileChanges != string.Empty),
                IsActive = x.IsActive,
                IsVerified = x.IsVerified,
                IsRejected = x.IsRejected,
                CreatedAt = UtcDateTimeHelper.AsUtc(x.CreatedAt),
                ImgPath = x.ImgPath,
                CompanyName = x.CompanyName,
                OrdersCount = dbContext.Orders.Count(o => o.FromUserId == x.Id || o.ToUserId == x.Id)
            })
            .ToListAsync(cancellationToken);

        var translations = await contentTranslationService.GetUserTranslationsAsync(
            items.Select(x => x.Id),
            cancellationToken);
        foreach (var item in items)
        {
            translations.TryGetValue(item.Id, out var tr);
            AdminUserTextHelper.ApplyToUserListItem(item, tr);
        }

        return new AdminPagedResult<AdminUserListItemDto>
        {
            Page = page,
            PageSize = pageSize,
            TotalCount = totalCount,
            TotalPages = (int)Math.Ceiling(totalCount / (double)pageSize),
            Items = items
        };
    }

    public async Task<AdminUserDetailDto> GetUserByIdAsync(
        string userId,
        CancellationToken cancellationToken = default)
    {
        if (!Guid.TryParse(userId, out var parsedUserId))
        {
            throw new ArgumentException("Invalid user id.");
        }

        var user = await dbContext.Users
            .AsNoTracking()
            .Include(x => x.Role)
            .Include(x => x.CompanyImages)
            .Include(x => x.Addresses)
                .ThenInclude(a => a.AddressType)
            .Include(x => x.Addresses)
                .ThenInclude(a => a.City!)
                    .ThenInclude(c => c.Country)
            .FirstOrDefaultAsync(x => x.Id == parsedUserId, cancellationToken)
            ?? throw new KeyNotFoundException("User not found.");

        var ordersCount = await dbContext.Orders.CountAsync(
            o => o.FromUserId == user.Id || o.ToUserId == user.Id,
            cancellationToken);

        var dto = new AdminUserDetailDto
        {
            Id = user.Id,
            FullName = user.FullName,
            Email = user.Email,
            PhoneNumber = user.PhoneNumber,
            LandNumber = user.LandNumber,
            RoleId = user.RoleId,
            RoleName = AdminMappings.GetRoleName(user.RoleId, user.IsCustomer),
            RoleLabelAr = AdminMappings.GetRoleLabelAr(user.RoleId, user.IsCustomer),
            TypeLabelAr = AdminMappings.GetUserTypeLabelAr(user.RoleId, user.IsCustomer),
            IsCustomer = user.IsCustomer == true,
            StatusLabelAr = AdminMappings.GetUserStatusLabelAr(
                user.IsActive,
                user.IsVerified,
                user.RoleId,
                user.IsRejected,
                user.IsApproved,
                !string.IsNullOrWhiteSpace(user.PendingProfileChanges)),
            IsActive = user.IsActive,
            IsVerified = user.IsVerified,
            IsRejected = user.IsRejected,
            RejectionReason = user.RejectionReason,
            CreatedAt = UtcDateTimeHelper.AsUtc(user.CreatedAt),
            ImgPath = user.ImgPath,
            CompanyName = user.CompanyName,
            LicenseNumber = user.LicenseNumber,
            LicencePath = WebRootFileHelper.NormalizeStoredPath(user.LicencePath),
            CommercialRegister = user.CommercialRegister,
            TaxNumber = user.TaxNumber,
            Website = user.Website,
            PendingProfileChanges = MapPendingProfileChanges(user.PendingProfileChanges),
            CompanyImages = user.CompanyImages
                .OrderByDescending(x => x.IsPrimary)
                .ThenBy(x => x.CreatedAt)
                .Select(x => new AdminUserCompanyImageDto
                {
                    Id = x.Id,
                    ImagePath = WebRootFileHelper.NormalizeStoredPath(x.ImagePath),
                    IsPrimary = x.IsPrimary
                })
                .ToList(),
            Addresses = user.Addresses
                .OrderByDescending(x => x.Id)
                .Select(a =>
                {
                    var typeId = a.AddressTypeId == 0 ? AddressTypeCodes.Home : a.AddressTypeId;
                    var cityName = a.City?.CityName;
                    var countryName = a.City?.Country?.CountryNameEn;
                    return new AdminUserAddressDto
                    {
                        AddressId = a.Id,
                        AddressTypeId = typeId,
                        AddressTypeNameEn = a.AddressType?.NameEn ?? AddressTypeCodes.NameEn(typeId),
                        AddressTypeNameAr = a.AddressType?.NameAr ?? AddressTypeCodes.NameAr(typeId),
                        FormattedAddress = AddressTextFormatter.ToDisplayText(a, cityName, countryName)
                            ?? AdminShippingDisplayHelper.FormatAddressParts(a.AddressLine1, a.AddressLine2, cityName)
                            ?? string.Empty,
                        PostalCode = a.PostalCode,
                        Latitude = a.Latitude,
                        Longitude = a.Longitude,
                        Coordinates = AddressTextFormatter.FormatCoordinates(a.Latitude, a.Longitude),
                        MapsUrl = AddressTextFormatter.MapsUrl(a.Latitude, a.Longitude)
                    };
                })
                .ToList(),
            OrdersCount = ordersCount,
            CanApprove = !user.IsRejected
                && (
                    ((user.RoleId == RoleIds.Seller || user.RoleId == RoleIds.ShippingCompany) && !user.IsApproved && user.IsVerified)
                    || !string.IsNullOrWhiteSpace(user.PendingProfileChanges)),
            CanDeactivate = user.RoleId != RoleIds.Admin,
            CanDelete = user.RoleId != RoleIds.Admin
                && (!user.IsApproved || ordersCount == 0)
        };

        var translations = await contentTranslationService.GetUserTranslationsAsync(
            [user.Id],
            cancellationToken);
        translations.TryGetValue(user.Id, out var tr);
        AdminUserTextHelper.ApplyToUserDetail(dto, tr);
        return dto;
    }

    private static PendingCompanyProfileChangeDto? MapPendingProfileChanges(string? raw)
    {
        var pending = PendingCompanyProfileChangeHelper.TryParse(raw);
        if (pending is null || !pending.HasAnyChange)
        {
            return null;
        }

        return new PendingCompanyProfileChangeDto
        {
            CompanyName = pending.CompanyName,
            CommercialRegister = pending.CommercialRegister,
            TaxNumber = pending.TaxNumber,
            Website = pending.Website,
            LandNumber = pending.LandNumber,
            FullName = pending.FullName,
            PhoneNumber = pending.PhoneNumber
        };
    }

    public async Task<object> SetUserActiveAsync(
        string userId,
        bool isActive,
        CancellationToken cancellationToken = default)
    {
        if (!Guid.TryParse(userId, out var parsedUserId))
        {
            throw new ArgumentException("Invalid user id.");
        }

        var user = await dbContext.Users
            .FirstOrDefaultAsync(x => x.Id == parsedUserId, cancellationToken)
            ?? throw new KeyNotFoundException("User not found.");

        if (user.RoleId == 1)
        {
            throw new InvalidOperationException("Admin accounts cannot be deactivated.");
        }

        if (RoleIds.RequiresAdminApproval(user.RoleId) && !user.IsApproved && !user.IsRejected && !isActive)
        {
            throw new InvalidOperationException(
                "Use reject to decline a pending company registration.");
        }

        user.IsActive = isActive;
        await dbContext.SaveChangesAsync(cancellationToken);

        return new
        {
            message = isActive ? "User account activated." : "User account deactivated.",
            userId = user.Id,
            isActive = user.IsActive
        };
    }

    public async Task<object> DeleteUserAsync(
        string userId,
        CancellationToken cancellationToken = default)
    {
        if (!Guid.TryParse(userId, out var parsedUserId))
        {
            throw new ArgumentException("Invalid user id.");
        }

        var user = await dbContext.Users
            .FirstOrDefaultAsync(x => x.Id == parsedUserId, cancellationToken)
            ?? throw new KeyNotFoundException("User not found.");

        if (user.RoleId == RoleIds.Admin)
        {
            throw new InvalidOperationException("Admin accounts cannot be deleted.");
        }

        var ordersCount = await dbContext.Orders.CountAsync(
            o => o.FromUserId == user.Id || o.ToUserId == user.Id,
            cancellationToken);

        if (user.IsApproved && ordersCount > 0)
        {
            throw new InvalidOperationException(
                "Cannot delete an approved account that has orders.");
        }

        var message = await accountDeletionAppService.DeleteUserByAdminAsync(
            userId,
            cancellationToken);

        return new { message, userId = parsedUserId };
    }
}
