namespace DataLayer.Models;

public class ProductType
{
    public byte Id { get; set; }
    public string TypeNameEn { get; set; } = string.Empty;

    public ICollection<Product> Products { get; set; } = new List<Product>();
}
