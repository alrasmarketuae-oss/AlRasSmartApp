namespace DataLayer.Models;

public class ChatSupportAssignment
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid CustomerUserId { get; set; }
    public Guid AgentUserId { get; set; }
    public DateTime AssignedAtUtc { get; set; } = DateTime.UtcNow;
    public DateTime? ReleasedAtUtc { get; set; }

    public User? CustomerUser { get; set; }
    public User? AgentUser { get; set; }
}
