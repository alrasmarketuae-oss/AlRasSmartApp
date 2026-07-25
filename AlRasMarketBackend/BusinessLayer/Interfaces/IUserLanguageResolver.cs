namespace BusinessLayer.Interfaces;

public interface IUserLanguageResolver
{
    Task<string> ResolveAsync(string? userId = null, string? acceptLanguageHeader = null, CancellationToken cancellationToken = default);

    string ResolveFromHttpHeaders(string? preferredLanguageHeader, string? acceptLanguageHeader);
}
