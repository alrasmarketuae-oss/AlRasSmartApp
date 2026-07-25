namespace BusinessLayer.Interfaces;

public interface IEmailOtpService
{
    Task SendOtpAsync(string email, CancellationToken cancellationToken = default);
    Task<OtpVerificationStatus> VerifyOtpAsync(string email, string otp, CancellationToken cancellationToken = default);
}

public enum OtpVerificationStatus
{
    Valid = 1,
    Invalid = 2,
    Expired = 3
}
