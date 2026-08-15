namespace DataLayer.Models;

public class Address
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid UserId { get; set; }
    public Guid CityId { get; set; }
    public byte AddressTypeId { get; set; } = 4;
    public string AddressLine1 { get; set; } = string.Empty;
    public string? AddressLine2 { get; set; }
    public string? Area { get; set; }
    public string? Street { get; set; }
    public string? Building { get; set; }
    public string? FloorNo { get; set; }
    public string? UnitNo { get; set; }
    public string? Landmark { get; set; }
    public string? PostalCode { get; set; }
    public string? ContactPerson { get; set; }
    public string? MobileNumber { get; set; }
    public string? DeliveryInstructions { get; set; }
    public decimal? Latitude { get; set; }
    public decimal? Longitude { get; set; }

    public User? User { get; set; }
    public City? City { get; set; }
    public AddressType? AddressType { get; set; }
}
