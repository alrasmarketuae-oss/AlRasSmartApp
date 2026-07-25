using System.Text;

namespace DataLayer.Helpers;

/// <summary>
/// Human-readable product codes: RS + 9 base-33 chars (~10 trillion capacity).
/// </summary>
public static class ProductCodeGenerator
{
    public const string Prefix = "RS";
    public const int BodyLength = 9;

    // Avoid ambiguous I/O/0/1 in customer-facing codes.
    private const string Alphabet = "23456789ABCDEFGHJKLMNPQRSTUVWXYZ";

    public static string FromSequenceValue(long sequenceValue)
    {
        if (sequenceValue < 0)
        {
            throw new ArgumentOutOfRangeException(nameof(sequenceValue));
        }

        var chars = new char[BodyLength];
        var remaining = sequenceValue;
        for (var i = BodyLength - 1; i >= 0; i--)
        {
            chars[i] = Alphabet[(int)(remaining % Alphabet.Length)];
            remaining /= Alphabet.Length;
        }

        return Prefix + new string(chars);
    }

    public static bool TryNormalize(string? input, out string normalized)
    {
        normalized = string.Empty;
        if (string.IsNullOrWhiteSpace(input))
        {
            return false;
        }

        var trimmed = new StringBuilder(input.Length);
        foreach (var ch in input.Trim())
        {
            if (char.IsWhiteSpace(ch) || ch is '-' or '_')
            {
                continue;
            }

            trimmed.Append(char.ToUpperInvariant(ch));
        }

        var candidate = trimmed.ToString();
        if (!candidate.StartsWith(Prefix, StringComparison.Ordinal)
            || candidate.Length != Prefix.Length + BodyLength)
        {
            return false;
        }

        foreach (var ch in candidate.AsSpan(Prefix.Length))
        {
            if (!Alphabet.Contains(ch))
            {
                return false;
            }
        }

        normalized = candidate;
        return true;
    }
}
