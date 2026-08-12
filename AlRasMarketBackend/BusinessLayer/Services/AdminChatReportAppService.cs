using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using BusinessLayer.Dtos;
using BusinessLayer.Helpers;
using BusinessLayer.Interfaces;
using BusinessLayer.Options;
using DataLayer.Interfaces;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace BusinessLayer.Services;

public sealed class AdminChatReportAppService(
    IRasAlSouqDbContext dbContext,
    HttpClient httpClient,
    IConfiguration configuration,
    IOptions<AiAssistantOptions> options,
    ILogger<AdminChatReportAppService> logger) : IAdminChatReportAppService
{
    private readonly AiAssistantOptions _options = options.Value;

    public async Task<AdminChatCompanyReportDto> GenerateCompanyReportAsync(
        AdminChatCompanyReportRequest request,
        CancellationToken cancellationToken = default)
    {
        if (request.ParticipantUserId == Guid.Empty)
        {
            throw new ArgumentException("ParticipantUserId is required.");
        }

        var language = NormalizeLanguage(request.Language);
        var user = await dbContext.Users
            .AsNoTracking()
            .Where(u => u.Id == request.ParticipantUserId)
            .Select(u => new
            {
                u.Id,
                u.FullName,
                u.CompanyName,
                u.ImgPath,
            })
            .FirstOrDefaultAsync(cancellationToken)
            .ConfigureAwait(false)
            ?? throw new KeyNotFoundException("Participant user not found.");

        var companyImage = await dbContext.CompanyImages
            .AsNoTracking()
            .Where(ci => ci.UserId == request.ParticipantUserId)
            .OrderByDescending(ci => ci.IsPrimary)
            .ThenBy(ci => ci.Id)
            .Select(ci => ci.ImagePath)
            .FirstOrDefaultAsync(cancellationToken)
            .ConfigureAwait(false);

        var ads = await LoadAdsAsync(request.ParticipantUserId, cancellationToken).ConfigureAwait(false);
        var companyName = !string.IsNullOrWhiteSpace(user.CompanyName)
            ? user.CompanyName!.Trim()
            : user.FullName.Trim();
        var messages = (request.Messages ?? [])
            .Where(m => !string.IsNullOrWhiteSpace(m.Content))
            .TakeLast(10)
            .ToList();

        var report = await GenerateReportTextAsync(
            language,
            companyName,
            user.FullName,
            messages,
            ads,
            cancellationToken).ConfigureAwait(false);

        return new AdminChatCompanyReportDto
        {
            CompanyName = companyName,
            ContactFullName = user.FullName,
            CompanyImageUrl = companyImage ?? user.ImgPath,
            AdsCount = ads.Count,
            Report = report,
            Language = language,
        };
    }

    private async Task<List<AdminChatReportAdLine>> LoadAdsAsync(
        Guid ownerId,
        CancellationToken cancellationToken)
    {
        var products = await dbContext.Products
            .AsNoTracking()
            .Where(p => p.OwnerId == ownerId && p.IsReadyForAdminReview)
            .Select(p => new
            {
                Name = p.NameEn ?? p.ProductCode ?? "Ad",
                p.ProductTypeId,
                TypeName = p.ProductType != null ? p.ProductType.TypeNameEn : null,
                CategoryName = p.Category != null ? p.Category.NameEn : null,
                p.CategoryId,
            })
            .OrderByDescending(p => p.Name)
            .ToListAsync(cancellationToken)
            .ConfigureAwait(false);

        var lines = products.Select(p => new AdminChatReportAdLine
        {
            Name = p.Name,
            TypeName = ResolveProductTypeLabel(p.ProductTypeId, p.TypeName, p.CategoryId),
            CategoryName = p.CategoryName,
        }).ToList();

        var shippingPosts = await dbContext.InternationalShippingPosts
            .AsNoTracking()
            .Where(sp => sp.PublisherUserId == ownerId)
            .Select(sp => new
            {
                From = sp.FromCountry!.CountryNameEn,
                To = sp.ToCountry!.CountryNameEn,
            })
            .ToListAsync(cancellationToken)
            .ConfigureAwait(false);

        foreach (var post in shippingPosts)
        {
            lines.Add(new AdminChatReportAdLine
            {
                Name = $"{post.From} → {post.To}",
                TypeName = "International Shipping",
                CategoryName = null,
            });
        }

        return lines;
    }

    private static string ResolveProductTypeLabel(byte? productTypeId, string? typeName, byte? categoryId)
    {
        if (!string.IsNullOrWhiteSpace(typeName))
        {
            return typeName!;
        }

        if (ProductTypeCodes.IsCategoryProduct(categoryId, productTypeId))
        {
            return "Category";
        }

        return productTypeId switch
        {
            ProductTypeCodes.Retail => "Retail",
            ProductTypeCodes.Booking => "Booking",
            ProductTypeCodes.Offers => "Offers",
            ProductTypeCodes.Requests => "Requests",
            _ => "Ad",
        };
    }

    private async Task<string> GenerateReportTextAsync(
        string language,
        string companyName,
        string fullName,
        IReadOnlyList<AdminChatReportMessageInput> messages,
        IReadOnlyList<AdminChatReportAdLine> ads,
        CancellationToken cancellationToken)
    {
        var apiKey = configuration["OpenAI:ApiKey"];
        var prompt = BuildPrompt(language, companyName, fullName, messages, ads);

        if (string.IsNullOrWhiteSpace(apiKey))
        {
            return language == "ar"
                ? "تعذر إنشاء التقرير: مفتاح OpenAI غير مُعد."
                : "Could not generate report: OpenAI API key is not configured.";
        }

        using var httpRequest = new HttpRequestMessage(
            HttpMethod.Post,
            "https://api.openai.com/v1/chat/completions");
        httpRequest.Headers.Authorization = new AuthenticationHeaderValue("Bearer", apiKey);
        httpRequest.Content = new StringContent(
            JsonSerializer.Serialize(new
            {
                model = _options.ChatModel,
                temperature = 0.2,
                max_tokens = 1800,
                messages = new object[]
                {
                    new
                    {
                        role = "system",
                        content = language == "ar"
                            ? """
                              أنت محلل دعم في منصة الراس الذكي. اكتب تقريراً إدارياً موجزاً وعملياً بالعربية
                              بناءً على آخر رسائل المحادثة وقائمة إعلانات الشركة/المستخدم.
                              استخدم عناوين Markdown. لا تخترع معلومات غير موجودة في البيانات.
                              غطِ: ملخص المحادثة، احتياج العميل/الشركة، الإعلانات ذات الصلة، وتوصيات للموظف.
                              """
                            : """
                              You are a support analyst for Al Ras Smart marketplace. Write a concise admin report
                              in English based on the latest chat messages and the participant's ad catalog.
                              Use Markdown headings. Do not invent facts not present in the data.
                              Cover: conversation summary, participant needs, relevant ads, and agent recommendations.
                              """,
                    },
                    new { role = "user", content = prompt },
                },
            }),
            Encoding.UTF8,
            "application/json");

        using var response = await httpClient.SendAsync(httpRequest, cancellationToken).ConfigureAwait(false);
        var json = await response.Content.ReadAsStringAsync(cancellationToken).ConfigureAwait(false);
        if (!response.IsSuccessStatusCode)
        {
            logger.LogWarning("Admin chat report OpenAI failed ({Status}): {Body}", (int)response.StatusCode, json);
            return language == "ar"
                ? "تعذر إنشاء التقرير من AI. حاول مرة أخرى لاحقاً."
                : "AI report generation failed. Please try again later.";
        }

        using var doc = JsonDocument.Parse(json);
        return doc.RootElement
            .GetProperty("choices")[0]
            .GetProperty("message")
            .GetProperty("content")
            .GetString()?
            .Trim()
            ?? (language == "ar" ? "لم يُرجع AI أي تقرير." : "AI returned an empty report.");
    }

    private static string BuildPrompt(
        string language,
        string companyName,
        string fullName,
        IReadOnlyList<AdminChatReportMessageInput> messages,
        IReadOnlyList<AdminChatReportAdLine> ads)
    {
        var sb = new StringBuilder();
        sb.AppendLine(language == "ar" ? "## بيانات المشارك" : "## Participant");
        sb.AppendLine($"Company: {companyName}");
        sb.AppendLine($"Contact name: {fullName}");
        sb.AppendLine();
        sb.AppendLine(language == "ar" ? "## آخر الرسائل (10 كحد أقصى)" : "## Latest messages (up to 10)");
        if (messages.Count == 0)
        {
            sb.AppendLine(language == "ar" ? "(لا توجد رسائل نصية)" : "(No messages provided)");
        }
        else
        {
            foreach (var message in messages)
            {
                sb.Append("- [")
                    .Append(message.Sender)
                    .Append(" | ")
                    .Append(message.MessageType)
                    .Append(" | ")
                    .Append(message.SentAtUtc)
                    .Append("] ")
                    .AppendLine(message.Content.Trim());
            }
        }

        sb.AppendLine();
        sb.AppendLine(language == "ar" ? "## إعلانات المشارك" : "## Participant ads");
        if (ads.Count == 0)
        {
            sb.AppendLine(language == "ar" ? "(لا توجد إعلانات)" : "(No ads)");
        }
        else
        {
            foreach (var ad in ads)
            {
                sb.Append("- ")
                    .Append(ad.Name)
                    .Append(" | type: ")
                    .Append(ad.TypeName);
                if (!string.IsNullOrWhiteSpace(ad.CategoryName))
                {
                    sb.Append(" | category: ").Append(ad.CategoryName);
                }

                sb.AppendLine();
            }
        }

        return sb.ToString();
    }

    private static string NormalizeLanguage(string? language) =>
        string.Equals(language, "en", StringComparison.OrdinalIgnoreCase) ? "en" : "ar";
}
