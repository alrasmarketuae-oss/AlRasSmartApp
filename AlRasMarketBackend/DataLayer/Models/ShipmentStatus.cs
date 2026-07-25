namespace DataLayer.Models;

public class ShipmentStatus
{
    public byte Id { get; set; }
    public string NameEn { get; set; } = string.Empty;
    public string NameAr { get; set; } = string.Empty;

    public ICollection<InternationalShipment> Shipments { get; set; } = [];
}
