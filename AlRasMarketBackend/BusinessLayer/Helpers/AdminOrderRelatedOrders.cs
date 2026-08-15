using BusinessLayer.Dtos;
using DataLayer.Interfaces;

namespace BusinessLayer.Helpers;

public static class AdminOrderRelatedOrders
{
    public static async Task AttachAsync(
        IOrderDataAccess orderData,
        IReadOnlyList<AdminOrderListItemDto> items,
        CancellationToken cancellationToken = default)
    {
        if (items.Count == 0)
        {
            return;
        }

        var groupIds = items
            .Where(x => x.OrderGroupId.HasValue)
            .Select(x => x.OrderGroupId!.Value)
            .Distinct()
            .ToList();
        if (groupIds.Count == 0)
        {
            return;
        }

        var siblings = await orderData.GetOrderGroupSiblingsAsync(groupIds, cancellationToken);
        if (siblings.Count == 0)
        {
            return;
        }

        var byGroup = siblings
            .GroupBy(x => x.OrderGroupId)
            .ToDictionary(g => g.Key, g => g.ToList());

        foreach (var item in items)
        {
            if (item.OrderGroupId is not Guid groupId
                || !byGroup.TryGetValue(groupId, out var group)
                || group.Count <= 1)
            {
                item.OrderGroupItemCount = 1;
                item.RelatedOrders = [];
                continue;
            }

            item.OrderGroupItemCount = group.Count;
            item.RelatedOrders = group
                .Where(row => row.Id != item.Id)
                .Select(row => new AdminRelatedOrderDto
                {
                    Id = row.Id,
                    ProductId = row.ProductId,
                    ProductName = string.IsNullOrWhiteSpace(row.ProductName) ? "—" : row.ProductName,
                    ProductNameEn = row.ProductName,
                    ProductNameAr = row.ProductNameAr,
                    PrimaryImagePath = row.PrimaryImagePath,
                    Quantity = row.Quantity,
                    StatusId = row.StatusId,
                    SupplierName = row.SupplierName,
                })
                .ToList();
        }
    }
}
