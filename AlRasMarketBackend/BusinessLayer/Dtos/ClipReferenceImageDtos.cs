namespace BusinessLayer.Dtos;

public sealed class ClipReferenceImageListItemDto
{
    public long Id { get; init; }

    public string ProductName { get; init; } = string.Empty;

    public string? ProductNameAr { get; init; }

    public string? ProductCode { get; init; }

    public string ImagePath { get; init; } = string.Empty;

    public DateTime CreatedAtUtc { get; init; }
}

public sealed class AdminClipReferenceImagesPageDto
{
    public int Page { get; init; }

    public int PageSize { get; init; }

    public int TotalCount { get; init; }

    public int TotalPages { get; init; }

    public IReadOnlyList<ClipReferenceImageListItemDto> Items { get; init; } = [];
}
