namespace BusinessLayer.Dtos;

public sealed class CreateUserIbanRequest
{
    public string Iban { get; set; } = string.Empty;
    public string? AccountHolderName { get; set; }
    public string? BankName { get; set; }
    public bool IsDefault { get; set; } = true;
}

public sealed class CreateWithdrawalRequestInput
{
    public Guid UserIbanId { get; set; }
    public decimal Amount { get; set; }
    public string? Notes { get; set; }
}

public sealed class AdminGetWithdrawalRequestsInput
{
    public int Page { get; set; } = 1;
    public int PageSize { get; set; } = 20;
    public byte? StatusId { get; set; }
    public string? Search { get; set; }
}

public sealed class AdminMarkWithdrawalPaidInput
{
    public string? Notes { get; set; }
}
