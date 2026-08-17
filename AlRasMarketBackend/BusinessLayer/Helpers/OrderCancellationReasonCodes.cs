namespace BusinessLayer.Helpers;

public static class OrderCancellationReasonCodes
{
    public const byte BuyerRequested = 1;
    public const byte SupplierUnavailable = 2;
    public const byte ProductUnavailable = 3;
    public const byte PaymentIssue = 4;
    public const byte AdminCancelled = 5;
    public const byte Other = 6;

    public static bool IsOther(byte id) => id == Other;

    public static bool RequiresNote(byte id) => IsOther(id);
}
