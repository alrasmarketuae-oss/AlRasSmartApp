using DataLayer.Models;

namespace BusinessLayer.Helpers;

public static class AdminOrderVisibilityHelper
{
    /// <summary>
    /// Request offers appear in admin immediately for review before the owner is notified.
    /// </summary>
    public static bool IsVisibleInAdminDashboard(Order order, Product? product) => true;

    public static IQueryable<Order> WhereVisibleInAdminDashboard(IQueryable<Order> query) => query;
}
