namespace DataLayer.Models;

/// <summary>Lookup: Company / Warehouse / Shop / Home. Tinyint PK to avoid storing the label on every row.</summary>
public class AddressType
{
    public byte Id { get; set; }
    public string NameEn { get; set; } = string.Empty;
    public string NameAr { get; set; } = string.Empty;

    public ICollection<Address> Addresses { get; set; } = new List<Address>();
}
