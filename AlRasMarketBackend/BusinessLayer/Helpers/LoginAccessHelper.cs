using BusinessLayer.Constants;
using DataLayer.Models;

namespace BusinessLayer.Helpers;

public static class LoginAccessHelper
{
    /// <summary>
    /// Rules for API access after a token is issued.
    /// Only verified + approved (when required) + active accounts may call protected APIs.
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
    /// Rules before issuing a login session token.
    /// Token is only allowed when the account is verified and (if required) admin-approved.
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
    /// JWT is issued only for verified, active, non-rejected accounts that are approved when required.
    /// </summary>
    public static bool ShouldIssueToken(User user) =>
        !user.IsRejected
        && user.IsVerified
        && user.IsActive
        && (!RoleIds.RequiresAdminApproval(user.RoleId) || user.IsApproved);

    public static bool IsPendingCompanyApproval(User user) =>
        RoleIds.RequiresAdminApproval(user.RoleId)
        && user.IsVerified
        && !user.IsApproved
        && !user.IsRejected;
}
