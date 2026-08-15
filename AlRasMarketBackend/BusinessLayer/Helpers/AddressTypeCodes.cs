namespace BusinessLayer.Helpers;

public static class AddressTypeCodes
{
    public const byte Company = 1;
    public const byte Warehouse = 2;
    public const byte Shop = 3;
    public const byte Home = 4;

    public static bool IsValid(byte id) => id is >= Company and <= Home;

    public static string NameEn(byte id) => id switch
    {
        Company => "Company",
        Warehouse => "Warehouse",
        Shop => "Shop",
        Home => "Home",
        _ => "Home"
    };

    public static string NameAr(byte id) => id switch
    {
        Company => "شركة",
        Warehouse => "مستودع",
        Shop => "محل",
        Home => "منزل",
        _ => "منزل"
    };
}
