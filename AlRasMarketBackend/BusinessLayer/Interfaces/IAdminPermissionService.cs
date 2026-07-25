namespace BusinessLayer.Interfaces;

public interface IAdminPermissionService
{
    bool IsSuperAdmin(byte roleId);
    bool IsEmployee(byte roleId);
    bool IsDashboardStaff(byte roleId);
    Task<IReadOnlyList<string>> GetPermissionKeysAsync(Guid userId, CancellationToken ct = default);
    Task<bool> HasPermissionAsync(Guid userId, byte roleId, string permissionKey, CancellationToken ct = default);
    Task SetPermissionsAsync(Guid userId, IReadOnlyList<string> permissionKeys, CancellationToken ct = default);
}
