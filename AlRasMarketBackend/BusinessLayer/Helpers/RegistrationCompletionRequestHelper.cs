using System.Text.Json;
using System.Text.Json.Serialization;

namespace BusinessLayer.Helpers;

/// <summary>
/// Admin request for a pending company to complete missing registration data
/// (location and/or licence/images) without deleting the account.
/// </summary>
public sealed class RegistrationCompletionRequest
{
    public bool MissingLocation { get; set; }
    public bool MissingImages { get; set; }
    public bool MissingDocuments { get; set; }
    public string? Message { get; set; }
    public DateTime RequestedAtUtc { get; set; } = DateTime.UtcNow;

    [JsonIgnore]
    public bool HasAnyMissing => MissingLocation || MissingImages || MissingDocuments;
}

public static class RegistrationCompletionRequestHelper
{
    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
        PropertyNameCaseInsensitive = true,
        DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull,
        WriteIndented = false
    };

    public static string Serialize(RegistrationCompletionRequest request) =>
        JsonSerializer.Serialize(request, JsonOptions);

    public static RegistrationCompletionRequest? TryParse(string? raw)
    {
        if (string.IsNullOrWhiteSpace(raw))
        {
            return null;
        }

        try
        {
            return JsonSerializer.Deserialize<RegistrationCompletionRequest>(raw, JsonOptions);
        }
        catch
        {
            return null;
        }
    }

    public static string BuildUserFacingMessage(RegistrationCompletionRequest request, string? language)
    {
        var isAr = NotificationMessages.IsArabic(language);
        var parts = new List<string>();
        if (request.MissingLocation)
        {
            parts.Add(isAr ? "الموقع / العنوان" : "location / address");
        }

        if (request.MissingDocuments)
        {
            parts.Add(isAr ? "الرخصة / المستندات" : "licence / documents");
        }

        if (request.MissingImages)
        {
            parts.Add(isAr ? "صور الشركة" : "company images");
        }

        var missingText = parts.Count == 0
            ? (isAr ? "بيانات التسجيل" : "registration details")
            : string.Join(isAr ? " و" : " and ", parts);

        var custom = string.IsNullOrWhiteSpace(request.Message) ? null : request.Message.Trim();
        if (isAr)
        {
            return custom is null
                ? $"يوجد بيانات ناقصة في تسجيلك: {missingText}. افتح التطبيق وأكمل الخطوات ثم أعد الإرسال للمراجعة."
                : $"{custom}\n\nالناقص: {missingText}.";
        }

        return custom is null
            ? $"Your registration is missing: {missingText}. Open the app, complete the steps, then resubmit for review."
            : $"{custom}\n\nMissing: {missingText}.";
    }
}
