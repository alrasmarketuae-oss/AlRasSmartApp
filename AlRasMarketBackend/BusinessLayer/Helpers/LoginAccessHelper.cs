using BusinessLayer.Constants;
using DataLayer.Models;

namespace BusinessLayer.Helpers;

public static class LoginAccessHelper
{
    /// <summary>
    /// Rules for API access after a token is issued.
    /// Pending-approval companies may call APIs so they can complete missing registration data.
    /// Product publish and similar flows still enforce IsApproved separately.
    /// </summary>
    public static void EnsureCanAuthenticate(User user)
    {
        var language = user.PreferredLanguage;

        if (user.IsRejected)
        {
            throw new UnauthorizedAccessException(UserMessages.AccountRejected(language, user.RejectionReason));
        }

        if (!user.IsVerified)
        {
            throw new UnauthorizedAccessException(UserMessages.Localize(
                "Please verify your email before logging in.",
                language));
        }

        if (!user.IsActive && !IsPendingCompanyApproval(user))
        {
            throw new UnauthorizedAccessException(UserMessages.Localize(
                "Your account is suspended or deactivated.",
                language));
        }

        // Pending admin approval is allowed (complete registration / under review).
        if (RoleIds.RequiresAdminApproval(user.RoleId) && !user.IsApproved)
        {
            return;
        }

        if (!user.IsActive)
        {
            throw new UnauthorizedAccessException(UserMessages.Localize(
                "Your account is suspended or deactivated.",
                language));
        }
    }

    /// <summary>
    /// Rules before issuing a login session token.
    /// </summary>
    public static void EnsureCanLogin(User user)
    {
        var language = user.PreferredLanguage;

        if (user.IsRejected)
        {
            throw new UnauthorizedAccessException(UserMessages.AccountRejected(language, user.RejectionReason));
        }

        if (!user.IsVerified)
        {
            throw new UnauthorizedAccessException(UserMessages.Localize(
                "Please verify your email before logging in.",
                language));
        }

        if (IsPendingCompanyApproval(user))
        {
            return;
        }

        if (RoleIds.RequiresAdminApproval(user.RoleId) && !user.IsApproved)
        {
            throw new UnauthorizedAccessException(UserMessages.Localize(
                "Your company account has not been approved yet. It is pending admin approval.",
                language));
        }

        if (!user.IsActive)
        {
            throw new UnauthorizedAccessException(UserMessages.Localize(
                "Your account is suspended or deactivated.",
                language));
        }
    }

    /// <summary>
    /// JWT is issued for verified non-rejected accounts that are either approved
    /// or still pending admin approval (so they can complete missing registration).
    /// </summary>
    public static bool ShouldIssueToken(User user) =>
        !user.IsRejected
        && user.IsVerified
        && (user.IsActive || IsPendingCompanyApproval(user))
        && (!RoleIds.RequiresAdminApproval(user.RoleId) || user.IsApproved || IsPendingCompanyApproval(user));

    public static bool IsPendingCompanyApproval(User user) =>
        RoleIds.RequiresAdminApproval(user.RoleId)
        && user.IsVerified
        && !user.IsApproved
        && !user.IsRejected;
}
