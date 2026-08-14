namespace BusinessLayer.Constants;

public static class ClipVectorIds
{
    /// <summary>Qdrant point ids for admin reference images (no catalog ad).</summary>
    public const long ReferencePointOffset = 9_000_000_000_000L;

    public static readonly Guid ReferenceProductId = Guid.Empty;

    public static long ToReferencePointId(long referenceImageId) => ReferencePointOffset + referenceImageId;

    public static bool IsReferencePointId(long pointId) => pointId >= ReferencePointOffset;

    public static long ToReferenceImageId(long pointId) => pointId - ReferencePointOffset;
}
