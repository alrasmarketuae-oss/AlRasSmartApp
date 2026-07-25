using Microsoft.AspNetCore.Authorization;

namespace RasAlSouqPresentaionLayer.Authorization;

public sealed class RequireAdminPermissionAttribute : AuthorizeAttribute
{
    public RequireAdminPermissionAttribute(string permission)
    {
        Policy = $"AdminPermission:{permission}";
    }
}
