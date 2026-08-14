namespace BusinessLayer.Dtos;

public sealed class AdminImageSearchStatusDto
{
    public bool Enabled { get; init; }

    public bool ClipConfigured { get; init; }

    public bool ClipReachable { get; init; }

    public string? ClipModel { get; init; }

    public int? ClipVectorDim { get; init; }

    public bool QdrantReachable { get; init; }

    public long QdrantPointsCount { get; init; }

    public string QdrantCollection { get; init; } = string.Empty;

    public int VectorSize { get; init; }

    public int TotalProductImages { get; init; }

    /// <summary>Indexed vectors as a percentage of catalog images (capped at 100).</summary>
    public int IndexedCoveragePercent { get; init; }

    public bool AutoIndexOnCatalogChanges { get; init; }

    public int ReferenceImageCount { get; init; }
}
