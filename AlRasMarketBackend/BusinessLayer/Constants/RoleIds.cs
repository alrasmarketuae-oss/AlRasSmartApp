namespace BusinessLayer.Constants;

public static class RoleIds
{
    public const byte Admin = 1;
    public const byte Seller = 2;
    public const byte Buyer = 3;
    public const byte Employee = 4;
    public const byte ShippingCompany = 5;

    public static bool IsShippingCompany(byte roleId) => roleId == ShippingCompany;

    /// <summary>In-memory checks only — do not use inside EF LINQ queries.</summary>
    public static bool RequiresAdminApproval(byte roleId) =>
        roleId is Seller or ShippingCompany;
}
