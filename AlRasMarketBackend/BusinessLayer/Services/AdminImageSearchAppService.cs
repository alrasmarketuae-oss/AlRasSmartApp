using System.Text.Json;
using BusinessLayer.Dtos;
using BusinessLayer.Interfaces;
using BusinessLayer.Options;
using DataLayer.Interfaces;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace BusinessLayer.Services;

public sealed class AdminImageSearchAppService(
    IRasAlSouqDbContext dbContext,
    IProductsAppService productsAppService,
    IProductImageVectorIndex productImageVectorIndex,
    HttpClient httpClient,
    IOptions<ImageEmbeddingOptions> embeddingOptions,
    IOptions<QdrantOptions> qdrantOptions,
    ILogger<AdminImageSearchAppService> logger) : IAdminImageSearchAppService
{
    private readonly ImageEmbeddingOptions _embeddingOptions = embeddingOptions.Value;
    private readonly QdrantOptions _qdrantOptions = qdrantOptions.Value;

    public async Task<AdminImageSearchStatusDto> GetStatusAsync(CancellationToken cancellationToken = default)
    {
        var totalImages = await dbContext.ProductImages
            .AsNoTracking()
            .CountAsync(cancellationToken)
            .ConfigureAwait(false);

        var referenceCount = await dbContext.ClipReferenceImages
            .AsNoTracking()
            .CountAsync(cancellationToken)
            .ConfigureAwait(false);

        var clipConfigured = !string.IsNullOrWhiteSpace(_embeddingOptions.ClipServiceUrl);
        var (clipReachable, clipModel, clipDim) = clipConfigured
            ? await ProbeClipHealthAsync(cancellationToken).ConfigureAwait(false)
            : (false, null, (int?)null);

        long qdrantPoints = -1;
        if (_embeddingOptions.Enabled && clipConfigured)
        {
            qdrantPoints = await productImageVectorIndex
                .GetPointsCountAsync(cancellationToken)
                .ConfigureAwait(false);
        }

        var qdrantReachable = qdrantPoints >= 0;
        var indexedCount = qdrantReachable ? qdrantPoints : 0;
        var coverage = totalImages > 0
            ? (int)Math.Min(100, Math.Round(indexedCount * 100.0 / totalImages))
            : 0;

        return new AdminImageSearchStatusDto
        {
            Enabled = _embeddingOptions.Enabled,
            ClipConfigured = clipConfigured,
            ClipReachable = clipReachable,
            ClipModel = clipModel,
            ClipVectorDim = clipDim,
            QdrantReachable = qdrantReachable,
            QdrantPointsCount = Math.Max(0, qdrantPoints),
            QdrantCollection = _qdrantOptions.Collection,
            VectorSize = _qdrantOptions.VectorSize,
            TotalProductImages = totalImages,
            IndexedCoveragePercent = coverage,
            AutoIndexOnCatalogChanges = _embeddingOptions.AutoIndexOnCatalogChanges,
            ReferenceImageCount = referenceCount,
        };
    }

    public Task<object> TestSearchAsync(
        Stream imageStream,
        string fileName,
        CancellationToken cancellationToken = default) =>
        productsAppService.DetectProductsFromImageAsync(imageStream, fileName, cancellationToken);

    private async Task<(bool Reachable, string? Model, int? Dim)> ProbeClipHealthAsync(
        CancellationToken cancellationToken)
    {
        try
        {
            var baseUrl = _embeddingOptions.ClipServiceUrl.TrimEnd('/') + "/";
            var url = new Uri(new Uri(baseUrl), "health").ToString();
            using var cts = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken);
            cts.CancelAfter(TimeSpan.FromSeconds(4));

            using var response = await httpClient.GetAsync(url, cts.Token).ConfigureAwait(false);
            if (!response.IsSuccessStatusCode)
            {
                return (false, null, null);
            }

            await using var stream = await response.Content
                .ReadAsStreamAsync(cts.Token)
                .ConfigureAwait(false);
            using var doc = await JsonDocument.ParseAsync(stream, cancellationToken: cts.Token)
                .ConfigureAwait(false);

            var root = doc.RootElement;
            var statusOk = root.TryGetProperty("status", out var statusEl)
                && string.Equals(statusEl.GetString(), "ok", StringComparison.OrdinalIgnoreCase);
            string? model = root.TryGetProperty("model", out var modelEl)
                ? modelEl.GetString()
                : null;
            int? dim = root.TryGetProperty("dim", out var dimEl) && dimEl.TryGetInt32(out var d)
                ? d
                : null;

            return (statusOk, model, dim);
        }
        catch (Exception ex)
        {
            logger.LogDebug(ex, "CLIP health probe failed.");
            return (false, null, null);
        }
    }
}
