using System.Security.Claims;
using BusinessLayer.Helpers;
using DataLayer.Interfaces;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;
using Microsoft.EntityFrameworkCore;

namespace RasAlSouqPresentaionLayer.Filters;

/// <summary>Blocks suspended or rejected users from using authenticated APIs.</summary>
public sealed class ActiveUserAuthorizationFilter(IRasAlSouqDbContext dbContext) : IAsyncActionFilter
{
    private static readonly PathString AuthPrefix = new("/api/auth");

    public async Task OnActionExecutionAsync(ActionExecutingContext context, ActionExecutionDelegate next)
    {
        var httpContext = context.HttpContext;
        var path = httpContext.Request.Path;

        if (httpContext.User.Identity?.IsAuthenticated != true
            || path.StartsWithSegments(AuthPrefix, StringComparison.OrdinalIgnoreCase))
        {
            await next();
            return;
        }

        var userIdText = httpContext.User.FindFirstValue("EntityId")
            ?? httpContext.User.FindFirstValue(ClaimTypes.NameIdentifier)
            ?? httpContext.User.FindFirstValue("sub");

        if (!Guid.TryParse(userIdText, out var userId))
        {
            await next();
            return;
        }

        var user = await dbContext.Users
            .AsNoTracking()
            .FirstOrDefaultAsync(x => x.Id == userId, httpContext.RequestAborted);

        if (user is null)
        {
            context.Result = new UnauthorizedObjectResult(new { message = "User not found." });
            return;
        }

        try
        {
            LoginAccessHelper.EnsureCanAuthenticate(user);
        }
        catch (UnauthorizedAccessException ex)
        {
            context.Result = new ObjectResult(new { message = ex.Message })
            {
                StatusCode = StatusCodes.Status403Forbidden
            };
            return;
        }

        await next();
    }
}
