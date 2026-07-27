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

public sealed class AdminOrderStatsRow
{
    public int TotalOrders { get; init; }
    public int OrdersThisMonth { get; init; }
    public int OrdersLastMonth { get; init; }
    public int OrderedCount { get; init; }
    public int ShippingCount { get; init; }
    public int DeliveredCount { get; init; }
}

public sealed class AdminOrdersPageFilter
{
    public int Page { get; init; }
    public int PageSize { get; init; }
    public byte? StatusId { get; init; }
    public byte? ProductTypeId { get; init; }
    public byte? ExcludeProductTypeId { get; init; }
    public Guid? ProductId { get; init; }
    public string? Search { get; init; }
    public DateTime? CreatedFrom { get; init; }
    public DateTime? CreatedTo { get; init; }
    public string? OfferReview { get; init; }
    public string? OrderChannel { get; init; }
}
