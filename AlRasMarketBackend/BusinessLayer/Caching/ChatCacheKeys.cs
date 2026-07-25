namespace BusinessLayer.Caching;

public static class ChatCacheKeys
{
    private const string Prefix = "chat";

    public static string Inbox(Guid userId) => $"{Prefix}:inbox:{userId:N}";

    public static string Unread(Guid userId) => $"{Prefix}:unread:{userId:N}";

    public static string InboxForViewer(Guid inboxOwnerId, Guid viewerId) =>
        $"{Prefix}:inbox:{inboxOwnerId:N}:{viewerId:N}";

    public static string UnreadForViewer(Guid inboxOwnerId, Guid viewerId) =>
        $"{Prefix}:unread:{inboxOwnerId:N}:{viewerId:N}";

    public static string Thread(Guid userA, Guid userB)
    {
        var (first, second) = userA.CompareTo(userB) <= 0 ? (userA, userB) : (userB, userA);
        return $"{Prefix}:thread:{first:N}:{second:N}";
    }

    public static IEnumerable<string> KeysForUser(Guid userId) => [Inbox(userId), Unread(userId)];

    public static IEnumerable<string> KeysForConversation(Guid userA, Guid userB) =>
        [Inbox(userA), Inbox(userB), Unread(userA), Unread(userB), Thread(userA, userB)];
}
