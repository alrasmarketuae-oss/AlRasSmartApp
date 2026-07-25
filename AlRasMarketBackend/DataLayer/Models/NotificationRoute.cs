namespace DataLayer.Models;

public class NotificationRoute
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public string Name { get; set; } = string.Empty;

    public ICollection<Notification> Notifications { get; set; } = new List<Notification>();
}
