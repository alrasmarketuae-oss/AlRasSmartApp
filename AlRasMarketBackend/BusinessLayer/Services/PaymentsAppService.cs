using BusinessLayer.Dtos;
using BusinessLayer.Helpers;
using BusinessLayer.Interfaces;
using DataLayer.Interfaces;
using DataLayer.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Stripe;
using Stripe.Checkout;

namespace BusinessLayer.Services;

public class PaymentsAppService(
    IConfiguration configuration,
    IRasAlSouqDbContext dbContext,
    IOrdersAppService ordersAppService,
    ILogger<PaymentsAppService> logger) : IPaymentsAppService
{
    private const byte CancelledStatusId = OrderStatusCodes.Cancelled;
    private const byte ReturnApprovedStatusId = OrderStatusCodes.ReturnApproved;

    private readonly string _successUrl = configuration["Stripe:SuccessUrl"] ?? "https://example.com/payment-success";
    private readonly string _cancelUrl = configuration["Stripe:CancelUrl"] ?? "https://example.com/payment-cancelled";
    private readonly string _mobileSuccessUrl = configuration["Stripe:MobileSuccessUrl"] ?? "alrasmarket://payment-success";
    private readonly string _mobileCancelUrl = configuration["Stripe:MobileCancelUrl"] ?? "alrasmarket://payment-cancel";
    private readonly string _secretKey = configuration["Stripe:SecretKey"] ?? string.Empty;
    private readonly string _webhookSecret = configuration["Stripe:WebhookSecret"] ?? string.Empty;

    public async Task<CreateStripeCheckoutResult> CreateStripeCheckoutAsync(
        CreateStripeCheckoutInput input,
        CancellationToken cancellationToken = default)
    {
        if (!IsStripeConfigured())
        {
            throw new InvalidOperationException("Online payment is not available right now.");
        }

        if (!Guid.TryParse(input.UserId, out var userId))
        {
            throw new ArgumentException("Invalid user id.");
        }

        if (!Guid.TryParse(input.OrderId, out var orderId))
        {
            throw new ArgumentException("Invalid order id.");
        }

        var pendingOrder = await dbContext.PendingOrders
            .Include(x => x.Items)
            .FirstOrDefaultAsync(x => x.Id == orderId, cancellationToken)
            ?? throw new KeyNotFoundException("Order not found.");

        if (pendingOrder.FromUserId != userId)
        {
            throw new UnauthorizedAccessException("You can only pay for your own orders.");
        }

        if (pendingOrder.PaymentMethod != DataLayer.Models.PaymentMethod.Online)
        {
            throw new InvalidOperationException("Order payment method is not online.");
        }

        if (pendingOrder.IsPaymentCompleted)
        {
            throw new InvalidOperationException("Order payment is already completed.");
        }

        var (stripeCurrency, currencyCode, checkoutAmount) = StripeCheckoutHelper.Resolve(
            pendingOrder,
            input.Currency,
            input.Amount,
            CurrencyConversionHelper.GetUsdToAedRate(configuration));

        var session = await CreateCheckoutSessionAsync(
            checkoutAmount,
            stripeCurrency,
            $"Al Ras App order #{pendingOrder.Id:N}",
            new Dictionary<string, string> { ["PendingOrderId"] = pendingOrder.Id.ToString() },
            ResolveSuccessUrl(input.Client),
            ResolveCancelUrl(input.Client),
            cancellationToken);

        pendingOrder.StripeSessionId = session.Id;
        pendingOrder.PaymentIntentId = null;
        pendingOrder.CheckoutCurrency = currencyCode;
        pendingOrder.CheckoutAmount = checkoutAmount;
        await dbContext.SaveChangesAsync(cancellationToken);

        return new CreateStripeCheckoutResult
        {
            SessionId = session.Id,
            CheckoutUrl = session.Url,
            Currency = currencyCode,
            Amount = checkoutAmount
        };
    }

    public async Task<Guid?> HandleWebhookAsync(string json, string signature, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(_webhookSecret))
        {
            throw new InvalidOperationException("Stripe webhook secret is not configured.");
        }

        var stripeEvent = EventUtility.ConstructEvent(
            json,
            signature,
            _webhookSecret,
            tolerance: 300,
            throwOnApiVersionMismatch: false);

        if (stripeEvent.Type != "checkout.session.completed")
        {
            return null;
        }

        var session = stripeEvent.Data.Object as Session;
        if (session is null)
        {
            return null;
        }

        return await CompletePaidCheckoutSessionAsync(session, cancellationToken);
    }

    public async Task<CheckoutStatusResult> GetCheckoutStatusAsync(
        string userId,
        string sessionId,
        CancellationToken cancellationToken = default)
    {
        if (!Guid.TryParse(userId, out var userGuid))
        {
            throw new ArgumentException("Invalid user id.");
        }

        var pendingOrder = await dbContext.PendingOrders
            .FirstOrDefaultAsync(x => x.StripeSessionId == sessionId, cancellationToken);

        if (pendingOrder is not null)
        {
            if (pendingOrder.FromUserId != userGuid)
            {
                throw new UnauthorizedAccessException("You can only view your own checkout status.");
            }

            if (!pendingOrder.IsPaymentCompleted)
            {
                await TrySyncCheckoutSessionFromStripeAsync(sessionId, cancellationToken);
                pendingOrder = await dbContext.PendingOrders
                    .FirstOrDefaultAsync(x => x.StripeSessionId == sessionId, cancellationToken)
                    ?? pendingOrder;
            }

            if (!pendingOrder.IsPaymentCompleted)
            {
                return new CheckoutStatusResult { Status = "pending" };
            }

            if (!pendingOrder.FinalOrderGroupId.HasValue)
            {
                return new CheckoutStatusResult { Status = "processing" };
            }

            return new CheckoutStatusResult
            {
                Status = "completed",
                OrderGroupId = pendingOrder.FinalOrderGroupId.Value.ToString(),
                OrderStatusId = OrderStatusCodes.Ordered
            };
        }

        var pendingPayment = await dbContext.PendingPayments
            .Include(x => x.Order)
            .FirstOrDefaultAsync(x => x.StripeSessionId == sessionId, cancellationToken);

        if (pendingPayment is null)
        {
            return new CheckoutStatusResult { Status = "not_found" };
        }

        if (pendingPayment.Order?.FromUserId != userGuid)
        {
            throw new UnauthorizedAccessException("You can only view your own checkout status.");
        }

        if (!pendingPayment.IsCompleted)
        {
            await TrySyncCheckoutSessionFromStripeAsync(sessionId, cancellationToken);
            pendingPayment = await dbContext.PendingPayments
                .Include(x => x.Order)
                .FirstOrDefaultAsync(x => x.StripeSessionId == sessionId, cancellationToken)
                ?? pendingPayment;
        }

        if (!pendingPayment.IsCompleted)
        {
            return new CheckoutStatusResult { Status = "pending" };
        }

        return new CheckoutStatusResult
        {
            Status = "completed",
            OrderGroupId = pendingPayment.Order?.OrderGroupId?.ToString(),
            OrderStatusId = pendingPayment.Order?.StatusId
        };
    }

    private async Task<Guid?> CompletePaidCheckoutSessionAsync(Session session, CancellationToken cancellationToken)
    {
        var isPaid = session.PaymentStatus?.Equals("paid", StringComparison.OrdinalIgnoreCase) == true
            || session.Status?.Equals("complete", StringComparison.OrdinalIgnoreCase) == true;
        if (!isPaid)
        {
            logger.LogWarning("Stripe session {SessionId} completed but not paid.", session.Id);
            return null;
        }

        var pendingOrder = await dbContext.PendingOrders
            .Include(x => x.Items)
            .FirstOrDefaultAsync(x => x.StripeSessionId == session.Id, cancellationToken);

        if (pendingOrder is not null)
        {
            var expectedAmount = pendingOrder.CheckoutAmount
                ?? StripeCheckoutHelper.Resolve(
                    pendingOrder,
                    pendingOrder.CheckoutCurrency,
                    null,
                    CurrencyConversionHelper.GetUsdToAedRate(configuration)).Amount;
            ValidatePaidAmount(session, expectedAmount);

            if (pendingOrder.FinalOrderGroupId.HasValue)
            {
                return pendingOrder.FinalOrderGroupId;
            }

            pendingOrder.IsPaymentCompleted = true;
            pendingOrder.PaymentIntentId = session.PaymentIntentId ?? session.Id;
            await dbContext.SaveChangesAsync(cancellationToken);

            var orderGroupId = await ordersAppService.CreateOrdersFromPendingOrderAsync(pendingOrder.Id, cancellationToken);
            return orderGroupId;
        }

        var pendingPayment = await dbContext.PendingPayments
            .Include(x => x.Order)
            .FirstOrDefaultAsync(x => x.StripeSessionId == session.Id, cancellationToken);

        if (pendingPayment is null || pendingPayment.IsCompleted)
        {
            return null;
        }

        var legacyOrder = pendingPayment.Order;
        if (legacyOrder is null)
        {
            return null;
        }

        ValidatePaidAmount(session, legacyOrder.TotalPrice);

        if (legacyOrder.StatusId == CancelledStatusId)
        {
            pendingPayment.IsCompleted = true;
            pendingPayment.PaymentIntentId = session.PaymentIntentId ?? session.Id;
            await dbContext.SaveChangesAsync(cancellationToken);
            return legacyOrder.OrderGroupId;
        }

        var legacyProductTypeId = await dbContext.Products
            .AsNoTracking()
            .Where(x => x.ProductId == legacyOrder.ProductId)
            .Select(x => x.ProductTypeId)
            .FirstOrDefaultAsync(cancellationToken);

        legacyOrder.StatusId = ProductTypeCodes.IsRetail(legacyProductTypeId)
            ? OrderStatusCodes.AwaitingSellerApproval
            : OrderStatusCodes.Ordered;
        legacyOrder.IsApproved = false;
        if (ProductTypeCodes.IsRetail(legacyProductTypeId))
        {
            legacyOrder.IsAdminApproved = true;
            RequestOfferStatusLabels.ApplyAwaitingSeller(legacyOrder);
        }
        pendingPayment.IsCompleted = true;
        pendingPayment.PaymentIntentId = session.PaymentIntentId ?? session.Id;
        await dbContext.SaveChangesAsync(cancellationToken);
        return legacyOrder.OrderGroupId;
    }

    private async Task TrySyncCheckoutSessionFromStripeAsync(string sessionId, CancellationToken cancellationToken)
    {
        if (!IsStripeConfigured())
        {
            return;
        }

        try
        {
            var session = await new SessionService().GetAsync(sessionId, cancellationToken: cancellationToken);
            await CompletePaidCheckoutSessionAsync(session, cancellationToken);
        }
        catch (Exception ex)
        {
            logger.LogWarning(ex, "Failed to sync Stripe checkout session {SessionId}.", sessionId);
        }
    }

    private string ResolveSuccessUrl(string? client) =>
        IsMobileClient(client) ? _mobileSuccessUrl : _successUrl;

    private string ResolveCancelUrl(string? client) =>
        IsMobileClient(client) ? _mobileCancelUrl : _cancelUrl;

    private static bool IsMobileClient(string? client) =>
        string.Equals(client, "mobile", StringComparison.OrdinalIgnoreCase);

    public async Task<ManualRefundResult> RefundCancelledOrderAsync(long orderId, CancellationToken cancellationToken = default)
    {
        if (!IsStripeConfigured())
        {
            throw new InvalidOperationException("Online payment is not available right now.");
        }

        var order = await dbContext.Orders.FirstOrDefaultAsync(x => x.Id == orderId, cancellationToken)
            ?? throw new KeyNotFoundException("Order not found.");

        if (order.PaymentMethod != (byte)DataLayer.Models.PaymentMethod.Online)
        {
            throw new InvalidOperationException("Only online payments can be refunded.");
        }

        if (order.StatusId != CancelledStatusId && order.StatusId != ReturnApprovedStatusId)
        {
            throw new InvalidOperationException(
                "Only cancelled or return-approved orders can be refunded manually.");
        }

        if (!string.IsNullOrWhiteSpace(order.StripeRefundId) || order.RefundedAtUtc.HasValue)
        {
            throw new InvalidOperationException("This order has already been refunded.");
        }

        PendingOrder? pendingOrder = null;
        if (order.PendingOrderId.HasValue)
        {
            pendingOrder = await dbContext.PendingOrders
                .Include(x => x.Items)
                .FirstOrDefaultAsync(x => x.Id == order.PendingOrderId.Value, cancellationToken);
        }
        else if (order.OrderGroupId.HasValue)
        {
            pendingOrder = await dbContext.PendingOrders
                .Include(x => x.Items)
                .FirstOrDefaultAsync(x => x.FinalOrderGroupId == order.OrderGroupId.Value, cancellationToken);
        }

        if (pendingOrder is not null)
        {
            return await RefundPendingOrderLineAsync(order, pendingOrder, cancellationToken);
        }

        var pendingPayment = await dbContext.PendingPayments
            .FirstOrDefaultAsync(x => x.OrderId == orderId, cancellationToken)
            ?? throw new InvalidOperationException("No completed online payment was found for this order.");

        return await RefundLegacyPaymentAsync(order, order.OrderGroupId?.ToString() ?? orderId.ToString(), pendingPayment, cancellationToken);
    }

    private async Task<ManualRefundResult> RefundPendingOrderLineAsync(
        Order order,
        PendingOrder pendingOrder,
        CancellationToken cancellationToken)
    {
        if (!pendingOrder.IsPaymentCompleted)
        {
            throw new InvalidOperationException("This online payment is not completed yet.");
        }

        if (string.IsNullOrWhiteSpace(pendingOrder.PaymentIntentId))
        {
            throw new InvalidOperationException("Payment intent is missing for this order.");
        }

        await EnsureRefundableAsync(pendingOrder.PaymentIntentId, cancellationToken);

        var refundAmountAed = ResolveOrderRefundAmount(order, pendingOrder);
        var refundMinor = (long)Math.Round(refundAmountAed * 100m, MidpointRounding.AwayFromZero);
        if (refundMinor <= 0)
        {
            throw new InvalidOperationException("Refund amount must be greater than zero.");
        }

        var refund = await new RefundService().CreateAsync(new RefundCreateOptions
        {
            PaymentIntent = pendingOrder.PaymentIntentId,
            Amount = refundMinor,
            Metadata = new Dictionary<string, string>
            {
                ["pendingOrderId"] = pendingOrder.Id.ToString(),
                ["orderId"] = order.Id.ToString()
            }
        }, cancellationToken: cancellationToken);

        order.StripeRefundId = refund.Id;
        order.RefundedAtUtc = DateTime.UtcNow;

        if (pendingOrder.FinalOrderGroupId.HasValue)
        {
            var groupOrders = await dbContext.Orders
                .Where(x => x.OrderGroupId == pendingOrder.FinalOrderGroupId.Value)
                .ToListAsync(cancellationToken);

            var allClosed = groupOrders.All(x =>
                x.StatusId == CancelledStatusId || x.StatusId == ReturnApprovedStatusId);
            var allRefunded = groupOrders.All(x =>
                !string.IsNullOrWhiteSpace(x.StripeRefundId) || x.RefundedAtUtc.HasValue);

            if (allClosed && allRefunded)
            {
                pendingOrder.StripeRefundId = refund.Id;
                pendingOrder.RefundedAtUtc = DateTime.UtcNow;
            }
        }
        else
        {
            pendingOrder.StripeRefundId = refund.Id;
            pendingOrder.RefundedAtUtc = DateTime.UtcNow;
        }

        await dbContext.SaveChangesAsync(cancellationToken);

        return new ManualRefundResult
        {
            OrderGroupId = pendingOrder.FinalOrderGroupId?.ToString() ?? pendingOrder.Id.ToString(),
            RefundId = refund.Id,
            RefundedAtUtc = order.RefundedAtUtc.Value
        };
    }

    private static decimal ResolveOrderRefundAmount(Order order, PendingOrder pendingOrder)
    {
        var line = pendingOrder.Items.FirstOrDefault(x =>
            x.ProductId == order.ProductId && x.Quantity == order.Quantity);
        var lineSubtotal = line?.LineTotalAed ?? order.TotalPrice;
        var orderSubtotal = pendingOrder.SubtotalAed > 0
            ? pendingOrder.SubtotalAed
            : pendingOrder.Items.Sum(x => x.LineTotalAed);
        var orderVat = pendingOrder.VatAed > 0
            ? pendingOrder.VatAed
            : VatHelper.CalculateVat(orderSubtotal);
        var lineVat = order.VatAed > 0
            ? order.VatAed
            : VatHelper.AllocateLineVat(lineSubtotal, orderSubtotal, orderVat);

        if (line is not null && orderSubtotal > 0 && pendingOrder.TotalPriceAed > 0)
        {
            var lineShare = lineSubtotal / orderSubtotal;
            var lineTotalWithVat = decimal.Round(lineSubtotal + lineVat, 2, MidpointRounding.AwayFromZero);
            var shippingShare = decimal.Round(pendingOrder.ShippingCostAed * lineShare, 2, MidpointRounding.AwayFromZero);
            return lineTotalWithVat + shippingShare;
        }

        if (orderSubtotal > 0 && pendingOrder.TotalPriceAed > 0)
        {
            var share = lineSubtotal / orderSubtotal;
            return decimal.Round(pendingOrder.TotalPriceAed * share, 2, MidpointRounding.AwayFromZero);
        }

        return decimal.Round(lineSubtotal + lineVat, 2, MidpointRounding.AwayFromZero);
    }

    private async Task<ManualRefundResult> RefundLegacyPaymentAsync(
        Order order,
        string orderGroupId,
        PendingPayment pending,
        CancellationToken cancellationToken)
    {
        if (!pending.IsCompleted)
        {
            throw new InvalidOperationException("This online payment is not completed yet.");
        }

        if (!string.IsNullOrWhiteSpace(pending.StripeRefundId) || pending.RefundedAtUtc.HasValue)
        {
            throw new InvalidOperationException("This order payment has already been refunded.");
        }

        if (string.IsNullOrWhiteSpace(pending.PaymentIntentId))
        {
            throw new InvalidOperationException("Payment intent is missing for this order.");
        }

        await EnsureRefundableAsync(pending.PaymentIntentId, cancellationToken);

        var refund = await new RefundService().CreateAsync(new RefundCreateOptions
        {
            PaymentIntent = pending.PaymentIntentId,
            Metadata = new Dictionary<string, string>
            {
                ["orderId"] = pending.OrderId.ToString()
            }
        }, cancellationToken: cancellationToken);

        pending.StripeRefundId = refund.Id;
        pending.RefundedAtUtc = DateTime.UtcNow;
        order.StripeRefundId = refund.Id;
        order.RefundedAtUtc = DateTime.UtcNow;
        await dbContext.SaveChangesAsync(cancellationToken);

        return new ManualRefundResult
        {
            OrderGroupId = orderGroupId,
            RefundId = refund.Id,
            RefundedAtUtc = pending.RefundedAtUtc.Value
        };
    }

    private static async Task EnsureRefundableAsync(string paymentIntentId, CancellationToken cancellationToken)
    {
        var paymentIntent = await new PaymentIntentService().GetAsync(paymentIntentId, cancellationToken: cancellationToken)
            ?? throw new InvalidOperationException("Stripe payment intent was not found.");

        if (paymentIntent.AmountReceived <= 0)
        {
            throw new InvalidOperationException("No captured payment amount was found for this order.");
        }

        var latestChargeId = paymentIntent.LatestChargeId;
        if (!string.IsNullOrWhiteSpace(latestChargeId))
        {
            var charge = await new ChargeService().GetAsync(latestChargeId, cancellationToken: cancellationToken);
            if (charge.AmountCaptured > 0 && charge.AmountRefunded >= charge.AmountCaptured)
            {
                throw new InvalidOperationException("This order payment has already been refunded.");
            }
        }
    }

    private static void ValidatePaidAmount(Session session, decimal expectedTotal)
    {
        var expectedMinor = (long)(expectedTotal * 100);
        if (session.AmountTotal.HasValue && session.AmountTotal.Value != expectedMinor)
        {
            throw new InvalidOperationException(
                $"Payment amount mismatch. Expected {expectedMinor}, received {session.AmountTotal.Value}.");
        }
    }

    private async Task<Session> CreateCheckoutSessionAsync(
        decimal totalPrice,
        string stripeCurrency,
        string description,
        Dictionary<string, string> metadata,
        string successUrl,
        string cancelUrl,
        CancellationToken cancellationToken)
    {
        return await new SessionService().CreateAsync(new SessionCreateOptions
        {
            PaymentMethodTypes = ["card"],
            Mode = "payment",
            SuccessUrl = $"{successUrl}?session_id={{CHECKOUT_SESSION_ID}}",
            CancelUrl = cancelUrl,
            Currency = stripeCurrency,
            LineItems =
            [
                new SessionLineItemOptions
                {
                    Quantity = 1,
                    PriceData = new SessionLineItemPriceDataOptions
                    {
                        Currency = stripeCurrency,
                        UnitAmount = (long)(totalPrice * 100),
                        ProductData = new SessionLineItemPriceDataProductDataOptions
                        {
                            Name = "Al Ras App Order",
                            Description = description
                        }
                    }
                }
            ],
            Metadata = metadata
        }, cancellationToken: cancellationToken);
    }

    private bool IsStripeConfigured() =>
        !string.IsNullOrWhiteSpace(_secretKey)
        && !_secretKey.Contains("change_me", StringComparison.OrdinalIgnoreCase);
}
