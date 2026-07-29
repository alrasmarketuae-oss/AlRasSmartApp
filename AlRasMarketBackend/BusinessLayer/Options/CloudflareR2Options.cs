namespace BusinessLayer.Options;

public sealed class CloudflareR2Options
{
    public const string SectionName = "CloudflareR2";

    public bool Enabled { get; set; }

    public string BucketName { get; set; } = string.Empty;

    public string AccessKey { get; set; } = string.Empty;

    public string SecretKey { get; set; } = string.Empty;

    /// <summary>S3 API endpoint, e.g. https://ACCOUNT_ID.r2.cloudflarestorage.com</summary>
    public string ServiceUrl { get; set; } = string.Empty;

    /// <summary>
    /// Public CDN/custom domain used to resolve relative DB paths to absolute URLs.
    /// Example: https://cdn.alrasmarketapp.com
    /// </summary>
    public string? PublicBaseUrl { get; set; }

    /// <summary>How long mobile may use a presigned PUT URL (default 15 minutes).</summary>
    public int PresignedPutExpirySeconds { get; set; } = 900;

    public bool IsConfigured =>
        Enabled
        && !string.IsNullOrWhiteSpace(BucketName)
        && !string.IsNullOrWhiteSpace(AccessKey)
        && !string.IsNullOrWhiteSpace(SecretKey)
        && !string.IsNullOrWhiteSpace(ServiceUrl)
        && !AccessKey.Contains("YOUR_", StringComparison.OrdinalIgnoreCase)
        && !SecretKey.Contains("YOUR_", StringComparison.OrdinalIgnoreCase)
        && !ServiceUrl.Contains("YOUR_", StringComparison.OrdinalIgnoreCase);
}
