namespace BusinessLayer.Helpers;

/// <summary>
/// These accounts publish ads live. Their listings skip the admin review queue.
/// </summary>
public static class TrustedAdPublishers
{
    private static readonly HashSet<Guid> OwnerIds =
    [
        Guid.Parse("BD469D54-8B82-47F3-A1F0-E1C5D91DDEB0"),
        Guid.Parse("1697C563-A158-431D-BCD1-FB3AA36953FC"),
    ];

    public static bool Contains(Guid? ownerId) =>
        ownerId.HasValue && OwnerIds.Contains(ownerId.Value);
}
