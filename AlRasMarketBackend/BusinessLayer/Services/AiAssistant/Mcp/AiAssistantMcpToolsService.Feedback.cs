using System.Text.Json;
using BusinessLayer.Interfaces;
using DataLayer.Models;
using Microsoft.Extensions.DependencyInjection;

namespace BusinessLayer.Services.AiAssistant.Mcp;

public sealed partial class AiAssistantMcpToolsService
{
    private static object SubmitFeedbackToolDefinition => new
    {
        type = "function",
        function = new
        {
            name = "submit_feedback",
            description =
                "Submit ONE user complaint or suggestion to Al Ras support per turn. " +
                "Use when the user wants to file a complaint (شكوى), report a problem, or share a suggestion (اقتراح / feedback). " +
                "Collect a clear subject and detailed message. Optionally include order number/reference if they mention an order.",
            parameters = new
            {
                type = "object",
                properties = new
                {
                    feedback_type = new
                    {
                        type = "string",
                        description = "\"complaint\" for problems/complaints or \"suggestion\" for ideas/feedback."
                    },
                    subject = new
                    {
                        type = "string",
                        description = "Short subject/title (3–200 chars)."
                    },
                    message = new
                    {
                        type = "string",
                        description = "Full complaint or suggestion details (10–2000 chars)."
                    },
                    order_reference = new
                    {
                        type = "string",
                        description = "Optional order id or reference if the user mentions a specific order."
                    }
                },
                required = new[] { "feedback_type", "subject", "message" },
                additionalProperties = false
            }
        }
    };

    private async Task<string> SubmitFeedbackAsync(
        Guid? userId,
        string argumentsJson,
        CancellationToken cancellationToken)
    {
        if (!userId.HasValue)
        {
            return Json(new
            {
                ok = false,
                error = "Sign in to submit a complaint or suggestion."
            });
        }

        using var args = JsonDocument.Parse(string.IsNullOrWhiteSpace(argumentsJson) ? "{}" : argumentsJson);
        var root = args.RootElement;
        var feedbackType = GetString(root, "feedback_type") ?? "complaint";
        var subject = GetString(root, "subject") ?? string.Empty;
        var message = GetString(root, "message") ?? string.Empty;
        var orderReference = GetString(root, "order_reference");

        using var scope = scopeFactory.CreateScope();
        var feedbackService = scope.ServiceProvider.GetRequiredService<IUserFeedbackAppService>();

        try
        {
            var result = await feedbackService.CreateAsync(
                userId.Value,
                new CreateUserFeedbackInput
                {
                    Type = feedbackType,
                    Subject = subject,
                    Message = message,
                    OrderReference = orderReference,
                    Source = "ai_assistant",
                    Language = ContainsArabic(subject + message) ? "ar" : "en"
                },
                cancellationToken).ConfigureAwait(false);

            return Json(new { ok = true, result });
        }
        catch (ArgumentException ex)
        {
            return Json(new { ok = false, error = ex.Message });
        }
        catch (InvalidOperationException ex)
        {
            return Json(new { ok = false, error = ex.Message, duplicate = true });
        }
    }

    private static bool ContainsArabic(string text) =>
        text.Any(c => c is >= '\u0600' and <= '\u06FF');
}
