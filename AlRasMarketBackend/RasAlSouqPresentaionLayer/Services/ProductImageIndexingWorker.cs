using BusinessLayer.Interfaces;
using BusinessLayer.Options;
using DataLayer.Interfaces;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace RasAlSouqPresentaionLayer.Services;

public sealed class ProductImageIndexingWorker(
    IServiceScopeFactory scopeFactory,
    IProductImageIndexingQueue queue,
    IOptions<ImageEmbeddingOptions> embeddingOptions,
    ILogger<ProductImageIndexingWorker> logger) : BackgroundService
{
    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        if (!embeddingOptions.Value.Enabled)
        {
            logger.LogInformation("Product image indexing worker idle — ImageEmbedding:Enabled=false.");
            return;
        }

        // If Qdrant is empty (fresh CLIP collection / failed prior index), rebuild once.
        _ = BootstrapIfEmptyAsync(stoppingToken);

        var concurrency = Math.Max(1, embeddingOptions.Value.MaxConcurrentIndexingJobs);
        logger.LogInformation(
            "Product image indexing worker started with {Concurrency} parallel workers.",
            concurrency);

        var workers = Enumerable
            .Range(0, concurrency)
            .Select(workerId => RunWorkerLoopAsync(workerId, stoppingToken))
            .ToArray();

        await Task.WhenAll(workers).ConfigureAwait(false);
    }

    private async Task BootstrapIfEmptyAsync(CancellationToken stoppingToken)
    {
        try
        {
            // Let Qdrant + CLIP finish warming after compose up.
            await Task.Delay(TimeSpan.FromSeconds(15), stoppingToken).ConfigureAwait(false);

            using var scope = scopeFactory.CreateScope();
            var index = scope.ServiceProvider.GetRequiredService<IProductImageVectorIndex>();
            var points = await index.GetPointsCountAsync(stoppingToken).ConfigureAwait(false);
            if (points != 0)
            {
                logger.LogInformation("CLIP index bootstrap skipped — Qdrant already has {Count} points.", points);
                return;
            }

            var db = scope.ServiceProvider.GetRequiredService<IRasAlSouqDbContext>();
            var imageIds = await db.ProductImages
                .AsNoTracking()
                .OrderBy(x => x.Id)
                .Select(x => x.Id)
                .ToListAsync(stoppingToken)
                .ConfigureAwait(false);

            logger.LogWarning(
                "Qdrant CLIP collection empty — enqueueing {Count} product images for bootstrap reindex.",
                imageIds.Count);

            foreach (var imageId in imageIds)
            {
                await queue.EnqueueAsync(imageId, stoppingToken).ConfigureAwait(false);
            }
        }
        catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested)
        {
            // shutting down
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "CLIP index bootstrap failed.");
        }
    }

    private async Task RunWorkerLoopAsync(int workerId, CancellationToken stoppingToken)
    {
        while (!stoppingToken.IsCancellationRequested)
        {
            QueuedWorkItem<long> message;
            try
            {
                message = await queue.DequeueAsync(stoppingToken).ConfigureAwait(false);
            }
            catch (OperationCanceledException)
            {
                break;
            }
            catch (Exception ex)
            {
                logger.LogError(
                    ex,
                    "Product image indexing worker {WorkerId}: failed to dequeue job.",
                    workerId);
                await Task.Delay(500, stoppingToken).ConfigureAwait(false);
                continue;
            }

            try
            {
                using var scope = scopeFactory.CreateScope();
                var processor = scope.ServiceProvider.GetRequiredService<IProductImageVectorIndexingProcessor>();
                await processor.IndexProductImageAsync(message.Payload, stoppingToken).ConfigureAwait(false);
                await queue.AcknowledgeAsync(message.MessageId, stoppingToken).ConfigureAwait(false);
            }
            catch (Exception ex)
            {
                logger.LogError(
                    ex,
                    "Product image indexing worker {WorkerId}: failed job for image {ImageId}.",
                    workerId,
                    message.Payload);
            }
        }
    }
}
