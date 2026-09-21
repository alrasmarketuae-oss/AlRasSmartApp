using BusinessLayer.Helpers;
using BusinessLayer.Interfaces;
using DataLayer.Interfaces;
using DataLayer.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace BusinessLayer.Services;

/// <summary>
/// Issues verification OTPs and delivers them by SMS to the account phone (Twilio Sender ID).
/// Falls back to email only when the account has no usable phone number.
/// </summary>
public class EmailOtpService(
    IRasAlSouqDbContext dbContext,
    IEmailService emailService,
    ISmsService smsService,
    ILogger<EmailOtpService> logger) : IEmailOtpService
{
    private readonly IRasAlSouqDbContext _dbContext = dbContext;
    private readonly IEmailService _emailService = emailService;
    private readonly ISmsService _smsService = smsService;
    private readonly ILogger<EmailOtpService> _logger = logger;

    public async Task SendOtpAsync(string email, CancellationToken cancellationToken = default)
    {
        var normalizedEmail = email.Trim().ToLowerInvariant();
        var user = await _dbContext.Users
            .AsNoTracking()
            .Where(x => x.Email == normalizedEmail)
            .Select(x => new { x.PreferredLanguage, x.PhoneNumber })
            .FirstOrDefaultAsync(cancellationToken)
            ?? throw new KeyNotFoundException("No account found for this email.");

        var otp = Random.Shared.Next(100000, 1000000).ToString();

        var activeOtps = await _dbContext.EmailOtps
            .Where(x => x.Email == normalizedEmail && !x.IsUsed && x.ExpiresAt > DateTime.UtcNow)
            .ToListAsync(cancellationToken);

        foreach (var item in activeOtps)
        {
            item.IsUsed = true;
        }

        var entity = new EmailOtp
        {
            Email = normalizedEmail,
            Code = otp,
            ExpiresAt = DateTime.UtcNow.AddMinutes(10),
            IsUsed = false
        };
        await _dbContext.EmailOtps.AddAsync(entity, cancellationToken);
        await _dbContext.SaveChangesAsync(cancellationToken);

        var isArabic = NotificationMessages.IsArabic(user.PreferredLanguage);
        var phone = SmsService.NormalizeToE164(user.PhoneNumber);

        if (!string.IsNullOrWhiteSpace(phone))
        {
            var smsBody = isArabic
                ? $"رمز التحقق من الراس سمارت: {otp}. صالح لمدة 10 دقائق."
                : $"Your Al Ras verification code is {otp}. Expires in 10 minutes.";

            try
            {
                await _smsService.SendAsync(phone, smsBody, cancellationToken);
                return;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "SMS OTP failed for {Email} / {Phone}. Falling back to email.", normalizedEmail, phone);
            }
        }

        var subject = isArabic
            ? "تطبيق الراس - رمز التحقق"
            : "Al Ras App - Your verification code";
        var body = isArabic
            ? BrandEmailLayout.Headline("رمز التحقق") +
              BrandEmailLayout.Paragraph("استخدم الرمز التالي لإكمال التحقق على تطبيق الراس:") +
              BrandEmailLayout.CodeBlock(otp) +
              BrandEmailLayout.Paragraph("ينتهي هذا الرمز خلال 10 دقائق. إذا لم تطلب هذا الرمز، تجاهل الرسالة.")
            : BrandEmailLayout.Headline("Verification code") +
              BrandEmailLayout.Paragraph("Use the code below to verify your Al Ras account:") +
              BrandEmailLayout.CodeBlock(otp) +
              BrandEmailLayout.Paragraph("This code expires in 10 minutes. If you did not request it, you can ignore this email.");

        await _emailService.SendAsync(normalizedEmail, subject, body, cancellationToken);
    }

    public async Task<OtpVerificationStatus> VerifyOtpAsync(string email, string otp, CancellationToken cancellationToken = default)
    {
        var normalizedEmail = email.Trim().ToLowerInvariant();
        var code = otp.Trim();

        var otpEntity = await _dbContext.EmailOtps
            .Where(x => x.Email == normalizedEmail && x.Code == code && !x.IsUsed)
            .OrderByDescending(x => x.CreatedAt)
            .FirstOrDefaultAsync(cancellationToken);

        if (otpEntity is null)
        {
            return OtpVerificationStatus.Invalid;
        }

        if (otpEntity.ExpiresAt < DateTime.UtcNow)
        {
            return OtpVerificationStatus.Expired;
        }

        otpEntity.IsUsed = true;
        await _dbContext.SaveChangesAsync(cancellationToken);
        return OtpVerificationStatus.Valid;
    }
}
