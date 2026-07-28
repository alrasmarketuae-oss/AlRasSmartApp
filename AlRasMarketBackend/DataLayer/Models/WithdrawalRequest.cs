using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace DataLayer.Models;

public class WithdrawalRequest
{
    [MaxLength(64)]
    public string Id { get; set; } = Guid.NewGuid().ToString("N");

    public Guid UserId { get; set; }
    public Guid UserIbanId { get; set; }

    [Column(TypeName = "decimal(18,2)")]
    public decimal Amount { get; set; }

    public byte StatusId { get; set; } = WithdrawalRequestStatusCodes.Pending;

    [MaxLength(500)]
    public string? Notes { get; set; }

    [MaxLength(34)]
    public string IbanSnapshot { get; set; } = string.Empty;

    [MaxLength(150)]
    public string? AccountHolderNameSnapshot { get; set; }

    [MaxLength(150)]
    public string? BankNameSnapshot { get; set; }

    public DateTime RequestedAtUtc { get; set; } = DateTime.UtcNow;
    public DateTime? CompletedAtUtc { get; set; }
    public Guid? CompletedByAdminUserId { get; set; }

    public User? User { get; set; }
    public UserIban? UserIban { get; set; }
    public User? CompletedByAdminUser { get; set; }
}

public static class WithdrawalRequestStatusCodes
{
    public const byte Pending = 1;
    public const byte Paid = 2;

    public static string ToNameEn(byte statusId) => statusId switch
    {
        Paid => "Paid",
        _ => "Pending"
    };

    public static string ToNameAr(byte statusId) => statusId switch
    {
        Paid => "تم التحويل",
        _ => "قيد الانتظار"
    };
}
