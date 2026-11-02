using System.Net;
using System.Text.RegularExpressions;

namespace BusinessLayer.Helpers;

/// <summary>
/// Shared branded HTML wrapper for all customer emails (Merge Spice).
/// </summary>
public static class BrandEmailLayout
{
    public const string BrandMarker = "data-brand=\"mergespice\"";
    public const string LogoContentId = "mergespice-logo";
    public const string BannerContentId = "mergespice-banner";
    public const string BannerFileName = "email-banner.jpg";

    public const string BrandNameEn = "Merge Spice";
    public const string BrandNameAr = "ميرج سبايس";
    public const string CompanyLegal = "Merge Spice Foodstuff Trading LLC";
    public const string CompanyTagline = "Wholesale Spices • B2B Trading";

    /// <summary>Brand green (Merge)</summary>
    public const string Green = "#2F6B45";

    /// <summary>Deep green for headings</summary>
    public const string GreenDark = "#1B4D32";

    /// <summary>Soft green for OTP card</summary>
    public const string GreenSoft = "#E8F3EC";

    /// <summary>Brand red accent</summary>
    public const string Red = "#C0392B";

    /// <summary>Legacy alias — maps to brand green</summary>
    public const string Blue = Green;

    public const string Ink = "#1A1A1A";
    public const string Muted = "#6B7280";
    public const string SoftBg = "#F7F3EC";
    public const string CardBg = "#FFFFFF";

    public static string EnsureBranded(string subject, string bodyHtml, string? logoSrc = null)
    {
        if (string.IsNullOrWhiteSpace(bodyHtml))
        {
            return Wrap(subject, "<p></p>", logoSrc);
        }

        // Already branded (new or previous marker)
        if (bodyHtml.Contains(BrandMarker, StringComparison.OrdinalIgnoreCase) ||
            bodyHtml.Contains("data-brand=\"rasalsouq\"", StringComparison.OrdinalIgnoreCase))
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
        var brand = rtl ? BrandNameAr : BrandNameEn;
        var safeTitle = WebUtility.HtmlEncode(string.IsNullOrWhiteSpace(subject) ? BrandNameEn : subject.Trim());
        var logo = string.IsNullOrWhiteSpace(logoSrc) ? $"cid:{LogoContentId}" : logoSrc.Trim();
        var footer = WebUtility.HtmlEncode(
            footerNote
            ?? (rtl
                ? $"هذه رسالة تلقائية من {BrandNameAr}. يمكنك متابعة كل شيء من التطبيق."
                : $"This is an automated message from {BrandNameEn}. Open the app to manage your account."));

        return $$"""
<!DOCTYPE html>
<html lang="{{lang}}" dir="{{dir}}">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <meta name="color-scheme" content="light" />
  <title>{{safeTitle}}</title>
</head>
<body style="margin:0;padding:0;background:{{SoftBg}};font-family:Arial,Helvetica,'Segoe UI',Tahoma,'Noto Sans Arabic',sans-serif;color:{{Ink}};-webkit-text-size-adjust:100%;">
  <table role="presentation" {{BrandMarker}} width="100%" cellspacing="0" cellpadding="0" style="background:{{SoftBg}};padding:28px 12px;">
    <tr>
      <td align="center">
        <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="max-width:580px;background:{{CardBg}};border-radius:20px;overflow:hidden;box-shadow:0 12px 36px rgba(31,77,50,0.10);">
          <tr>
            <td style="padding:28px 24px 12px;text-align:center;background:{{CardBg}};">
              <img src="{{logo}}" alt="{{BrandNameEn}}" width="120" style="display:block;margin:0 auto;width:120px;max-width:160px;height:auto;border:0;" />
              <p style="margin:14px 0 0;font-family:Georgia,'Times New Roman',serif;font-size:22px;font-weight:700;color:{{Ink}};letter-spacing:0.02em;">{{WebUtility.HtmlEncode(brand)}}</p>
            </td>
          </tr>
          <tr>
            <td style="padding:18px 26px 8px;font-size:15px;line-height:1.75;color:#334155;">
              {{innerHtml}}
            </td>
          </tr>
          <tr>
            <td style="padding:8px 26px 28px;text-align:center;">
              <div style="height:1px;background:#E5E7EB;margin:8px 0 16px;"></div>
              <p style="margin:0 0 4px;font-size:13px;font-weight:700;color:{{Ink}};">{{WebUtility.HtmlEncode(CompanyLegal)}}</p>
              <p style="margin:0 0 12px;font-size:12px;color:{{Muted}};">{{WebUtility.HtmlEncode(CompanyTagline)}}</p>
              <p style="margin:0;font-size:12px;line-height:1.65;color:#94a3b8;">{{footer}}</p>
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

    /// <summary>
    /// OTP email matching the Merge Spice verification design:
    /// cream canvas, logo + brand, green shield, code card, legal footer.
    /// </summary>
    public static string VerificationCodeEmail(string subject, string code, bool isArabic)
    {
        var dir = isArabic ? "rtl" : "ltr";
        var lang = isArabic ? "ar" : "en";
        var safeTitle = WebUtility.HtmlEncode(subject);
        var safeCode = WebUtility.HtmlEncode(code);
        var spacedCode = WebUtility.HtmlEncode(string.Join(' ', code.Trim().ToCharArray()));
        var brand = isArabic ? BrandNameAr : BrandNameEn;

        var headline = isArabic ? "تحقق من بريدك الإلكتروني" : "Verify your email";
        var welcome = isArabic
            ? $"مرحباً بك في {brand}!"
            : $"Welcome to {BrandNameEn}!";
        var intro = isArabic
            ? "استخدم رمز التحقق أدناه لإكمال التسجيل."
            : "Use the verification code below to complete your registration.";
        var codeLabel = isArabic ? "رمز التحقق الخاص بك" : "YOUR VERIFICATION CODE";
        var expiry = isArabic
            ? "ينتهي هذا الرمز خلال 10 دقائق."
            : "This code expires in 10 minutes.";
        var security = isArabic
            ? "لحمايتك، لا تشارك هذا الرمز مع أي شخص."
            : "For your security, do not share this code with anyone.";
        var ignore = isArabic
            ? "لم تطلب هذا الرمز؟ يمكنك تجاهل هذه الرسالة بأمان."
            : "Didn't request this code? You can safely ignore this email.";
        var preheader = isArabic
            ? $"رمز التحقق الخاص بك: {safeCode}"
            : $"Your verification code is {safeCode}";
        // Plain line for OS autofill / keyboard suggestion
        var autofillLine = isArabic
            ? $"رمز التحقق: {safeCode}"
            : $"Verification code: {safeCode}";

        return $$"""
<!DOCTYPE html>
<html lang="{{lang}}" dir="{{dir}}">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <meta name="color-scheme" content="light" />
  <title>{{safeTitle}}</title>
</head>
<body style="margin:0;padding:0;background:{{SoftBg}};font-family:Arial,Helvetica,'Segoe UI',Tahoma,'Noto Sans Arabic',sans-serif;color:{{Ink}};-webkit-text-size-adjust:100%;">
  <div style="display:none;max-height:0;overflow:hidden;opacity:0;color:transparent;">{{preheader}}</div>
  <table role="presentation" {{BrandMarker}} width="100%" cellspacing="0" cellpadding="0" style="background:{{SoftBg}};padding:32px 12px;">
    <tr>
      <td align="center">
        <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="max-width:560px;background:{{CardBg}};border-radius:18px;overflow:hidden;box-shadow:0 10px 32px rgba(27,77,50,0.08);">
          <tr>
            <td style="padding:36px 28px 8px;text-align:center;">
              <img src="cid:{{LogoContentId}}" alt="{{BrandNameEn}}" width="140" style="display:block;margin:0 auto;width:140px;max-width:180px;height:auto;border:0;" />
              <p style="margin:16px 0 0;font-family:Georgia,'Times New Roman',serif;font-size:24px;line-height:1.2;font-weight:700;color:{{Ink}};">{{WebUtility.HtmlEncode(brand)}}</p>
            </td>
          </tr>
          <tr>
            <td style="padding:22px 28px 0;text-align:center;">
              <div style="display:inline-block;width:42px;height:42px;border-radius:50%;background:{{Green}};line-height:42px;text-align:center;">
                <span style="color:#ffffff;font-size:22px;font-weight:700;">&#10003;</span>
              </div>
              <h1 style="margin:16px 0 10px;font-family:Georgia,'Times New Roman',serif;font-size:30px;line-height:1.25;font-weight:700;color:{{GreenDark}};">{{WebUtility.HtmlEncode(headline)}}</h1>
              <p style="margin:0 0 6px;font-size:17px;font-weight:700;color:{{Ink}};">{{WebUtility.HtmlEncode(welcome)}}</p>
              <p style="margin:0;font-size:15px;line-height:1.6;color:{{Muted}};">{{WebUtility.HtmlEncode(intro)}}</p>
            </td>
          </tr>
          <tr>
            <td style="padding:26px 28px 8px;" align="center">
              <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="max-width:360px;background:{{GreenSoft}};border-radius:16px;">
                <tr>
                  <td style="padding:22px 20px;text-align:center;">
                    <p style="margin:0 0 12px;font-size:11px;letter-spacing:0.14em;font-weight:700;color:{{GreenDark}};text-transform:uppercase;">{{WebUtility.HtmlEncode(codeLabel)}}</p>
                    <p dir="ltr" style="margin:0;font-size:36px;line-height:1.15;font-weight:800;letter-spacing:0.28em;color:{{Ink}};font-family:Georgia,'Times New Roman',serif;">{{spacedCode}}</p>
                  </td>
                </tr>
              </table>
            </td>
          </tr>
          <tr>
            <td style="padding:18px 28px 6px;text-align:center;">
              <p style="margin:0 0 8px;font-size:15px;font-weight:700;color:{{Ink}};">{{WebUtility.HtmlEncode(expiry)}}</p>
              <p style="margin:0;font-size:13px;line-height:1.55;color:{{Muted}};">{{WebUtility.HtmlEncode(security)}}</p>
              <p dir="ltr" style="margin:16px 0 0;font-size:14px;color:{{GreenDark}};font-weight:600;">{{WebUtility.HtmlEncode(autofillLine)}}</p>
            </td>
          </tr>
          <tr>
            <td style="padding:24px 28px 32px;text-align:center;">
              <div style="height:1px;background:#E5E7EB;margin:0 0 16px;"></div>
              <p style="margin:0 0 18px;font-size:13px;line-height:1.55;color:{{Muted}};">{{WebUtility.HtmlEncode(ignore)}}</p>
              <div style="height:1px;background:#E5E7EB;margin:0 0 16px;"></div>
              <p style="margin:0 0 4px;font-size:14px;font-weight:700;color:{{Ink}};">{{WebUtility.HtmlEncode(CompanyLegal)}}</p>
              <p style="margin:0;font-size:12px;color:{{Muted}};">{{WebUtility.HtmlEncode(CompanyTagline)}}</p>
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
        $"<h1 style=\"margin:0 0 14px;font-size:22px;line-height:1.4;color:{GreenDark};font-family:Georgia,'Times New Roman',serif;font-weight:700;\">{WebUtility.HtmlEncode(text)}</h1>";

    public static string Paragraph(string text) =>
        $"<p style=\"margin:0 0 14px;font-size:15px;line-height:1.75;color:#334155;\">{WebUtility.HtmlEncode(text)}</p>";

    public static string HtmlParagraph(string html) =>
        $"<p style=\"margin:0 0 14px;font-size:15px;line-height:1.75;color:#334155;\">{html}</p>";

    public static string CodeBlock(string code)
    {
        var spaced = WebUtility.HtmlEncode(string.Join(' ', code.Trim().ToCharArray()));
        return $"""
<div style="margin:18px 0 20px;text-align:center;">
  <div style="display:inline-block;padding:18px 28px;border-radius:14px;background:{GreenSoft};color:{Ink};font-size:28px;font-weight:800;letter-spacing:0.28em;font-family:Georgia,'Times New Roman',serif;">
    {spaced}
  </div>
</div>
""";
    }

    public static string InfoCard(string label, string value)
    {
        return $"""
<table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="margin:0 0 16px;background:{GreenSoft};border:1px solid #D5E8DB;border-radius:14px;">
  <tr>
    <td style="padding:14px 16px;font-size:13px;color:{Muted};width:40%;">{WebUtility.HtmlEncode(label)}</td>
    <td style="padding:14px 16px;font-size:14px;font-weight:700;color:{Ink};text-align:start;">{WebUtility.HtmlEncode(value)}</td>
  </tr>
</table>
""";
    }

    public static string StatusPill(string text, string? background = null)
    {
        var bg = background ?? Green;
        return $"""
<div style="display:inline-block;padding:8px 14px;border-radius:999px;background:{bg};color:#ffffff;font-size:13px;font-weight:700;margin:0 0 18px;">
  {WebUtility.HtmlEncode(text)}
</div>
""";
    }

    /// Vertical tracking timeline (ordered step + status history), aligned with app/dashboard.
    public static string Timeline(
        IReadOnlyList<(string Label, string? Date, bool IsLatest)> steps,
        bool rtl)
    {
        if (steps.Count == 0)
        {
            return string.Empty;
        }

        var title = rtl ? "تتبع الطلب" : "Order tracking";
        var align = rtl ? "right" : "left";
        var sb = new System.Text.StringBuilder();
        sb.Append(
            $"""<div style="margin:22px 0 6px;text-align:{align};"><p style="margin:0 0 14px;font-size:14px;font-weight:800;color:{Ink};">{WebUtility.HtmlEncode(title)}</p>""");

        for (var i = 0; i < steps.Count; i++)
        {
            var (label, date, isLatest) = steps[i];
            var dot = isLatest ? Green : GreenDark;
            var weight = isLatest ? "800" : "600";
            var color = isLatest ? Green : Ink;
            var dateHtml = string.IsNullOrWhiteSpace(date)
                ? string.Empty
                : $"""<div style="font-size:12px;color:{Muted};margin-top:4px;">{WebUtility.HtmlEncode(date)}</div>""";

            sb.Append(
                $"""
<table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="margin:0 0 4px;">
  <tr>
    <td width="24" valign="top" style="padding-top:3px;">
      <div style="width:11px;height:11px;border-radius:50%;background:{dot};margin:0 auto;"></div>
    </td>
    <td style="padding:0 0 12px 10px;border-left:2px solid #D5E8DB;">
      <div style="font-size:14px;font-weight:{weight};color:{color};line-height:1.45;">{WebUtility.HtmlEncode(label)}</div>
      {dateHtml}
    </td>
  </tr>
</table>
""");
        }

        sb.Append("</div>");
        return sb.ToString();
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
