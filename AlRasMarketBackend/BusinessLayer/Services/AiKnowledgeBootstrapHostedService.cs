using BusinessLayer.Interfaces;
using BusinessLayer.Options;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace BusinessLayer.Services;

public sealed class AiKnowledgeBootstrapHostedService(
    IServiceScopeFactory scopeFactory,
    IOptions<AiAssistantOptions> options,
    ILogger<AiKnowledgeBootstrapHostedService> logger) : IHostedService
{
    private readonly AiAssistantOptions _options = options.Value;

    public Task StartAsync(CancellationToken cancellationToken)
    {
        if (_options.Enabled)
        {
            _ = Task.Run(() => BootstrapAsync(cancellationToken), CancellationToken.None);
        }
        return Task.CompletedTask;
    }

    public Task StopAsync(CancellationToken cancellationToken) => Task.CompletedTask;

    private async Task BootstrapAsync(CancellationToken cancellationToken)
    {
        try
        {
            await using var scope = scopeFactory.CreateAsyncScope();
            var index = scope.ServiceProvider.GetRequiredService<IAiKnowledgeIndex>();
            var embedder = scope.ServiceProvider.GetRequiredService<IAiTextEmbeddingService>();
            var chunks = AiAssistantKnowledgeSource.Build();

            await index.EnsureCollectionAsync(cancellationToken).ConfigureAwait(false);

            // Always re-upsert so content edits overwrite the same stable point ids.
            var points = new List<(AiKnowledgeChunk Chunk, float[] Vector)>(chunks.Count);
            foreach (var chunk in chunks)
            {
                cancellationToken.ThrowIfCancellationRequested();
                var vector = await embedder.EmbedAsync(
                    $"{chunk.Title}\n{chunk.Content}",
                    cancellationToken).ConfigureAwait(false);
                points.Add((chunk, vector));
            }

            await index.UpsertAsync(points, cancellationToken).ConfigureAwait(false);
            logger.LogInformation(
                "AI knowledge indexed: {Count} chunks into {Collection}.",
                points.Count,
                _options.Collection);
        }
        catch (OperationCanceledException)
        {
            // Host is stopping.
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "AI knowledge bootstrap failed; assistant will return a safe fallback.");
        }
    }
}
