namespace DataLayer.Models;

public class Country
{
    public short Id { get; set; }
    public string Iso2Code { get; set; } = string.Empty;
    public string CountryNameEn { get; set; } = string.Empty;
    public string? CountryNameAr { get; set; }

    public ICollection<City> Cities { get; set; } = new List<City>();
    public ICollection<Port> Ports { get; set; } = new List<Port>();
}
