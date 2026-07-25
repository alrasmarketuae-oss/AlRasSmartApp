namespace BusinessLayer.Options;

public sealed class CloudflareTurnstileOptions
{
    public const string SectionName = "CloudflareTurnstile";

    /// <summary>Optional fallback when TURNSTILE_SECRET env var is not set.</summary>
    public string? Secret { get; set; }

    /// <summary>Public site key (optional on server; used for docs/diagnostics).</summary>
    public string? SiteKey { get; set; }

    public string ResolveSecret()
    {
        var fromEnv = Environment.GetEnvironmentVariable("TURNSTILE_SECRET");
        if (!string.IsNullOrWhiteSpace(fromEnv))
        {
            return fromEnv.Trim();
        }

        return Secret?.Trim() ?? string.Empty;
    }

    public bool IsConfigured => !string.IsNullOrWhiteSpace(ResolveSecret());
}
