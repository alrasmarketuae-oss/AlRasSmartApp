using BusinessLayer.Interfaces;
using BusinessLayer.Options;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace BusinessLayer.Services.AiAssistant;

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
            var indexer = scope.ServiceProvider.GetRequiredService<IAiKnowledgeIndexer>();

            // force:false → skip embedding entirely when the knowledge content,
            // embedding model, and chunk count are unchanged since last deploy.
            await indexer.ReindexAsync(force: false, cancellationToken).ConfigureAwait(false);
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
