using Microsoft.AspNetCore.Http;

namespace BusinessLayer.Interfaces;

public interface INasserPortfolioAppService
{
    Task SubmitLeadAsync(NasserPortfolioLeadInput input, CancellationToken cancellationToken = default);

    /// <summary>Validates input and compresses any attached image before it is sent to OpenAI.</summary>
    Task<NasserPortfolioPreparedChat> PrepareChatAsync(
        NasserPortfolioChatInput input,
        CancellationToken cancellationToken = default);

    /// <summary>Generates or edits an image and returns watermarked PNG bytes, or null on failure.</summary>
    Task<byte[]?> CreateImageAsync(
        NasserPortfolioPreparedChat chat,
        CancellationToken cancellationToken = default);

    IAsyncEnumerable<string> StreamReplyAsync(
        NasserPortfolioPreparedChat chat,
        bool imageLimitReached,
        bool imageProduced,
        CancellationToken cancellationToken = default);
}

public sealed class NasserPortfolioLeadInput
{
    public string Phone { get; set; } = string.Empty;
    public string? Name { get; set; }
    public string? Locale { get; set; }
    public string? Source { get; set; }
}

public sealed record NasserPortfolioChatTurn(string Role, string Content);

public sealed class NasserPortfolioChatInput
{
    public string Message { get; set; } = string.Empty;
    public string? Locale { get; set; }
    public IFormFile? Image { get; set; }
    public IReadOnlyList<NasserPortfolioChatTurn> History { get; set; } = [];
}

public sealed class NasserPortfolioPreparedChat
{
    public string Message { get; init; } = string.Empty;
    public string Locale { get; init; } = "en";
    public byte[]? ImageBytes { get; init; }
    public string ImageContentType { get; init; } = "image/png";
    public string ImageFileName { get; init; } = "input.png";
    public int ImageWidth { get; init; }
    public int ImageHeight { get; init; }
    public byte[]? CompressedJpeg => ImageBytes;
    public IReadOnlyList<NasserPortfolioChatTurn> History { get; init; } = [];
    public bool ImageRequested { get; init; }

    /// <summary>Visitor ISO country code from IP (e.g. "EG", "AE"); drives the pricing rules.</summary>
    public string? Country { get; set; }
}
