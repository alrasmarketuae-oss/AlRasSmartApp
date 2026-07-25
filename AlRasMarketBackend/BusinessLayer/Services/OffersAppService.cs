using BusinessLayer.Dtos;
using BusinessLayer.Helpers;
using BusinessLayer.Interfaces;
using DataLayer.Interfaces;
using DataLayer.Models;
using Microsoft.EntityFrameworkCore;

namespace BusinessLayer.Services;

public class OffersAppService(
    IRasAlSouqDbContext dbContext,
    IStaticReferenceCache staticReferenceCache,
    ICommissionSettingsProvider commissionSettingsProvider) : IOffersAppService
{
    private const string ProductImagesFolder = "product-images";
    private const string ProductDocumentsFolder = "product-documents";

    public async Task<object> CreateAsync(CreateOfferInput input, CancellationToken cancellationToken = default)
    {
        if (!Guid.TryParse(input.FromUserId, out var fromUserId))
        {
            throw new ArgumentException("Invalid from user id.");
        }

        if (!Guid.TryParse(input.ToUserId, out var toUserId))
        {
            throw new ArgumentException("Invalid to user id.");
        }
        if (!Guid.TryParse(input.ProductId, out var productId))
        {
            throw new ArgumentException("Invalid product id.");
        }

        if (fromUserId == toUserId)
        {
            throw new ArgumentException("From user and to user must be different.");
        }

        if (string.IsNullOrWhiteSpace(input.CountryName) ||
            string.IsNullOrWhiteSpace(input.PortName) ||
            string.IsNullOrWhiteSpace(input.DeliveryWindow) ||
            string.IsNullOrWhiteSpace(input.UnitName))
        {
            throw new ArgumentException("CountryName, PortName, DeliveryWindow and UnitName are required.");
        }

        if (input.RequestedQuantity <= 0)
        {
            throw new ArgumentException("RequestedQuantity must be greater than zero.");
        }

        if (input.UnitPrice <= 0)
        {
            throw new ArgumentException("UnitPrice must be greater than zero.");
        }
        if (input.TotalPrice <= 0)
        {
            throw new ArgumentException("TotalPrice must be greater than zero.");
        }

        var fromUser = await dbContext.Users.FindAsync([fromUserId], cancellationToken)
            ?? throw new KeyNotFoundException("From user not found.");
        var toUser = await dbContext.Users.FindAsync([toUserId], cancellationToken)
            ?? throw new KeyNotFoundException("To user not found.");
        var product = await dbContext.Products
            .AsNoTracking()
            .FirstOrDefaultAsync(x => x.ProductId == productId, cancellationToken)
            ?? throw new KeyNotFoundException("Product not found.");

        if (product.ProductTypeId != ProductTypeCodes.Requests)
        {
            throw new InvalidOperationException("Offers can only be submitted for request products.");
        }

        OrderOwnershipRules.EnsureBuyerIsNotOwner(fromUserId, product.OwnerId);

        var commissionSettings = await commissionSettingsProvider.GetAsync(cancellationToken);
        var offersCommissionPercent = commissionSettings.OffersCommissionPercent;
        var supplierUnitPrice = decimal.Round(input.UnitPrice, 2, MidpointRounding.AwayFromZero);
        var supplierTotalPrice = decimal.Round(input.TotalPrice, 2, MidpointRounding.AwayFromZero);
        var customerUnitPrice = CustomerPriceCalculator.ApplyPercentMarkup(supplierUnitPrice, offersCommissionPercent);
        var customerTotalPrice = CustomerPriceCalculator.ApplyPercentMarkup(supplierTotalPrice, offersCommissionPercent);

        var country = staticReferenceCache.FindCountryByEnglishName(input.CountryName)
            ?? throw new KeyNotFoundException($"Country '{input.CountryName}' was not found.");

        var port = staticReferenceCache.FindPortByEnglishName(input.PortName, country.Id)
            ?? throw new KeyNotFoundException($"Port '{input.PortName}' was not found for country '{input.CountryName}'.");

        var unit = staticReferenceCache.FindUnitByName(input.UnitName)
            ?? throw new KeyNotFoundException($"Unit '{input.UnitName}' was not found.");

        var imagePaths = NormalizeAssetPaths(input.ImagePaths, ProductImagesFolder, "image");
        var documentPaths = NormalizeAssetPaths(input.DocumentPaths, ProductDocumentsFolder, "document");

        var entity = new Offer
        {
            FromUserId = fromUser.Id,
            ToUserId = toUser.Id,
            CountryId = country.Id,
            PortId = port.Id,
            DeliveryWindow = input.DeliveryWindow.Trim(),
            ProductId = product.ProductId,
            RequestedQuantity = input.RequestedQuantity,
            UnitId = unit.Id,
            UnitPrice = customerUnitPrice,
            TotalPrice = customerTotalPrice,
            StatusId = 1
        };

        foreach (var path in imagePaths)
        {
            entity.Images.Add(new OfferOnRequestImage { ImagePath = path });
        }

        foreach (var path in documentPaths)
        {
            entity.Documents.Add(new OfferOnRequestDocument { DocumentPath = path });
        }

        await dbContext.Offers.AddAsync(entity, cancellationToken);
        await dbContext.SaveChangesAsync(cancellationToken);

        return new
        {
            entity.Id,
            entity.FromUserId,
            entity.ToUserId,
            country = country.CountryNameEn,
            port = port.PortNameEn,
            entity.DeliveryWindow,
            entity.ProductId,
            entity.RequestedQuantity,
            unit = unit.UnitNameEn,
            supplierUnitPrice,
            supplierTotalPrice,
            unitPrice = entity.UnitPrice,
            totalPrice = entity.TotalPrice,
            commissionPercent = offersCommissionPercent,
            entity.StatusId,
            imagePaths,
            documentPaths
        };
    }

    public async Task<object> GetOffersOnRequestsAsync(string? productId, CancellationToken cancellationToken = default)
    {
        var query = dbContext.Offers
            .Include(x => x.Unit)
            .Include(x => x.Product)
            .Include(x => x.Status)
            .Include(x => x.Country)
            .Include(x => x.Port)
            .Include(x => x.Images)
            .Include(x => x.Documents)
            .AsQueryable();

        if (!string.IsNullOrWhiteSpace(productId))
        {
            if (!Guid.TryParse(productId, out var productGuid))
            {
                throw new ArgumentException("Invalid product id.");
            }

            query = query.Where(x => x.ProductId == productGuid);
        }

        var data = await query
            .OrderByDescending(x => x.CreatedAt)
            .Select(x => new
            {
                x.Id,
                x.ProductId,
                productName = x.Product!.NameEn,
                x.FromUserId,
                x.ToUserId,
                country = x.Country!.CountryNameEn,
                port = x.Port!.PortNameEn,
                x.DeliveryWindow,
                x.RequestedQuantity,
                unit = x.Unit!.UnitNameEn,
                x.UnitPrice,
                x.TotalPrice,
                x.StatusId,
                statusName = x.Status!.NameEn,
                x.CreatedAt,
                imagePaths = x.Images.OrderBy(i => i.Id).Select(i => i.ImagePath).ToList(),
                documentPaths = x.Documents.OrderBy(d => d.Id).Select(d => d.DocumentPath).ToList()
            })
            .ToListAsync(cancellationToken);

        return data;
    }

    public async Task<object> CreateOfferOnNegotiableAsync(CreateOfferOnNegotiableInput input, CancellationToken cancellationToken = default)
    {
        if (!Guid.TryParse(input.FromUserId, out var fromUserId))
        {
            throw new ArgumentException("Invalid from user id.");
        }

        if (!Guid.TryParse(input.ToUserId, out var toUserId))
        {
            throw new ArgumentException("Invalid to user id.");
        }

        if (!Guid.TryParse(input.ProductId, out var productId))
        {
            throw new ArgumentException("Invalid product id.");
        }

        if (fromUserId == toUserId)
        {
            throw new ArgumentException("From user and to user must be different.");
        }

        if (input.OfferedPrice <= 0 || input.BaseUnitPrice <= 0 || input.RequestedQuantity <= 0)
        {
            throw new ArgumentException("OfferedPrice, BaseUnitPrice and RequestedQuantity must be greater than zero.");
        }

        if (string.IsNullOrWhiteSpace(input.UnitName))
        {
            throw new ArgumentException("UnitName is required.");
        }

        var fromUser = await dbContext.Users.FindAsync([fromUserId], cancellationToken)
            ?? throw new KeyNotFoundException("From user not found.");
        var toUser = await dbContext.Users.FindAsync([toUserId], cancellationToken)
            ?? throw new KeyNotFoundException("To user not found.");
        var product = await dbContext.Products.FindAsync([productId], cancellationToken)
            ?? throw new KeyNotFoundException("Product not found.");
        OrderOwnershipRules.EnsureBuyerIsNotOwner(fromUserId, product.OwnerId);
        var unit = staticReferenceCache.FindUnitByName(input.UnitName)
            ?? throw new KeyNotFoundException($"Unit '{input.UnitName}' was not found.");

        var entity = new OfferOnNegotiable
        {
            ProductId = product.ProductId,
            FromUserId = fromUser.Id,
            ToUserId = toUser.Id,
            OfferedPrice = input.OfferedPrice,
            UnitId = unit.Id,
            BaseUnitPrice = input.BaseUnitPrice,
            RequestedQuantity = input.RequestedQuantity,
            StatusId = 1
        };

        await dbContext.OffersOnNegotiable.AddAsync(entity, cancellationToken);
        await dbContext.SaveChangesAsync(cancellationToken);

        return new
        {
            entity.Id,
            entity.ProductId,
            entity.FromUserId,
            entity.ToUserId,
            entity.OfferedPrice,
            unit = unit.UnitNameEn,
            entity.BaseUnitPrice,
            entity.RequestedQuantity,
            entity.StatusId
        };
    }

    public async Task<object> GetOfferOnNegotiableAsync(string? productId, CancellationToken cancellationToken = default)
    {
        var query = dbContext.OffersOnNegotiable
            .Include(x => x.Unit)
            .Include(x => x.Product)
            .Include(x => x.Status)
            .AsQueryable();

        if (!string.IsNullOrWhiteSpace(productId))
        {
            if (!Guid.TryParse(productId, out var productGuid))
            {
                throw new ArgumentException("Invalid product id.");
            }

            query = query.Where(x => x.ProductId == productGuid);
        }

        var data = await query
            .OrderByDescending(x => x.CreatedAt)
            .Select(x => new
            {
                x.Id,
                x.ProductId,
                productName = x.Product!.NameEn,
                x.FromUserId,
                x.ToUserId,
                x.OfferedPrice,
                unit = x.Unit!.UnitNameEn,
                x.BaseUnitPrice,
                x.RequestedQuantity,
                x.StatusId,
                statusName = x.Status!.NameEn,
                x.CreatedAt
            })
            .ToListAsync(cancellationToken);

        return data;
    }

    private static List<string> NormalizeAssetPaths(
        IReadOnlyList<string>? paths,
        string expectedFolder,
        string assetKind)
    {
        if (paths is null || paths.Count == 0)
        {
            return [];
        }

        var normalizedFolder = expectedFolder.Trim('/').ToLowerInvariant();
        var result = new List<string>();

        foreach (var rawPath in paths)
        {
            if (string.IsNullOrWhiteSpace(rawPath))
            {
                continue;
            }

            var path = WebRootFileHelper.NormalizeStoredPath(rawPath);
            var folderSegment = path.TrimStart('/').Split('/').FirstOrDefault()?.ToLowerInvariant();
            if (!string.Equals(folderSegment, normalizedFolder, StringComparison.OrdinalIgnoreCase))
            {
                throw new ArgumentException(
                    $"Each {assetKind} path must be stored under '/{expectedFolder}/'.");
            }

            if (!result.Contains(path, StringComparer.OrdinalIgnoreCase))
            {
                result.Add(path);
            }
        }

        return result;
    }
}
