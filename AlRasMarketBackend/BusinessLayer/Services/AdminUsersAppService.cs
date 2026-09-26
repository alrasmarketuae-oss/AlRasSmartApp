using System.Net.Mail;
using BusinessLayer.Constants;
using BusinessLayer.Dtos;
using BusinessLayer.Helpers;
using BusinessLayer.Interfaces;
using DataLayer.Interfaces;
using DataLayer.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace BusinessLayer.Services;

public class AdminUsersAppService(
    IRasAlSouqDbContext dbContext,
    IAccountDeletionAppService accountDeletionAppService,
    IContentTranslationService contentTranslationService,
    IPasswordHasher passwordHasher,
    UserNameTranslationQueue userNameTranslationQueue,
    IAddressesAppService addressesAppService,
    IAdminAuditLogAppService auditLogAppService,
    ILogger<AdminUsersAppService> logger) : IAdminUsersAppService
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
        bool companiesOnly = false,
        bool? isCustomer = null,
        bool pendingProfileEditsOnly = false)
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
            if (roleId.Value == RoleIds.Seller && isCustomer.HasValue)
            {
                query = isCustomer.Value
                    ? query.Where(x => x.IsCustomer == true)
                    : query.Where(x => x.IsCustomer != true);
            }
        }

        if (pendingProfileEditsOnly)
        {
            query = query.Where(x =>
                x.PendingProfileChanges != null && x.PendingProfileChanges != string.Empty);
        }

        if (!string.IsNullOrWhiteSpace(search))
        {
            var term = search.Trim().ToLowerInvariant();
            query = query.Where(x =>
                x.FullName.ToLower().Contains(term)
                || x.Email.ToLower().Contains(term)
                || (x.CompanyName != null && x.CompanyName.ToLower().Contains(term))
                || (x.PhoneNumber != null && x.PhoneNumber.ToLower().Contains(term)));
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
                // Match GetUserStatusLabelAr: pending approval for unverified/unapproved
                // sellers/shipping, or any account with pending profile edits.
                "pending" or "بانتظار الموافقة" => query.Where(x =>
                    !x.IsRejected
                    && (
                        ((x.RoleId == RoleIds.Seller || x.RoleId == RoleIds.ShippingCompany)
                            && !x.IsApproved)
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
                        (x.RoleId == RoleIds.Seller && !x.IsApproved && x.IsVerified)
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
                ImgPath = x.ImgPath
                    ?? x.CompanyImages
                        .OrderByDescending(c => c.IsPrimary)
                        .Select(c => c.ImagePath)
                        .FirstOrDefault(),
                CompanyName = x.CompanyName,
                OrdersCount = dbContext.Orders.Count(o => o.FromUserId == x.Id || o.ToUserId == x.Id),
                ProductsCount = dbContext.Products.Count(p => p.OwnerId == x.Id),
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
        var productsCount = await dbContext.Products.CountAsync(
            p => p.OwnerId == user.Id,
            cancellationToken);

        var revealRows = await dbContext.ShippingPhoneReveals
            .AsNoTracking()
            .Where(x => x.ViewerUserId == user.Id)
            .GroupBy(x => x.ShippingCompanyUserId)
            .Select(g => new
            {
                CompanyUserId = g.Key,
                RevealCount = g.Count()
            })
            .OrderByDescending(x => x.RevealCount)
            .ToListAsync(cancellationToken);

        var companyIds = revealRows.Select(x => x.CompanyUserId).ToList();
        var companyUsers = companyIds.Count == 0
            ? []
            : await dbContext.Users
                .AsNoTracking()
                .Where(x => companyIds.Contains(x.Id))
                .Select(x => new { x.Id, x.CompanyName, x.FullName })
                .ToListAsync(cancellationToken);
        var companyNameById = companyUsers.ToDictionary(
            x => x.Id,
            x => string.IsNullOrWhiteSpace(x.CompanyName) ? x.FullName : x.CompanyName!);

        var revealsByCompany = revealRows
            .Select(x => new AdminShippingPhoneRevealCompanyDto
            {
                CompanyUserId = x.CompanyUserId,
                CompanyName = companyNameById.TryGetValue(x.CompanyUserId, out var name)
                    ? name
                    : "—",
                RevealCount = x.RevealCount
            })
            .ToList();

        // For shipping companies: also surface who revealed THIS company's number
        // (admins often open the company from Users, not only Shipping).
        List<AdminShippingPhoneRevealViewerDto> revealsByViewer = [];
        var inboundRevealCount = 0;
        if (user.RoleId == RoleIds.ShippingCompany)
        {
            var inboundRows = await dbContext.ShippingPhoneReveals
                .AsNoTracking()
                .Where(x => x.ShippingCompanyUserId == user.Id)
                .GroupBy(x => x.ViewerUserId)
                .Select(g => new
                {
                    ViewerUserId = g.Key,
                    RevealCount = g.Count()
                })
                .OrderByDescending(x => x.RevealCount)
                .Take(50)
                .ToListAsync(cancellationToken);

            inboundRevealCount = inboundRows.Sum(x => x.RevealCount);
            var viewerIds = inboundRows.Select(x => x.ViewerUserId).ToList();
            var viewers = viewerIds.Count == 0
                ? []
                : await dbContext.Users
                    .AsNoTracking()
                    .Where(x => viewerIds.Contains(x.Id))
                    .Select(x => new { x.Id, x.FullName, x.CompanyName, x.Email, x.PhoneNumber })
                    .ToListAsync(cancellationToken);
            var viewerById = viewers.ToDictionary(x => x.Id);
            revealsByViewer = inboundRows
                .Select(x =>
                {
                    viewerById.TryGetValue(x.ViewerUserId, out var viewer);
                    var name = viewer is null
                        ? "—"
                        : (!string.IsNullOrWhiteSpace(viewer.CompanyName)
                            ? viewer.CompanyName!
                            : viewer.FullName);
                    return new AdminShippingPhoneRevealViewerDto
                    {
                        ViewerUserId = x.ViewerUserId,
                        ViewerName = name,
                        ViewerEmail = viewer?.Email,
                        ViewerPhone = viewer?.PhoneNumber,
                        RevealCount = x.RevealCount
                    };
                })
                .ToList();
        }

        var dto = new AdminUserDetailDto
        {
            Id = user.Id,
            FullName = user.FullName,
            Email = user.Email,
            PhoneNumber = user.PhoneNumber,
            LandNumber = user.LandNumber,
            PreferredLanguage = user.PreferredLanguage ?? "en",
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
            ImgPath = !string.IsNullOrWhiteSpace(user.ImgPath)
                ? user.ImgPath
                : user.CompanyImages
                    .OrderByDescending(x => x.IsPrimary)
                    .ThenBy(x => x.CreatedAt)
                    .Select(x => x.ImagePath)
                    .FirstOrDefault(),
            CompanyName = user.CompanyName,
            LicenseNumber = user.LicenseNumber,
            LicencePath = WebRootFileHelper.NormalizeStoredPath(user.LicencePath),
            CommercialRegister = user.CommercialRegister,
            TaxNumber = user.TaxNumber,
            Website = user.Website,
            PendingProfileChanges = MapPendingProfileChanges(user.PendingProfileChanges),
            RegistrationCompletionRequest = MapRegistrationCompletionRequest(user.RegistrationCompletionRequest),
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
            ProductsCount = productsCount,
            ShippingPhoneRevealCount = user.RoleId == RoleIds.ShippingCompany
                ? inboundRevealCount
                : revealRows.Sum(x => x.RevealCount),
            ShippingPhoneRevealsByCompany = revealsByCompany,
            ShippingPhoneRevealsByViewer = revealsByViewer,
            CanApprove = !user.IsRejected
                && (
                    (RoleIds.RequiresAdminApproval(user.RoleId) && !user.IsApproved && user.IsVerified)
                    || !string.IsNullOrWhiteSpace(user.PendingProfileChanges)),
            CanDeactivate = user.RoleId != RoleIds.Admin,
            CanDelete = user.RoleId != RoleIds.Admin,
            CanConvertToSupplier = user.RoleId == RoleIds.Seller && user.IsCustomer == true,
            CanConvertToCompanyCustomer = user.RoleId == RoleIds.Seller && user.IsCustomer != true
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
            PhoneNumber = pending.PhoneNumber,
            LicencePath = pending.LicencePath,
            CompanyImagesChanged = pending.CompanyImagesChanged,
            CompanyImagePaths = pending.CompanyImagePaths ?? []
        };
    }

    private static RegistrationCompletionRequestDto? MapRegistrationCompletionRequest(string? raw)
    {
        var request = RegistrationCompletionRequestHelper.TryParse(raw);
        if (request is null || !request.HasAnyMissing)
        {
            return null;
        }

        return new RegistrationCompletionRequestDto
        {
            MissingLocation = request.MissingLocation,
            MissingImages = request.MissingImages,
            MissingDocuments = request.MissingDocuments,
            Message = request.Message,
            RequestedAtUtc = request.RequestedAtUtc
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

    public async Task<object> ConvertCompanyCustomerToSupplierAsync(
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

        if (user.RoleId != RoleIds.Seller)
        {
            throw new InvalidOperationException(
                "Only company accounts (Seller role) can be converted to supplier.");
        }

        if (user.IsCustomer != true)
        {
            throw new InvalidOperationException(
                "This account is already a supplier (IsCustomer is not set).");
        }

        user.IsCustomer = false;
        await dbContext.SaveChangesAsync(cancellationToken);

        return new
        {
            message = "Company customer account converted to supplier.",
            userId = user.Id,
            isCustomer = false,
            typeLabelAr = AdminMappings.GetUserTypeLabelAr(user.RoleId, user.IsCustomer)
        };
    }

    public async Task<object> ConvertSupplierToCompanyCustomerAsync(
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

        if (user.RoleId != RoleIds.Seller)
        {
            throw new InvalidOperationException(
                "Only company accounts (Seller role) can be converted to company customer.");
        }

        if (user.IsCustomer == true)
        {
            throw new InvalidOperationException(
                "This account is already a company customer.");
        }

        user.IsCustomer = true;
        await dbContext.SaveChangesAsync(cancellationToken);

        return new
        {
            message = "Supplier account converted to company customer.",
            userId = user.Id,
            isCustomer = true,
            typeLabelAr = AdminMappings.GetUserTypeLabelAr(user.RoleId, user.IsCustomer)
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

        var message = await accountDeletionAppService.DeleteUserByAdminAsync(
            userId,
            cancellationToken);

        return new { message, userId = parsedUserId };
    }

    public async Task<CreateAdminUserResult> CreateUserAsync(
        CreateAdminUserRequest request,
        CancellationToken cancellationToken = default)
    {
        var accountType = (request.AccountType ?? string.Empty).Trim().ToLowerInvariant();
        if (accountType is not ("person" or "supplier" or "companycustomer" or "shippingcompany"))
        {
            throw new ArgumentException(
                "Account type must be person, supplier, companyCustomer, or shippingCompany.");
        }

        if (string.IsNullOrWhiteSpace(request.Password) || request.Password.Trim().Length < 6)
        {
            throw new ArgumentException("Password must be at least 6 characters.");
        }

        var email = NormalizeAndValidateEmail(request.Email);
        var emailExists = await dbContext.Users.AnyAsync(x => x.Email == email, cancellationToken);
        if (emailExists)
        {
            throw new InvalidOperationException("Email is already registered.");
        }

        var preferredLanguage = NotificationMessages.NormalizeLanguage(request.PreferredLanguage);
        var passwordHash = passwordHasher.HashPassword(request.Password.Trim());
        var phone = string.IsNullOrWhiteSpace(request.PhoneNumber)
            ? null
            : request.PhoneNumber.Trim();

        User user;
        switch (accountType)
        {
            case "person":
            {
                var fullName = (request.FullName ?? string.Empty).Trim();
                if (string.IsNullOrWhiteSpace(fullName))
                {
                    throw new ArgumentException("Full name is required.");
                }

                user = new User
                {
                    Id = Guid.NewGuid(),
                    FullName = fullName,
                    Email = email,
                    HashedPassword = passwordHash,
                    RoleId = RoleIds.Buyer,
                    LoginProviderName = "Local",
                    IsActive = true,
                    IsApproved = true,
                    IsVerified = true,
                    IsRejected = false,
                    PhoneNumber = phone,
                    PreferredLanguage = preferredLanguage,
                };
                break;
            }
            case "supplier":
            case "companycustomer":
            {
                var companyName = string.IsNullOrWhiteSpace(request.CompanyName)
                    ? null
                    : request.CompanyName.Trim();
                var ownerName = (request.FullName ?? string.Empty).Trim();
                var displayName = !string.IsNullOrWhiteSpace(companyName)
                    ? companyName
                    : ownerName;
                if (string.IsNullOrWhiteSpace(displayName))
                {
                    throw new ArgumentException("Company name or full name is required.");
                }

                var isCustomer = accountType == "companycustomer";
                user = new User
                {
                    Id = Guid.NewGuid(),
                    FullName = displayName,
                    CompanyName = companyName,
                    Email = email,
                    HashedPassword = passwordHash,
                    RoleId = RoleIds.Seller,
                    LoginProviderName = "Local",
                    IsActive = true,
                    IsApproved = true,
                    IsVerified = true,
                    IsRejected = false,
                    PhoneNumber = phone,
                    LandNumber = TrimOrNull(request.LandNumber),
                    LicenseNumber = TrimOrNull(request.LicenseNumber),
                    BirthDate = request.BirthDate,
                    CommercialRegister = TrimOrNull(request.CommercialRegister),
                    TaxNumber = TrimOrNull(request.TaxNumber),
                    Website = NormalizeOptionalWebsite(request.Website),
                    IsCustomer = isCustomer,
                    PreferredLanguage = preferredLanguage,
                    LicencePath = string.IsNullOrWhiteSpace(request.LicencePath)
                        ? null
                        : WebRootFileHelper.NormalizeStoredPath(request.LicencePath),
                    ImgPath = string.IsNullOrWhiteSpace(request.ImgPath)
                        ? null
                        : WebRootFileHelper.NormalizeStoredPath(request.ImgPath),
                };

                await dbContext.Users.AddAsync(user, cancellationToken);
                if (request.CompanyImagePaths is not null)
                {
                    for (var i = 0; i < request.CompanyImagePaths.Count; i++)
                    {
                        var path = WebRootFileHelper.NormalizeStoredPath(request.CompanyImagePaths[i]);
                        if (string.IsNullOrWhiteSpace(path)) continue;
                        await dbContext.CompanyImages.AddAsync(
                            new CompanyImage
                            {
                                UserId = user.Id,
                                ImagePath = path,
                                IsPrimary = i == 0,
                            },
                            cancellationToken);
                    }
                }

                await dbContext.SaveChangesAsync(cancellationToken);
                await TryAddCompanyAddressAsync(user.Id, request.Address, cancellationToken);
                userNameTranslationQueue.Enqueue(
                    user.Id,
                    user.FullName,
                    user.CompanyName,
                    user.PreferredLanguage);

                await auditLogAppService.WriteAsync(
                    AdminAuditActions.UserCreate,
                    AdminAuditEntityTypes.User,
                    user.Id.ToString("D"),
                    $"Admin created {(isCustomer ? "company customer" : "supplier")} '{displayName}'",
                    new { email, accountType },
                    cancellationToken);

                return new CreateAdminUserResult
                {
                    UserId = user.Id.ToString("D"),
                    Email = email,
                    AccountType = isCustomer ? "companyCustomer" : "supplier",
                    Message =
                        "Account created as verified, approved, and active (no OTP sent).",
                };
            }
            case "shippingcompany":
            {
                var companyName = (request.CompanyName ?? string.Empty).Trim();
                if (string.IsNullOrWhiteSpace(companyName))
                {
                    throw new ArgumentException("Company name is required.");
                }

                if (string.IsNullOrWhiteSpace(phone))
                {
                    throw new ArgumentException("Phone number is required.");
                }

                user = new User
                {
                    Id = Guid.NewGuid(),
                    FullName = companyName,
                    CompanyName = companyName,
                    Email = email,
                    HashedPassword = passwordHash,
                    RoleId = RoleIds.ShippingCompany,
                    LoginProviderName = "Local",
                    IsActive = true,
                    IsApproved = true,
                    IsVerified = true,
                    IsRejected = false,
                    PhoneNumber = phone,
                    LandNumber = TrimOrNull(request.LandNumber),
                    CommercialRegister = TrimOrNull(request.CommercialRegister),
                    TaxNumber = TrimOrNull(request.TaxNumber),
                    Website = NormalizeOptionalWebsite(request.Website),
                    PreferredLanguage = preferredLanguage,
                };
                break;
            }
            default:
                throw new ArgumentException("Unsupported account type.");
        }

        await dbContext.Users.AddAsync(user, cancellationToken);
        await dbContext.SaveChangesAsync(cancellationToken);
        userNameTranslationQueue.Enqueue(
            user.Id,
            user.FullName,
            user.CompanyName,
            user.PreferredLanguage);

        await auditLogAppService.WriteAsync(
            AdminAuditActions.UserCreate,
            AdminAuditEntityTypes.User,
            user.Id.ToString("D"),
            $"Admin created {accountType} user '{user.FullName}'",
            new { email, accountType },
            cancellationToken);

        return new CreateAdminUserResult
        {
            UserId = user.Id.ToString("D"),
            Email = email,
            AccountType = accountType == "shippingcompany" ? "shippingCompany" : accountType,
            Message = "Account created as verified, approved, and active (no OTP sent).",
        };
    }

    public async Task<UpdateAdminUserResult> UpdateUserAsync(
        string userId,
        UpdateAdminUserRequest request,
        CancellationToken cancellationToken = default)
    {
        if (!Guid.TryParse(userId, out var parsedUserId))
        {
            throw new ArgumentException("Invalid user id.");
        }

        var user = await dbContext.Users
            .FirstOrDefaultAsync(x => x.Id == parsedUserId, cancellationToken)
            ?? throw new KeyNotFoundException("User not found.");

        if (user.RoleId is RoleIds.Admin or RoleIds.Employee)
        {
            throw new InvalidOperationException("Admin and employee accounts cannot be edited here.");
        }

        var email = NormalizeAndValidateEmail(request.Email);
        var emailTaken = await dbContext.Users.AnyAsync(
            x => x.Email == email && x.Id != parsedUserId,
            cancellationToken);
        if (emailTaken)
        {
            throw new InvalidOperationException("Email is already registered.");
        }

        user.Email = email;

        if (!string.IsNullOrWhiteSpace(request.Password))
        {
            if (request.Password.Trim().Length < 6)
            {
                throw new ArgumentException("Password must be at least 6 characters.");
            }

            user.HashedPassword = passwordHasher.HashPassword(request.Password.Trim());
        }

        user.PreferredLanguage = NotificationMessages.NormalizeLanguage(request.PreferredLanguage);
        user.PhoneNumber = string.IsNullOrWhiteSpace(request.PhoneNumber)
            ? null
            : request.PhoneNumber.Trim();

        if (user.RoleId == RoleIds.Buyer)
        {
            var fullName = (request.FullName ?? string.Empty).Trim();
            if (string.IsNullOrWhiteSpace(fullName))
            {
                throw new ArgumentException("Full name is required.");
            }

            user.FullName = fullName;
        }
        else if (user.RoleId == RoleIds.ShippingCompany)
        {
            var companyName = (request.CompanyName ?? string.Empty).Trim();
            if (string.IsNullOrWhiteSpace(companyName))
            {
                throw new ArgumentException("Company name is required.");
            }

            if (string.IsNullOrWhiteSpace(user.PhoneNumber))
            {
                throw new ArgumentException("Phone number is required.");
            }

            user.CompanyName = companyName;
            user.FullName = companyName;
            user.LandNumber = TrimOrNull(request.LandNumber);
            user.CommercialRegister = TrimOrNull(request.CommercialRegister);
            user.TaxNumber = TrimOrNull(request.TaxNumber);
            user.Website = NormalizeOptionalWebsite(request.Website);
        }
        else if (user.RoleId == RoleIds.Seller)
        {
            var companyName = TrimOrNull(request.CompanyName);
            var ownerName = TrimOrNull(request.FullName);
            var displayName = companyName ?? ownerName;
            if (string.IsNullOrWhiteSpace(displayName))
            {
                throw new ArgumentException("Company name or full name is required.");
            }

            user.CompanyName = companyName;
            user.FullName = displayName;
            user.LandNumber = TrimOrNull(request.LandNumber);
            user.LicenseNumber = TrimOrNull(request.LicenseNumber);
            user.CommercialRegister = TrimOrNull(request.CommercialRegister);
            user.TaxNumber = TrimOrNull(request.TaxNumber);
            user.Website = NormalizeOptionalWebsite(request.Website);
        }
        else
        {
            throw new InvalidOperationException("Unsupported account type for edit.");
        }

        // Admin edit applies immediately — drop any staged mobile profile edits.
        user.PendingProfileChanges = null;

        await dbContext.SaveChangesAsync(cancellationToken);
        userNameTranslationQueue.Enqueue(
            user.Id,
            user.FullName,
            user.CompanyName,
            user.PreferredLanguage);

        await auditLogAppService.WriteAsync(
            AdminAuditActions.UserUpdate,
            AdminAuditEntityTypes.User,
            user.Id.ToString("D"),
            $"Admin updated user '{user.FullName}'",
            new { email },
            cancellationToken);

        return new UpdateAdminUserResult
        {
            UserId = user.Id.ToString("D"),
            Email = email,
            Message = "User updated successfully.",
        };
    }

    private async Task TryAddCompanyAddressAsync(
        Guid userId,
        RegisterCompanyAddressInput? address,
        CancellationToken cancellationToken)
    {
        if (address is null) return;
        if (string.IsNullOrWhiteSpace(address.AddressLine1)
            && !address.Latitude.HasValue
            && string.IsNullOrWhiteSpace(address.CityName)
            && !address.CityId.HasValue)
        {
            return;
        }

        try
        {
            await addressesAppService.AddAsync(
                new AddAddressInput
                {
                    UserId = userId.ToString("D"),
                    CityId = address.CityId,
                    CountryId = address.CountryId,
                    CityName = address.CityName,
                    AddressLine1 = string.IsNullOrWhiteSpace(address.AddressLine1)
                        ? "Company location"
                        : address.AddressLine1,
                    AddressLine2 = address.AddressLine2,
                    AddressTypeId = address.AddressTypeId ?? 1,
                    Area = address.Area,
                    Street = address.Street,
                    Building = address.Building,
                    FloorNo = address.FloorNo,
                    UnitNo = address.UnitNo,
                    Landmark = address.Landmark,
                    PostalCode = address.PostalCode,
                    ContactPerson = address.ContactPerson,
                    MobileNumber = address.MobileNumber,
                    DeliveryInstructions = address.DeliveryInstructions,
                    Latitude = address.Latitude,
                    Longitude = address.Longitude,
                },
                cancellationToken);
        }
        catch (Exception ex)
        {
            logger.LogWarning(ex, "Failed to save admin-created company address for {UserId}", userId);
        }
    }

    private static string? TrimOrNull(string? value) =>
        string.IsNullOrWhiteSpace(value) ? null : value.Trim();

    private static string NormalizeAndValidateEmail(string email)
    {
        if (string.IsNullOrWhiteSpace(email))
        {
            throw new ArgumentException("Email is required.");
        }

        var normalized = email.Trim().ToLowerInvariant();
        try
        {
            var address = new MailAddress(normalized);
            if (!string.Equals(address.Address, normalized, StringComparison.OrdinalIgnoreCase)
                || address.Host.IndexOf('.') < 0
                || address.User.Length == 0)
            {
                throw new ArgumentException("Invalid email address.");
            }
        }
        catch (FormatException)
        {
            throw new ArgumentException("Invalid email address.");
        }

        return normalized;
    }

    private static string? NormalizeOptionalWebsite(string? website)
    {
        if (string.IsNullOrWhiteSpace(website)) return null;
        var trimmed = website.Trim();
        if (trimmed is "https://" or "http://") return null;
        if (!trimmed.Contains("://", StringComparison.Ordinal))
        {
            trimmed = "https://" + trimmed;
        }

        return trimmed;
    }
}
