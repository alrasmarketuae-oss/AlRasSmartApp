using BusinessLayer.Helpers;
using DataLayer.Models;
using Microsoft.EntityFrameworkCore;

namespace BusinessLayer.Services.AiAssistant.Mcp;

public sealed partial class AiAssistantMcpToolsService
{
    private async Task<string> GetMyLastAdAsync(
        Guid? userId,
        CancellationToken cancellationToken) =>
        await GetMyExtremeAdAsync(userId, newestFirst: true, cancellationToken)
            .ConfigureAwait(false);

    private async Task<string> GetMyFirstAdAsync(
        Guid? userId,
        CancellationToken cancellationToken) =>
        await GetMyExtremeAdAsync(userId, newestFirst: false, cancellationToken)
            .ConfigureAwait(false);

    private async Task<string> GetMyExtremeAdAsync(
        Guid? userId,
        bool newestFirst,
        CancellationToken cancellationToken)
    {
        if (!userId.HasValue)
        {
            return Json(new
            {
                ok = false,
                error = "Sign in as a seller to view your ads."
            });
        }

        var ownerId = userId.Value;
        var which = newestFirst ? "last" : "first";

        var query =
            from p in dbContext.Products.AsNoTracking()
            join t in dbContext.ContentTranslations.AsNoTracking()
                    .Where(x =>
                        x.Scope == ContentTranslationScopes.Product &&
                        x.Field == ContentTranslationFields.Name)
                on p.ProductId equals t.ProductId into tj
            from t in tj.DefaultIfEmpty()
            join u in dbContext.Units.AsNoTracking() on p.UnitId equals u.Id into uj
            from u in uj.DefaultIfEmpty()
            join ru in dbContext.Units.AsNoTracking() on p.RetailUnitId equals ru.Id into ruj
            from ru in ruj.DefaultIfEmpty()
            where p.OwnerId == ownerId
            select new
            {
                p.ProductId,
                p.ProductCode,
                p.RetailCode,
                p.NameEn,
                NameAr = t != null ? t.TextAr : null,
                p.USDPrice,
                p.Quantity,
                UnitName = u != null ? u.UnitNameEn : null,
                p.RetailPrice,
                p.RetailQuantity,
                RetailUnitName = ru != null ? ru.UnitNameEn : null,
                p.CategoryId,
                p.ProductTypeId,
                p.RetailUnitId,
                p.Status,
                p.IsApproved,
                p.CreatedAt,
                p.UpdatedAt
            };

        var row = newestFirst
            ? await query
                .OrderByDescending(x => x.CreatedAt)
                .ThenByDescending(x => x.ProductId)
                .FirstOrDefaultAsync(cancellationToken)
                .ConfigureAwait(false)
            : await query
                .OrderBy(x => x.CreatedAt)
                .ThenBy(x => x.ProductId)
                .FirstOrDefaultAsync(cancellationToken)
                .ConfigureAwait(false);

        if (row is null)
        {
            return Json(new
            {
                ok = true,
                found = false,
                which,
                message = "No ads found on this account (لا توجد إعلانات)."
            });
        }

        var isHybrid = ProductTypeCodes.HasRetailStockConfigured(
            row.CategoryId,
            row.ProductTypeId,
            row.RetailPrice,
            row.RetailUnitId);
        var statusCode = ProductStatusCodes.Normalize(row.Status, row.IsApproved);
        var status = ProductStatusCodes.ToDisplayName(row.Status, row.IsApproved);
        var outOfStock = row.Quantity <= 0
            && (!isHybrid || row.RetailQuantity is null or <= 0);

        object ad;
        if (isHybrid)
        {
            ad = new
            {
                productId = row.ProductId,
                productCode = row.ProductCode,
                retailCode = row.RetailCode,
                productNameEn = row.NameEn,
                productNameAr = row.NameAr,
                productTypeId = row.ProductTypeId,
                isHybrid = true,
                status,
                statusCode,
                isApproved = row.IsApproved,
                outOfStock,
                wholesalePrice = row.USDPrice,
                wholesaleQuantity = row.Quantity,
                wholesaleUnitName = row.UnitName,
                retailPrice = row.RetailPrice,
                retailQuantity = row.RetailQuantity,
                retailUnitName = row.RetailUnitName,
                createdAtUtc = DateTime.SpecifyKind(row.CreatedAt, DateTimeKind.Utc),
                updatedAtUtc = row.UpdatedAt.HasValue
                    ? DateTime.SpecifyKind(row.UpdatedAt.Value, DateTimeKind.Utc)
                    : (DateTime?)null
            };
        }
        else
        {
            ad = new
            {
                productId = row.ProductId,
                productCode = row.ProductCode,
                productNameEn = row.NameEn,
                productNameAr = row.NameAr,
                productTypeId = row.ProductTypeId,
                isHybrid = false,
                status,
                statusCode,
                isApproved = row.IsApproved,
                outOfStock,
                price = row.USDPrice,
                quantity = row.Quantity,
                unitName = row.UnitName,
                createdAtUtc = DateTime.SpecifyKind(row.CreatedAt, DateTimeKind.Utc),
                updatedAtUtc = row.UpdatedAt.HasValue
                    ? DateTime.SpecifyKind(row.UpdatedAt.Value, DateTimeKind.Utc)
                    : (DateTime?)null
            };
        }

        return Json(new
        {
            ok = true,
            found = true,
            which,
            meaning = newestFirst
                ? "The seller's most recently created ad (آخر إعلان نزلته / نشرته / أضفته)."
                : "The seller's earliest created ad (أول إعلان نزلته / نشرته / أضفته).",
            ad,
            instruction = newestFirst
                ? "Summarize the LAST ad this seller posted: name (AR/EN), ProductCode, status, price/qty with unit, and created date. " +
                  "This is their listing, not a customer order. Do not invent prices. " +
                  "If isHybrid=false, report the single price only — never mention جملة/تجزئة/هجين."
                : "Summarize the FIRST ad this seller posted: name (AR/EN), ProductCode, status, price/qty with unit, and created date. " +
                  "This is their listing, not a customer order. Do not invent prices. " +
                  "If isHybrid=false, report the single price only — never mention جملة/تجزئة/هجين."
        });
    }
}
