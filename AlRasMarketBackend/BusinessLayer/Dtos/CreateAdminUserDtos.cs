namespace BusinessLayer.Dtos;

/// <summary>
/// Admin-provisioned app users: same field shapes as public registration,
/// but verified/approved/active immediately with no email OTP.
/// </summary>
public sealed class CreateAdminUserRequest
{
    /// <summary>person | supplier | companyCustomer | shippingCompany</summary>
    public string AccountType { get; set; } = string.Empty;

    public string Email { get; set; } = string.Empty;
    public string Password { get; set; } = string.Empty;
    public string? PhoneNumber { get; set; }
    public string? PreferredLanguage { get; set; }

    /// <summary>Person full name, or company owner name.</summary>
    public string? FullName { get; set; }

    public string? CompanyName { get; set; }
    public string? LandNumber { get; set; }
    public string? LicenseNumber { get; set; }
    public string? CommercialRegister { get; set; }
    public string? TaxNumber { get; set; }
    public string? Website { get; set; }
    public string? LicencePath { get; set; }
    public string? ImgPath { get; set; }
    public List<string>? CompanyImagePaths { get; set; }
    public DateTime? BirthDate { get; set; }

    public RegisterCompanyAddressInput? Address { get; set; }
}

public sealed class CreateAdminUserResult
{
    public string UserId { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string AccountType { get; set; } = string.Empty;
    public string Message { get; set; } = string.Empty;
}

/// <summary>
/// Admin update of marketplace user profile fields. Password is optional
/// (leave empty to keep current). Account type / role is not changed here.
/// </summary>
public sealed class UpdateAdminUserRequest
{
    public string Email { get; set; } = string.Empty;
    /// <summary>Optional. When set, must be at least 6 characters.</summary>
    public string? Password { get; set; }
    public string? PhoneNumber { get; set; }
    public string? PreferredLanguage { get; set; }
    public string? FullName { get; set; }
    public string? CompanyName { get; set; }
    public string? LandNumber { get; set; }
    public string? LicenseNumber { get; set; }
    public string? CommercialRegister { get; set; }
    public string? TaxNumber { get; set; }
    public string? Website { get; set; }
}

public sealed class UpdateAdminUserResult
{
    public string UserId { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string Message { get; set; } = string.Empty;
}
