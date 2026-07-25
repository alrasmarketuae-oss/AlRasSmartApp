namespace DataLayer.Models;

public class Role
{
    public byte Id { get; set; }
    public string RoleName { get; set; } = string.Empty;

    public ICollection<User> Users { get; set; } = new List<User>();
}
