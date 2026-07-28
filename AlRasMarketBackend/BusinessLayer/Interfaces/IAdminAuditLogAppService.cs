using System.Text.Json;

namespace BusinessLayer.Interfaces;

public interface IAdminAuditLogAppService
{
    Task WriteAsync(
        string action,
        string entityType,
        string? entityId,
        string summary,
        object? details = null,
        CancellationToken cancellationToken = default);

    Task<object> GetPagedAsync(
        int page,
        int pageSize,
        string? search,
        string? action,
        string? entityType,
        DateTime? fromUtc,
        DateTime? toUtc,
        CancellationToken cancellationToken = default);
}

public static class AdminAuditActions
{
    public const string CompanyApprove = "company.approve";
    public const string CompanyReject = "company.reject";
    public const string CompanyProfileApprove = "company.profile_approve";
    public const string CompanyProfileReject = "company.profile_reject";
    public const string ProductApprove = "product.approve";
    public const string ProductReject = "product.reject";
    public const string ProductUpdate = "product.update";
    public const string ProductDelete = "product.delete";
    public const string CategoryCreate = "category.create";
    public const string CategoryUpdate = "category.update";
    public const string CategoryDelete = "category.delete";
    public const string SettingsUpdate = "settings.update";
    public const string EmployeeCreate = "employee.create";
    public const string EmployeeUpdate = "employee.update";
    public const string EmployeeDelete = "employee.delete";
    public const string ShippingPostApprove = "shipping.post_approve";
    public const string ShippingPostReject = "shipping.post_reject";
    public const string ShippingProviderCreate = "shipping.provider_create";
    public const string ShippingProviderUpdate = "shipping.provider_update";
    public const string ShippingProviderDelete = "shipping.provider_delete";
    public const string ShippingProviderSetActive = "shipping.provider_set_active";
    public const string BannerCreate = "banner.create";
    public const string BannerUpdate = "banner.update";
    public const string BannerDelete = "banner.delete";
    public const string DomesticShippingUpdate = "shipping.domestic_rates_update";
    public const string OrderManage = "order.manage";
    public const string OrderStatusUpdate = "order.status_update";
    public const string OrderApproveOffer = "order.approve_offer";
    public const string OrderRejectOffer = "order.reject_offer";
    public const string OrderCustomStatus = "order.custom_status";
    public const string OrderMarkReceived = "order.mark_received";
    public const string OrderReturnApprove = "order.return_approve";
    public const string OrderReturnReject = "order.return_reject";
    public const string OrderRefund = "order.refund";
    public const string UserSetActive = "user.set_active";
    public const string NotificationSend = "notification.send";
    public const string FinanceWithdrawalPaid = "finance.withdrawal_paid";
}

public static class AdminAuditEntityTypes
{
    public const string Company = "Company";
    public const string Product = "Product";
    public const string Category = "Category";
    public const string Settings = "Settings";
    public const string Employee = "Employee";
    public const string Shipping = "Shipping";
    public const string Order = "Order";
    public const string User = "User";
    public const string Notification = "Notification";
    public const string Banner = "Banner";
    public const string WithdrawalRequest = "WithdrawalRequest";
}
