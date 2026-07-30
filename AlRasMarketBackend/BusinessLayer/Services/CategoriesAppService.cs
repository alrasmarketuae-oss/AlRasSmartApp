using BusinessLayer.Caching;
using BusinessLayer.Constants;
using BusinessLayer.Dtos;
using BusinessLayer.Helpers;
using BusinessLayer.Interfaces;
using DataLayer.Interfaces;
using DataLayer.Seeding;
using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;

namespace BusinessLayer.Services;

public class CategoriesAppService(
    IRasAlSouqDbContext dbContext,
    IMemoryCache cache,
    IAdminPermissionService permissionService,
    IAdminAuditLogAppService auditLogAppService,
    IMediaStorageService mediaStorage,
    IStaticReferenceCache staticReferenceCache) : ICategoriesAppService
{
    private const string PublicCategoriesCacheKeyPrefix = "categories:public";
    private const string AdminCategoriesCacheKeyPrefix = "categories:admin";

    private void BustCategoryCaches()
    {
        CategoriesListCache.Bump();
        staticReferenceCache.InvalidateCategories();
    }

    public async Task<object> GetAllAsync(CancellationToken cancellationToken = default)
    {
        var cacheKey = $"{PublicCategoriesCacheKeyPrefix}:v{CategoriesListCache.Version}";
        if (cache.TryGetValue(cacheKey, out object? cached) && cached is not null)
        {
            return cached;
        }

        var items = await LoadCategoryItemsAsync(includeHidden: false, cancellationToken);
        var result = new { count = items.Count, items };
        cache.Set(cacheKey, result, TimeSpan.FromMinutes(2));
        return result;
    }

    public async Task<object> GetAllForAdminAsync(string userId, CancellationToken cancellationToken = default)
    {
        await ValidateAdminAsync(userId, cancellationToken);

        var cacheKey = $"{AdminCategoriesCacheKeyPrefix}:v{CategoriesListCache.Version}";
        if (cache.TryGetValue(cacheKey, out object? cached) && cached is not null)
        {
            return cached;
        }

        var items = await LoadCategoryItemsAsync(includeHidden: true, cancellationToken);
        var result = new { count = items.Count, items };
        cache.Set(cacheKey, result, TimeSpan.FromMinutes(2));
        return result;
    }

    public async Task<object> CreateAsync(CreateCategoryInput input, CancellationToken cancellationToken = default)
    {
        var user = await ValidateAdminAsync(input.UserId, cancellationToken);

        if (string.IsNullOrWhiteSpace(input.NameEn))
        {
            throw new ArgumentException("NameEn is required.");
        }

        if (string.IsNullOrWhiteSpace(input.NameAr))
        {
            throw new ArgumentException("NameAr is required.");
        }

        var name = input.NameEn.Trim();
        var nameAr = input.NameAr.Trim();
        var exists = await dbContext.Categories.AnyAsync(x => x.NameEn.ToLower() == name.ToLower(), cancellationToken);
        if (exists)
        {
            throw new InvalidOperationException($"Category '{name}' already exists.");
        }

        var entity = new DataLayer.Models.Category
        {
            NameEn = name,
            NameAr = nameAr,
            ImgPath = string.IsNullOrWhiteSpace(input.ImgPath) ? "/images/categories/default.jpg" : input.ImgPath.Trim()
        };

        await dbContext.Categories.AddAsync(entity, cancellationToken);
        await dbContext.SaveChangesAsync(cancellationToken);
        BustCategoryCaches();

        await auditLogAppService.WriteAsync(
            AdminAuditActions.CategoryCreate,
            AdminAuditEntityTypes.Category,
            entity.CategoryId.ToString(),
            $"Created category '{entity.NameEn}'",
            new { nameEn = entity.NameEn, nameAr = entity.NameAr },
            cancellationToken);

        return MapCategory(entity, user.Id);
    }

    public async Task<object> UpdateAsync(UpdateCategoryInput input, CancellationToken cancellationToken = default)
    {
        await ValidateAdminAsync(input.UserId, cancellationToken);

        var category = await dbContext.Categories.FirstOrDefaultAsync(x => x.CategoryId == input.CategoryId, cancellationToken)
            ?? throw new KeyNotFoundException("Category not found.");

        if (string.IsNullOrWhiteSpace(input.NameEn))
        {
            throw new ArgumentException("NameEn is required.");
        }

        if (string.IsNullOrWhiteSpace(input.NameAr))
        {
            throw new ArgumentException("NameAr is required.");
        }

        var name = input.NameEn.Trim();
        var nameAr = input.NameAr.Trim();
        var duplicate = await dbContext.Categories.AnyAsync(
            x => x.CategoryId != input.CategoryId && x.NameEn.ToLower() == name.ToLower(), cancellationToken);
        if (duplicate)
        {
            throw new InvalidOperationException($"Category '{name}' already exists.");
        }

        var oldNameEn = category.NameEn;
        var oldNameAr = category.NameAr;
        category.NameEn = name;
        category.NameAr = nameAr;
        if (!string.IsNullOrWhiteSpace(input.ImgPath))
        {
            category.ImgPath = input.ImgPath.Trim();
        }

        await dbContext.SaveChangesAsync(cancellationToken);
        BustCategoryCaches();
        ProductsAppService.InvalidateProductListCaches();

        await auditLogAppService.WriteAsync(
            AdminAuditActions.CategoryUpdate,
            AdminAuditEntityTypes.Category,
            category.CategoryId.ToString(),
            $"Updated category '{name}'",
            new
            {
                oldNameEn,
                oldNameAr,
                newNameEn = name,
                newNameAr = nameAr
            },
            cancellationToken);

        return MapCategory(category);
    }

    public async Task<object> SetHideAsync(SetCategoryHideInput input, CancellationToken cancellationToken = default)
    {
        await ValidateAdminAsync(input.UserId, cancellationToken);

        var category = await dbContext.Categories.FirstOrDefaultAsync(x => x.CategoryId == input.CategoryId, cancellationToken)
            ?? throw new KeyNotFoundException("Category not found.");

        category.IsHide = input.IsHide;
        await dbContext.SaveChangesAsync(cancellationToken);
        BustCategoryCaches();
        ProductsAppService.InvalidateProductListCaches();

        await auditLogAppService.WriteAsync(
            AdminAuditActions.CategoryUpdate,
            AdminAuditEntityTypes.Category,
            category.CategoryId.ToString(),
            input.IsHide
                ? $"Hid category '{category.NameEn}'"
                : $"Showed category '{category.NameEn}'",
            new { isHide = input.IsHide, nameEn = category.NameEn },
            cancellationToken);

        return MapCategory(category);
    }

    public async Task<object> UploadImageAsync(UploadCategoryImageInput input, CancellationToken cancellationToken = default)
    {
        await ValidateAdminAsync(input.UserId, cancellationToken);

        if (input.File is null || input.File.Length == 0)
        {
            throw new ArgumentException("File is required.");
        }

        var category = await dbContext.Categories.FirstOrDefaultAsync(x => x.CategoryId == input.CategoryId, cancellationToken)
            ?? throw new KeyNotFoundException("Category not found.");

        // Unique file name so browsers/CDNs do not keep serving a cached previous image.
        var fileName = $"category-{category.CategoryId}-{DateTime.UtcNow:yyyyMMddHHmmssfff}.jpg";
        var previousPath = category.ImgPath;

        category.ImgPath = await mediaStorage.SaveCompressedJpegAsync(
            input.File,
            "images/categories",
            fileName,
            cancellationToken: cancellationToken);
        await dbContext.SaveChangesAsync(cancellationToken);
        BustCategoryCaches();

        await mediaStorage.DeleteAsync(previousPath, cancellationToken);

        return MapCategory(category);
    }

    public async Task<object> DeleteAsync(DeleteCategoryInput input, CancellationToken cancellationToken = default)
    {
        await ValidateAdminAsync(input.UserId, cancellationToken);

        var category = await dbContext.Categories.FirstOrDefaultAsync(x => x.CategoryId == input.CategoryId, cancellationToken)
            ?? throw new KeyNotFoundException("Category not found.");

        // Unlink products so the category row can be removed permanently.
        var linkedProducts = await dbContext.Products
            .Where(x => x.CategoryId == input.CategoryId)
            .ToListAsync(cancellationToken);
        foreach (var product in linkedProducts)
        {
            product.CategoryId = null;
        }

        var imagePath = category.ImgPath;
        var categoryName = category.NameEn;
        var categoryId = category.CategoryId;
        dbContext.Categories.Remove(category);
        await dbContext.SaveChangesAsync(cancellationToken);
        BustCategoryCaches();
        ProductsAppService.InvalidateProductListCaches();

        await mediaStorage.DeleteAsync(imagePath, cancellationToken);

        await auditLogAppService.WriteAsync(
            AdminAuditActions.CategoryDelete,
            AdminAuditEntityTypes.Category,
            categoryId.ToString(),
            $"Deleted category '{categoryName}'",
            new { nameEn = categoryName },
            cancellationToken);

        return new { message = "Category deleted successfully.", CategoryId = categoryId };
    }

    private async Task<DataLayer.Models.User> ValidateAdminAsync(string userId, CancellationToken cancellationToken)
    {
        if (!Guid.TryParse(userId, out var userGuid))
        {
            throw new ArgumentException("Invalid user id.");
        }

        var user = await dbContext.Users.FindAsync([userGuid], cancellationToken)
            ?? throw new KeyNotFoundException("User not found.");

        if (permissionService.IsSuperAdmin(user.RoleId))
        {
            return user;
        }

        if (await permissionService.HasPermissionAsync(
                user.Id,
                user.RoleId,
                AdminPermissions.CategoriesManage,
                cancellationToken))
        {
            return user;
        }

        throw new UnauthorizedAccessException("Only admin can manage categories.");
    }

    private async Task<List<object>> LoadCategoryItemsAsync(bool includeHidden, CancellationToken cancellationToken)
    {
        var canonicalOrder = CanonicalCategories.Seed.Select(c => c.NameEn).ToList();
        var query = dbContext.Categories.AsNoTracking();
        if (!includeHidden)
        {
            query = query.Where(x => !x.IsHide);
        }

        var rows = await query
            .Select(x => new
            {
                x.CategoryId,
                x.NameEn,
                x.NameAr,
                ImgPath = x.ImgPath,
                x.CommissionPercent,
                x.IsHide
            })
            .ToListAsync(cancellationToken);

        return rows
            .OrderBy(x =>
            {
                var i = canonicalOrder.IndexOf(x.NameEn);
                return i >= 0 ? i : 1000 + x.CategoryId;
            })
            .Select(x => (object)new
            {
                x.CategoryId,
                x.NameEn,
                x.NameAr,
                ImgPath = NormalizeCategoryImgPath(x.ImgPath),
                x.CommissionPercent,
                x.IsHide
            })
            .ToList();
    }

    private static object MapCategory(DataLayer.Models.Category category, Guid? byUserId = null)
    {
        if (byUserId.HasValue)
        {
            return new
            {
                category.CategoryId,
                category.NameEn,
                category.NameAr,
                ImgPath = NormalizeCategoryImgPath(category.ImgPath),
                category.CommissionPercent,
                category.IsHide,
                byUserId = byUserId.Value
            };
        }

        return new
        {
            category.CategoryId,
            category.NameEn,
            category.NameAr,
            ImgPath = NormalizeCategoryImgPath(category.ImgPath),
            category.CommissionPercent,
            category.IsHide
        };
    }

    private static string NormalizeCategoryImgPath(string? path)
    {
        var normalized = WebRootFileHelper.NormalizeStoredPath(path);
        return string.IsNullOrWhiteSpace(normalized)
            ? "/images/categories/default.jpg"
            : normalized;
    }
}
