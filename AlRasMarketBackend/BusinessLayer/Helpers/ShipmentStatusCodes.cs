namespace BusinessLayer.Helpers;

public static class ShipmentStatusCodes
{
    public const byte Pending = 1;
    public const byte InDelivery = 2;
    public const byte Completed = 3;
    public const byte Late = 4;

    public static string GetNameEn(byte statusId) => statusId switch
    {
        Pending => "Pending",
        InDelivery => "InDelivery",
        Completed => "Completed",
        Late => "Late",
        _ => "Unknown"
    };

    public static string GetNameAr(byte statusId) => statusId switch
    {
        Pending => "قيد الانتظار",
        InDelivery => "قيد التوصيل",
        Completed => "مكتمل",
        Late => "متأخر",
        _ => "—"
    };

    public static bool IsValid(byte statusId) =>
        statusId is Pending or InDelivery or Completed or Late;
}
