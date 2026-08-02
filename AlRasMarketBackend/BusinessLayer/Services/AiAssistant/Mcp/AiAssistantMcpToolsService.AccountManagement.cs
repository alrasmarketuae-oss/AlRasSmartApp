using System.Text.Json;
using BusinessLayer.Dtos;
using BusinessLayer.Helpers;
using BusinessLayer.Interfaces;
using BusinessLayer.Services;
using DataLayer.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;

namespace BusinessLayer.Services.AiAssistant.Mcp;

public sealed partial class AiAssistantMcpToolsService
{
    private async Task<string> SetAdListingStatusAsync(
        Guid? userId,
        string argumentsJson,
        CancellationToken cancellationToken)
    {
        if (!userId.HasValue)
        {
            return Json(new { ok = false, error = "Sign in as the ad owner to pause or activate listings." });
        }

        using var args = JsonDocument.Parse(string.IsNullOrWhiteSpace(argumentsJson) ? "{}" : argumentsJson);
        var root = args.RootElement;
        var action = (GetString(root, "action") ?? "").Trim().ToLowerInvariant();
        var isActive = action is "active" or "activate" or "resume" or "unpause";
        var isPause = action is "pause" or "paused";
        if (!isActive && !isPause)
        {
            return Json(new { ok = false, error = "action must be \"pause\" or \"active\"." });
        }

        var resolved = await ResolveOwnedAdAsync(
                userId.Value,
                GetString(root, "product_code"),
                GetString(root, "product_name"),
                cancellationToken)
            .ConfigureAwait(false);
        if (resolved.ErrorJson is not null) return resolved.ErrorJson;

        try
        {
            await using var scope = scopeFactory.CreateAsyncScope();
            var products = scope.ServiceProvider.GetRequiredService<IProductsAppService>();
            var result = await products.SetListingStatusAsync(
                    new SetProductListingStatusInput
                    {
                        ProductId = resolved.ProductId.ToString("D"),
                        OwnerId = userId.Value.ToString("D"),
                        IsActive = isActive
                    },
                    cancellationToken)
                .ConfigureAwait(false);

            return Json(new
            {
                ok = true,
                action = isActive ? "active" : "pause",
                productId = resolved.ProductId,
                productCode = resolved.ProductCode,
                nameEn = resolved.NameEn,
                result
            });
        }
        catch (Exception ex)
        {
            return Json(new { ok = false, error = ex.Message });
        }
    }

    private async Task<string> MarkAdSoldOutAsync(
        Guid? userId,
        string argumentsJson,
        CancellationToken cancellationToken)
    {
        if (!userId.HasValue)
        {
            return Json(new { ok = false, error = "Sign in as the ad owner to mark sold out." });
        }

        using var args = JsonDocument.Parse(string.IsNullOrWhiteSpace(argumentsJson) ? "{}" : argumentsJson);
        var root = args.RootElement;
        var productName = GetString(root, "product_name");
        var productCode = GetString(root, "product_code");
        var channel = NormalizeUpdateChannel(GetString(root, "channel"))
                      ?? InferUpdateChannelFromText(productName);

        var resolved = await ResolveOwnedAdAsync(
                userId.Value, productCode, productName, cancellationToken)
            .ConfigureAwait(false);
        if (resolved.ErrorJson is not null) return resolved.ErrorJson;

        var product = await dbContext.Products
            .Include(p => p.Unit)
            .Include(p => p.RetailUnit)
            .FirstAsync(p => p.ProductId == resolved.ProductId, cancellationToken)
            .ConfigureAwait(false);

        if (!string.IsNullOrWhiteSpace(productCode))
        {
            channel ??= InferChannelFromProductCode(product, productCode.Trim());
        }

        var isHybrid = ProductTypeCodes.HasRetailStockConfigured(product);
        if (isHybrid && channel is null)
        {
            return Json(new
            {
                ok = false,
                needs_channel_clarification = true,
                productCode = product.ProductCode,
                retailCode = product.RetailCode,
                nameEn = product.NameEn,
                wholesaleQuantity = product.Quantity,
                retailQuantity = product.RetailQuantity,
                message =
                    "Hybrid ad. Ask: جملة ولا تجزئة؟ Then call mark_ad_sold_out again with channel=wholesale or channel=retail."
            });
        }

        channel ??= "wholesale";
        if (channel == "retail")
        {
            if (!isHybrid)
            {
                return Json(new { ok = false, error = "This ad has no retail channel." });
            }

            var before = product.RetailQuantity;
            if (before is null or <= 0)
            {
                return Json(new
                {
                    ok = true,
                    channel = "retail",
                    productCode = product.RetailCode ?? product.ProductCode,
                    quantity = product.RetailQuantity ?? 0,
                    message = "Retail channel is already sold out."
                });
            }

            product.RetailQuantity = 0;
            product.UpdatedAt = DateTime.UtcNow;
            await dbContext.SaveChangesAsync(cancellationToken).ConfigureAwait(false);
            ProductsAppService.InvalidateProductListCaches(product.OwnerId);
            productCacheVersions.BumpDetail();
            QueueTextSearchSync(product.ProductId);

            return Json(new
            {
                ok = true,
                channel = "retail",
                productCode = product.RetailCode ?? product.ProductCode,
                previousQuantity = before,
                quantity = 0,
                unitName = product.RetailUnit?.UnitNameEn,
                message = "Retail channel marked sold out. Wholesale quantity was NOT changed."
            });
        }

        try
        {
            await using var scope = scopeFactory.CreateAsyncScope();
            var products = scope.ServiceProvider.GetRequiredService<IProductsAppService>();
            var result = await products.MarkSoldOutAsync(
                    product.ProductId.ToString("D"),
                    userId.Value.ToString("D"),
                    cancellationToken)
                .ConfigureAwait(false);

            return Json(new
            {
                ok = true,
                channel = "wholesale",
                productCode = product.ProductCode,
                retailCode = product.RetailCode,
                result,
                message = isHybrid
                    ? "Wholesale channel marked sold out. Retail quantity was NOT changed."
                    : "Listing marked as sold out."
            });
        }
        catch (Exception ex)
        {
            return Json(new { ok = false, error = ex.Message });
        }
    }

    private async Task<string> DeleteAdAsync(
        Guid? userId,
        string argumentsJson,
        CancellationToken cancellationToken)
    {
        if (!userId.HasValue)
        {
            return Json(new { ok = false, error = "Sign in as the ad owner to delete listings." });
        }

        using var args = JsonDocument.Parse(string.IsNullOrWhiteSpace(argumentsJson) ? "{}" : argumentsJson);
        var root = args.RootElement;
        var confirm = GetBool(root, "confirm") == true;

        var resolved = await ResolveOwnedAdAsync(
                userId.Value,
                GetString(root, "product_code"),
                GetString(root, "product_name"),
                cancellationToken)
            .ConfigureAwait(false);
        if (resolved.ErrorJson is not null) return resolved.ErrorJson;

        if (!confirm)
        {
            return Json(new
            {
                ok = false,
                needs_confirmation = true,
                productId = resolved.ProductId,
                productCode = resolved.ProductCode,
                retailCode = resolved.RetailCode,
                nameEn = resolved.NameEn,
                nameAr = resolved.NameAr,
                message =
                    "Deletion is permanent. Ask the user to confirm clearly. " +
                    "Only after they agree, call delete_ad again with the same product_code/name and confirm=true."
            });
        }

        try
        {
            await using var scope = scopeFactory.CreateAsyncScope();
            var products = scope.ServiceProvider.GetRequiredService<IProductsAppService>();
            var result = await products.DeleteAsync(
                    new DeleteProductInput
                    {
                        ProductId = resolved.ProductId.ToString("D"),
                        UserId = userId.Value.ToString("D"),
                        AllowAdminDelete = false
                    },
                    cancellationToken)
                .ConfigureAwait(false);

            return Json(new
            {
                ok = true,
                deleted = true,
                productId = resolved.ProductId,
                productCode = resolved.ProductCode,
                nameEn = resolved.NameEn,
                result
            });
        }
        catch (Exception ex)
        {
            return Json(new { ok = false, error = ex.Message });
        }
    }

    private async Task<string> ListMyIbansAsync(Guid? userId, CancellationToken cancellationToken)
    {
        if (!userId.HasValue)
        {
            return Json(new { ok = false, error = "Sign in as a seller to view IBANs and balance." });
        }

        try
        {
            await using var scope = scopeFactory.CreateAsyncScope();
            var balanceApp = scope.ServiceProvider.GetRequiredService<ISupplierBalanceService>();

            var balance = await balanceApp.GetBalanceAsync(userId.Value, cancellationToken)
                .ConfigureAwait(false);

            var pendingTotal = await dbContext.WithdrawalRequests.AsNoTracking()
                .Where(x =>
                    x.UserId == userId.Value
                    && x.StatusId == WithdrawalRequestStatusCodes.Pending)
                .SumAsync(x => (decimal?)x.Amount, cancellationToken)
                .ConfigureAwait(false) ?? 0m;

            var available = balance - pendingTotal;

            var ibanRows = await dbContext.UserIbans.AsNoTracking()
                .Where(x => x.UserId == userId.Value)
                .OrderByDescending(x => x.IsDefault)
                .ThenByDescending(x => x.CreatedAtUtc)
                .Select(x => new
                {
                    x.Id,
                    x.Iban,
                    x.AccountHolderName,
                    x.BankName,
                    x.IsDefault
                })
                .ToListAsync(cancellationToken)
                .ConfigureAwait(false);

            var items = ibanRows
                .Select((x, i) => (object)new
                {
                    choice = i + 1,
                    userIbanId = x.Id,
                    iban = x.Iban,
                    accountHolderName = x.AccountHolderName,
                    bankName = x.BankName,
                    isDefault = x.IsDefault
                })
                .ToList();

            return Json(new
            {
                ok = true,
                balance,
                pendingWithdrawals = pendingTotal,
                availableBalance = available,
                ibanCount = items.Count,
                ibans = items,
                instruction =
                    items.Count == 0
                        ? "No saved IBANs. Tell the seller to add an IBAN from the Balance page before withdrawing."
                        : "Show the numbered IBANs and availableBalance. Ask which number to use (1, 2, 3…). " +
                          "If they want a different IBAN, tell them to add it from the Balance page."
            });
        }
        catch (Exception ex)
        {
            return Json(new { ok = false, error = ex.Message });
        }
    }

    private async Task<string> CreateWithdrawalAsync(
        Guid? userId,
        string argumentsJson,
        CancellationToken cancellationToken)
    {
        if (!userId.HasValue)
        {
            return Json(new { ok = false, error = "Sign in as a seller to create a withdrawal." });
        }

        using var args = JsonDocument.Parse(string.IsNullOrWhiteSpace(argumentsJson) ? "{}" : argumentsJson);
        var root = args.RootElement;
        var amount = GetDecimal(root, "amount");
        if (amount is null or <= 0)
        {
            return Json(new { ok = false, error = "amount must be greater than zero." });
        }

        Guid? userIbanId = null;
        var ibanIdRaw = GetString(root, "user_iban_id");
        if (!string.IsNullOrWhiteSpace(ibanIdRaw) && Guid.TryParse(ibanIdRaw, out var parsedIban))
        {
            userIbanId = parsedIban;
        }

        var choice = GetLong(root, "iban_choice");
        if (!userIbanId.HasValue)
        {
            if (choice is null or < 1)
            {
                return Json(new
                {
                    ok = false,
                    needs_iban_choice = true,
                    error =
                        "Call list_my_ibans first, then ask the seller to pick IBAN number 1, 2, or 3 " +
                        "(or say they want a different IBAN via the Balance page)."
                });
            }

            var ibans = await dbContext.UserIbans.AsNoTracking()
                .Where(x => x.UserId == userId.Value)
                .OrderByDescending(x => x.IsDefault)
                .ThenByDescending(x => x.CreatedAtUtc)
                .Select(x => x.Id)
                .ToListAsync(cancellationToken)
                .ConfigureAwait(false);

            if (choice.Value > ibans.Count)
            {
                return Json(new
                {
                    ok = false,
                    error = $"iban_choice {choice.Value} is out of range. You have {ibans.Count} saved IBAN(s)."
                });
            }

            userIbanId = ibans[(int)choice.Value - 1];
        }

        try
        {
            await using var scope = scopeFactory.CreateAsyncScope();
            var withdrawals = scope.ServiceProvider.GetRequiredService<IWithdrawalRequestsAppService>();
            var result = await withdrawals.CreateMyWithdrawalRequestAsync(
                    userId.Value.ToString("D"),
                    new CreateWithdrawalRequestInput
                    {
                        UserIbanId = userIbanId.Value,
                        Amount = amount.Value,
                        Notes = GetString(root, "notes")
                    },
                    cancellationToken)
                .ConfigureAwait(false);

            return Json(new
            {
                ok = true,
                amount = amount.Value,
                userIbanId,
                ibanChoice = choice,
                result,
                message = "Withdrawal request created and is pending admin review."
            });
        }
        catch (Exception ex)
        {
            return Json(new { ok = false, error = ex.Message });
        }
    }

    private async Task<OwnedAdResolution> ResolveOwnedAdAsync(
        Guid ownerId,
        string? productCode,
        string? productName,
        CancellationToken cancellationToken)
    {
        if (!string.IsNullOrWhiteSpace(productCode))
        {
            var code = productCode.Trim();
            var product = await dbContext.Products.AsNoTracking()
                .Where(p => p.OwnerId == ownerId)
                .Where(p =>
                    (p.ProductCode != null && p.ProductCode.ToLower() == code.ToLower())
                    || (p.RetailCode != null && p.RetailCode.ToLower() == code.ToLower()))
                .Select(p => new
                {
                    p.ProductId,
                    p.ProductCode,
                    p.RetailCode,
                    p.NameEn
                })
                .FirstOrDefaultAsync(cancellationToken)
                .ConfigureAwait(false);

            if (product is null)
            {
                return OwnedAdResolution.Fail(Json(new
                {
                    ok = false,
                    error = $"No ad with code '{code}' was found on your account."
                }));
            }

            return OwnedAdResolution.Ok(
                product.ProductId,
                product.ProductCode,
                product.RetailCode,
                product.NameEn,
                null);
        }

        if (string.IsNullOrWhiteSpace(productName))
        {
            return OwnedAdResolution.Fail(Json(new
            {
                ok = false,
                error = "Provide product_code or product_name."
            }));
        }

        if (LooksLikeBulkUpdateRequest(productName))
        {
            return OwnedAdResolution.Fail(Json(new
            {
                ok = false,
                blocked_bulk_update = true,
                error = "Bulk actions are not allowed. Name one specific ad."
            }));
        }

        var candidates = await LoadOwnerNameCandidatesAsync(ownerId, cancellationToken)
            .ConfigureAwait(false);
        var ranked = RankOwnerAdsByName(productName, candidates);
        if (ranked.Count == 0)
        {
            return OwnedAdResolution.Fail(Json(new
            {
                ok = false,
                needs_clarification = true,
                error = $"No ads named like '{productName.Trim()}' were found.",
                suggestions = candidates.OrderBy(x => x.NameEn).Take(20).Select(ToAdSuggestion).ToList()
            }));
        }

        var best = ranked[0];
        var secondScore = ranked.Count > 1 ? ranked[1].Score : 0;
        var uniqueStrong = best.Score >= 85
                           && (ranked.Count == 1 || best.Score - secondScore >= 12);
        if (uniqueStrong)
        {
            var peers = ranked.Where(x => x.Score == best.Score).ToList();
            if (peers.Count == 1)
            {
                return OwnedAdResolution.Ok(
                    best.ProductId,
                    best.ProductCode,
                    null,
                    best.NameEn,
                    best.NameAr);
            }
        }

        return OwnedAdResolution.Fail(Json(new
        {
            ok = false,
            needs_clarification = true,
            message =
                "Ask which ad they meant. When they pick one, call again with product_code or exact product_name.",
            suggestions = ranked.Take(5).Select(ToAdSuggestion).ToList()
        }));
    }

    private static bool? GetBool(JsonElement root, string name)
    {
        if (!root.TryGetProperty(name, out var el)) return null;
        return el.ValueKind switch
        {
            JsonValueKind.True => true,
            JsonValueKind.False => false,
            JsonValueKind.String when bool.TryParse(el.GetString(), out var b) => b,
            _ => null
        };
    }

    private sealed record OwnedAdResolution(
        Guid ProductId,
        string? ProductCode,
        string? RetailCode,
        string? NameEn,
        string? NameAr,
        string? ErrorJson)
    {
        public static OwnedAdResolution Ok(
            Guid id, string? code, string? retailCode, string? nameEn, string? nameAr) =>
            new(id, code, retailCode, nameEn, nameAr, null);

        public static OwnedAdResolution Fail(string errorJson) =>
            new(Guid.Empty, null, null, null, null, errorJson);
    }
}
