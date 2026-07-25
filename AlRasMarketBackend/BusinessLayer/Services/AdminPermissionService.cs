using BusinessLayer.Constants;
using BusinessLayer.Interfaces;
using DataLayer.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace BusinessLayer.Services;

public sealed class AdminPermissionService(IRasAlSouqDbContext dbContext) : IAdminPermissionService
{
    public bool IsSuperAdmin(byte roleId) => roleId == 1;

    public bool IsEmployee(byte roleId) => roleId == AdminPermissions.EmployeeRoleId;

    public bool IsDashboardStaff(byte roleId) => IsSuperAdmin(roleId) || IsEmployee(roleId);

    public async Task<IReadOnlyList<string>> GetPermissionKeysAsync(Guid userId, CancellationToken ct = default)
    {
        return await dbContext.UserAdminPermissions
            .AsNoTracking()
            .Where(x => x.UserId == userId)
            .Select(x => x.PermissionKey)
            .ToListAsync(ct);
    }

    public async Task<bool> HasPermissionAsync(Guid userId, byte roleId, string permissionKey, CancellationToken ct = default)
    {
        if (IsSuperAdmin(roleId))
        {
            return true;
        }

        if (!IsEmployee(roleId))
        {
            return false;
        }

        return await dbContext.UserAdminPermissions
            .AsNoTracking()
            .AnyAsync(x => x.UserId == userId && x.PermissionKey == permissionKey, ct);
    }

    public async Task SetPermissionsAsync(Guid userId, IReadOnlyList<string> permissionKeys, CancellationToken ct = default)
    {
        var normalized = permissionKeys
            .Where(AdminPermissions.IsValidKey)
            .Distinct(StringComparer.Ordinal)
            .ToList();

        var existing = await dbContext.UserAdminPermissions
            .Where(x => x.UserId == userId)
            .ToListAsync(ct);

        dbContext.UserAdminPermissions.RemoveRange(existing);

        foreach (var key in normalized)
        {
            dbContext.UserAdminPermissions.Add(new DataLayer.Models.UserAdminPermission
            {
                UserId = userId,
                PermissionKey = key,
            });
        }

        await dbContext.SaveChangesAsync(ct);
    }
}
