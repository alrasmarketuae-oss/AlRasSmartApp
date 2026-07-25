using BusinessLayer.Interfaces;
using BusinessLayer.Services;

namespace BusinessLayer.Factories;

public class PasswordResetNotifierFactory
{
    private readonly Dictionary<string, IPasswordResetNotifier> _notifiers;

    public PasswordResetNotifierFactory(
        IEmailService emailService,
        ISmsService smsService)
    {
        _notifiers = new Dictionary<string, IPasswordResetNotifier>(StringComparer.OrdinalIgnoreCase)
        {
            ["Email"] = new EmailPasswordResetNotifier(emailService),
            ["Phone"] = new PhonePasswordResetNotifier(smsService)
        };
    }

    public IPasswordResetNotifier GetProvider(string providerName)
    {
        if (string.IsNullOrWhiteSpace(providerName))
        {
            throw new ArgumentException("Provider name is required.");
        }

        if (!_notifiers.TryGetValue(providerName, out var notifier))
        {
            throw new ArgumentException($"Unsupported provider '{providerName}'.");
        }

        return notifier;
    }
}
