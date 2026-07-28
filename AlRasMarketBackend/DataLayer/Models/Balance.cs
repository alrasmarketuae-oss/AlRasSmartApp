using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace DataLayer.Models;

/// <summary>
/// Supplier wallet ledger (الرصيد). String Id avoids numeric identity overflow.
/// Positive Balance = deposit; negative = withdrawal/debit.
/// </summary>
public class Balance
{
    [MaxLength(64)]
    public string Id { get; set; } = string.Empty;

    public Guid UserId { get; set; }

    public long? OrderId { get; set; }

    [Column(TypeName = "decimal(18,2)")]
    public decimal BalanceAmount { get; set; }

    /// <summary><see cref="BalanceEntryTypes"/>.</summary>
    public byte EntryType { get; set; }

    [MaxLength(300)]
    public string? ReasonEn { get; set; }

    [MaxLength(300)]
    public string? ReasonAr { get; set; }

    public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;

    public User? User { get; set; }
    public Order? Order { get; set; }
}

public static class BalanceEntryTypes
{
    public const byte Deposit = 1;
    public const byte Withdrawal = 2;

    public static string ToNameEn(byte type) => type switch
    {
        Deposit => "Deposit",
        Withdrawal => "Withdrawal",
        _ => "Unknown"
    };

    public static string ToNameAr(byte type) => type switch
    {
        Deposit => "إيداع",
        Withdrawal => "سحب",
        _ => "غير معروف"
    };
}
