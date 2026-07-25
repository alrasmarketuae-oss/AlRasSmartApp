namespace BusinessLayer.Helpers;

public static class OrderOwnershipRules
{
    public const string CannotOrderOwnProductMessage =
        "You cannot place an order on your own product.";

    public static void EnsureBuyerIsNotOwner(Guid buyerUserId, Guid? productOwnerId)
    {
        if (productOwnerId.HasValue && productOwnerId.Value == buyerUserId)
        {
            throw new InvalidOperationException(CannotOrderOwnProductMessage);
        }
    }
}
