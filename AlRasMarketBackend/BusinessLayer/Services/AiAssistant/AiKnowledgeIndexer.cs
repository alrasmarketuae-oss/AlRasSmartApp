using System.Security.Cryptography;
using System.Text;
using BusinessLayer.Interfaces;
using BusinessLayer.Options;
using DataLayer.Interfaces;
using DataLayer.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace BusinessLayer.Services.AiAssistant;

public sealed class AiKnowledgeIndexer(
    IRasAlSouqDbContext dbContext,
    IAiKnowledgeIndex index,
    IAiTextEmbeddingService embedder,
    IOptions<AiAssistantOptions> options,
    ILogger<AiKnowledgeIndexer> logger) : IAiKnowledgeIndexer
{
    private readonly AiAssistantOptions _options = options.Value;

    public async Task<AiKnowledgeReindexResult> ReindexAsync(
        bool force,
        CancellationToken cancellationToken = default)
    {
        var chunks = AiAssistantKnowledgeSource.Build();
        var modelSignature = $"{_options.EmbeddingModel}@{_options.EmbeddingDimensions}";
        var contentHash = ComputeHash(chunks, modelSignature);

        await index.EnsureCollectionAsync(cancellationToken).ConfigureAwait(false);

        if (!force)
        {
            var state = await dbContext.AiKnowledgeIndexStates
                .AsNoTracking()
                .FirstOrDefaultAsync(x => x.Id == 1, cancellationToken)
                .ConfigureAwait(false);

            var vectorCount = await index.GetCountAsync(cancellationToken).ConfigureAwait(false);

            if (state is not null
                && state.ContentHash == contentHash
                && state.EmbeddingModel == modelSignature
                && state.ChunkCount == chunks.Count
                && vectorCount >= chunks.Count)
            {
                logger.LogInformation(
                    "AI knowledge unchanged ({Count} chunks, hash {Hash}) — skipping embedding.",
                    chunks.Count,
                    contentHash[..8]);
                return new AiKnowledgeReindexResult(false, chunks.Count, contentHash, "unchanged");
            }
        }

        // Re-embed everything (content changed, model changed, or forced).
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

        // Verify Qdrant actually holds the points before trusting the marker.
        var indexedCount = await index.GetCountAsync(cancellationToken).ConfigureAwait(false);
        if (indexedCount < chunks.Count)
        {
            throw new InvalidOperationException(
                $"AI knowledge upsert verification failed: index has {indexedCount} points, expected at least {chunks.Count}.");
        }

        await PersistStateAsync(contentHash, modelSignature, chunks.Count, cancellationToken).ConfigureAwait(false);

        logger.LogInformation(
            "AI knowledge indexed: {Count} chunks into {Collection} (hash {Hash}).",
            chunks.Count,
            _options.Collection,
            contentHash[..8]);

        return new AiKnowledgeReindexResult(true, chunks.Count, contentHash, force ? "forced" : "changed");
    }

    private async Task PersistStateAsync(
        string contentHash,
        string modelSignature,
        int chunkCount,
        CancellationToken cancellationToken)
    {
        var row = await dbContext.AiKnowledgeIndexStates
            .FirstOrDefaultAsync(x => x.Id == 1, cancellationToken)
            .ConfigureAwait(false);

        if (row is null)
        {
            row = new AiKnowledgeIndexState { Id = 1 };
            await dbContext.AiKnowledgeIndexStates.AddAsync(row, cancellationToken).ConfigureAwait(false);
        }

        row.ContentHash = contentHash;
        row.EmbeddingModel = modelSignature;
        row.ChunkCount = chunkCount;
        row.UpdatedAtUtc = DateTime.UtcNow;

        await dbContext.SaveChangesAsync(cancellationToken).ConfigureAwait(false);
    }

    private static string ComputeHash(IReadOnlyList<AiKnowledgeChunk> chunks, string modelSignature)
    {
        var builder = new StringBuilder();
        builder.Append("model=").Append(modelSignature).Append('\n');

        // Order by Id so the hash is independent of Build() call order.
        foreach (var chunk in chunks.OrderBy(c => c.Id, StringComparer.Ordinal))
        {
            builder.Append(chunk.Id).Append('\u001f')
                .Append(chunk.Source).Append('\u001f')
                .Append(chunk.Language).Append('\u001f')
                .Append(chunk.Title).Append('\u001f')
                .Append(string.Join(',', chunk.Audiences)).Append('\u001f')
                .Append(chunk.Content).Append('\u001e');
        }

        var bytes = SHA256.HashData(Encoding.UTF8.GetBytes(builder.ToString()));
        return Convert.ToHexString(bytes).ToLowerInvariant();
    }
}
