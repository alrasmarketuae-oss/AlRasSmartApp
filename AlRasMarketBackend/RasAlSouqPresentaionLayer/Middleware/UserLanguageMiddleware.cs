using BusinessLayer.Interfaces;

namespace RasAlSouqPresentaionLayer.Middleware;

public sealed class UserLanguageMiddleware(RequestDelegate next)
{
    public async Task InvokeAsync(HttpContext context, IUserLanguageResolver languageResolver)
    {
        await languageResolver.ResolveAsync(cancellationToken: context.RequestAborted);
        await next(context);
    }
}
