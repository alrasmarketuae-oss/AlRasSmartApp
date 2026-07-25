using System.Net.Http.Json;
using BusinessLayer.Interfaces;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;

namespace BusinessLayer.Services;

public class SmsService(HttpClient httpClient, IConfiguration configuration, ILogger<SmsService> logger) : ISmsService
{
    private readonly HttpClient _httpClient = httpClient;
    private readonly IConfiguration _configuration = configuration;
    private readonly ILogger<SmsService> _logger = logger;

    public async Task SendAsync(string phoneNumber, string message, CancellationToken cancellationToken = default)
    {
        var section = _configuration.GetSection("SmsSettings");
        var providerUrl = section["ProviderUrl"];
        var apiKey = section["ApiKey"];
        var senderId = section["SenderId"] ?? "AlRasMarket";

        if (string.IsNullOrWhiteSpace(providerUrl) || string.IsNullOrWhiteSpace(apiKey))
        {
            throw new InvalidOperationException("SmsSettings are not configured.");
        }

        var payload = new
        {
            to = phoneNumber,
            message,
            senderId
        };

        using var request = new HttpRequestMessage(HttpMethod.Post, providerUrl)
        {
            Content = JsonContent.Create(payload)
        };
        request.Headers.Add("X-Api-Key", apiKey);

        using var response = await _httpClient.SendAsync(request, cancellationToken);
        if (!response.IsSuccessStatusCode)
        {
            var body = await response.Content.ReadAsStringAsync(cancellationToken);
            _logger.LogError("SMS provider failed. Status: {StatusCode}. Body: {Body}", response.StatusCode, body);
            throw new InvalidOperationException("Failed to send SMS notification.");
        }
    }
}
