using BusinessLayer.Dtos;

namespace BusinessLayer.Interfaces;

public interface ICommissionSettingsProvider
{
    Task<CommissionSettingsSnapshot> GetAsync(CancellationToken cancellationToken = default);
    void Invalidate();
}

public interface ICategoryCommissionProvider
{
    Task<IReadOnlyDictionary<byte, decimal>> GetAsync(CancellationToken cancellationToken = default);
    void Invalidate();
}

/// <summary>
/// In-memory UAE emirate shipping rates loaded once at startup; refreshed in-place after admin updates only.
/// </summary>
public interface IInternalDomesticShippingProvider
{
    Task EnsureLoadedAsync(CancellationToken cancellationToken = default);

    object GetAllRatesResponse();

    object GetPriceByEmirateResponse(string emirateName);

    byte GetExcessKgRateAed();

    void ApplyInMemoryUpdates(IReadOnlyList<(byte Id, decimal PriceAed)> updates);

    void ApplyExcessKgRateUpdate(byte excessKgRateAed);
}

public interface IStaticReferenceCache
{
    Task EnsureLoadedAsync(CancellationToken cancellationToken = default);

    IReadOnlyList<GeoCountrySnapshot> GetCountries();
    GeoCountrySnapshot? FindCountryById(short id);
    GeoCountrySnapshot? FindCountryByEnglishName(string countryName);
    GeoCountrySnapshot? FindCountryByName(string countryName);

    IReadOnlyList<GeoPortSnapshot> GetPortsByCountryId(short countryId);
    GeoPortSnapshot? FindPortById(int id);
    GeoPortSnapshot? FindPortByEnglishName(string portName, short countryId);
    GeoPortSnapshot? FindPortByName(string portName, short countryId);
    GeoPortSnapshot? FindPortByEnglishName(string portName, IReadOnlyCollection<int> allowedPortIds);
    GeoPortSnapshot? FindPortByEnglishName(string portName);
    GeoPortSnapshot? FindPortByName(string portName);
    object GetPortsByCountryNameResponse(string countryName);

    IReadOnlyList<GeoCitySnapshot> GetCities();
    IReadOnlyList<GeoCitySnapshot> GetCitiesByCountryId(short countryId);
    GeoCitySnapshot? FindCityById(Guid id);
    GeoCitySnapshot? FindCityByName(string cityName);
    object GetCitiesByCountryNameResponse(string countryName);
    object GetCitiesByCountryIdResponse(short countryId);

    IReadOnlyList<RoleSnapshot> GetRoles();
    RoleSnapshot? FindRoleById(byte id);

    IReadOnlyList<UnitSnapshot> GetUnits();
    UnitSnapshot? FindUnitById(byte id);
    UnitSnapshot? FindUnitByName(string unitNameEn);

    /// <summary>Product types (Retail/Booking/…) — static seed; Redis + memory.</summary>
    ProductTypeSnapshot? FindProductTypeByName(string typeNameEn);
    ProductTypeSnapshot? FindProductTypeById(byte id);
    bool ProductTypeExistsByName(string typeNameEn);

    /// <summary>Categories — Redis + memory; call <see cref="InvalidateCategories"/> after admin writes.</summary>
    CategorySnapshot? FindCategoryById(byte id);
    CategorySnapshot? FindCategoryByName(string name);
    bool CategoryExistsById(byte id);
    bool CategoryExistsByName(string name);
    void InvalidateCategories();

    RequestTypeSnapshot? FindRequestTypeById(byte id);
    RequestTypeSnapshot? FindRequestTypeByName(string nameEn);
    BookingPriceTypeSnapshot? FindBookingPriceTypeById(byte id);
    BookingPriceTypeSnapshot? FindBookingPriceTypeByName(string nameEn);
}

/// <summary>Backward-compatible alias for geo lookups on <see cref="IStaticReferenceCache"/>.</summary>
public interface IGeoReferenceCache : IStaticReferenceCache;

public interface IAdminSettingsAppService
{
    Task<object> GetSettingsAsync(CancellationToken cancellationToken = default);
    Task<object> GetPublicCommissionsAsync(CancellationToken cancellationToken = default);
    Task<object> UpdateSettingsAsync(UpdateSystemSettingsInput input, CancellationToken cancellationToken = default);
}
