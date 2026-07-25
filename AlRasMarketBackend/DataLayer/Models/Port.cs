namespace DataLayer.Models;

public class Port
{
    public int Id { get; set; }
    public string PortNameEn { get; set; } = string.Empty;
    public string? PortNameAr { get; set; }
    public string? UnLocode { get; set; }
    public short CountryId { get; set; }

    public Country? Country { get; set; }
}
