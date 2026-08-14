using BusinessLayer.Interfaces;
using DataLayer.Interfaces;
using DataLayer.Models;
using Microsoft.EntityFrameworkCore;

namespace BusinessLayer.Services;

public sealed class UserFeedbackAppService(
    IRasAlSouqDbContext dbContext,
    IAdminRealtimeNotificationService adminRealtimeNotificationService) : IUserFeedbackAppService
{
    public async Task<object> CreateAsync(
        Guid? userId,
        CreateUserFeedbackInput input,
        CancellationToken cancellationToken = default)
    {
        var type = NormalizeType(input.Type);
        var subject = (input.Subject ?? string.Empty).Trim();
        var message = (input.Message ?? string.Empty).Trim();
        var orderReference = (input.OrderReference ?? string.Empty).Trim();
        var language = (input.Language ?? "ar").Trim().StartsWith("ar", StringComparison.OrdinalIgnoreCase)
            ? "ar"
            : "en";

        if (subject.Length is < 3 or > 200)
        {
            throw new ArgumentException(language == "ar"
                ? "الموضوع مطلوب (3–200 حرف)."
                : "Subject is required (3–200 characters).");
        }

        if (message.Length is < 10 or > 2000)
        {
            throw new ArgumentException(language == "ar"
                ? "الرسالة مطلوبة (10–2000 حرف)."
                : "Message is required (10–2000 characters).");
        }

        if (orderReference.Length > 80)
        {
            orderReference = orderReference[..80];
        }

        string fullName;
        string? email;
        string? phone;

        if (userId.HasValue)
        {
            var user = await dbContext.Users.AsNoTracking()
                .FirstOrDefaultAsync(x => x.Id == userId.Value, cancellationToken)
                .ConfigureAwait(false)
                ?? throw new KeyNotFoundException(language == "ar"
                    ? "المستخدم غير موجود."
                    : "User not found.");

            fullName = user.FullName?.Trim() ?? string.Empty;
            email = user.Email?.Trim();
            phone = user.PhoneNumber?.Trim();

            var since = DateTime.UtcNow.AddMinutes(-5);
            var recent = await dbContext.UserFeedbackSubmissions.AsNoTracking()
                .AnyAsync(
                    x => x.UserId == userId.Value
                         && x.Type == type
                         && x.Status == UserFeedbackStatuses.Pending
                         && x.CreatedAtUtc >= since,
                    cancellationToken)
                .ConfigureAwait(false);
            if (recent)
            {
                throw new InvalidOperationException(language == "ar"
                    ? "طلبك مسجّل بالفعل. فريق الدعم هيراجعه قريباً."
                    : "Your request is already registered. Our team will review it shortly.");
            }
        }
        else
        {
            fullName = (input.FullName ?? string.Empty).Trim();
            email = (input.Email ?? string.Empty).Trim();
            phone = (input.Phone ?? string.Empty).Trim();

            if (fullName.Length is < 2 or > 200)
            {
                throw new ArgumentException(language == "ar"
                    ? "الاسم مطلوب."
                    : "Full name is required.");
            }
        }

        var entity = new UserFeedbackSubmission
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            Type = type,
            Subject = subject,
            Message = message,
            OrderReference = string.IsNullOrWhiteSpace(orderReference) ? null : orderReference,
            FullName = fullName,
            Email = string.IsNullOrWhiteSpace(email) ? null : email,
            Phone = string.IsNullOrWhiteSpace(phone) ? null : phone,
            Language = language,
            Status = UserFeedbackStatuses.Pending,
            Source = string.IsNullOrWhiteSpace(input.Source) ? "profile" : input.Source!.Trim(),
            AiConversationId = string.IsNullOrWhiteSpace(input.AiConversationId)
                ? null
                : input.AiConversationId!.Trim(),
            CreatedAtUtc = DateTime.UtcNow
        };

        dbContext.UserFeedbackSubmissions.Add(entity);
        await dbContext.SaveChangesAsync(cancellationToken).ConfigureAwait(false);

        await adminRealtimeNotificationService
            .NotifyUserFeedbackAsync(entity, cancellationToken)
            .ConfigureAwait(false);

        var isComplaint = type == UserFeedbackTypes.Complaint;
        return new
        {
            id = entity.Id,
            type = entity.Type,
            status = entity.Status,
            message = language == "ar"
                ? isComplaint
                    ? "تم استلام شكواك. فريق الدعم هيراجعها ويتواصل معاك."
                    : "تم استلام اقتراحك. شكراً لمشاركتك!"
                : isComplaint
                    ? "Your complaint was received. Our team will review it and get back to you."
                    : "Your suggestion was received. Thank you for sharing!"
        };
    }

    public async Task<object> GetPagedAsync(
        int page,
        int pageSize,
        string? search,
        string? status,
        string? type,
        CancellationToken cancellationToken = default)
    {
        page = page < 1 ? 1 : page;
        pageSize = pageSize is < 1 or > 100 ? 20 : pageSize;
        var searchTerm = search?.Trim();
        var statusFilter = status?.Trim();
        var typeFilter = type?.Trim();

        var query = dbContext.UserFeedbackSubmissions.AsNoTracking().AsQueryable();

        if (!string.IsNullOrWhiteSpace(statusFilter)
            && !statusFilter.Equals("all", StringComparison.OrdinalIgnoreCase))
        {
            query = query.Where(x => x.Status == statusFilter);
        }

        if (!string.IsNullOrWhiteSpace(typeFilter)
            && !typeFilter.Equals("all", StringComparison.OrdinalIgnoreCase))
        {
            query = query.Where(x => x.Type == typeFilter);
        }

        if (!string.IsNullOrWhiteSpace(searchTerm))
        {
            var term = searchTerm.ToLowerInvariant();
            query = query.Where(x =>
                x.FullName.ToLower().Contains(term)
                || x.Subject.ToLower().Contains(term)
                || x.Message.ToLower().Contains(term)
                || (x.Email != null && x.Email.ToLower().Contains(term))
                || (x.Phone != null && x.Phone.ToLower().Contains(term))
                || (x.OrderReference != null && x.OrderReference.ToLower().Contains(term)));
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
                type = x.Type,
                subject = x.Subject,
                message = x.Message,
                orderReference = x.OrderReference,
                fullName = x.FullName,
                email = x.Email,
                phone = x.Phone,
                language = x.Language,
                status = x.Status,
                source = x.Source,
                createdAtUtc = x.CreatedAtUtc,
                resolvedAtUtc = x.ResolvedAtUtc,
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
        UpdateUserFeedbackStatusInput input,
        CancellationToken cancellationToken = default)
    {
        var status = (input.Status ?? string.Empty).Trim();
        if (status is not (
            UserFeedbackStatuses.Pending
            or UserFeedbackStatuses.InReview
            or UserFeedbackStatuses.Resolved
            or UserFeedbackStatuses.Closed))
        {
            throw new ArgumentException("Status must be Pending, InReview, Resolved, or Closed.");
        }

        var entity = await dbContext.UserFeedbackSubmissions
            .FirstOrDefaultAsync(x => x.Id == id, cancellationToken)
            .ConfigureAwait(false)
            ?? throw new KeyNotFoundException("Feedback submission not found.");

        entity.Status = status;
        entity.AdminNotes = string.IsNullOrWhiteSpace(input.AdminNotes)
            ? entity.AdminNotes
            : input.AdminNotes.Trim();

        if (status is UserFeedbackStatuses.Resolved or UserFeedbackStatuses.Closed)
        {
            entity.ResolvedAtUtc ??= DateTime.UtcNow;
            entity.ResolvedByAdminUserId ??= adminUserId;
        }

        await dbContext.SaveChangesAsync(cancellationToken).ConfigureAwait(false);
        await adminRealtimeNotificationService.BroadcastCountsAsync(cancellationToken)
            .ConfigureAwait(false);

        return new { id = entity.Id, status = entity.Status };
    }

    public Task<int> CountPendingAsync(CancellationToken cancellationToken = default) =>
        dbContext.UserFeedbackSubmissions.AsNoTracking()
            .CountAsync(x => x.Status == UserFeedbackStatuses.Pending, cancellationToken);

    private static string NormalizeType(string? raw)
    {
        var value = (raw ?? string.Empty).Trim();
        if (value.Equals(UserFeedbackTypes.Suggestion, StringComparison.OrdinalIgnoreCase)
            || value.Equals("suggestion", StringComparison.OrdinalIgnoreCase)
            || value.Equals("اقتراح", StringComparison.OrdinalIgnoreCase))
        {
            return UserFeedbackTypes.Suggestion;
        }

        return UserFeedbackTypes.Complaint;
    }
}
