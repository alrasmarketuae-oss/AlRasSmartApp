namespace DataLayer.Models;

public class OrderStatus
{
    public byte Id { get; set; }
    public string Name { get; set; } = string.Empty;

    public ICollection<Order> Orders { get; set; } = new List<Order>();
}
