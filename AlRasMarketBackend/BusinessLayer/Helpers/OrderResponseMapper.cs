using BusinessLayer.Dtos;
using DataLayer.Models;

namespace BusinessLayer.Helpers;

public static class OrderResponseMapper
{
    public static OrderDetailDto ToDetail(Order order)
    {
        var imageList = order.Images?
            .OrderBy(x => x.Id)
            .Select(x => x.ImagePath)
            .ToList() ?? [];

        var videoList = order.Videos?
            .OrderByDescending(x => x.CreatedAt)
            .Select(x => x.VideoPath)
            .ToList() ?? [];

        return new OrderDetailDto
        {
            Id = order.Id,
            FromUserId = order.FromUserId,
            ToUserId = order.ToUserId,
            ProductId = order.ProductId,
            Quantity = order.Quantity,
            UnitPrice = order.UnitPrice,
            TotalPrice = order.TotalPrice,
            CreatedAt = UtcDateTimeHelper.AsUtc(order.CreatedAt),
            StatusId = order.StatusId,
            Status = RequestOfferStatusLabels.ResolveNameEn(order),
            StatusAr = RequestOfferStatusLabels.ResolveNameAr(order),
            OrderGroupId = order.OrderGroupId,
            PendingOrderId = order.PendingOrderId,
            PaymentMethod = order.PaymentMethod,
            PaymentMethodName = GetPaymentMethodName(order.PaymentMethod),
            StripeSessionId = order.StripeSessionId,
            UnitId = order.UnitId,
            IsApproved = order.IsApproved,
            Notes = order.Notes,
            PortId = order.PortId,
            PortName = order.Port?.PortNameEn,
            ImagePaths = imageList,
            VideoPaths = videoList,
            StripeRefundId = order.StripeRefundId,
            RefundedAtUtc = order.RefundedAtUtc.HasValue
                ? UtcDateTimeHelper.AsUtc(order.RefundedAtUtc.Value)
                : null,
            IsRefunded = order.RefundedAtUtc.HasValue
                || !string.IsNullOrWhiteSpace(order.StripeRefundId)
        };
    }

    public static string GetPaymentMethodName(byte paymentMethod) =>
        paymentMethod switch
        {
            (byte)PaymentMethod.Online => "Online",
            (byte)PaymentMethod.CashOnDelivery => "CashOnDelivery",
            _ => "Unknown"
        };
}
