namespace BusinessLayer.Interfaces;

public sealed class ProductImageVectorPoint
{
    public required long ProductImageId { get; init; }
    public required Guid ProductId { get; init; }
    public string ProductCode { get; init; } = string.Empty;
    public string ProductName { get; init; } = string.Empty;
    public string ImagePath { get; init; } = string.Empty;
    public required float[] Vector { get; init; }
}

public sealed class ProductImageVectorHit
{
    public long ProductImageId { get; init; }
    public Guid ProductId { get; init; }
    public string ProductCode { get; init; } = string.Empty;
    public string ProductName { get; init; } = string.Empty;
    public string ImagePath { get; init; } = string.Empty;
    public float Score { get; init; }
}

public interface IProductImageVectorIndex
{
    Task EnsureCollectionAsync(CancellationToken cancellationToken = default);

    Task<long> GetPointsCountAsync(CancellationToken cancellationToken = default);

    Task UpsertAsync(ProductImageVectorPoint point, CancellationToken cancellationToken = default);

    Task DeleteByProductImageIdAsync(long productImageId, CancellationToken cancellationToken = default);

    Task DeleteByProductIdAsync(Guid productId, CancellationToken cancellationToken = default);

    Task<IReadOnlyList<ProductImageVectorHit>> SearchSimilarAsync(
        float[] queryVector,
        CancellationToken cancellationToken = default);
}
