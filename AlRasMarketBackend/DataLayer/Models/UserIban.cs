using System.ComponentModel.DataAnnotations;

namespace DataLayer.Models;

public class UserIban
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid UserId { get; set; }

    [MaxLength(34)]
    public string Iban { get; set; } = string.Empty;

    [MaxLength(150)]
    public string? AccountHolderName { get; set; }

    [MaxLength(150)]
    public string? BankName { get; set; }

    public bool IsDefault { get; set; }
    public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;

    public User? User { get; set; }
    public ICollection<WithdrawalRequest> WithdrawalRequests { get; set; } = new List<WithdrawalRequest>();
}
