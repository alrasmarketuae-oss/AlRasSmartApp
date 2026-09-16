using System.Security.Cryptography;
using System.Text;
using System.Text.RegularExpressions;
using BusinessLayer.Interfaces.AiAssistant;
using BusinessLayer.Options;
using Microsoft.Extensions.Options;

namespace BusinessLayer.Services.AiAssistant.Shopping;

public sealed class AiShoppingAccessGate(IOptions<AiShoppingAgentOptions> options) : IAiShoppingAccessGate
{
    private readonly AiShoppingAgentOptions _options = options.Value;

    private static readonly Regex ShoppingIntent = new(
        @"رز|قهوة|شاي|نسكافيه|منتج|منتجات|سعر|أسعار|اسعار|بكام|بكم|سلة|السلة|طلب|طلباتي|أوردر|order|cart|buy|search|find|product|coffee|tea|rice|cheap|أرخص|اغلى|بديل|كمية|كيلو|كرتونة|اضف|ضيف|أضف|remove|حذف من السلة",
        RegexOptions.IgnoreCase | RegexOptions.CultureInvariant | RegexOptions.Compiled);

    public bool IsGloballyEnabled() => _options.Enabled;

    public bool IsAllowed(Guid? userId, Guid? companyId = null)
    {
        if (!_options.Enabled)
        {
            return false;
        }

        if (!_options.TestMode)
        {
            return userId.HasValue;
        }

        if (userId is null)
        {
            return false;
        }

        var userKey = userId.Value.ToString("D");
        if (_options.AllowedUserIds.Any(id =>
                string.Equals(id?.Trim(), userKey, StringComparison.OrdinalIgnoreCase)))
        {
            return true;
        }

        if (companyId is Guid cid)
        {
            var companyKey = cid.ToString("D");
            if (_options.AllowedCompanyIds.Any(id =>
                    string.Equals(id?.Trim(), companyKey, StringComparison.OrdinalIgnoreCase)))
            {
                return true;
            }
        }

        // Company accounts often use EntityId == userId; allow matching company allowlist that way.
        if (_options.AllowedCompanyIds.Any(id =>
                string.Equals(id?.Trim(), userKey, StringComparison.OrdinalIgnoreCase)))
        {
            return true;
        }

        return false;
    }

    public bool ShouldRouteToShoppingAgent(Guid? userId, string message, Guid? companyId = null)
    {
        if (!IsAllowed(userId, companyId))
        {
            return false;
        }

        var text = (message ?? string.Empty).Trim();
        if (text.Length == 0)
        {
            return false;
        }

        // Keep ad-creation / seller workflows on the legacy MCP path.
        if (LooksLikeAdCreation(text))
        {
            return false;
        }

        return ShoppingIntent.IsMatch(text);
    }

    private static bool LooksLikeAdCreation(string text)
    {
        var q = text.ToLowerInvariant();
        return q.Contains("انشئ اعلان", StringComparison.Ordinal)
            || q.Contains("أنشئ إعلان", StringComparison.Ordinal)
            || q.Contains("اعمل اعلان", StringComparison.Ordinal)
            || q.Contains("create ad", StringComparison.Ordinal)
            || q.Contains("create booking", StringComparison.Ordinal)
            || q.Contains("create offer", StringComparison.Ordinal)
            || q.Contains("plan mode", StringComparison.Ordinal);
    }

    public static string HashUserId(Guid? userId)
    {
        if (userId is null)
        {
            return "anon";
        }

        var bytes = SHA256.HashData(Encoding.UTF8.GetBytes(userId.Value.ToString("D")));
        return Convert.ToHexString(bytes.AsSpan(0, 8));
    }
}
