using BusinessLayer.Dtos;
using BusinessLayer.Helpers;
using BusinessLayer.Interfaces;
using DataLayer.Interfaces;
using DataLayer.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.Configuration;

namespace BusinessLayer.Services;

public class CartAppService(
    IRasAlSouqDbContext dbContext,
    IMemoryCache cache,
    IStaticReferenceCache staticReferenceCache,
    IConfiguration configuration,
    ICommissionSettingsProvider commissionSettingsProvider,
    ICategoryCommissionProvider categoryCommissionProvider) : ICartAppService
{
    private static readonly TimeSpan CacheDuration = TimeSpan.FromMinutes(2);

    public async Task<object> AddItemAsync(AddCartItemInput input, CancellationToken cancellationToken = default)
    {
        if (!Guid.TryParse(input.UserId, out var userId))
        {
            throw new ArgumentException("Invalid user id.");
        }

        if (!Guid.TryParse(input.ProductId, out var productId))
        {
            throw new ArgumentException("Invalid product id.");
        }

        if (input.Quantity <= 0)
        {
            throw new ArgumentException("Quantity must be greater than zero.");
        }

        if (string.IsNullOrWhiteSpace(input.UnitName))
        {
            throw new ArgumentException("UnitName is required.");
        }

        _ = await dbContext.Users.FindAsync([userId], cancellationToken)
            ?? throw new KeyNotFoundException("User not found.");

        var product = await dbContext.Products
            .Include(x => x.Unit)
            .Include(x => x.RetailUnit)
            .Include(x => x.ProductImages)
            .Include(x => x.ProductVideos)
            .FirstOrDefaultAsync(x => x.ProductId == productId, cancellationToken)
            ?? throw new KeyNotFoundException("Product not found.");

        if (!ProductTypeCodes.IsRetailSellable(product))
        {
            throw new InvalidOperationException("Only retail-sellable products can be added to the cart.");
        }

        OrderOwnershipRules.EnsureBuyerIsNotOwner(userId, product.OwnerId);

        var (stockUnit, stockQuantity) = ResolveCartStock(product);
        if (stockUnit is null)
        {
            throw new InvalidOperationException("Product unit is not set.");
        }

        var requestedUnit = staticReferenceCache.FindUnitByName(input.UnitName)
            ?? throw new KeyNotFoundException($"Unit '{input.UnitName}' was not found.");

        // Hybrid (category + retail) and retail-priced products must persist the retail unit
        // on cart/order rows — never the wholesale UnitId.
        var useRetailUnit = ProductTypeCodes.HasRetailStockConfigured(product);
        var cartUnitId = useRetailUnit ? stockUnit.Id : requestedUnit.Id;
        var cartUnitNameEn = useRetailUnit ? stockUnit.UnitNameEn : requestedUnit.UnitNameEn;
        var stockUnitNameEn = stockUnit.UnitNameEn;

        var quantityInStockUnit = OrderUnitConversion.ConvertQuantity(
            input.Quantity,
            requestedUnit.UnitNameEn,
            stockUnitNameEn);

        if (quantityInStockUnit > stockQuantity)
        {
            var existingCartItem = await dbContext.CartItems
                .Include(x => x.Cart)
                .Include(x => x.Unit)
                .FirstOrDefaultAsync(
                    x => x.Cart!.UserId == userId && x.ProductId == productId,
                    cancellationToken);

            if (existingCartItem is not null)
            {
                var existingUnitName = existingCartItem.Unit?.UnitNameEn ?? cartUnitNameEn;
                var alreadyInCart = OrderUnitConversion.ConvertQuantity(
                    existingCartItem.Quantity,
                    existingUnitName,
                    stockUnitNameEn);

                if (alreadyInCart >= stockQuantity)
                {
                    throw new InvalidOperationException(
                        $"CART_MAX_AVAILABLE:{stockQuantity}");
                }
            }

            throw new InvalidOperationException(
                $"CART_MAX_AVAILABLE:{stockQuantity}");
        }

        var cartQuantity = OrderUnitConversion.ConvertQuantity(
            input.Quantity,
            requestedUnit.UnitNameEn,
            cartUnitNameEn);

        var pricingContext = await GetPricingContextAsync(cancellationToken);
        var unitPriceAed = ResolveUnitPriceAed(product, cartUnitNameEn, pricingContext);

        if (unitPriceAed <= 0)
        {
            throw new InvalidOperationException("Product price is not available.");
        }

        var cart = await dbContext.Carts.FirstOrDefaultAsync(x => x.UserId == userId, cancellationToken);
        if (cart is null)
        {
            cart = new Cart { UserId = userId };
            await dbContext.Carts.AddAsync(cart, cancellationToken);
            await dbContext.SaveChangesAsync(cancellationToken);
        }

        var existingItems = await dbContext.CartItems
            .Include(x => x.Unit)
            .Where(x => x.CartId == cart.CartId && x.ProductId == productId)
            .ToListAsync(cancellationToken);

        CartItem existingItem;
        if (existingItems.Count == 0)
        {
            existingItem = new CartItem
            {
                CartId = cart.CartId,
                ProductId = productId,
                Quantity = cartQuantity,
                UnitId = cartUnitId,
                UnitPriceAed = unitPriceAed
            };
            await dbContext.CartItems.AddAsync(existingItem, cancellationToken);
        }
        else
        {
            existingItem = existingItems[0];
            decimal existingInCartUnit = 0;
            foreach (var row in existingItems)
            {
                var rowUnitName = row.Unit?.UnitNameEn ?? cartUnitNameEn;
                existingInCartUnit += OrderUnitConversion.ConvertQuantity(
                    row.Quantity,
                    rowUnitName,
                    cartUnitNameEn);
            }

            var newQuantity = existingInCartUnit + cartQuantity;
            var totalInStockUnit = OrderUnitConversion.ConvertQuantity(
                newQuantity,
                cartUnitNameEn,
                stockUnitNameEn);

            if (totalInStockUnit > stockQuantity)
            {
                if (existingInCartUnit >= stockQuantity)
                {
                    throw new InvalidOperationException(
                        $"CART_MAX_AVAILABLE:{stockQuantity}");
                }

                throw new InvalidOperationException(
                    $"CART_MAX_AVAILABLE:{stockQuantity}");
            }

            existingItem.Quantity = newQuantity;
            existingItem.UnitId = cartUnitId;
            existingItem.UnitPriceAed = unitPriceAed;

            if (existingItems.Count > 1)
            {
                dbContext.CartItems.RemoveRange(existingItems.Skip(1));
            }
        }

        cart.UpdatedAt = DateTime.UtcNow;
        await dbContext.SaveChangesAsync(cancellationToken);
        cache.Remove(GetCartCacheKey(userId));

        return BuildCartItemResponse(
            existingItem,
            product,
            product.NameEn,
            cartUnitNameEn,
            unitPriceAed,
            pricingContext);
    }

    public async Task<object> GetMyCartAsync(string userId, CancellationToken cancellationToken = default)
    {
        if (!Guid.TryParse(userId, out var userGuid))
        {
            throw new ArgumentException("Invalid user id.");
        }

        var cacheKey = GetCartCacheKey(userGuid);
        if (cache.TryGetValue(cacheKey, out object? cached) && cached is not null)
        {
            return cached;
        }

        var cart = await dbContext.Carts
            .Include(x => x.CartItems)
            .ThenInclude(x => x.Product!)
            .ThenInclude(x => x!.ProductImages)
            .Include(x => x.CartItems)
            .ThenInclude(x => x.Product!)
            .ThenInclude(x => x!.ProductVideos)
            .Include(x => x.CartItems)
            .ThenInclude(x => x.Product!)
            .ThenInclude(x => x!.Unit)
            .Include(x => x.CartItems)
            .ThenInclude(x => x.Product!)
            .ThenInclude(x => x!.RetailUnit)
            .Include(x => x.CartItems)
            .ThenInclude(x => x.Unit)
            .FirstOrDefaultAsync(x => x.UserId == userGuid, cancellationToken);

        var pricingContext = await GetPricingContextAsync(cancellationToken);
        var cartChanged = false;
        var items = new List<object>();
        decimal subtotalAed = 0;

        if (cart is not null)
        {
            foreach (var item in cart.CartItems)
            {
                if (item.Product is null || item.Unit is null)
                {
                    continue;
                }

                var unitPriceAed = ResolveUnitPriceAed(item.Product, item.Unit.UnitNameEn, pricingContext);
                if (item.UnitPriceAed != unitPriceAed)
                {
                    item.UnitPriceAed = unitPriceAed;
                    cartChanged = true;
                }

                var lineTotalAed = CartItemHelper.ToTotalPriceAed(item.Quantity, unitPriceAed);
                subtotalAed += lineTotalAed;

                items.Add(BuildCartItemResponse(
                    item,
                    item.Product,
                    item.Product.NameEn,
                    item.Unit.UnitNameEn,
                    unitPriceAed,
                    pricingContext));
            }
        }

        if (cartChanged && cart is not null)
        {
            cart.UpdatedAt = DateTime.UtcNow;
            await dbContext.SaveChangesAsync(cancellationToken);
        }

        subtotalAed = decimal.Round(subtotalAed, 2, MidpointRounding.AwayFromZero);
        var vatAed = VatHelper.CalculateVat(subtotalAed);

        var response = new
        {
            cartId = cart?.CartId,
            subtotalAed,
            vatAed,
            totalAed = decimal.Round(subtotalAed + vatAed, 2, MidpointRounding.AwayFromZero),
            items
        };

        cache.Set(cacheKey, response, CacheDuration);
        return response;
    }

    public async Task<object> RemoveItemAsync(RemoveCartItemInput input, CancellationToken cancellationToken = default)
    {
        var (userId, cartItem) = await GetOwnedCartItemAsync(input.UserId, input.CartItemId, cancellationToken);

        dbContext.CartItems.Remove(cartItem);
        cartItem.Cart!.UpdatedAt = DateTime.UtcNow;
        await dbContext.SaveChangesAsync(cancellationToken);
        cache.Remove(GetCartCacheKey(userId));

        return new
        {
            message = "Cart item removed.",
            cartItemId = cartItem.Id,
            removed = true
        };
    }

    public async Task<object> ReduceItemQuantityAsync(ReduceCartItemInput input, CancellationToken cancellationToken = default)
    {
        if (input.Quantity <= 0)
        {
            throw new ArgumentException("Quantity must be greater than zero.");
        }

        var (userId, cartItem) = await GetOwnedCartItemAsync(input.UserId, input.CartItemId, cancellationToken);
        var pricingContext = await GetPricingContextAsync(cancellationToken);

        if (input.Quantity >= cartItem.Quantity)
        {
            dbContext.CartItems.Remove(cartItem);
            cartItem.Cart!.UpdatedAt = DateTime.UtcNow;
            await dbContext.SaveChangesAsync(cancellationToken);
            cache.Remove(GetCartCacheKey(userId));

            return new
            {
                message = "Cart item removed because quantity reached zero.",
                cartItemId = cartItem.Id,
                removed = true
            };
        }

        cartItem.Quantity -= input.Quantity;
        cartItem.Cart!.UpdatedAt = DateTime.UtcNow;

        if (cartItem.Product is not null && cartItem.Unit is not null)
        {
            cartItem.UnitPriceAed = ResolveUnitPriceAed(cartItem.Product, cartItem.Unit.UnitNameEn, pricingContext);
        }

        await dbContext.SaveChangesAsync(cancellationToken);
        cache.Remove(GetCartCacheKey(userId));

        return BuildCartItemResponse(
            cartItem,
            cartItem.Product,
            cartItem.Product?.NameEn,
            cartItem.Unit!.UnitNameEn,
            cartItem.UnitPriceAed,
            pricingContext);
    }

    private async Task<PricingContext> GetPricingContextAsync(CancellationToken cancellationToken)
    {
        var settings = await commissionSettingsProvider.GetAsync(cancellationToken);
        var categoryCommissions = await categoryCommissionProvider.GetAsync(cancellationToken);
        return new PricingContext(
            settings,
            categoryCommissions,
            CurrencyConversionHelper.GetUsdToAedRate(configuration));
    }

    private static decimal ResolveUnitPriceAed(
        Product product,
        string requestedUnitNameEn,
        PricingContext pricingContext) =>
        decimal.Round(
            CartItemHelper.ResolveCustomerUnitPriceAed(
                product,
                requestedUnitNameEn,
                pricingContext.Settings,
                pricingContext.CategoryCommissions,
                pricingContext.UsdToAedRate),
            2,
            MidpointRounding.AwayFromZero);

    private async Task<(Guid UserId, CartItem CartItem)> GetOwnedCartItemAsync(
        string userIdText,
        long cartItemId,
        CancellationToken cancellationToken)
    {
        if (!Guid.TryParse(userIdText, out var userId))
        {
            throw new ArgumentException("Invalid user id.");
        }

        if (cartItemId <= 0)
        {
            throw new ArgumentException("Invalid cart item id.");
        }

        var cartItem = await dbContext.CartItems
            .Include(x => x.Cart)
            .Include(x => x.Unit)
            .Include(x => x.Product!)
            .ThenInclude(x => x!.ProductImages)
            .Include(x => x.Product!)
            .ThenInclude(x => x!.ProductVideos)
            .Include(x => x.Product!)
            .ThenInclude(x => x!.Unit)
            .Include(x => x.Product!)
            .ThenInclude(x => x!.RetailUnit)
            .FirstOrDefaultAsync(x => x.Id == cartItemId, cancellationToken)
            ?? throw new KeyNotFoundException("Cart item not found.");

        if (cartItem.Cart is null || cartItem.Cart.UserId != userId)
        {
            throw new UnauthorizedAccessException("You can only modify items in your own cart.");
        }

        return (userId, cartItem);
    }

    private static object BuildCartItemResponse(
        CartItem item,
        Product? product,
        string? productName,
        string unitName,
        decimal unitPriceAed,
        PricingContext pricingContext)
    {
        var commissionPercent = product is null
            ? 0m
            : CustomerPricingHelper.ResolveCommissionPercent(
                product,
                pricingContext.Settings,
                pricingContext.CategoryCommissions);

        var availableQuantity = product is null
            ? 0m
            : ResolveAvailableQuantityInCartUnit(product, unitName);

        var imagePath = CartItemHelper.ResolvePrimaryImagePath(product);
        var videoPath = string.IsNullOrWhiteSpace(imagePath)
            ? CartItemHelper.ResolvePrimaryVideoPath(product)
            : null;

        return new
        {
            id = item.Id,
            productId = item.ProductId,
            productName,
            quantity = item.Quantity,
            unit = unitName,
            currency = "AED",
            commissionPercent,
            unitPriceAed,
            totalPriceAed = CartItemHelper.ToTotalPriceAed(item.Quantity, unitPriceAed),
            imageUrl = imagePath,
            videoUrl = videoPath,
            videoDurationSeconds = product?.VideoDurationSeconds,
            availableQuantity
        };
    }

    private static (Unit? Unit, long Quantity) ResolveCartStock(Product product)
    {
        if (ProductTypeCodes.HasRetailStockConfigured(product))
        {
            return (product.RetailUnit, product.RetailQuantity ?? 0);
        }

        return (product.Unit, product.Quantity);
    }

    private static decimal ResolveAvailableQuantityInCartUnit(Product product, string cartUnitName)
    {
        var (stockUnit, stockQuantity) = ResolveCartStock(product);
        if (stockUnit is null)
        {
            return Math.Max(0, stockQuantity);
        }

        try
        {
            return OrderUnitConversion.ConvertQuantity(
                Math.Max(0, stockQuantity),
                stockUnit.UnitNameEn,
                cartUnitName);
        }
        catch (InvalidOperationException)
        {
            return Math.Max(0, stockQuantity);
        }
    }

    private static string GetCartCacheKey(Guid userId) => $"cart:v9:{userId:N}";

    private sealed record PricingContext(
        CommissionSettingsSnapshot Settings,
        IReadOnlyDictionary<byte, decimal> CategoryCommissions,
        decimal UsdToAedRate);
}
