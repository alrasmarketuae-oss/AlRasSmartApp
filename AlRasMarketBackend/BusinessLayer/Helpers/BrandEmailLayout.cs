using System.Net;
using System.Text.RegularExpressions;

namespace BusinessLayer.Helpers;

/// <summary>
/// Shared branded HTML wrapper for all customer emails (logo colors + app logo).
/// </summary>
public static class BrandEmailLayout
{
    public const string BrandMarker = "data-brand=\"rasalsouq\"";
    public const string LogoContentId = "rasalsouq-logo";

    /// <summary>Logo blue</summary>
    public const string Blue = "#3376C2";

    /// <summary>Logo red</summary>
    public const string Red = "#BE362F";

    /// <summary>Logo green</summary>
    public const string Green = "#5A9652";

    public const string Ink = "#0f172a";
    public const string Muted = "#64748b";
    public const string SoftBg = "#f3f7fb";

    public static string EnsureBranded(string subject, string bodyHtml, string? logoSrc = null)
    {
        if (string.IsNullOrWhiteSpace(bodyHtml))
        {
            return Wrap(subject, "<p></p>", logoSrc);
        }

        if (bodyHtml.Contains(BrandMarker, StringComparison.OrdinalIgnoreCase))
        {
            return bodyHtml;
        }

        var content = ExtractBodyInnerHtml(bodyHtml) ?? bodyHtml.Trim();
        return Wrap(subject, content, logoSrc);
    }

    public static string Wrap(string subject, string innerHtml, string? logoSrc = null, string? footerNote = null)
    {
        var rtl = ContainsArabic($"{subject}\n{innerHtml}");
        var dir = rtl ? "rtl" : "ltr";
        var lang = rtl ? "ar" : "en";
        var safeTitle = WebUtility.HtmlEncode(string.IsNullOrWhiteSpace(subject) ? "Al Ras App" : subject.Trim());
        var logo = string.IsNullOrWhiteSpace(logoSrc) ? $"cid:{LogoContentId}" : logoSrc.Trim();
        var footer = WebUtility.HtmlEncode(
            footerNote
            ?? (rtl
                ? "هذه رسالة تلقائية من تطبيق الراس. يمكنك متابعة كل شيء من التطبيق."
                : "This is an automated message from Al Ras App. Open the app to manage your account."));

        var brandAr = rtl ? "تطبيق الراس" : "Al Ras App";
        var brandEn = rtl ? "Al Ras App" : "تطبيق الراس";

        return $$"""
<!DOCTYPE html>
<html lang="{{lang}}" dir="{{dir}}">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <meta name="color-scheme" content="light" />
  <title>{{safeTitle}}</title>
</head>
<body style="margin:0;padding:0;background:{{SoftBg}};font-family:'Segoe UI',Tahoma,'Noto Sans Arabic',Arial,sans-serif;color:{{Ink}};-webkit-text-size-adjust:100%;">
  <table role="presentation" {{BrandMarker}} width="100%" cellspacing="0" cellpadding="0" style="background:{{SoftBg}};padding:28px 12px;">
    <tr>
      <td align="center">
        <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="max-width:580px;background:#ffffff;border-radius:22px;overflow:hidden;box-shadow:0 14px 42px rgba(51,118,194,0.12);">
          <tr>
            <td style="padding:0;line-height:0;font-size:0;">
              <table role="presentation" width="100%" cellspacing="0" cellpadding="0">
                <tr>
                  <td width="34%" height="6" style="background:{{Blue}};"></td>
                  <td width="32%" height="6" style="background:{{Red}};"></td>
                  <td width="34%" height="6" style="background:{{Green}};"></td>
                </tr>
              </table>
            </td>
          </tr>
          <tr>
            <td style="background:linear-gradient(135deg,{{Blue}} 0%,#2f6aad 48%,{{Green}} 100%);padding:26px 24px 22px;text-align:center;">
              <img src="{{logo}}" alt="Al Ras App" width="72" height="72" style="display:block;margin:0 auto 12px;width:72px;height:72px;border-radius:18px;border:3px solid rgba(255,255,255,0.85);background:#000000;object-fit:contain;" />
              <div style="font-size:24px;font-weight:800;color:#ffffff;letter-spacing:0.2px;line-height:1.25;">{{brandAr}}</div>
              <div style="font-size:13px;color:rgba(255,255,255,0.92);margin-top:6px;font-weight:600;">{{brandEn}}</div>
            </td>
          </tr>
          <tr>
            <td style="padding:28px 26px 8px;font-size:15px;line-height:1.75;color:#334155;">
              {{innerHtml}}
            </td>
          </tr>
          <tr>
            <td style="padding:8px 26px 26px;text-align:center;">
              <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="margin-top:8px;">
                <tr>
                  <td width="34%" height="3" style="background:{{Blue}};border-radius:3px 0 0 3px;"></td>
                  <td width="32%" height="3" style="background:{{Red}};"></td>
                  <td width="34%" height="3" style="background:{{Green}};border-radius:0 3px 3px 0;"></td>
                </tr>
              </table>
              <p style="margin:16px 0 0;font-size:12px;line-height:1.65;color:#94a3b8;">{{footer}}</p>
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>
""";
    }

    public static string Headline(string text) =>
        $"<h1 style=\"margin:0 0 14px;font-size:22px;line-height:1.4;color:{Ink};font-weight:800;\">{WebUtility.HtmlEncode(text)}</h1>";

    public static string Paragraph(string text) =>
        $"<p style=\"margin:0 0 14px;font-size:15px;line-height:1.75;color:#334155;\">{WebUtility.HtmlEncode(text)}</p>";

    public static string HtmlParagraph(string html) =>
        $"<p style=\"margin:0 0 14px;font-size:15px;line-height:1.75;color:#334155;\">{html}</p>";

    public static string CodeBlock(string code)
    {
        var safe = WebUtility.HtmlEncode(code);
        return $"""
<div style="margin:18px 0 20px;text-align:center;">
  <div style="display:inline-block;padding:14px 28px;border-radius:14px;background:#eef5fc;border:2px solid {Blue};color:{Blue};font-size:28px;font-weight:800;letter-spacing:6px;font-family:Consolas,'Courier New',monospace;">
    {safe}
  </div>
</div>
""";
    }

    public static string InfoCard(string label, string value)
    {
        return $"""
<table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="margin:0 0 16px;background:#f8fbff;border:1px solid #d7e6f5;border-radius:14px;">
  <tr>
    <td style="padding:14px 16px;font-size:13px;color:{Muted};width:40%;">{WebUtility.HtmlEncode(label)}</td>
    <td style="padding:14px 16px;font-size:14px;font-weight:700;color:{Ink};text-align:start;">{WebUtility.HtmlEncode(value)}</td>
  </tr>
</table>
""";
    }

    public static string StatusPill(string text, string? background = null)
    {
        var bg = background ?? Blue;
        return $"""
<div style="display:inline-block;padding:8px 14px;border-radius:999px;background:{bg};color:#ffffff;font-size:13px;font-weight:700;margin:0 0 18px;">
  {WebUtility.HtmlEncode(text)}
</div>
""";
    }

    public static bool ContainsArabic(string? value)
    {
        if (string.IsNullOrEmpty(value))
        {
            return false;
        }

        foreach (var ch in value)
        {
            if (ch is >= '\u0600' and <= '\u06FF'
                or >= '\u0750' and <= '\u077F'
                or >= '\u08A0' and <= '\u08FF'
                or >= '\uFB50' and <= '\uFDFF'
                or >= '\uFE70' and <= '\uFEFF')
            {
                return true;
            }
        }

        return false;
    }

    private static string? ExtractBodyInnerHtml(string html)
    {
        if (!html.Contains("<html", StringComparison.OrdinalIgnoreCase) &&
            !html.Contains("<!DOCTYPE", StringComparison.OrdinalIgnoreCase))
        {
            return null;
        }

        var match = Regex.Match(
            html,
            @"<body[^>]*>(.*)</body>",
            RegexOptions.IgnoreCase | RegexOptions.Singleline);
        return match.Success ? match.Groups[1].Value.Trim() : null;
    }
}
