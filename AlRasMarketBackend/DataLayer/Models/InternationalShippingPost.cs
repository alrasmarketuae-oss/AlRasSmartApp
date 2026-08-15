namespace DataLayer.Models;

public class InternationalShippingPost
{
    public long Id { get; set; }
    public short FromCountryId { get; set; }
    public int FromPortId { get; set; }
    public short ToCountryId { get; set; }
    public int ToPortId { get; set; }
    public decimal PriceUsd { get; set; }
    public decimal ShippingCostUsd { get; set; }
    public Guid PublisherUserId { get; set; }
    public string PhoneNumber { get; set; } = string.Empty;
    public decimal? Container20ftPriceUsd { get; set; }
    public decimal? Container40ftPriceUsd { get; set; }
    public int? MinDurationDays { get; set; }
    public int? MaxDurationDays { get; set; }
    public string? Details { get; set; }
    public byte Status { get; set; } = 1;
    public bool IsApproved { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public Country? FromCountry { get; set; }
    public Port? FromPort { get; set; }
    public Country? ToCountry { get; set; }
    public Port? ToPort { get; set; }
    public User? PublisherUser { get; set; }
}
