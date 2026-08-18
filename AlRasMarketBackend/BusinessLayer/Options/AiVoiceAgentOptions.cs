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

    /// <summary>server_vad energy threshold (0–1). Lower = more sensitive to quiet speech.</summary>
    public double VadThreshold { get; set; } = 0.35;

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

    public string[] ProgressPhrases { get; set; } =
    [
        "ثواني يا فندم، براجع البيانات.",
        "لحظة يا فندم، بتحقق من النتيجة.",
        "ثواني بس، بتأكد من المعلومات.",
        "لحظة يا فندم، لسه براجع النتيجة."
    ];
}
