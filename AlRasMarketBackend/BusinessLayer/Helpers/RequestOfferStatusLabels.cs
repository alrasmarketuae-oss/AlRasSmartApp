using DataLayer.Models;

namespace BusinessLayer.Helpers;

/// <summary>Bilingual display labels for request-offer and retail order workflows.</summary>
public static class RequestOfferStatusLabels
{
    public const string AwaitingAdminEn = "Awaiting app approval";
    public const string AwaitingAdminAr = "بانتظار موافقة التطبيق";

    public const string AwaitingAdvertiserEn = "Awaiting advertiser approval";
    public const string AwaitingAdvertiserAr = "بانتظار موافقة المعلن";

    public const string AcceptedByRequesterEn = "Accepted by the requester";
    public const string AcceptedByRequesterAr = "تم القبول من قبل الطالب";

    public const string RejectedByAdvertiserEn = "Rejected by the advertiser";
    public const string RejectedByAdvertiserAr = "تم الرفض من قبل المعلن";

    public const string RejectedByAdminEn = "Rejected by admin";
    public const string RejectedByAdminAr = "تم الرفض من قبل الإدارة";

    public const string AwaitingSellerEn = "Awaiting seller approval";
    public const string AwaitingSellerAr = "بانتظار موافقة البائع";

    public const string AcceptedBySellerEn = "Accepted by the seller";
    public const string AcceptedBySellerAr = "تم قبول الطلب من البائع";

    public const string RejectedOrderEn = "Order rejected";
    public const string RejectedOrderAr = "تم رفض الطلب";

    public const string ReceivedEn = "Received";
    public const string ReceivedAr = "تم الاستلام";

    /// <summary>
    /// Sets the current bilingual label and appends an immutable history row.
    /// </summary>
    public static void Apply(Order order, string nameEn, string nameAr, Guid? createdByUserId = null)
    {
        order.CustomStatusNameEn = nameEn;
        order.CustomStatusNameAr = nameAr;
        order.StatusHistories.Add(new OrderStatusHistory
        {
            OrderId = order.Id,
            StatusId = order.StatusId,
            StatusNameEn = nameEn.Trim(),
            StatusNameAr = nameAr.Trim(),
            CreatedAtUtc = DateTime.UtcNow,
            CreatedByUserId = createdByUserId,
        });
    }

    public static void ApplyAwaitingAdmin(Order order, Guid? createdByUserId = null) =>
        Apply(order, AwaitingAdminEn, AwaitingAdminAr, createdByUserId);

    public static void ApplyAwaitingAdvertiser(Order order, Guid? createdByUserId = null) =>
        Apply(order, AwaitingAdvertiserEn, AwaitingAdvertiserAr, createdByUserId);

    public static void ApplyAcceptedByRequester(Order order, Guid? createdByUserId = null) =>
        Apply(order, AcceptedByRequesterEn, AcceptedByRequesterAr, createdByUserId);

    public static void ApplyRejectedByAdvertiser(Order order, Guid? createdByUserId = null) =>
        Apply(order, RejectedByAdvertiserEn, RejectedByAdvertiserAr, createdByUserId);

    public static void ApplyRejectedByAdmin(Order order, Guid? createdByUserId = null) =>
        Apply(order, RejectedByAdminEn, RejectedByAdminAr, createdByUserId);

    public static void ApplyAwaitingSeller(Order order, Guid? createdByUserId = null) =>
        Apply(order, AwaitingSellerEn, AwaitingSellerAr, createdByUserId);

    public static void ApplyAcceptedBySeller(Order order, Guid? createdByUserId = null) =>
        Apply(order, AcceptedBySellerEn, AcceptedBySellerAr, createdByUserId);

    public static void ApplyRejectedOrder(Order order, Guid? createdByUserId = null) =>
        Apply(order, RejectedOrderEn, RejectedOrderAr, createdByUserId);

    public static void ApplyReceived(Order order, Guid? createdByUserId = null) =>
        Apply(order, ReceivedEn, ReceivedAr, createdByUserId);

    public static void ApplyReturnRequested(Order order, Guid? createdByUserId = null) =>
        Apply(
            order,
            OrderStatusCodes.GetNameEn(OrderStatusCodes.ReturnRequested),
            OrderStatusCodes.GetNameAr(OrderStatusCodes.ReturnRequested),
            createdByUserId);

    public static void ApplyReturnApproved(Order order, Guid? createdByUserId = null) =>
        Apply(
            order,
            OrderStatusCodes.GetNameEn(OrderStatusCodes.ReturnApproved),
            OrderStatusCodes.GetNameAr(OrderStatusCodes.ReturnApproved),
            createdByUserId);

    public static void ApplyDelivered(Order order, Guid? createdByUserId = null) =>
        Apply(
            order,
            OrderStatusCodes.GetNameEn(OrderStatusCodes.Delivered),
            OrderStatusCodes.GetNameAr(OrderStatusCodes.Delivered),
            createdByUserId);

    public static string ResolveNameEn(Order order)
    {
        // Return workflow labels must always follow StatusId (custom "Received"
        // must not stick after the buyer requests a return).
        if (order.StatusId is OrderStatusCodes.ReturnRequested
            or OrderStatusCodes.ReturnApproved)
        {
            return OrderStatusCodes.GetNameEn(order.StatusId);
        }

        var name = !string.IsNullOrWhiteSpace(order.CustomStatusNameEn)
            ? order.CustomStatusNameEn.Trim()
            : OrderStatusCodes.GetNameEn(order.StatusId);
        return NormalizeDisplayEn(name);
    }

    public static string ResolveNameAr(Order order)
    {
        if (order.StatusId is OrderStatusCodes.ReturnRequested
            or OrderStatusCodes.ReturnApproved)
        {
            return OrderStatusCodes.GetNameAr(order.StatusId);
        }

        var name = !string.IsNullOrWhiteSpace(order.CustomStatusNameAr)
            ? order.CustomStatusNameAr.Trim()
            : OrderStatusCodes.GetNameAr(order.StatusId);
        return NormalizeDisplayAr(name);
    }

    /// <summary>Display-only remap; does not change stored workflow fields.</summary>
    public static string NormalizeDisplayEn(string? name)
    {
        if (string.IsNullOrWhiteSpace(name))
        {
            return string.Empty;
        }

        var trimmed = name.Trim();
        return string.Equals(trimmed, "Awaiting admin approval", StringComparison.OrdinalIgnoreCase)
            ? AwaitingAdminEn
            : trimmed;
    }

    /// <summary>Display-only remap; does not change stored workflow fields.</summary>
    public static string NormalizeDisplayAr(string? name)
    {
        if (string.IsNullOrWhiteSpace(name))
        {
            return string.Empty;
        }

        var trimmed = name.Trim();
        return string.Equals(trimmed, "بانتظار موافقة الإدارة", StringComparison.Ordinal)
            ? AwaitingAdminAr
            : trimmed;
    }

    /// <summary>Terminal fulfillment states — no more manual text updates / blink.</summary>
    public static bool IsFulfillmentComplete(byte statusId) =>
        statusId is OrderStatusCodes.Delivered
            or OrderStatusCodes.Received
            or OrderStatusCodes.Cancelled
            or OrderStatusCodes.PaidToSupplier
            or OrderStatusCodes.ReturnApproved;

    public static bool NeedsAttention(Order order)
    {
        if (IsFulfillmentComplete(order.StatusId))
        {
            return false;
        }

        // Request offers: blink for any open offer except awaiting-seller.
        if (ProductTypeCodes.IsRequests(order.Product?.ProductTypeId))
        {
            return order.StatusId != OrderStatusCodes.AwaitingSellerApproval;
        }

        // Category / booking / offers awaiting admin approval.
        if (!order.IsAdminApproved
            && order.StatusId == OrderStatusCodes.Ordered
            && ProductTypeCodes.RequiresAdminModerationBeforeSellerApproval(order.Product))
        {
            return true;
        }

        if (order.IsApproved)
        {
            return true;
        }

        return ProductTypeCodes.IsRetail(order.Product?.ProductTypeId);
    }
}
