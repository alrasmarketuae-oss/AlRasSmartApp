namespace BusinessLayer.Options;

/// <summary>
/// GPT-6 Astra text shopping agent. Independent of the legacy MCP chat loop.
/// Defaults keep the feature off until explicitly enabled and allowlisted.
/// </summary>
public sealed class AiShoppingAgentOptions
{
    public const string SectionName = "AiShoppingAgent";

    /// <summary>Master switch. When false, no request uses Astra shopping.</summary>
    public bool Enabled { get; set; }

    /// <summary>
    /// When true with <see cref="Enabled"/>, only allowlisted users/companies may use Astra.
    /// </summary>
    public bool TestMode { get; set; } = true;

    public List<string> AllowedUserIds { get; set; } = [];

    public List<string> AllowedCompanyIds { get; set; } = [];

    public string Model { get; set; } = "gpt-6-astra";

    /// <summary>low | medium | high | xhigh (never default to max).</summary>
    public string DefaultReasoning { get; set; } = "low";

    public int MaxToolCalls { get; set; } = 8;

    public int MaxIterations { get; set; } = 10;

    public int MaxAsyncJobs { get; set; } = 4;

    public int TimeoutSeconds { get; set; } = 60;

    public int ToolTimeoutSeconds { get; set; } = 30;

    /// <summary>Soft cap for serialized tool JSON; results are shaped to stay under this.</summary>
    public int MaxResultBytes { get; set; } = 8_192;

    public int MaxSearchItems { get; set; } = 8;

    public int MaxTextFieldChars { get; set; } = 180;

    public bool EnableSteering { get; set; }

    public bool EnableAsyncTools { get; set; } = true;

    public string PromptCacheKey { get; set; } = "alras-shopping-v1";

    public int MaxOutputTokens { get; set; } = 700;

    public int MaxAstraRequestsPerSession { get; set; } = 40;

    public decimal MaxEstimatedUsdPerUserPerDay { get; set; } = 5m;

    public decimal MaxEstimatedUsdGlobalPerDay { get; set; } = 50m;

    public decimal EstimatedInputUsdPerMTok { get; set; } = 10m;

    public decimal EstimatedCachedInputUsdPerMTok { get; set; } = 1m;

    public decimal EstimatedOutputUsdPerMTok { get; set; } = 50m;
}
