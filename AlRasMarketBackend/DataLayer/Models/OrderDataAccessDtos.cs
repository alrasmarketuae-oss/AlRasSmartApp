namespace DataLayer.Models;

public sealed class OrderNotifyUserRow
{
    public Guid Id { get; init; }
    public string Email { get; init; } = string.Empty;
    public string? FcmToken { get; init; }
    public string? PreferredLanguage { get; init; }
    public byte RoleId { get; init; }
}

public sealed class OrderProductNotifyMeta
{
    public Guid ProductId { get; init; }
    public string? NameEn { get; init; }
    public byte? ProductTypeId { get; init; }
    public byte? CategoryId { get; init; }
    public Guid? OwnerId { get; init; }
}
