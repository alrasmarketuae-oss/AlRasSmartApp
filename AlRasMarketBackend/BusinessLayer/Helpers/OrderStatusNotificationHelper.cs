namespace BusinessLayer.Helpers;

public static class OrderStatusNotificationHelper
{
    public sealed record OrderStatusEmailModel(
        long OrderId,
        decimal Quantity,
        decimal TotalPrice,
        string? ProductName);

    public sealed record OrderStatusNotificationContent(
        string EmailSubject,
        string EmailSubjectAr,
        string PushTitle,
        string PushTitleAr,
        string PushBody,
        string PushBodyAr,
        string StatusHeadlineAr,
        string StatusMessageAr);

    public static OrderStatusNotificationContent Build(byte statusId, OrderStatusEmailModel order, string recipientName)
    {
        var orderId = order.OrderId.ToString();
        var productName = order.ProductName ?? "—";
        var statusAr = OrderStatusCodes.GetNameAr(statusId);
        var statusEn = OrderStatusCodes.GetNameEn(statusId);
        var safeName = string.IsNullOrWhiteSpace(recipientName) ? "عميلنا الكريم" : recipientName.Trim();

        var (headlineAr, messageAr, pushBodyAr) = statusId switch
        {
            OrderStatusCodes.Approved => (
                "تمت الموافقة على طلبك",
                $"خبر سار {safeName}! تمت الموافقة على طلبك رقم #{orderId} للمنتج «{productName}».",
                $"تمت الموافقة على طلب #{orderId}"),
            OrderStatusCodes.Paid => (
                "تم الدفع لـ Merge Spice",
                $"تم استلام دفعتك لـ Merge Spice لطلب رقم #{orderId} — «{productName}». شكراً لتعاملك معنا.",
                $"تم الدفع لـ Merge Spice — طلب #{orderId}"),
            OrderStatusCodes.Shipping => (
                "طلبك في الطريق",
                $"طلبك رقم #{orderId} — «{productName}» أصبح قيد الشحن.",
                $"طلب #{orderId} قيد الشحن"),
            OrderStatusCodes.Delivered => (
                "تم التسليم",
                $"تم تسليم طلبك رقم #{orderId} — «{productName}». نتمنى أن تكون راضياً عن تجربتك.",
                $"تم تسليم طلب #{orderId}"),
            // Legacy Received — same meaning as Delivered.
            OrderStatusCodes.Received => (
                "تم التسليم",
                $"تم تسليم طلبك رقم #{orderId} — «{productName}». نتمنى أن تكون راضياً عن تجربتك.",
                $"تم تسليم طلب #{orderId}"),
            OrderStatusCodes.PaidToSupplier => (
                "تم الدفع للمورد من Merge Spice",
                $"تم إتمام الدفع للمورد من Merge Spice بخصوص طلبك رقم #{orderId}.",
                $"تم الدفع للمورد من Merge Spice — طلب #{orderId}"),
            OrderStatusCodes.Cancelled => (
                "تم إلغاء الطلب",
                $"تم إلغاء طلبك رقم #{orderId} — «{productName}». للاستفسار تواصل معنا.",
                $"تم إلغاء طلب #{orderId}"),
            _ => (
                "تحديث حالة الطلب",
                $"تم تحديث حالة طلبك رقم #{orderId} إلى: {statusAr}.",
                $"تحديث طلب #{orderId}: {statusAr}")
        };

        return new OrderStatusNotificationContent(
            EmailSubject: $"Al Ras Smart — Order #{orderId} is now {statusEn}",
            EmailSubjectAr: $"تطبيق الراس الذكي — تحديث طلب #{orderId}: {statusAr}",
            PushTitle: "Order update",
            PushTitleAr: "تحديث الطلب",
            PushBody: $"Order #{orderId}: {statusEn}",
            PushBodyAr: pushBodyAr,
            StatusHeadlineAr: headlineAr,
            StatusMessageAr: messageAr);
    }

    public static string BuildEmailHtml(
        OrderStatusEmailModel order,
        byte statusId,
        OrderStatusNotificationContent content,
        string recipientName)
    {
        var orderId = order.OrderId.ToString();
        var productName = order.ProductName ?? "—";
        var statusAr = OrderStatusCodes.GetNameAr(statusId);
        var statusEn = OrderStatusCodes.GetNameEn(statusId);
        var safeName = string.IsNullOrWhiteSpace(recipientName) ? "عميلنا الكريم" : recipientName.Trim();
        var total = order.TotalPrice.ToString("N2");
        var quantity = order.Quantity.ToString("0.###", System.Globalization.CultureInfo.InvariantCulture);
        var accent = StatusAccentColor(statusId);

        var inner =
            BrandEmailLayout.Paragraph($"مرحباً {safeName}،") +
            BrandEmailLayout.Headline(content.StatusHeadlineAr) +
            BrandEmailLayout.Paragraph(content.StatusMessageAr) +
            BrandEmailLayout.StatusPill($"{statusAr} · {statusEn}", accent) +
            BrandEmailLayout.InfoCard("رقم الطلب", $"#{orderId}") +
            BrandEmailLayout.InfoCard("المنتج", productName) +
            BrandEmailLayout.InfoCard("الكمية", quantity) +
            BrandEmailLayout.InfoCard("الإجمالي (AED)", total);

        // Full branded document so callers can send as-is; EmailService also recognizes the brand marker.
        return BrandEmailLayout.Wrap(content.EmailSubjectAr, inner);
    }

    private static string StatusAccentColor(byte statusId) => statusId switch
    {
        OrderStatusCodes.Approved => BrandEmailLayout.Green,
        OrderStatusCodes.Paid => BrandEmailLayout.Blue,
        OrderStatusCodes.Shipping => BrandEmailLayout.Blue,
        OrderStatusCodes.Delivered => BrandEmailLayout.Green,
        OrderStatusCodes.Cancelled => BrandEmailLayout.Red,
        _ => BrandEmailLayout.Blue
    };
}
