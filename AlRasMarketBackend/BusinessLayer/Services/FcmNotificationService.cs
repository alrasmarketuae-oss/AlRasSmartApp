using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using BusinessLayer.Interfaces;
using Google.Apis.Auth.OAuth2;
using Google.Apis.Util;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;

namespace BusinessLayer.Services;

public class FcmNotificationService : IFcmNotificationService
{
    private const string Scope = "https://www.googleapis.com/auth/firebase.messaging";
    private readonly IHttpClientFactory _httpClientFactory;
    private readonly ILogger<FcmNotificationService> _logger;
    private readonly ServiceAccountCredential? _credential;
    private readonly string? _projectId;

    public FcmNotificationService(IConfiguration configuration, IHttpClientFactory httpClientFactory, ILogger<FcmNotificationService> logger)
    {
        _httpClientFactory = httpClientFactory;
        _logger = logger;

        var section = configuration.GetSection("Firebase");
        _projectId = section["ProjectId"] ?? section["project_id"];
        var clientEmail = section["ClientEmail"] ?? section["client_email"];
        var privateKey = section["PrivateKey"] ?? section["private_key"];

        if (!string.IsNullOrWhiteSpace(clientEmail) && !string.IsNullOrWhiteSpace(privateKey))
        {
            var initializer = new ServiceAccountCredential.Initializer(clientEmail)
            {
                Scopes = new[] { Scope },
                Clock = SystemClock.Default
            }.FromPrivateKey(privateKey.Replace("\\n", "\n"));
            _credential = new ServiceAccountCredential(initializer);
        }
    }

    public async Task SendNotificationAsync(string fcmToken, FcmNotificationPayload payload, CancellationToken ct = default)
    {
        if (_credential is null || string.IsNullOrWhiteSpace(_projectId))
        {
            throw new InvalidOperationException("Firebase is not configured.");
        }

        var accessToken = await _credential.GetAccessTokenForRequestAsync(cancellationToken: ct);
        var endpoint = $"https://fcm.googleapis.com/v1/projects/{_projectId}/messages:send";

        var data = new Dictionary<string, string>
        {
            ["title"] = payload.Title ?? string.Empty,
            ["body"] = payload.Body ?? string.Empty,
        };
        if (!string.IsNullOrWhiteSpace(payload.Type))
        {
            data["type"] = payload.Type;
        }

        if (!string.IsNullOrWhiteSpace(payload.RouteId))
        {
            data["routeId"] = payload.RouteId;
        }

        if (!string.IsNullOrWhiteSpace(payload.ReferenceId))
        {
            data["referenceId"] = payload.ReferenceId;
        }

        if (payload.Data is not null)
        {
            foreach (var (key, value) in payload.Data)
            {
                if (!string.IsNullOrWhiteSpace(key) && !string.IsNullOrWhiteSpace(value))
                {
                    data[key] = value;
                }
            }
        }

        // Mobile app channel `app_alerts` uses notification_ding (same as web).
        var body = new
        {
            message = new
            {
                token = fcmToken,
                notification = new { title = payload.Title, body = payload.Body },
                data,
                android = new
                {
                    priority = "HIGH",
                    notification = new
                    {
                        channel_id = "app_alerts",
                        sound = "notification_ding",
                        default_sound = false
                    }
                },
                apns = new
                {
                    payload = new
                    {
                        aps = new
                        {
                            sound = "notification_ding.mp3"
                        }
                    }
                }
            }
        };

        var client = _httpClientFactory.CreateClient();
        using var request = new HttpRequestMessage(HttpMethod.Post, endpoint);
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", accessToken);
        request.Content = new StringContent(JsonSerializer.Serialize(body), Encoding.UTF8, "application/json");

        var response = await client.SendAsync(request, ct);
        if (!response.IsSuccessStatusCode)
        {
            var content = await response.Content.ReadAsStringAsync(ct);
            _logger.LogError("FCM failed with status {Status}: {Body}", response.StatusCode, content);
            throw new HttpRequestException($"FCM failed: {(int)response.StatusCode}");
        }
    }
}
