using BusinessLayer.Dtos;
using BusinessLayer.Interfaces;
using DataLayer.Interfaces;
using DataLayer.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;

namespace BusinessLayer.Services;

public partial class OrdersAppService
{
    public async Task<object> GetOrderVideosAsync(string userId, long orderId, CancellationToken cancellationToken = default)
    {
        if (!Guid.TryParse(userId, out var parsedUserId))
        {
            throw new ArgumentException("Invalid user id.");
        }

        var order = await dbContext.Orders
            .Include(x => x.Videos)
            .FirstOrDefaultAsync(x => x.Id == orderId, cancellationToken)
            ?? throw new KeyNotFoundException("Order not found.");

        await EnsureUserCanAccessOrderAsync(parsedUserId, order, cancellationToken);

        return order.Videos
            .OrderByDescending(x => x.CreatedAt)
            .Select(x => new
            {
                x.Id,
                x.OrderId,
                path = x.VideoPath,
                x.UploadedByUserId,
                x.CreatedAt
            })
            .ToList();
    }

    public async Task<object> UploadOrderVideoAsync(UploadOrderVideoInput input, CancellationToken cancellationToken = default)
    {
        if (!Guid.TryParse(input.UserId, out var userId))
        {
            throw new ArgumentException("Invalid user id.");
        }

        if (input.File is null || input.File.Length == 0)
        {
            throw new ArgumentException("Video file is required.");
        }

        var order = await dbContext.Orders.FindAsync([input.OrderId], cancellationToken)
            ?? throw new KeyNotFoundException("Order not found.");

        await EnsureUserCanAccessOrderAsync(userId, order, cancellationToken);

        var extension = Path.GetExtension(input.File.FileName).ToLowerInvariant();
        var allowed = new[] { ".mp4", ".mov", ".webm", ".m4v" };
        if (!allowed.Contains(extension))
        {
            throw new ArgumentException("Unsupported video format. Allowed: .mp4, .mov, .webm, .m4v");
        }

        var videoFileName = $"order-video-{Guid.NewGuid():N}{extension}";
        var videoPath = await mediaStorage.SaveFormFileAsync(
            input.File,
            "order-videos",
            videoFileName,
            cancellationToken: cancellationToken);
        var entity = new OrderVideo
        {
            OrderId = order.Id,
            VideoPath = videoPath,
            UploadedByUserId = userId
        };

        await dbContext.OrderVideos.AddAsync(entity, cancellationToken);
        await dbContext.SaveChangesAsync(cancellationToken);

        return new
        {
            entity.Id,
            entity.OrderId,
            path = entity.VideoPath,
            entity.UploadedByUserId,
            entity.CreatedAt
        };
    }

    public async Task DeleteOrderVideoAsync(string userId, long orderId, long videoId, CancellationToken cancellationToken = default)
    {
        if (!Guid.TryParse(userId, out var parsedUserId))
        {
            throw new ArgumentException("Invalid user id.");
        }

        var video = await dbContext.OrderVideos
            .Include(x => x.Order)
            .FirstOrDefaultAsync(x => x.Id == videoId && x.OrderId == orderId, cancellationToken)
            ?? throw new KeyNotFoundException("Order video not found.");

        await EnsureUserCanAccessOrderAsync(parsedUserId, video.Order!, cancellationToken);

        dbContext.OrderVideos.Remove(video);
        await dbContext.SaveChangesAsync(cancellationToken);
    }

    public async Task<object> UploadOrderImageAsync(UploadOrderImageInput input, CancellationToken cancellationToken = default)
    {
        if (!Guid.TryParse(input.UserId, out var userId))
        {
            throw new ArgumentException("Invalid user id.");
        }

        if (input.File is null || input.File.Length == 0)
        {
            throw new ArgumentException("Image file is required.");
        }

        var order = await dbContext.Orders.FindAsync([input.OrderId], cancellationToken)
            ?? throw new KeyNotFoundException("Order not found.");

        await EnsureUserCanAccessOrderAsync(userId, order, cancellationToken);

        const int maxOrderImages = 15;
        var existingImageCount = await dbContext.OrderImages
            .CountAsync(x => x.OrderId == order.Id, cancellationToken);
        if (existingImageCount >= maxOrderImages)
        {
            throw new InvalidOperationException("An order can have at most 15 images.");
        }

        var extension = Path.GetExtension(input.File.FileName).ToLowerInvariant();
        var allowed = new[] { ".jpg", ".jpeg", ".png", ".webp" };
        if (!allowed.Contains(extension))
        {
            throw new ArgumentException("Unsupported image format. Allowed: .jpg, .jpeg, .png, .webp");
        }

        var imageFileName = $"{Guid.NewGuid():N}{extension}";
        var imagePath = await mediaStorage.SaveFormFileAsync(
            input.File,
            "product-images",
            imageFileName,
            cancellationToken: cancellationToken);
        var entity = new OrderImage
        {
            OrderId = order.Id,
            ImagePath = imagePath,
            UploadedByUserId = userId
        };

        await dbContext.OrderImages.AddAsync(entity, cancellationToken);
        await dbContext.SaveChangesAsync(cancellationToken);

        return new
        {
            entity.Id,
            entity.OrderId,
            path = entity.ImagePath,
            entity.UploadedByUserId,
            entity.CreatedAt
        };
    }

    public async Task DeleteOrderImageAsync(string userId, long orderId, long imageId, CancellationToken cancellationToken = default)
    {
        if (!Guid.TryParse(userId, out var parsedUserId))
        {
            throw new ArgumentException("Invalid user id.");
        }

        var image = await dbContext.OrderImages
            .Include(x => x.Order)
            .FirstOrDefaultAsync(x => x.Id == imageId && x.OrderId == orderId, cancellationToken)
            ?? throw new KeyNotFoundException("Order image not found.");

        await EnsureUserCanAccessOrderAsync(parsedUserId, image.Order!, cancellationToken);

        dbContext.OrderImages.Remove(image);
        await dbContext.SaveChangesAsync(cancellationToken);
    }

}
