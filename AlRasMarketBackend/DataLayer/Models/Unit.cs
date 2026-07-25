namespace DataLayer.Models;

public class Unit
{
    public byte Id { get; set; }
    public string UnitNameEn { get; set; } = string.Empty;

    public ICollection<Product> Products { get; set; } = new List<Product>();
}
