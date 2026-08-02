using BusinessLayer.Helpers;
using DataLayer.Models;
using Microsoft.EntityFrameworkCore;

namespace BusinessLayer.Services.AiAssistant.Mcp;

public sealed partial class AiAssistantMcpToolsService
{
    private async Task<string> GetMyPurchaseSummaryAsync(
        Guid? userId,
        CancellationToken cancellationToken)
    {
        if (!userId.HasValue)
        {
            return Json(new { ok = false, error = "Sign in to view your purchase totals." });
        }

        var buyerId = userId.Value;
        var cancelled = OrderStatusCodes.Cancelled;

        var rows = await dbContext.Orders.AsNoTracking()
            .Where(o => o.FromUserId == buyerId && o.StatusId != cancelled)
            .Select(o => new
            {
                o.Id,
                o.TotalPrice,
                o.VatAed,
                o.ShippingCostAed,
                o.StatusId,
                o.CreatedAt
            })
            .ToListAsync(cancellationToken)
            .ConfigureAwait(false);

        var delivered = rows.Where(o => OrderStatusCodes.CountsAsDeliveredSale(o.StatusId)).ToList();
        var open = rows
            .Where(o =>
                !OrderStatusCodes.CountsAsDeliveredSale(o.StatusId)
                && o.StatusId != OrderStatusCodes.ReturnApproved)
            .ToList();

        var goodsTotal = rows.Sum(x => x.TotalPrice);
        var vatTotal = rows.Sum(x => x.VatAed);
        var shippingTotal = rows.Sum(x => x.ShippingCostAed);

        return Json(new
        {
            ok = true,
            perspective = "as_buyer",
            meaning = "Purchases this user made (My Orders / طلباتي). Not orders on their ads.",
            currency = "AED",
            orderCount = rows.Count,
            deliveredOrderCount = delivered.Count,
            openOrderCount = open.Count,
            goodsTotal,
            vatTotal,
            shippingTotal,
            estimatedChargedTotal = goodsTotal + vatTotal + shippingTotal,
            instruction =
                "This is BUYER spend (طلباتي). Answer how much THEY bought using estimatedChargedTotal in AED. " +
                "Do NOT confuse with sales on their ads. Do not invent amounts."
        });
    }

    private async Task<string> GetMyLastOrderAsync(
        Guid? userId,
        CancellationToken cancellationToken)
    {
        if (!userId.HasValue)
        {
            return Json(new { ok = false, error = "Sign in to view your last order." });
        }

        var snapshot = await LoadOrderSnapshotAsync(
                userId.Value,
                orderId: null,
                asSeller: false,
                cancellationToken)
            .ConfigureAwait(false);
        if (snapshot is null)
        {
            return Json(new
            {
                ok = true,
                found = false,
                perspective = "as_buyer",
                message = "No orders found for this account as a buyer (My Orders / طلباتي)."
            });
        }

        return Json(new
        {
            ok = true,
            found = true,
            perspective = "as_buyer",
            meaning = "Last purchase this user placed as a buyer (طلباتي). Not an order on their ads.",
            order = snapshot,
            instruction =
                "Summarize THIS USER's last BUYER order (طلباتي): order id, product, amount, status. " +
                "Never present it as an order on their listings."
        });
    }

    private async Task<string> ExplainMyOrderDelayAsync(
        Guid? userId,
        string argumentsJson,
        CancellationToken cancellationToken)
    {
        if (!userId.HasValue)
        {
            return Json(new { ok = false, error = "Sign in to check order status." });
        }

        var orderId = ParseOptionalOrderId(argumentsJson);
        var snapshot = await LoadOrderSnapshotAsync(
                userId.Value,
                orderId,
                asSeller: false,
                cancellationToken)
            .ConfigureAwait(false);
        if (snapshot is null)
        {
            return Json(new
            {
                ok = true,
                found = false,
                perspective = "as_buyer",
                message = orderId.HasValue
                    ? $"No buyer order #{orderId.Value} was found in My Orders (طلباتي)."
                    : "No orders found for this account as a buyer (طلباتي)."
            });
        }

        return Json(new
        {
            ok = true,
            found = true,
            perspective = "as_buyer",
            meaning = "Delay explanation for a purchase this user made (طلباتي).",
            order = snapshot,
            instruction =
                "Explain delay for THIS USER's BUYER order using delayAnalysis. " +
                "Do not invent courier tracking. Do not treat this as a seller-ad order."
        });
    }

    private async Task<string> GetLastOrderOnMyAdsAsync(
        Guid? userId,
        CancellationToken cancellationToken)
    {
        if (!userId.HasValue)
        {
            return Json(new { ok = false, error = "Sign in to view orders on your ads." });
        }

        var snapshot = await LoadOrderSnapshotAsync(
                userId.Value,
                orderId: null,
                asSeller: true,
                cancellationToken)
            .ConfigureAwait(false);
        if (snapshot is null)
        {
            return Json(new
            {
                ok = true,
                found = false,
                perspective = "as_seller",
                message = "No customer orders found on this account's ads (الطلبات على إعلاناتي)."
            });
        }

        return Json(new
        {
            ok = true,
            found = true,
            perspective = "as_seller",
            meaning =
                "Last order a CUSTOMER placed on this seller's ads (الطلبات على إعلاناتي). " +
                "Not this user's own purchases in My Orders.",
            order = snapshot,
            instruction =
                "Summarize the last INCOMING order on the seller's ads: order id, product (their ad), amount, status. " +
                "Never call this طلباتي / My Orders."
        });
    }

    private async Task<string> ExplainOrderDelayOnMyAdsAsync(
        Guid? userId,
        string argumentsJson,
        CancellationToken cancellationToken)
    {
        if (!userId.HasValue)
        {
            return Json(new { ok = false, error = "Sign in to check orders on your ads." });
        }

        var orderId = ParseOptionalOrderId(argumentsJson);
        var snapshot = await LoadOrderSnapshotAsync(
                userId.Value,
                orderId,
                asSeller: true,
                cancellationToken)
            .ConfigureAwait(false);
        if (snapshot is null)
        {
            return Json(new
            {
                ok = true,
                found = false,
                perspective = "as_seller",
                message = orderId.HasValue
                    ? $"No seller-side order #{orderId.Value} was found on this account's ads."
                    : "No customer orders found on this account's ads."
            });
        }

        return Json(new
        {
            ok = true,
            found = true,
            perspective = "as_seller",
            meaning = "Delay explanation for a customer order on the seller's ads.",
            order = snapshot,
            instruction =
                "Explain why this INCOMING ad order may still be pending using delayAnalysis. " +
                "Speak to the seller about their listing order, not their personal purchases."
        });
    }

    private static long? ParseOptionalOrderId(string argumentsJson)
    {
        using var args = System.Text.Json.JsonDocument.Parse(
            string.IsNullOrWhiteSpace(argumentsJson) ? "{}" : argumentsJson);
        var rawId = GetString(args.RootElement, "order_id");
        if (!string.IsNullOrWhiteSpace(rawId) && long.TryParse(rawId.Trim(), out var parsed))
        {
            return parsed;
        }

        var asLong = GetLong(args.RootElement, "order_id");
        return asLong is > 0 ? asLong : null;
    }

    private async Task<object?> LoadOrderSnapshotAsync(
        Guid userId,
        long? orderId,
        bool asSeller,
        CancellationToken cancellationToken)
    {
        var query =
            from o in dbContext.Orders.AsNoTracking()
            join p in dbContext.Products.AsNoTracking() on o.ProductId equals p.ProductId into pj
            from p in pj.DefaultIfEmpty()
            join t in dbContext.ContentTranslations.AsNoTracking()
                    .Where(x =>
                        x.Scope == ContentTranslationScopes.Product &&
                        x.Field == ContentTranslationFields.Name)
                on p.ProductId equals t.ProductId into tj
            from t in tj.DefaultIfEmpty()
            join u in dbContext.Units.AsNoTracking() on o.UnitId equals u.Id into uj
            from u in uj.DefaultIfEmpty()
            where asSeller ? o.ToUserId == userId : o.FromUserId == userId
            select new
            {
                o.Id,
                o.ProductId,
                o.Quantity,
                o.UnitPrice,
                o.TotalPrice,
                o.VatAed,
                o.ShippingCostAed,
                o.StatusId,
                o.CreatedAt,
                o.PaymentMethod,
                o.IsRetailPurchase,
                o.IsSelfPickup,
                o.DeliveryCityName,
                o.DeliveryAddressLine,
                o.CustomStatusNameEn,
                o.CustomStatusNameAr,
                o.Notes,
                ProductCode = p != null ? p.ProductCode : null,
                RetailCode = p != null ? p.RetailCode : null,
                NameEn = p != null ? p.NameEn : null,
                NameAr = t != null ? t.TextAr : null,
                UnitName = u != null ? u.UnitNameEn : null
            };

        if (orderId.HasValue)
        {
            query = query.Where(x => x.Id == orderId.Value);
        }

        var row = await query
            .OrderByDescending(x => x.CreatedAt)
            .ThenByDescending(x => x.Id)
            .FirstOrDefaultAsync(cancellationToken)
            .ConfigureAwait(false);

        if (row is null) return null;

        var history = await dbContext.OrderStatusHistories.AsNoTracking()
            .Where(h => h.OrderId == row.Id)
            .OrderByDescending(h => h.CreatedAtUtc)
            .ThenByDescending(h => h.Id)
            .Take(8)
            .Select(h => new
            {
                h.StatusId,
                statusEn = h.StatusNameEn,
                statusAr = h.StatusNameAr,
                atUtc = DateTime.SpecifyKind(h.CreatedAtUtc, DateTimeKind.Utc)
            })
            .ToListAsync(cancellationToken)
            .ConfigureAwait(false);

        var lastChangeUtc = history.Count > 0
            ? history[0].atUtc
            : DateTime.SpecifyKind(row.CreatedAt, DateTimeKind.Utc);
        var now = DateTime.UtcNow;
        var ageDays = Math.Max(0, (now - DateTime.SpecifyKind(row.CreatedAt, DateTimeKind.Utc)).TotalDays);
        var daysSinceStatusChange = Math.Max(0, (now - lastChangeUtc).TotalDays);
        var isOpen = !OrderStatusCodes.CountsAsDeliveredSale(row.StatusId)
                     && row.StatusId != OrderStatusCodes.Cancelled
                     && row.StatusId != OrderStatusCodes.ReturnApproved;
        var likelyDelayed = isOpen && (
            (row.StatusId == OrderStatusCodes.Shipping && daysSinceStatusChange >= 3)
            || ((row.StatusId is OrderStatusCodes.Ordered
                    or OrderStatusCodes.Approved
                    or OrderStatusCodes.Paid
                    or OrderStatusCodes.AwaitingSellerApproval)
                && ageDays >= 2)
            || ageDays >= 5);

        var statusEn = !string.IsNullOrWhiteSpace(row.CustomStatusNameEn)
            ? row.CustomStatusNameEn
            : OrderStatusCodes.GetNameEn(row.StatusId);
        var statusAr = !string.IsNullOrWhiteSpace(row.CustomStatusNameAr)
            ? row.CustomStatusNameAr
            : OrderStatusCodes.GetNameAr(row.StatusId);

        var stageHint = row.StatusId switch
        {
            OrderStatusCodes.Ordered =>
                "Waiting for admin/platform review before approval.",
            OrderStatusCodes.AwaitingSellerApproval =>
                "Waiting for the seller to accept the order.",
            OrderStatusCodes.Approved =>
                "Approved; waiting for payment confirmation or next shipping step.",
            OrderStatusCodes.Paid =>
                "Payment recorded; waiting for the supplier to ship.",
            OrderStatusCodes.Shipping =>
                row.IsSelfPickup
                    ? "Marked as shipped/ready; self-pickup may still be pending collection."
                    : "Shipped by supplier; waiting for delivery confirmation.",
            OrderStatusCodes.Delivered or OrderStatusCodes.Received or OrderStatusCodes.PaidToSupplier =>
                "Order already delivered / completed.",
            OrderStatusCodes.Cancelled =>
                "Order was cancelled.",
            OrderStatusCodes.ReturnRequested =>
                "Buyer return request is under review.",
            OrderStatusCodes.ReturnApproved =>
                "Return was approved.",
            _ => "Status is in progress on the platform workflow."
        };

        return new
        {
            perspective = asSeller ? "as_seller" : "as_buyer",
            orderId = row.Id,
            productId = row.ProductId,
            productCode = row.ProductCode,
            retailCode = row.RetailCode,
            productNameEn = row.NameEn,
            productNameAr = row.NameAr,
            quantity = row.Quantity,
            unitName = row.UnitName,
            unitPrice = row.UnitPrice,
            goodsTotal = row.TotalPrice,
            vatAed = row.VatAed,
            shippingCostAed = row.ShippingCostAed,
            estimatedChargedTotal = row.TotalPrice + row.VatAed + row.ShippingCostAed,
            currency = "AED",
            statusId = row.StatusId,
            statusEn,
            statusAr,
            paymentMethod = OrderResponseMapper.GetPaymentMethodName(row.PaymentMethod),
            isRetailPurchase = row.IsRetailPurchase,
            isSelfPickup = row.IsSelfPickup,
            deliveryCityName = row.DeliveryCityName,
            deliveryAddressLine = row.DeliveryAddressLine,
            notes = row.Notes,
            createdAtUtc = DateTime.SpecifyKind(row.CreatedAt, DateTimeKind.Utc),
            recentStatusHistory = history,
            delayAnalysis = new
            {
                isOpen,
                likelyDelayed,
                ageDays = Math.Round(ageDays, 1),
                daysSinceLastStatusChange = Math.Round(daysSinceStatusChange, 1),
                currentStageHint = stageHint,
                explanationEn =
                    !isOpen
                        ? $"This order is not open anymore ({statusEn})."
                        : likelyDelayed
                            ? $"The order is still at \"{statusEn}\" after about {Math.Round(ageDays, 0)} day(s). {stageHint}"
                            : $"The order is still in progress at \"{statusEn}\". {stageHint}"
            }
        };
    }
}
