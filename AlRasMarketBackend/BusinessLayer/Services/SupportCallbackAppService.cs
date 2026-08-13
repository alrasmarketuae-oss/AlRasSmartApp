using BusinessLayer.Interfaces;
using DataLayer.Interfaces;
using DataLayer.Models;
using Microsoft.EntityFrameworkCore;

namespace BusinessLayer.Services;

public sealed class SupportCallbackAppService(
    IRasAlSouqDbContext dbContext,
    IAdminRealtimeNotificationService adminRealtimeNotificationService) : ISupportCallbackAppService
{
    public async Task<object> CreateAsync(
        Guid? userId,
        CreateSupportCallbackRequestInput input,
        CancellationToken cancellationToken = default)
    {
        var fullName = (input.FullName ?? string.Empty).Trim();
        var phone = (input.Phone ?? string.Empty).Trim();
        var email = (input.Email ?? string.Empty).Trim();
        var question = (input.Question ?? string.Empty).Trim();
        var language = (input.Language ?? "ar").Trim().StartsWith("ar", StringComparison.OrdinalIgnoreCase)
            ? "ar"
            : "en";

        if (fullName.Length is < 2 or > 200)
        {
            throw new ArgumentException("Full name is required.");
        }

        if (phone.Length is < 6 or > 50)
        {
            throw new ArgumentException("Phone is required.");
        }

        if (email.Length is < 5 or > 256 || !email.Contains('@'))
        {
            throw new ArgumentException("A valid email is required.");
        }

        if (question.Length > 1000)
        {
            question = question[..1000];
        }

        // Soft rate-limit: one pending request per phone within 10 minutes.
        var since = DateTime.UtcNow.AddMinutes(-10);
        var recent = await dbContext.SupportCallbackRequests.AsNoTracking()
            .AnyAsync(
                x => x.Phone == phone
                     && x.Status == "Pending"
                     && x.CreatedAtUtc >= since,
                cancellationToken)
            .ConfigureAwait(false);
        if (recent)
        {
            throw new InvalidOperationException(
                language == "ar"
                    ? "طلبك مسجّل بالفعل. فريق الدعم هيتواصل معاك خلال خمس دقايق."
                    : "Your request is already registered. Support will call you within five minutes.");
        }

        var entity = new SupportCallbackRequest
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            FullName = fullName,
            Phone = phone,
            Email = email,
            Question = string.IsNullOrWhiteSpace(question) ? null : question,
            Language = language,
            Status = "Pending",
            Source = string.IsNullOrWhiteSpace(input.Source) ? "ai_assistant" : input.Source!.Trim(),
            AiConversationId = string.IsNullOrWhiteSpace(input.AiConversationId)
                ? null
                : input.AiConversationId!.Trim(),
            CreatedAtUtc = DateTime.UtcNow
        };

        dbContext.SupportCallbackRequests.Add(entity);
        await dbContext.SaveChangesAsync(cancellationToken).ConfigureAwait(false);

        await adminRealtimeNotificationService
            .NotifySupportCallbackAsync(entity, cancellationToken)
            .ConfigureAwait(false);

        return new
        {
            id = entity.Id,
            status = entity.Status,
            message = language == "ar"
                ? "تم استلام بياناتك. فريق الدعم الفني هيتواصل معاك خلال خمس دقايق."
                : "Got your details. Technical support will call you within five minutes."
        };
    }

    public async Task<object> GetPagedAsync(
        int page,
        int pageSize,
        string? search,
        string? status,
        CancellationToken cancellationToken = default)
    {
        page = page < 1 ? 1 : page;
        pageSize = pageSize is < 1 or > 100 ? 20 : pageSize;
        var searchTerm = search?.Trim();
        var statusFilter = status?.Trim();

        var query = dbContext.SupportCallbackRequests.AsNoTracking().AsQueryable();

        if (!string.IsNullOrWhiteSpace(statusFilter)
            && !statusFilter.Equals("all", StringComparison.OrdinalIgnoreCase))
        {
            query = query.Where(x => x.Status == statusFilter);
        }

        if (!string.IsNullOrWhiteSpace(searchTerm))
        {
            var term = searchTerm.ToLowerInvariant();
            query = query.Where(x =>
                x.FullName.ToLower().Contains(term)
                || x.Phone.ToLower().Contains(term)
                || x.Email.ToLower().Contains(term)
                || (x.Question != null && x.Question.ToLower().Contains(term)));
        }

        var totalCount = await query.CountAsync(cancellationToken).ConfigureAwait(false);
        var now = DateTime.UtcNow;
        var items = await query
            .OrderByDescending(x => x.CreatedAtUtc)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(x => new
            {
                id = x.Id,
                userId = x.UserId,
                fullName = x.FullName,
                phone = x.Phone,
                email = x.Email,
                question = x.Question,
                language = x.Language,
                status = x.Status,
                source = x.Source,
                createdAtUtc = x.CreatedAtUtc,
                contactedAtUtc = x.ContactedAtUtc,
                adminNotes = x.AdminNotes,
                ageSeconds = (int)Math.Max(0, (now - x.CreatedAtUtc).TotalSeconds)
            })
            .ToListAsync(cancellationToken)
            .ConfigureAwait(false);

        return new
        {
            page,
            pageSize,
            totalCount,
            totalPages = Math.Max(1, (int)Math.Ceiling(totalCount / (double)pageSize)),
            serverUtcNow = now,
            items
        };
    }

    public async Task<object> UpdateStatusAsync(
        Guid id,
        Guid adminUserId,
        UpdateSupportCallbackStatusInput input,
        CancellationToken cancellationToken = default)
    {
        var status = (input.Status ?? string.Empty).Trim();
        if (status is not ("Pending" or "Contacted" or "Closed"))
        {
            throw new ArgumentException("Status must be Pending, Contacted, or Closed.");
        }

        var entity = await dbContext.SupportCallbackRequests
            .FirstOrDefaultAsync(x => x.Id == id, cancellationToken)
            .ConfigureAwait(false)
            ?? throw new KeyNotFoundException("Support callback request not found.");

        entity.Status = status;
        entity.AdminNotes = string.IsNullOrWhiteSpace(input.AdminNotes)
            ? entity.AdminNotes
            : input.AdminNotes.Trim();

        if (status == "Contacted" || status == "Closed")
        {
            entity.ContactedAtUtc ??= DateTime.UtcNow;
            entity.ContactedByAdminUserId ??= adminUserId;
        }

        await dbContext.SaveChangesAsync(cancellationToken).ConfigureAwait(false);
        await adminRealtimeNotificationService.BroadcastCountsAsync(cancellationToken)
            .ConfigureAwait(false);

        return new { id = entity.Id, status = entity.Status };
    }

    public Task<int> CountPendingAsync(CancellationToken cancellationToken = default) =>
        dbContext.SupportCallbackRequests.AsNoTracking()
            .CountAsync(x => x.Status == "Pending", cancellationToken);
}
