namespace DataLayer.Models;

/// <summary>
/// Admin-uploaded product photos indexed in CLIP before a catalog ad exists.
/// </summary>
public class ClipReferenceImage
{
    public long Id { get; set; }

    public string ProductName { get; set; } = string.Empty;

    public string? ProductNameAr { get; set; }

    public string? ProductCode { get; set; }

    public string ImagePath { get; set; } = string.Empty;

    public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;

    public Guid? CreatedByAdminUserId { get; set; }
}
