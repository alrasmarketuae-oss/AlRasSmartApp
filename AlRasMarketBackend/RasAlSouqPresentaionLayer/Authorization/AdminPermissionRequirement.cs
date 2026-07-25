using Microsoft.AspNetCore.Authorization;

namespace RasAlSouqPresentaionLayer.Authorization;

public sealed class AdminPermissionRequirement(string permission) : IAuthorizationRequirement
{
    public string Permission { get; } = permission;
}
