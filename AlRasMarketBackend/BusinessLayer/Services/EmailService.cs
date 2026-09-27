using System.Net;
using System.Net.Mail;
using System.Net.Mime;
using BusinessLayer.Helpers;
using BusinessLayer.Interfaces;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;

namespace BusinessLayer.Services;

public class EmailService(IConfiguration configuration, ILogger<EmailService> logger) : IEmailService
{
    private readonly IConfiguration _configuration = configuration;
    private readonly ILogger<EmailService> _logger = logger;

    public async Task SendAsync(string toEmail, string subject, string bodyHtml, CancellationToken cancellationToken = default)
    {
        var section = _configuration.GetSection("EmailSettings");
        var smtpServer = section["SmtpServer"];
        var senderEmail = section["SenderEmail"];
        var senderPassword = section["SenderPassword"];
        var senderName = section["SenderName"] ?? "Al Ras Smart";
        var smtpPortRaw = section["SmtpPort"];
        var enableSslRaw = section["EnableSsl"];

        if (string.IsNullOrWhiteSpace(smtpServer) ||
            string.IsNullOrWhiteSpace(senderEmail) ||
            string.IsNullOrWhiteSpace(senderPassword) ||
            string.IsNullOrWhiteSpace(smtpPortRaw))
        {
            _logger.LogError("Email settings are not configured. Cannot send email to {ToEmail}.", toEmail);
            throw new InvalidOperationException("Email service is not configured.");
        }

        try
        {
            _ = new MailAddress(toEmail);
        }
        catch (FormatException ex)
        {
            throw new ArgumentException("Invalid email address.", ex);
        }

        var smtpPort = int.TryParse(smtpPortRaw, out var parsedPort) ? parsedPort : 587;
        var enableSsl = !string.IsNullOrWhiteSpace(enableSslRaw) && bool.TryParse(enableSslRaw, out var parsedSsl) && parsedSsl;

        var logoPath = ResolveLogoPath(section["LogoFilePath"]);
        var logoSrc = BuildLogoSrc(section["PublicBaseUrl"], logoPath);
        var brandedHtml = BrandEmailLayout.EnsureBranded(subject, bodyHtml, logoSrc);

        var bannerCid = $"cid:{BrandEmailLayout.BannerContentId}";
        var usesBanner = brandedHtml.Contains(bannerCid, StringComparison.OrdinalIgnoreCase);
        var bannerPath = usesBanner ? ResolveAssetPath(BrandEmailLayout.BannerFileName) : null;
        if (usesBanner && bannerPath is null && !string.IsNullOrWhiteSpace(section["PublicBaseUrl"]))
        {
            brandedHtml = brandedHtml.Replace(
                bannerCid,
                $"{section["PublicBaseUrl"]!.TrimEnd('/')}/branding/{BrandEmailLayout.BannerFileName}",
                StringComparison.OrdinalIgnoreCase);
        }

        var usesLogo = brandedHtml.Contains($"cid:{BrandEmailLayout.LogoContentId}", StringComparison.OrdinalIgnoreCase);
        var embedLogo = usesLogo && !string.IsNullOrWhiteSpace(logoPath) && File.Exists(logoPath);

        using var client = new SmtpClient(smtpServer, smtpPort)
        {
            EnableSsl = enableSsl,
            Credentials = new NetworkCredential(senderEmail, senderPassword)
        };

        using var message = new MailMessage
        {
            From = new MailAddress(senderEmail, senderName),
            Subject = subject,
            IsBodyHtml = true
        };
        message.To.Add(toEmail);

        if (embedLogo || bannerPath is not null)
        {
            var htmlView = AlternateView.CreateAlternateViewFromString(brandedHtml, null, MediaTypeNames.Text.Html);
            if (embedLogo)
            {
                htmlView.LinkedResources.Add(new LinkedResource(logoPath!)
                {
                    ContentId = BrandEmailLayout.LogoContentId,
                    TransferEncoding = TransferEncoding.Base64,
                    ContentType = new ContentType("image/png") { Name = "logo.png" }
                });
            }

            if (bannerPath is not null)
            {
                htmlView.LinkedResources.Add(new LinkedResource(bannerPath)
                {
                    ContentId = BrandEmailLayout.BannerContentId,
                    TransferEncoding = TransferEncoding.Base64,
                    ContentType = new ContentType(MediaTypeNames.Image.Jpeg) { Name = BrandEmailLayout.BannerFileName }
                });
            }

            message.AlternateViews.Add(htmlView);
        }
        else
        {
            message.Body = brandedHtml;
        }

        cancellationToken.ThrowIfCancellationRequested();
        await client.SendMailAsync(message, cancellationToken);
    }

    private static string? BuildLogoSrc(string? publicBaseUrl, string? logoPath)
    {
        // Prefer CID when the logo file ships with the app (works offline for email clients).
        if (!string.IsNullOrWhiteSpace(logoPath) && File.Exists(logoPath))
        {
            return $"cid:{BrandEmailLayout.LogoContentId}";
        }

        if (string.IsNullOrWhiteSpace(publicBaseUrl))
        {
            return $"cid:{BrandEmailLayout.LogoContentId}";
        }

        return $"{publicBaseUrl.TrimEnd('/')}/branding/logo.png";
    }

    private static string? ResolveAssetPath(string fileName)
    {
        string[] candidates =
        [
            Path.Combine(AppContext.BaseDirectory, "Assets", fileName),
            Path.Combine(Directory.GetCurrentDirectory(), "Assets", fileName),
            Path.Combine(AppContext.BaseDirectory, "wwwroot", "branding", fileName),
            Path.Combine(Directory.GetCurrentDirectory(), "wwwroot", "branding", fileName),
        ];

        return candidates.FirstOrDefault(File.Exists);
    }

    private static string? ResolveLogoPath(string? configuredPath)
    {
        var candidates = new List<string>();

        if (!string.IsNullOrWhiteSpace(configuredPath))
        {
            candidates.Add(configuredPath);
            if (!Path.IsPathRooted(configuredPath))
            {
                candidates.Add(Path.GetFullPath(configuredPath));
                candidates.Add(Path.Combine(AppContext.BaseDirectory, configuredPath));
            }
        }

        candidates.Add(Path.Combine(AppContext.BaseDirectory, "Assets", "email-logo.png"));
        candidates.Add(Path.Combine(AppContext.BaseDirectory, "wwwroot", "branding", "logo.png"));
        candidates.Add(Path.Combine(Directory.GetCurrentDirectory(), "wwwroot", "branding", "logo.png"));
        candidates.Add(Path.Combine(Directory.GetCurrentDirectory(), "Assets", "email-logo.png"));

        foreach (var path in candidates)
        {
            if (!string.IsNullOrWhiteSpace(path) && File.Exists(path))
            {
                return path;
            }
        }

        return null;
    }
}
