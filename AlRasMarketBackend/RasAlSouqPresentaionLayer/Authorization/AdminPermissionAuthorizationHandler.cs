using Microsoft.AspNetCore.Authorization;

namespace RasAlSouqPresentaionLayer.Authorization;

public sealed class AdminPermissionAuthorizationHandler : AuthorizationHandler<AdminPermissionRequirement>
{
    protected override Task HandleRequirementAsync(
        AuthorizationHandlerContext context,
        AdminPermissionRequirement requirement)
    {
        if (context.User.IsInRole("Admin"))
        {
            context.Succeed(requirement);
            return Task.CompletedTask;
        }

        if (context.User.IsInRole("Employee")
            && context.User.HasClaim("permission", requirement.Permission))
        {
            context.Succeed(requirement);
        }

        return Task.CompletedTask;
    }
}
