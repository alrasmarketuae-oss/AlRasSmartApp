namespace DataLayer.Models;

public class UserAdminPermission
{
    public Guid UserId { get; set; }
    public string PermissionKey { get; set; } = string.Empty;

    public User? User { get; set; }
}
