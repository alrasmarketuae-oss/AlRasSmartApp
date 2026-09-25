using System.Text.Json;
using BusinessLayer.Constants;
using BusinessLayer.Dtos;
using BusinessLayer.Interfaces;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;

namespace BusinessLayer.Services.AiAssistant.Mcp;

public sealed partial class AiAssistantMcpToolsService
{
    private const string DefaultSupplierPassword = "123456";

    private static object CreateSupplierFromBusinessCardsToolDefinition => new
    {
        type = "function",
        function = new
        {
            name = "create_supplier_from_business_cards",
            description =
                "ADMIN ONLY. Register a SUPPLIER company account from 1–2 uploaded business-card photos. " +
                "Use when the admin message contains [business_card_image_paths: …] or asks to create a supplier from a business card. " +
                "The tool OCRs the card(s), then creates the account as Seller (IsCustomer=false) with password 123456, " +
                "already verified, approved, and active — NO email OTP is sent. " +
                "Pass the R2 image paths exactly as tagged. Optional field overrides if the admin corrected a value.",
            parameters = new
            {
                type = "object",
                properties = new
                {
                    image_paths = new
                    {
                        type = "array",
                        items = new { type = "string" },
                        description =
                            "1–2 R2 draft/image paths from [business_card_image_paths: path1 | path2]."
                    },
                    company_name = new
                    {
                        type = "string",
                        description =
                            "Optional override for company name. MUST be English (Latin letters) only — never Arabic script."
                    },
                    email = new { type = "string", description = "Optional email override." },
                    phone_number = new { type = "string", description = "Optional mobile override." },
                    land_number = new { type = "string", description = "Optional landline override." },
                    website = new { type = "string", description = "Optional website override." },
                    address_line1 = new { type = "string", description = "Optional full address override." },
                    preferred_language = new
                    {
                        type = "string",
                        description = "en or ar. Defaults to en."
                    },
                    password = new
                    {
                        type = "string",
                        description = "Defaults to 123456. Only change if the admin explicitly asked."
                    }
                },
                required = new[] { "image_paths" },
                additionalProperties = false
            }
        }
    };

    private async Task<string> CreateSupplierFromBusinessCardsAsync(
        Guid? userId,
        string argumentsJson,
        CancellationToken cancellationToken)
    {
        if (!userId.HasValue)
        {
            return Json(new { ok = false, error = "Sign in as admin to create suppliers from business cards." });
        }

        var roleId = await dbContext.Users
            .AsNoTracking()
            .Where(x => x.Id == userId.Value)
            .Select(x => (byte?)x.RoleId)
            .FirstOrDefaultAsync(cancellationToken)
            .ConfigureAwait(false);

        if (roleId != RoleIds.Admin)
        {
            return Json(new
            {
                ok = false,
                error = "Only platform admin accounts can create suppliers from business cards."
            });
        }

        using var args = JsonDocument.Parse(string.IsNullOrWhiteSpace(argumentsJson) ? "{}" : argumentsJson);
        var root = args.RootElement;
        var imagePaths = (GetStringList(root, "image_paths") ?? [])
            .Where(p => !string.IsNullOrWhiteSpace(p))
            .Select(p => p.Trim())
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .Take(2)
            .ToList();

        if (imagePaths.Count == 0)
        {
            return Json(new
            {
                ok = false,
                error = "image_paths is required (1–2 uploaded business-card paths)."
            });
        }

        using var scope = scopeFactory.CreateScope();
        var fileStorage = scope.ServiceProvider.GetRequiredService<IFileStorage>();
        var vision = scope.ServiceProvider.GetRequiredService<IOpenAiVisionService>();
        var adminUsers = scope.ServiceProvider.GetRequiredService<IAdminUsersAppService>();

        var opened = new List<(Stream Stream, string FileName)>();
        try
        {
            foreach (var path in imagePaths)
            {
                var stream = await fileStorage.OpenReadAsync(path, cancellationToken).ConfigureAwait(false);
                if (stream is null)
                {
                    return Json(new
                    {
                        ok = false,
                        error = $"Could not read image path: {path}"
                    });
                }

                opened.Add((stream, Path.GetFileName(path)));
            }

            var extracted = await vision
                .ExtractBusinessCardAsync(opened, cancellationToken)
                .ConfigureAwait(false);

            if (extracted.ExtractionFailed)
            {
                return Json(new
                {
                    ok = false,
                    error = "Could not read the business card images.",
                    reason = extracted.FailureReason
                });
            }

            var companyName = FirstNonEmpty(GetString(root, "company_name"), extracted.CompanyName);
            companyName = EnsureEnglishCompanyName(companyName);
            var email = FirstNonEmpty(GetString(root, "email"), extracted.Email);
            var phone = FirstNonEmpty(GetString(root, "phone_number"), extracted.PhoneNumber);
            var land = FirstNonEmpty(GetString(root, "land_number"), extracted.LandNumber);
            var website = FirstNonEmpty(GetString(root, "website"), extracted.Website);
            var addressLine1 = FirstNonEmpty(GetString(root, "address_line1"), extracted.AddressLine1);
            var preferredLanguage = FirstNonEmpty(GetString(root, "preferred_language"), "en");
            var password = FirstNonEmpty(GetString(root, "password"), DefaultSupplierPassword)
                           ?? DefaultSupplierPassword;

            if (string.IsNullOrWhiteSpace(companyName))
            {
                return Json(new
                {
                    ok = false,
                    needs_clarification = true,
                    error =
                        "Company name must be in English (Latin letters). " +
                        "Ask the admin for the English company name, then call again with company_name.",
                    extracted = new
                    {
                        companyName = (string?)null,
                        email,
                        phoneNumber = phone,
                        landNumber = land,
                        website,
                        addressLine1
                    }
                });
            }

            if (string.IsNullOrWhiteSpace(email))
            {
                return Json(new
                {
                    ok = false,
                    needs_clarification = true,
                    error = "Could not read email from the card. Ask the admin for the supplier email.",
                    extracted = new
                    {
                        companyName,
                        email,
                        phoneNumber = phone,
                        landNumber = land,
                        website,
                        addressLine1
                    }
                });
            }

            // Business cards usually only have company + phones + address + email + website.
            // Everything else stays null.
            RegisterCompanyAddressInput? address = null;
            if (!string.IsNullOrWhiteSpace(addressLine1))
            {
                address = new RegisterCompanyAddressInput
                {
                    AddressLine1 = addressLine1,
                    MobileNumber = phone
                };
            }

            try
            {
                var result = await adminUsers.CreateUserAsync(
                    new CreateAdminUserRequest
                    {
                        AccountType = "supplier",
                        Email = email!,
                        Password = password,
                        PhoneNumber = phone,
                        PreferredLanguage = preferredLanguage,
                        FullName = null,
                        CompanyName = companyName,
                        LandNumber = land,
                        Website = website,
                        CompanyImagePaths = imagePaths,
                        Address = address
                    },
                    cancellationToken).ConfigureAwait(false);

                return Json(new
                {
                    ok = true,
                    accountType = "supplier",
                    isCustomer = false,
                    role = "Seller",
                    passwordUsed = password,
                    otpSent = false,
                    verified = true,
                    approved = true,
                    active = true,
                    extracted = new
                    {
                        companyName,
                        email,
                        phoneNumber = phone,
                        landNumber = land,
                        website,
                        addressLine1,
                        fullName = (string?)null,
                        cityName = (string?)null,
                        area = (string?)null,
                        street = (string?)null,
                        building = (string?)null,
                        postalCode = (string?)null,
                        latitude = (decimal?)null,
                        longitude = (decimal?)null
                    },
                    result
                });
            }
            catch (ArgumentException ex)
            {
                return Json(new { ok = false, error = ex.Message, extracted });
            }
            catch (InvalidOperationException ex)
            {
                return Json(new { ok = false, error = ex.Message, conflict = true, extracted });
            }
        }
        finally
        {
            foreach (var (stream, _) in opened)
            {
                await stream.DisposeAsync().ConfigureAwait(false);
            }
        }
    }

    private static string? FirstNonEmpty(params string?[] values) =>
        values.FirstOrDefault(x => !string.IsNullOrWhiteSpace(x))?.Trim();

    /// <summary>
    /// Company name must be English. If OCR returned Arabic-only text, reject it
    /// so the model asks the admin (or retries with an English override).
    /// </summary>
    private static string? EnsureEnglishCompanyName(string? name)
    {
        if (string.IsNullOrWhiteSpace(name)) return null;
        var trimmed = name.Trim();
        // Arabic / Arabic Supplement / Presentation Forms
        if (trimmed.Any(c => c is >= '\u0600' and <= '\u06FF'
            or >= '\u0750' and <= '\u077F'
            or >= '\uFB50' and <= '\uFDFF'
            or >= '\uFE70' and <= '\uFEFF'))
        {
            return null;
        }

        return trimmed;
    }
}
