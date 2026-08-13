namespace BusinessLayer.Constants;

public static class AdminPermissions
{
    public const string DashboardView = "dashboard.view";
    public const string UsersView = "users.view";
    public const string UsersManage = "users.manage";
    public const string ProductsView = "products.view";
    public const string ProductsManage = "products.manage";
    public const string OrdersView = "orders.view";
    public const string OrdersManage = "orders.manage";
    public const string CategoriesManage = "categories.manage";
    public const string BannersManage = "banners.manage";
    public const string ShippingView = "shipping.view";
    public const string ShippingManage = "shipping.manage";
    public const string ChatAccess = "chat.access";
    public const string NotificationsView = "notifications.view";
    public const string NotificationsSend = "notifications.send";
    public const string SettingsView = "settings.view";
    public const string SettingsManage = "settings.manage";
    public const string SearchAccess = "search.access";
    public const string EmployeesManage = "employees.manage";
    public const string UsersProfileEdits = "users.profile_edits";
    public const string ProductsAdEdits = "products.ad_edits";
    public const string OrdersReqsOffers = "orders.reqs_offers";
    public const string AuditView = "audit.view";
    public const string MonitoringView = "monitoring.view";

    public const byte EmployeeRoleId = 4;

    public static readonly IReadOnlyList<string> AllKeys =
    [
        DashboardView,
        UsersView,
        UsersManage,
        UsersProfileEdits,
        ProductsView,
        ProductsManage,
        ProductsAdEdits,
        OrdersView,
        OrdersManage,
        OrdersReqsOffers,
        CategoriesManage,
        BannersManage,
        ShippingView,
        ShippingManage,
        ChatAccess,
        NotificationsView,
        NotificationsSend,
        SettingsView,
        SettingsManage,
        SearchAccess,
        AuditView,
        MonitoringView,
    ];

    public static bool IsValidKey(string key) =>
        AllKeys.Contains(key, StringComparer.Ordinal);
}
