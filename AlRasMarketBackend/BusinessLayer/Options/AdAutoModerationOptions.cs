namespace BusinessLayer.Options;

public sealed class AdAutoModerationOptions
{
    public const string SectionName = "AdAutoModeration";

    /// <summary>When false, all ads stay on manual admin review.</summary>
    public bool Enabled { get; set; } = true;

    /// <summary>
    /// Max product images to scan with Vision per ad.
    /// 0 or less = scan all images.
    /// </summary>
    public int MaxImagesToScan { get; set; } = 0;
}
