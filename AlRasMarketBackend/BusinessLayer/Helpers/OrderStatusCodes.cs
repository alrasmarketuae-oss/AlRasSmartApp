namespace BusinessLayer.Helpers;

public static class OrderStatusCodes
{
    public const byte Ordered = 1;
    public const byte Approved = 2;
    public const byte Paid = 3;
    public const byte Shipping = 4;
    public const byte Delivered = 5;
    public const byte Cancelled = 6;
    public const byte Received = 7;
    public const byte PaidToSupplier = 8;
    /// <summary>Retail only: buyer requested a return after delivery.</summary>
    public const byte ReturnRequested = 9;
    /// <summary>Retail only: support approved the return (refund applied when online).</summary>
    public const byte ReturnApproved = 10;
    /// <summary>Admin pre-approved; waiting for seller accept/reject (non-retail only).</summary>
    public const byte AwaitingSellerApproval = 11;

    public static string GetNameEn(byte statusId) => statusId switch
    {
        Ordered => "Ordered",
        Approved => "Approved",
        Paid => "Paid to Merge Spice",
        Shipping => "Shipping",
        Delivered => "Delivered",
        Cancelled => "Cancelled",
        // Legacy status: same meaning as Delivered (no longer used in workflow).
        Received => "Delivered",
        PaidToSupplier => "Paid to supplier from Merge Spice",
        ReturnRequested => "Return requested",
        ReturnApproved => "Return approved",
        AwaitingSellerApproval => "Awaiting seller approval",
        _ => "Unknown"
    };

    public static string GetNameAr(byte statusId) => statusId switch
    {
        Ordered => "تم الطلب",
        Approved => "تمت الموافقة",
        Paid => "تم الدفع لـ Merge Spice",
        Shipping => "تم الشحن من المورد",
        Delivered => "تم التسليم",
        Cancelled => "ملغي",
        // Legacy status: same meaning as Delivered (no longer used in workflow).
        Received => "تم التسليم",
        PaidToSupplier => "تم الدفع للمورد من Merge Spice",
        ReturnRequested => "طلب استرجاع",
        ReturnApproved => "تمت الموافقة على الاسترجاع",
        AwaitingSellerApproval => "بانتظار موافقة البائع",
        _ => "غير معروف"
    };

    public static bool IsValid(byte statusId) =>
        statusId is Ordered or Approved or Paid or Shipping or Delivered or Cancelled
            or Received or PaidToSupplier or ReturnRequested or ReturnApproved
            or AwaitingSellerApproval;

    /// <summary>
    /// Completed delivery for sales/dashboard stats (excludes cancelled and return flows).
    /// Includes PaidToSupplier because those orders were already delivered.
    /// </summary>
    public static bool CountsAsDeliveredSale(byte statusId) =>
        statusId is Delivered or Received or PaidToSupplier;

    public static bool CanTransition(byte fromStatusId, byte toStatusId, byte? productTypeId = null)
    {
        if (fromStatusId == toStatusId)
        {
            return false;
        }

        var isRetail = productTypeId.HasValue && ProductTypeCodes.IsRetail(productTypeId.Value);

        var allowed = (fromStatusId, toStatusId) switch
        {
            (Ordered, Approved) => true,
            (Ordered, Paid) => true,
            (Ordered, Cancelled) => true,
            (AwaitingSellerApproval, Approved) => true,
            (AwaitingSellerApproval, Cancelled) => true,
            (Approved, Paid) => true,
            // Retail after seller accept: admin moves to Shipping (skip Paid).
            (Approved, Shipping) => true,
            (Approved, Cancelled) => true,
            (Paid, Shipping) => true,
            (Paid, Cancelled) => true,
            // Legacy retail online that was marked Paid before seller accept.
            (Paid, Approved) => isRetail,
            (Paid, AwaitingSellerApproval) => false,
            (Shipping, Delivered) => true,
            (Delivered, Cancelled) => true,
            _ => false
        };

        if (allowed)
        {
            return true;
        }

        if (isRetail)
        {
            return (fromStatusId, toStatusId) switch
            {
                (Delivered, ReturnRequested) => true,
                (Received, ReturnRequested) => true,
                (ReturnRequested, ReturnApproved) => true,
                (ReturnRequested, Delivered) => true,
                _ => false
            };
        }

        return (fromStatusId, toStatusId) switch
        {
            (Delivered, PaidToSupplier) => true,
            // Legacy orders that were already moved to Received.
            (Received, PaidToSupplier) => true,
            _ => false
        };
    }
}
