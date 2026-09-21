using System.Net.Http.Headers;
using System.Text;
using BusinessLayer.Interfaces;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;

namespace BusinessLayer.Services;

/// <summary>
/// Sends SMS via Twilio REST API using an alphanumeric Sender ID (e.g. AL RAS SMART).
/// </summary>
public class SmsService(HttpClient httpClient, IConfiguration configuration, ILogger<SmsService> logger) : ISmsService
{
    private readonly HttpClient _httpClient = httpClient;
    private readonly IConfiguration _configuration = configuration;
    private readonly ILogger<SmsService> _logger = logger;

    public async Task SendAsync(string phoneNumber, string message, CancellationToken cancellationToken = default)
    {
        var section = _configuration.GetSection("SmsSettings");
        var accountSid = section["AccountSid"]?.Trim();
        var authToken = section["AuthToken"]?.Trim();
        var from = section["From"]?.Trim()
            ?? section["SenderId"]?.Trim()
            ?? "AL RAS SMART";

        if (string.IsNullOrWhiteSpace(accountSid) || string.IsNullOrWhiteSpace(authToken))
        {
            throw new InvalidOperationException("SmsSettings are not configured.");
        }

        var to = NormalizeToE164(phoneNumber);
        if (string.IsNullOrWhiteSpace(to))
        {
            throw new ArgumentException("A valid phone number is required to send SMS.");
        }

        var url = $"https://api.twilio.com/2010-04-01/Accounts/{accountSid}/Messages.json";
        using var request = new HttpRequestMessage(HttpMethod.Post, url);
        var credentials = Convert.ToBase64String(Encoding.ASCII.GetBytes($"{accountSid}:{authToken}"));
        request.Headers.Authorization = new AuthenticationHeaderValue("Basic", credentials);
        request.Content = new FormUrlEncodedContent(new Dictionary<string, string>
        {
            ["To"] = to,
            ["From"] = from,
            ["Body"] = message
        });

        using var response = await _httpClient.SendAsync(request, cancellationToken);
        var body = await response.Content.ReadAsStringAsync(cancellationToken);
        if (!response.IsSuccessStatusCode)
        {
            _logger.LogError(
                "Twilio SMS failed. Status: {StatusCode}. To: {To}. Body: {Body}",
                response.StatusCode,
                to,
                body);
            throw new InvalidOperationException("Failed to send SMS notification.");
        }

        _logger.LogInformation("Twilio SMS sent to {To} from {From}", to, from);
    }

    /// <summary>
    /// Normalizes UAE-local and international numbers to E.164 (+971...).
    /// </summary>
    internal static string NormalizeToE164(string? phoneNumber)
    {
        if (string.IsNullOrWhiteSpace(phoneNumber))
        {
            return string.Empty;
        }

        var raw = phoneNumber.Trim().Replace(" ", string.Empty).Replace("-", string.Empty);
        if (raw.StartsWith("00", StringComparison.Ordinal))
        {
            raw = "+" + raw[2..];
        }

        var digits = new string(raw.Where(char.IsDigit).ToArray());
        if (raw.StartsWith('+'))
        {
            return "+" + digits;
        }

        // Local UAE mobile: 05xxxxxxxx / 5xxxxxxxx
        if (digits.StartsWith("971", StringComparison.Ordinal))
        {
            return "+" + digits;
        }

        if (digits.StartsWith('0') && digits.Length >= 9)
        {
            return "+971" + digits.TrimStart('0');
        }

        if (digits.StartsWith('5') && digits.Length == 9)
        {
            return "+971" + digits;
        }

        return digits.Length >= 8 ? "+" + digits : string.Empty;
    }
}
