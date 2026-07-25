namespace BusinessLayer.LoginServices.Dtos;

public static class LoginDtos
{
    public sealed class LoginRequest
    {
        public string LoginProviderName { get; set; } = string.Empty;
        public string? Email { get; set; }
        public string? Password { get; set; }
        public string? Token { get; set; }
        public string? FcmToken { get; set; }
        public string? PreferredLanguage { get; set; }
        /// <summary>Optional display name from social providers (e.g. Apple given+family name on first sign-in).</summary>
        public string? FullName { get; set; }

        /// <summary>
        /// Cloudflare Turnstile token from the admin dashboard login widget.
        /// Required when <c>ClientApp</c> is <c>AdminDashboard</c> and Turnstile is configured.
        /// </summary>
        public string? TurnstileToken { get; set; }

        /// <summary>
        /// Caller identity. Use <c>AdminDashboard</c> for the web admin login form.
        /// </summary>
        public string? ClientApp { get; set; }
    }
}
