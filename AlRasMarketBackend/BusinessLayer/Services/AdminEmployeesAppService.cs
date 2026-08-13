using BusinessLayer.Constants;
using BusinessLayer.Dtos;
using BusinessLayer.Interfaces;
using DataLayer.Interfaces;
using DataLayer.Models;
using Microsoft.EntityFrameworkCore;

namespace BusinessLayer.Services;

public sealed class AdminEmployeesAppService(
    IRasAlSouqDbContext dbContext,
    IPasswordHasher passwordHasher,
    IAdminPermissionService permissionService,
    IAdminAuditLogAppService auditLogAppService) : IAdminEmployeesAppService
{
    public IReadOnlyList<AdminPermissionDefinitionDto> GetPermissionDefinitions() =>
        AdminPermissionCatalog.Definitions;

    public async Task<AdminEmployeesListResponseDto> GetEmployeesAsync(
        int page,
        int pageSize,
        string? search,
        CancellationToken ct = default)
    {
        page = Math.Max(1, page);
        pageSize = Math.Clamp(pageSize, 1, 100);

        var query = dbContext.Users
            .AsNoTracking()
            .Where(x => x.RoleId == AdminPermissions.EmployeeRoleId);

        if (!string.IsNullOrWhiteSpace(search))
        {
            var term = search.Trim();
            query = query.Where(x =>
                x.FullName.Contains(term) ||
                x.Email.Contains(term) ||
                (x.PhoneNumber != null && x.PhoneNumber.Contains(term)));
        }

        var totalCount = await query.CountAsync(ct);
        var totalPages = Math.Max(1, (int)Math.Ceiling(totalCount / (double)pageSize));

        var users = await query
            .OrderByDescending(x => x.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync(ct);

        var userIds = users.Select(x => x.Id).ToList();
        var permissionRows = await dbContext.UserAdminPermissions
            .AsNoTracking()
            .Where(x => userIds.Contains(x.UserId))
            .ToListAsync(ct);

        var permissionMap = permissionRows
            .GroupBy(x => x.UserId)
            .ToDictionary(g => g.Key, g => (IReadOnlyList<string>)g.Select(x => x.PermissionKey).ToList());

        var items = users.Select(user => new AdminEmployeeListItemDto(
            user.Id.ToString("D"),
            user.FullName,
            user.Email,
            user.PhoneNumber,
            user.IsActive,
            permissionMap.TryGetValue(user.Id, out var perms) ? perms : [],
            user.CreatedAt.ToString("O"))).ToList();

        return new AdminEmployeesListResponseDto(items, totalCount, page, pageSize, totalPages);
    }

    public async Task<AdminEmployeeDetailDto> GetEmployeeByIdAsync(string employeeId, CancellationToken ct = default)
    {
        var user = await GetEmployeeEntityAsync(employeeId, ct);
        var permissions = await permissionService.GetPermissionKeysAsync(user.Id, ct);

        return new AdminEmployeeDetailDto(
            user.Id.ToString("D"),
            user.FullName,
            user.Email,
            user.PhoneNumber,
            user.IsActive,
            permissions,
            user.CreatedAt.ToString("O"));
    }

    public async Task<AdminEmployeeDetailDto> CreateEmployeeAsync(
        CreateAdminEmployeeRequest request,
        CancellationToken ct = default)
    {
        var fullName = request.FullName.Trim();
        var email = request.Email.Trim().ToLowerInvariant();
        var password = request.Password?.Trim() ?? string.Empty;

        if (string.IsNullOrWhiteSpace(fullName))
        {
            throw new ArgumentException("Full name is required.");
        }

        if (string.IsNullOrWhiteSpace(email))
        {
            throw new ArgumentException("Email is required.");
        }

        if (password.Length < 6)
        {
            throw new ArgumentException("Password must be at least 6 characters.");
        }

        var permissions = NormalizePermissions(request.Permissions);
        if (permissions.Count == 0)
        {
            throw new ArgumentException("Select at least one permission.");
        }

        var emailExists = await dbContext.Users.AnyAsync(x => x.Email == email, ct);
        if (emailExists)
        {
            throw new InvalidOperationException("Email is already registered.");
        }

        var user = new User
        {
            FullName = fullName,
            Email = email,
            PhoneNumber = string.IsNullOrWhiteSpace(request.PhoneNumber) ? null : request.PhoneNumber.Trim(),
            HashedPassword = passwordHasher.HashPassword(password),
            RoleId = AdminPermissions.EmployeeRoleId,
            LoginProviderName = "Local",
            IsActive = true,
            IsApproved = true,
            IsVerified = true,
            IsRejected = false,
        };

        dbContext.Users.Add(user);
        await dbContext.SaveChangesAsync(ct);
        await permissionService.SetPermissionsAsync(user.Id, ExpandImpliedPermissions(permissions), ct);

        await auditLogAppService.WriteAsync(
            AdminAuditActions.EmployeeCreate,
            AdminAuditEntityTypes.Employee,
            user.Id.ToString("D"),
            $"Created employee '{fullName}'",
            new { email, permissions },
            ct);

        return await GetEmployeeByIdAsync(user.Id.ToString("D"), ct);
    }

    public async Task<AdminEmployeeDetailDto> UpdateEmployeeAsync(
        string employeeId,
        UpdateAdminEmployeeRequest request,
        CancellationToken ct = default)
    {
        var user = await GetEmployeeEntityAsync(employeeId, ct, tracked: true);
        var fullName = request.FullName.Trim();

        if (string.IsNullOrWhiteSpace(fullName))
        {
            throw new ArgumentException("Full name is required.");
        }

        var permissions = NormalizePermissions(request.Permissions);
        if (permissions.Count == 0)
        {
            throw new ArgumentException("Select at least one permission.");
        }

        user.FullName = fullName;
        user.PhoneNumber = string.IsNullOrWhiteSpace(request.PhoneNumber) ? null : request.PhoneNumber.Trim();
        user.IsActive = request.IsActive;

        if (!string.IsNullOrWhiteSpace(request.NewPassword))
        {
            if (request.NewPassword.Trim().Length < 6)
            {
                throw new ArgumentException("Password must be at least 6 characters.");
            }

            user.HashedPassword = passwordHasher.HashPassword(request.NewPassword.Trim());
        }

        await dbContext.SaveChangesAsync(ct);
        await permissionService.SetPermissionsAsync(user.Id, ExpandImpliedPermissions(permissions), ct);

        await auditLogAppService.WriteAsync(
            AdminAuditActions.EmployeeUpdate,
            AdminAuditEntityTypes.Employee,
            user.Id.ToString("D"),
            $"Updated employee '{user.FullName}'",
            new { email = user.Email, permissions, isActive = user.IsActive },
            ct);

        return await GetEmployeeByIdAsync(user.Id.ToString("D"), ct);
    }

    public async Task DeleteEmployeeAsync(string employeeId, CancellationToken ct = default)
    {
        var user = await GetEmployeeEntityAsync(employeeId, ct, tracked: true);
        var name = user.FullName;
        var email = user.Email;
        dbContext.Users.Remove(user);
        await dbContext.SaveChangesAsync(ct);

        await auditLogAppService.WriteAsync(
            AdminAuditActions.EmployeeDelete,
            AdminAuditEntityTypes.Employee,
            employeeId,
            $"Deleted employee '{name}'",
            new { email },
            ct);
    }

    private static IReadOnlyList<string> NormalizePermissions(IReadOnlyList<string> permissions) =>
        permissions
            .Where(AdminPermissions.IsValidKey)
            .Distinct(StringComparer.Ordinal)
            .ToList();

    private static IReadOnlyList<string> ExpandImpliedPermissions(IReadOnlyList<string> permissions)
    {
        var set = new HashSet<string>(permissions, StringComparer.Ordinal);

        if (set.Contains(AdminPermissions.UsersManage))
        {
            set.Add(AdminPermissions.UsersView);
            set.Add(AdminPermissions.UsersProfileEdits);
        }
        if (set.Contains(AdminPermissions.ProductsManage))
        {
            set.Add(AdminPermissions.ProductsView);
            set.Add(AdminPermissions.ProductsAdEdits);
        }
        if (set.Contains(AdminPermissions.OrdersManage))
        {
            set.Add(AdminPermissions.OrdersView);
            set.Add(AdminPermissions.OrdersReqsOffers);
        }
        if (set.Contains(AdminPermissions.ShippingManage)) set.Add(AdminPermissions.ShippingView);
        if (set.Contains(AdminPermissions.NotificationsSend)) set.Add(AdminPermissions.NotificationsView);
        if (set.Contains(AdminPermissions.SettingsManage)) set.Add(AdminPermissions.SettingsView);

        return set.ToList();
    }

    private async Task<User> GetEmployeeEntityAsync(
        string employeeId,
        CancellationToken ct,
        bool tracked = false)
    {
        if (!Guid.TryParse(employeeId, out var id))
        {
            throw new ArgumentException("Invalid employee id.");
        }

        var query = tracked ? dbContext.Users : dbContext.Users.AsNoTracking();
        var user = await query.FirstOrDefaultAsync(
            x => x.Id == id && x.RoleId == AdminPermissions.EmployeeRoleId,
            ct);

        if (user is null)
        {
            throw new KeyNotFoundException("Employee not found.");
        }

        return user;
    }
}

internal static class AdminPermissionCatalog
{
    /// <summary>One entry per dashboard page (plus manage extras). Labels match sidebar nav.</summary>
    public static readonly IReadOnlyList<AdminPermissionDefinitionDto> Definitions =
    [
        new("dashboard.view", "صفحة لوحة التحكم", "Dashboard page", "pages", "صفحات اللوحة", "Dashboard pages"),

        new("users.view", "صفحة المستخدمين", "Users page", "pages", "صفحات اللوحة", "Dashboard pages"),
        new("users.manage", "إدارة المستخدمين (قبول/رفض/تفعيل)", "Manage users (approve/reject/activate)", "pages", "صفحات اللوحة", "Dashboard pages"),
        new("users.profile_edits", "صفحة تعديل بيانات الشركات", "Company profile edits page", "pages", "صفحات اللوحة", "Dashboard pages"),

        new("products.view", "صفحة الإعلانات", "Ads page", "pages", "صفحات اللوحة", "Dashboard pages"),
        new("products.manage", "إدارة الإعلانات (قبول/رفض/تعديل)", "Manage ads (approve/reject/edit)", "pages", "صفحات اللوحة", "Dashboard pages"),
        new("products.ad_edits", "صفحة تعديل الإعلانات", "Ad edit requests page", "pages", "صفحات اللوحة", "Dashboard pages"),

        new("orders.view", "صفحة الطلبات", "Orders page", "pages", "صفحات اللوحة", "Dashboard pages"),
        new("orders.manage", "إدارة الطلبات", "Manage orders", "pages", "صفحات اللوحة", "Dashboard pages"),
        new("orders.reqs_offers", "صفحة العروض والطلبات", "Offers & requests page", "pages", "صفحات اللوحة", "Dashboard pages"),

        new("categories.manage", "صفحة التصنيفات", "Categories page", "pages", "صفحات اللوحة", "Dashboard pages"),
        new("banners.manage", "صفحة البانرات", "Banners page", "pages", "صفحات اللوحة", "Dashboard pages"),

        new("shipping.view", "صفحة الشحن", "Shipping page", "pages", "صفحات اللوحة", "Dashboard pages"),
        new("shipping.manage", "إدارة الشحن", "Manage shipping", "pages", "صفحات اللوحة", "Dashboard pages"),

        new("chat.access", "صفحة الشات والدعم", "Chat & support page", "pages", "صفحات اللوحة", "Dashboard pages"),

        new("notifications.view", "صفحة الإشعارات", "Notifications page", "pages", "صفحات اللوحة", "Dashboard pages"),
        new("notifications.send", "إرسال الإشعارات", "Send notifications", "pages", "صفحات اللوحة", "Dashboard pages"),

        new("audit.view", "صفحة سجل الأحداث", "Audit logs page", "pages", "صفحات اللوحة", "Dashboard pages"),
        new("monitoring.view", "صفحة المراقبة", "Monitoring page", "pages", "صفحات اللوحة", "Dashboard pages"),

        new("settings.view", "صفحة الإعدادات", "Settings page", "pages", "صفحات اللوحة", "Dashboard pages"),
        new("settings.manage", "تعديل الإعدادات", "Manage settings", "pages", "صفحات اللوحة", "Dashboard pages"),

        new("search.access", "البحث العام", "Global search", "pages", "صفحات اللوحة", "Dashboard pages"),
    ];
}
