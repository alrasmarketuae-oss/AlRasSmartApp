namespace DataLayer.Models;

public class Cart
{
    public Guid CartId { get; set; } = Guid.NewGuid();
    public Guid UserId { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? UpdatedAt { get; set; }

    public User? User { get; set; }
    public ICollection<CartItem> CartItems { get; set; } = new List<CartItem>();
}
