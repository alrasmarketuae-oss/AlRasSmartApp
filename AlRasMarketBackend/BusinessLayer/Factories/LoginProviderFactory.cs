using BusinessLayer.Interfaces;
using BusinessLayer.LoginProviders;
using DataLayer.Interfaces;
using Microsoft.Extensions.Configuration;

namespace BusinessLayer.Factories;

public class LoginProviderFactory
{
    private readonly Dictionary<string, ILoginProvider> _providers;

    public LoginProviderFactory(
        IUserRepository userRepository,
        IPasswordHasher passwordHasher,
        IConfiguration configuration,
        IHttpClientFactory httpClientFactory)
    {
        _providers = new Dictionary<string, ILoginProvider>(StringComparer.OrdinalIgnoreCase)
        {
            ["Local"] = new LocalProvider(userRepository, passwordHasher),
            ["Google"] = new GoogleProvider(userRepository, configuration),
            ["Apple"] = new AppleProvider(userRepository, configuration, httpClientFactory),
            ["Facebook"] = new FacebookProvider(userRepository, httpClientFactory)
        };
    }

    public ILoginProvider GetProvider(string providerName)
    {
        if (string.IsNullOrWhiteSpace(providerName))
        {
            throw new ArgumentException("Provider name is required.");
        }

        if (!_providers.TryGetValue(providerName, out var provider))
        {
            throw new ArgumentException($"Unknown login provider: {providerName}");
        }

        return provider;
    }
}
