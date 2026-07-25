namespace DataLayer.Models;

public class RequestType
{
    public byte Id { get; set; }
    public string NameEn { get; set; } = string.Empty;

    public ICollection<Product> Products { get; set; } = new List<Product>();
}
