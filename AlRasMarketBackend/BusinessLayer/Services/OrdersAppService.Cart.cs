using BusinessLayer.Dtos;
using BusinessLayer.Helpers;
using BusinessLayer.Interfaces;
using DataLayer.Interfaces;
using DataLayer.Models;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;

namespace BusinessLayer.Services;

public partial class OrdersAppService
{
    public async Task<object> PlaceOrderFromCartAsync(PlaceOrderInput input, CancellationToken cancellationToken = default)
    {
        if (!Guid.TryParse(input.UserId, out var userId))
        {
            throw new ArgumentException("Invalid user id.");
        }

        var paymentMethod = ParsePaymentMethod(input.PaymentMethodName);
        if (paymentMethod == PaymentMethod.Online && !IsStripeConfigured())
        {
            throw new InvalidOperationException("Online payment is not available right now.");
        }

        var (addressId, fulfillmentFromAddress) = await ResolveCheckoutAddressAsync(
            input,
            userId,
            cancellationToken);

        var cart = await orderData.GetCartForCheckoutAsync(userId, cancellationToken);

        if (cart is null || cart.CartItems.Count == 0)
        {
            throw new InvalidOperationException("Cart is empty.");
        }

        var shippingCostAed = decimal.Round(Math.Max(0, input.ShippingCostAed ?? 0), 2, MidpointRounding.AwayFromZero);
        var fulfillment = fulfillmentFromAddress
            ?? BuildCheckoutFulfillmentSnapshot(input, shippingCostAed);

        if (!fulfillment.IsSelfPickup && addressId is null)
        {
            throw new InvalidOperationException("Please select a saved delivery address.");
        }

        var isRetailCart = cart.CartItems.All(x => ProductTypeCodes.IsRetailSellable(x.Product));
        if (!isRetailCart)
        {
            throw new InvalidOperationException("Cart contains products that are not retail-sellable.");
        }

        if (!fulfillment.IsSelfPickup && isRetailCart)
        {
            var cartWeightKg = RetailDomesticShippingCalculator.SumCartWeightKg(
                cart.CartItems.Select(x => (
                    x.Quantity,
                    x.Unit?.UnitNameEn,
                    x.Product?.Packaging)));
            shippingCostAed = ResolveRetailDomesticShippingAed(
                fulfillment.DeliveryCityName,
                shippingCostAed,
                cartWeightKg);
            fulfillment = fulfillment with { ShippingCostAed = shippingCostAed };
        }

        var itemSnapshots = new List<ValidatedCartLine>();
        decimal subtotalAed = 0;

        foreach (var cartItem in cart.CartItems)
        {
            var product = cartItem.Product
                ?? throw new InvalidOperationException("Cart contains an invalid product.");

            var (stockUnit, stockQuantity) = ResolveRetailChannelStock(product);
            if (stockUnit is null || cartItem.Unit is null)
            {
                throw new InvalidOperationException($"Product '{product.NameEn}' has no valid unit.");
            }

            if (product.OwnerId is null)
            {
                throw new InvalidOperationException($"Product '{product.NameEn}' has no owner.");
            }

            OrderOwnershipRules.EnsureBuyerIsNotOwner(userId, product.OwnerId);

            EnsureOnlinePaymentAllowed(product, paymentMethod);

            var quantityInStockUnit = OrderUnitConversion.ConvertQuantity(
                cartItem.Quantity,
                cartItem.Unit.UnitNameEn,
                stockUnit.UnitNameEn);

            if (quantityInStockUnit > (decimal)stockQuantity)
            {
                throw new InvalidOperationException($"Requested quantity exceeds available stock for '{product.NameEn}'.");
            }

            var lineAed = decimal.Round(cartItem.Quantity * cartItem.UnitPriceAed, 2, MidpointRounding.AwayFromZero);
            subtotalAed += lineAed;

            var (persistedUnitId, persistedQuantity) = NormalizeRetailCartLineUnit(
                product,
                cartItem.UnitId,
                cartItem.Quantity);
            var persistedUnitPriceAed = cartItem.UnitPriceAed;
            if (persistedQuantity != cartItem.Quantity && persistedQuantity > 0)
            {
                persistedUnitPriceAed = decimal.Round(
                    lineAed / persistedQuantity,
                    2,
                    MidpointRounding.AwayFromZero);
            }

            itemSnapshots.Add(new ValidatedCartLine(
                product.ProductId,
                product.OwnerId.Value,
                persistedUnitId,
                persistedQuantity,
                persistedUnitPriceAed,
                lineAed,
                0m,
                quantityInStockUnit));
        }

        var vatAed = VatHelper.CalculateVat(subtotalAed);
        var vatAllocations = VatHelper.AllocateVat(
            itemSnapshots.Select(x => x.LineTotalAed).ToList(),
            vatAed);
        itemSnapshots = itemSnapshots
            .Select((line, index) => line with { LineVatAed = vatAllocations[index] })
            .ToList();

        var totalAed = VatHelper.CalculateGrandTotal(subtotalAed, shippingCostAed);
        var usdToAed = GetUsdToAedRate();
        var totalUsd = decimal.Round(totalAed / usdToAed, 2, MidpointRounding.AwayFromZero);

        if (paymentMethod == PaymentMethod.Online)
        {
            var pendingOrder = new PendingOrder
            {
                FromUserId = userId,
                AddressId = addressId,
                ShippingCostAed = fulfillment.ShippingCostAed,
                SubtotalAed = subtotalAed,
                VatAed = vatAed,
                TotalPriceUsd = totalUsd,
                TotalPriceAed = totalAed,
                PaymentMethod = PaymentMethod.Online,
                Notes = NormalizeNotes(input.Notes),
                IsSelfPickup = fulfillment.IsSelfPickup,
                DeliveryAddressLine = fulfillment.DeliveryAddressLine,
                DeliveryCityName = fulfillment.DeliveryCityName,
                DeliveryLatitude = fulfillment.DeliveryLatitude,
                DeliveryLongitude = fulfillment.DeliveryLongitude,
            };

            foreach (var line in itemSnapshots)
            {
                pendingOrder.Items.Add(new PendingOrderItem
                {
                    ProductId = line.ProductId,
                    ToUserId = line.ToUserId,
                    UnitId = line.UnitId,
                    Quantity = line.Quantity,
                    UnitPriceUsd = decimal.Round(line.UnitPriceAed / usdToAed, 2, MidpointRounding.AwayFromZero),
                    UnitPriceAed = line.UnitPriceAed,
                    LineTotalAed = line.LineTotalAed
                });
            }

            await orderData.AddPendingOrderAsync(pendingOrder, cancellationToken);
            await orderData.SaveChangesAsync(cancellationToken);

            return new
            {
                pendingOrderId = pendingOrder.Id,
                paymentMethod = "Online",
                status = "PendingPayment",
                subtotalAed = pendingOrder.SubtotalAed,
                vatAed = pendingOrder.VatAed,
                totalPriceUsd = pendingOrder.TotalPriceUsd,
                totalPriceAed = pendingOrder.TotalPriceAed,
                shippingCostAed = pendingOrder.ShippingCostAed,
                items = pendingOrder.Items.Select(x => new
                {
                    x.ProductId,
                    x.ToUserId,
                    x.UnitId,
                    x.Quantity,
                    x.UnitPriceUsd,
                    x.UnitPriceAed,
                    x.LineTotalAed
                })
            };
        }

        var orderGroupId = Guid.NewGuid();
        var createdOrders = await CreateOrderRowsAsync(
            userId,
            orderGroupId,
            null,
            null,
            (byte)paymentMethod,
            itemSnapshots,
            NormalizeNotes(input.Notes),
            fulfillment,
            cancellationToken);

        await ClearCartAsync(userId, cart, cancellationToken);
        await NotifyOrderPartiesAsync(createdOrders, cancellationToken);

        return new
        {
            orderGroupId,
            paymentMethod = OrderResponseMapper.GetPaymentMethodName((byte)paymentMethod),
            status = "OrderRequested",
            subtotalAed,
            vatAed,
            totalPriceAed = totalAed,
            shippingCostAed,
            orders = createdOrders.Select(x => OrderResponseMapper.ToDetail(x)).ToList()
        };
    }

    public async Task<Guid> CreateOrdersFromPendingOrderAsync(Guid pendingOrderId, CancellationToken cancellationToken = default)
    {
        var pendingOrder = await orderData.GetPendingOrderWithItemsAsync(pendingOrderId, cancellationToken)
            ?? throw new KeyNotFoundException("Pending order not found.");

        if (!pendingOrder.IsPaymentCompleted)
        {
            throw new InvalidOperationException("Pending order payment is not completed yet.");
        }

        if (pendingOrder.FinalOrderGroupId.HasValue)
        {
            return pendingOrder.FinalOrderGroupId.Value;
        }

        var lineSubtotals = pendingOrder.Items.Select(x => x.LineTotalAed).ToList();
        var orderVat = pendingOrder.VatAed > 0
            ? pendingOrder.VatAed
            : VatHelper.CalculateVat(lineSubtotals.Sum());
        var vatAllocations = VatHelper.AllocateVat(lineSubtotals, orderVat);

        var snapshots = pendingOrder.Items
            .Select((x, index) => new ValidatedCartLine(
                x.ProductId,
                x.ToUserId,
                x.UnitId,
                x.Quantity,
                x.UnitPriceAed,
                x.LineTotalAed,
                vatAllocations[index],
                x.Quantity))
            .ToList();

        var fulfillment = new CheckoutFulfillmentSnapshot(
            pendingOrder.ShippingCostAed,
            pendingOrder.IsSelfPickup,
            pendingOrder.DeliveryAddressLine,
            pendingOrder.DeliveryCityName,
            pendingOrder.DeliveryLatitude,
            pendingOrder.DeliveryLongitude);

        var orderGroupId = Guid.NewGuid();
        var createdOrders = await CreateOrderRowsAsync(
            pendingOrder.FromUserId,
            orderGroupId,
            pendingOrder.Id,
            pendingOrder.StripeSessionId,
            (byte)PaymentMethod.Online,
            snapshots,
            pendingOrder.Notes,
            fulfillment,
            cancellationToken);

        pendingOrder.FinalOrderGroupId = orderGroupId;
        await orderData.SaveChangesAsync(cancellationToken);

        var cart = await orderData.GetCartWithItemsAsync(pendingOrder.FromUserId, cancellationToken);
        if (cart is not null)
        {
            await ClearCartAsync(pendingOrder.FromUserId, cart, cancellationToken);
        }

        await NotifyOrderPartiesAsync(createdOrders, cancellationToken);

        return orderGroupId;
    }


    private async Task<List<Order>> CreateOrderRowsAsync(
        Guid fromUserId,
        Guid orderGroupId,
        Guid? pendingOrderId,
        string? stripeSessionId,
        byte paymentMethod,
        IReadOnlyList<ValidatedCartLine> lines,
        string? notes,
        CheckoutFulfillmentSnapshot? fulfillment,
        CancellationToken cancellationToken)
    {
        var created = new List<Order>();
        var lineSubtotals = lines.Select(x => x.LineTotalAed).ToList();
        var cartShipping = fulfillment is { IsSelfPickup: false }
            ? fulfillment.ShippingCostAed
            : 0m;
        var shippingAllocations = VatHelper.AllocateVat(lineSubtotals, cartShipping);

        var productIds = lines.Select(x => x.ProductId).Distinct().ToList();
        var products = await orderData.GetProductsByIdsWithUnitsAsync(productIds, cancellationToken);

        foreach (var (line, index) in lines.Select((line, index) => (line, index)))
        {
            OrderOwnershipRules.EnsureBuyerIsNotOwner(fromUserId, line.ToUserId);

            products.TryGetValue(line.ProductId, out var product);
            var (unitId, quantity) = NormalizeRetailCartLineUnit(product, line.UnitId, line.Quantity);

            // Cart checkout is always the retail channel (including hybrid category retail).
            var (statusId, isAdminApproved) = ResolveInitialOrderStatusForCartLine(
                product?.ProductTypeId,
                product?.CategoryId,
                notes);

            var order = new Order
            {
                FromUserId = fromUserId,
                ToUserId = line.ToUserId,
                ProductId = line.ProductId,
                Quantity = quantity,
                UnitPrice = line.UnitPriceAed,
                TotalPrice = line.LineTotalAed,
                VatAed = line.LineVatAed,
                StatusId = statusId,
                OrderGroupId = orderGroupId,
                PendingOrderId = pendingOrderId,
                PaymentMethod = paymentMethod,
                StripeSessionId = stripeSessionId,
                UnitId = unitId,
                IsApproved = false,
                IsAdminApproved = isAdminApproved,
                IsRetailPurchase = true,
                Notes = notes,
                StockQuantityDeducted = false,
                ShippingCostAed = shippingAllocations[index],
                IsSelfPickup = fulfillment?.IsSelfPickup ?? false,
                DeliveryAddressLine = fulfillment?.DeliveryAddressLine,
                DeliveryCityName = fulfillment?.DeliveryCityName,
                DeliveryLatitude = fulfillment?.DeliveryLatitude,
                DeliveryLongitude = fulfillment?.DeliveryLongitude,
                CreatedAt = DateTime.SpecifyKind(UtcDateTimeHelper.UtcNow, DateTimeKind.Utc),
            };

            if (isAdminApproved)
            {
                RequestOfferStatusLabels.ApplyAwaitingSeller(order);
            }
            else
            {
                RequestOfferStatusLabels.ApplyAwaitingAdmin(order);
            }

            await orderData.AddOrderAsync(order, cancellationToken);
            created.Add(order);
        }

        await orderData.SaveChangesAsync(cancellationToken);

        if (!string.IsNullOrWhiteSpace(notes))
        {
            foreach (var order in created)
            {
                await TryTranslateOrderNotesAsync(order.Id, notes, cancellationToken);
            }
        }

        return created;
    }

    /// <summary>
    /// Ensures retail-channel lines persist RetailUnitId on Order.UnitId (hybrids especially).
    /// </summary>
    private (byte UnitId, decimal Quantity) NormalizeRetailCartLineUnit(
        Product? product,
        byte unitId,
        decimal quantity)
    {
        if (product is null
            || !ProductTypeCodes.HasRetailStockConfigured(product)
            || product.RetailUnitId is not byte retailUnitId)
        {
            return (unitId, quantity);
        }

        if (unitId == retailUnitId)
        {
            return (unitId, quantity);
        }

        var fromUnit = staticReferenceCache.FindUnitById(unitId);
        var toUnitName = product.RetailUnit?.UnitNameEn
            ?? staticReferenceCache.FindUnitById(retailUnitId)?.UnitNameEn;
        if (fromUnit is null || string.IsNullOrWhiteSpace(toUnitName))
        {
            return (retailUnitId, quantity);
        }

        try
        {
            var converted = OrderUnitConversion.ConvertQuantity(
                quantity,
                fromUnit.UnitNameEn,
                toUnitName);
            return (retailUnitId, converted);
        }
        catch (InvalidOperationException)
        {
            return (retailUnitId, quantity);
        }
    }

    private async Task ClearCartAsync(Guid userId, Cart cart, CancellationToken cancellationToken)
    {
        orderData.RemoveCartItems(cart.CartItems);
        cart.UpdatedAt = DateTime.UtcNow;
        await orderData.SaveChangesAsync(cancellationToken);
        cache.Remove($"cart:v8:{userId:N}");
        cache.Remove($"cart:v7:{userId:N}");
    }


    private sealed record ValidatedCartLine(
        Guid ProductId,
        Guid ToUserId,
        byte UnitId,
        decimal Quantity,
        decimal UnitPriceAed,
        decimal LineTotalAed,
        decimal LineVatAed,
        decimal QuantityInProductUnits);

}
