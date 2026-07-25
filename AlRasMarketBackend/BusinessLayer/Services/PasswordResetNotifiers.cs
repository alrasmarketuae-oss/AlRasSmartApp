using BusinessLayer.Helpers;
using BusinessLayer.Interfaces;
using DataLayer.Models;

namespace BusinessLayer.Services;

public class EmailPasswordResetNotifier(IEmailService emailService) : IPasswordResetNotifier
{
    public string ProviderName => "Email";

    public async Task SendCodeAsync(User user, string destination, string code, CancellationToken cancellationToken = default)
    {
        var isArabic = NotificationMessages.IsArabic(user.PreferredLanguage);
        var subject = isArabic
            ? "تطبيق الراس - رمز إعادة تعيين كلمة المرور"
            : "Al Ras App - Password reset code";
        var body = isArabic
            ? BrandEmailLayout.Headline("إعادة تعيين كلمة المرور") +
              BrandEmailLayout.Paragraph("رمز إعادة تعيين كلمة المرور لحسابك على تطبيق الراس:") +
              BrandEmailLayout.CodeBlock(code) +
              BrandEmailLayout.Paragraph("ينتهي الرمز خلال 10 دقائق. إذا لم تطلب ذلك، تجاهل الرسالة.")
            : BrandEmailLayout.Headline("Password reset") +
              BrandEmailLayout.Paragraph("Your Al Ras App password reset code:") +
              BrandEmailLayout.CodeBlock(code) +
              BrandEmailLayout.Paragraph("This code expires in 10 minutes. If you did not request a reset, ignore this email.");

        await emailService.SendAsync(destination, subject, body, cancellationToken);
    }
}

public class PhonePasswordResetNotifier(ISmsService smsService) : IPasswordResetNotifier
{
    public string ProviderName => "Phone";

    public async Task SendCodeAsync(User user, string destination, string code, CancellationToken cancellationToken = default)
    {
        var message = NotificationMessages.IsArabic(user.PreferredLanguage)
            ? $"رمز إعادة تعيين كلمة المرور في تطبيق الراس: {code}. ينتهي خلال 10 دقائق."
            : $"Al Ras App password reset code: {code}. Expires in 10 minutes.";

        await smsService.SendAsync(destination, message, cancellationToken);
    }
}
