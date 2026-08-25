namespace BusinessLayer.Helpers;

/// <summary>
/// User preference for push/email delivery. In-app notification rows are always stored.
/// </summary>
public static class NotificationDeliveryPrefs
{
    /// <summary>True when FCM and notification emails may be sent.</summary>
    public static bool AllowsPushAndEmail(bool isNotificationsOn) => isNotificationsOn;
}
