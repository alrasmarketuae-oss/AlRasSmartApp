namespace DataLayer.Models;

public class City
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public string CityName { get; set; } = string.Empty;
    public short CountryId { get; set; }

    public Country? Country { get; set; }
    public ICollection<Address> Addresses { get; set; } = new List<Address>();
}
