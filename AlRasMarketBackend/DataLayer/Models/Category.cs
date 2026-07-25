namespace DataLayer.Models;

public class Category
{
    public byte CategoryId { get; set; }
    public string NameEn { get; set; } = string.Empty;
    public string NameAr { get; set; } = string.Empty;
    public string ImgPath { get; set; } = string.Empty;
    public decimal CommissionPercent { get; set; }
    /// <summary>When true, category is hidden from the mobile app public APIs.</summary>
    public bool IsHide { get; set; }

    public ICollection<Product> Products { get; set; } = new List<Product>();
}
