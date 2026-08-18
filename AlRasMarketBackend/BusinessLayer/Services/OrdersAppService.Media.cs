using BusinessLayer.Dtos;
using BusinessLayer.Helpers;
using BusinessLayer.Interfaces;
using DataLayer.Interfaces;
using DataLayer.Models;
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

        var order = await orderData.GetOrderWithVideosAsync(orderId, cancellationToken)
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

        var order = await orderData.GetOrderByIdTrackedAsync(input.OrderId, cancellationToken)
            ?? throw new KeyNotFoundException("Order not found.");

        await EnsureUserCanAccessOrderAsync(userId, order, cancellationToken);

        var extension = Path.GetExtension(input.File.FileName).ToLowerInvariant();
        var allowed = new[] { ".mp4", ".mov", ".webm", ".m4v" };
        if (!allowed.Contains(extension))
        {
            throw new ArgumentException("Unsupported video format. Allowed: .mp4, .mov, .webm, .m4v");
        }

        var prepared = await VideoMobileCompatHelper.PrepareForMobilePlaybackAsync(
            input.File,
            logger,
            cancellationToken);
        await using (prepared.Content)
        {
            if (!allowed.Contains(prepared.Extension))
            {
                throw new ArgumentException("Unsupported video format. Allowed: .mp4, .mov, .webm, .m4v");
            }

            byte[] bytes;
            if (prepared.Content is MemoryStream memory)
            {
                bytes = memory.ToArray();
            }
            else
            {
                await using var buffer = new MemoryStream();
                if (prepared.Content.CanSeek)
                {
                    prepared.Content.Position = 0;
                }

                await prepared.Content.CopyToAsync(buffer, cancellationToken);
                bytes = buffer.ToArray();
            }

            var videoFileName = $"order-video-{Guid.NewGuid():N}{prepared.Extension}";
            var videoPath = await mediaStorage.SaveBytesAsync(
                bytes,
                "order-videos",
                videoFileName,
                prepared.ContentType,
                cancellationToken);
            var entity = new OrderVideo
            {
                OrderId = order.Id,
                VideoPath = videoPath,
                UploadedByUserId = userId
            };

            await orderData.AddOrderVideoAsync(entity, cancellationToken);
            await orderData.SaveChangesAsync(cancellationToken);

            return new
            {
                entity.Id,
                entity.OrderId,
                path = entity.VideoPath,
                entity.UploadedByUserId,
                entity.CreatedAt
            };
        }
    }

    public async Task<object> TrimOrderVideoAsync(TrimOrderVideoInput input, CancellationToken cancellationToken = default)
    {
        if (!Guid.TryParse(input.UserId, out var userId))
        {
            throw new ArgumentException("Invalid user id.");
        }

        VideoMobileCompatHelper.ResolveTrimDurationSeconds(input.StartSeconds, input.EndSeconds);

        var video = await orderData.GetOrderVideoWithOrderAsync(input.VideoId, input.OrderId, cancellationToken)
            ?? throw new KeyNotFoundException("Order video not found.");

        await EnsureUserCanAccessOrderAsync(userId, video.Order!, cancellationToken);

        var sourcePath = video.VideoPath;
        if (string.IsNullOrWhiteSpace(sourcePath))
        {
            throw new KeyNotFoundException("Order video file not found.");
        }

        await using var sourceStream = await mediaStorage.OpenReadAsync(sourcePath, cancellationToken)
            ?? throw new KeyNotFoundException("Order video file not found.");

        var trimmed = await VideoMobileCompatHelper.TrimSegmentAsync(
            sourceStream,
            Path.GetExtension(sourcePath),
            input.StartSeconds,
            input.EndSeconds,
            logger,
            cancellationToken);
        await using (trimmed.Content)
        {
            byte[] bytes;
            if (trimmed.Content is MemoryStream memory)
            {
                bytes = memory.ToArray();
            }
            else
            {
                await using var buffer = new MemoryStream();
                if (trimmed.Content.CanSeek)
                {
                    trimmed.Content.Position = 0;
                }

                await trimmed.Content.CopyToAsync(buffer, cancellationToken);
                bytes = buffer.ToArray();
            }

            var videoFileName = $"order-video-{Guid.NewGuid():N}{trimmed.Extension}";
            var videoPath = await mediaStorage.SaveBytesAsync(
                bytes,
                "order-videos",
                videoFileName,
                trimmed.ContentType,
                cancellationToken);

            var oldPath = video.VideoPath;
            video.VideoPath = videoPath;
            await orderData.SaveChangesAsync(cancellationToken);

            try
            {
                await mediaStorage.DeleteAsync(oldPath, cancellationToken);
            }
            catch
            {
                // Replacement succeeded even if the old object remains.
            }

            return new
            {
                video.Id,
                video.OrderId,
                path = video.VideoPath,
                video.UploadedByUserId,
                video.CreatedAt
            };
        }
    }

    public async Task DeleteOrderVideoAsync(string userId, long orderId, long videoId, CancellationToken cancellationToken = default)
    {
        if (!Guid.TryParse(userId, out var parsedUserId))
        {
            throw new ArgumentException("Invalid user id.");
        }

        var video = await orderData.GetOrderVideoWithOrderAsync(videoId, orderId, cancellationToken)
            ?? throw new KeyNotFoundException("Order video not found.");

        await EnsureUserCanAccessOrderAsync(parsedUserId, video.Order!, cancellationToken);

        orderData.RemoveOrderVideo(video);
        await orderData.SaveChangesAsync(cancellationToken);
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

        var order = await orderData.GetOrderByIdTrackedAsync(input.OrderId, cancellationToken)
            ?? throw new KeyNotFoundException("Order not found.");

        await EnsureUserCanAccessOrderAsync(userId, order, cancellationToken);

        const int maxOrderImages = 15;
        var existingImageCount = await orderData.CountOrderImagesAsync(order.Id, cancellationToken);
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

        await orderData.AddOrderImageAsync(entity, cancellationToken);
        await orderData.SaveChangesAsync(cancellationToken);

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

        var image = await orderData.GetOrderImageWithOrderAsync(imageId, orderId, cancellationToken)
            ?? throw new KeyNotFoundException("Order image not found.");

        await EnsureUserCanAccessOrderAsync(parsedUserId, image.Order!, cancellationToken);

        orderData.RemoveOrderImage(image);
        await orderData.SaveChangesAsync(cancellationToken);
    }

}
