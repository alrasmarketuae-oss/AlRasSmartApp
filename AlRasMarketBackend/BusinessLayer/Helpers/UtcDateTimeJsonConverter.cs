using System.Text.Json;
using System.Text.Json.Serialization;

namespace BusinessLayer.Helpers;

/// <summary>
/// Always serialize DateTime as UTC ISO-8601 with Z so clients never parse SQL
/// wall-clock values as local time.
/// </summary>
public sealed class UtcDateTimeJsonConverter : JsonConverter<DateTime>
{
    public override DateTime Read(ref Utf8JsonReader reader, Type typeToConvert, JsonSerializerOptions options)
    {
        var raw = reader.GetString();
        if (string.IsNullOrWhiteSpace(raw))
        {
            return default;
        }

        var parsed = DateTime.Parse(raw, null, System.Globalization.DateTimeStyles.RoundtripKind);
        return UtcDateTimeHelper.AsUtc(parsed);
    }

    public override void Write(Utf8JsonWriter writer, DateTime value, JsonSerializerOptions options) =>
        writer.WriteStringValue(UtcDateTimeHelper.FormatApiDateTime(value));
}

public sealed class UtcNullableDateTimeJsonConverter : JsonConverter<DateTime?>
{
    public override DateTime? Read(ref Utf8JsonReader reader, Type typeToConvert, JsonSerializerOptions options)
    {
        if (reader.TokenType == JsonTokenType.Null)
        {
            return null;
        }

        var raw = reader.GetString();
        if (string.IsNullOrWhiteSpace(raw))
        {
            return null;
        }

        var parsed = DateTime.Parse(raw, null, System.Globalization.DateTimeStyles.RoundtripKind);
        return UtcDateTimeHelper.AsUtc(parsed);
    }

    public override void Write(Utf8JsonWriter writer, DateTime? value, JsonSerializerOptions options)
    {
        if (!value.HasValue)
        {
            writer.WriteNullValue();
            return;
        }

        writer.WriteStringValue(UtcDateTimeHelper.FormatApiDateTime(value.Value));
    }
}
