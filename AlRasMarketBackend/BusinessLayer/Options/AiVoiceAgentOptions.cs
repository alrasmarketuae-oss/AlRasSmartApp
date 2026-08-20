namespace BusinessLayer.Options;

/// <summary>
/// OpenAI Realtime Voice Agent settings. Nested under AiAssistant:VoiceAgent.
/// </summary>
public sealed class AiVoiceAgentOptions
{
    public const string SectionName = "AiAssistant:VoiceAgent";

    public bool Enabled { get; set; } = true;

    /// <summary>OpenAI Realtime speech-to-speech model.</summary>
    public string RealtimeModel { get; set; } = "gpt-realtime";

    /// <summary>OpenAI TTS model used only for delayed progress phrases during slow tools.</summary>
    public string ProgressSpeechModel { get; set; } = "gpt-4o-mini-tts";

    public string FemaleVoice { get; set; } = "coral";
    public string MaleVoice { get; set; } = "ash";

    /// <summary>semantic_vad or server_vad. server_vad is more reliable on phone mics.</summary>
    public string TurnDetection { get; set; } = "server_vad";

    /// <summary>semantic_vad eagerness: low | medium | high | auto.</summary>
    public string SemanticEagerness { get; set; } = "medium";

    /// <summary>
    /// When false, distant/quiet speech will not cancel the assistant mid-response.
    /// Barge-in is handled on the client when mic level is clearly close.
    /// </summary>
    public bool InterruptResponse { get; set; } = false;

    /// <summary>server_vad energy threshold (0–1). Higher = ignore quieter/farther speech.</summary>
    public double VadThreshold { get; set; } = 0.55;

    public int PrefixPaddingMs { get; set; } = 300;

    /// <summary>
    /// Silence before ending a turn. Long enough to keep mid-sentence pauses
    /// in one utterance, short enough that a finished turn does not hang.
    /// </summary>
    public int SilenceDurationMs { get; set; } = 700;

    /// <summary>Minimum speech before a turn can complete (server_vad).</summary>
    public int MinSpeechDurationMs { get; set; } = 180;

    /// <summary>
    /// Play a short user-facing progress phrase only if a tool is still running
    /// after this delay. Fast tools skip it.
    /// </summary>
    public int ProgressSpeechDelayMs { get; set; } = 900;

    /// <summary>Follow-up progress phrase if the same tool is still running.</summary>
    public int ProgressSpeechRepeatMs { get; set; } = 4500;

    public int SampleRate { get; set; } = 24000;

    public double Temperature { get; set; } = 0.7;

    /// <summary>
    /// Cap tokens for one assistant turn (speech + tool calls). 0 = no cap.
    /// Keeps voice replies short; leave enough headroom for a tool call.
    /// </summary>
    public int MaxResponseOutputTokens { get; set; } = 700;

    /// <summary>
    /// Cap tool JSON returned into the Realtime conversation to limit text tokens.
    /// </summary>
    public int MaxToolOutputChars { get; set; } = 2800;

    /// <summary>
    /// Close idle voice sessions after this many seconds with no client audio/activity.
    /// </summary>
    public int IdleTimeoutSeconds { get; set; } = 90;

    /// <summary>
    /// Clear OpenAI input buffer after this many seconds of continuous silent appends.
    /// </summary>
    public int SilentBufferSeconds { get; set; } = 3;

    public string[] ProgressPhrases { get; set; } =
    [
        "ثواني يا فندم، براجع البيانات.",
        "لحظة يا فندم، بتحقق من النتيجة.",
        "ثواني بس، بتأكد من المعلومات.",
        "لحظة يا فندم، لسه براجع النتيجة."
    ];
}
