namespace BusinessLayer.Interfaces;

public interface ITurnstileVerifier
{
    /// <summary>
    /// Validates a Cloudflare Turnstile token via siteverify.
    /// No-ops (success) when Turnstile is not configured.
    /// </summary>
    Task EnsureValidAsync(
        string? token,
        string? remoteIp,
        CancellationToken cancellationToken = default);
}
