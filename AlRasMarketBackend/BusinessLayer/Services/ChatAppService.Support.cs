using BusinessLayer.Caching;
using BusinessLayer.Constants;
using BusinessLayer.Helpers;
using BusinessLayer.Interfaces;
using DataLayer.Interfaces;
using DataLayer.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;

namespace BusinessLayer.Services;

public sealed partial class ChatAppService
{
    private Guid? _supportAdminUserId;

    private async Task<Guid> GetSupportAdminUserIdAsync(CancellationToken ct)
    {
        if (_supportAdminUserId.HasValue)
        {
            return _supportAdminUserId.Value;
        }

        var configured = configuration["SupportChat:AdminUserId"]?.Trim();
        if (Guid.TryParse(configured, out var parsed))
        {
            _supportAdminUserId = parsed;
            return parsed;
        }

        var adminId = await dbContext.Users
            .AsNoTracking()
            .Where(x => x.RoleId == 1 && x.IsActive)
            .OrderBy(x => x.CreatedAt)
            .Select(x => x.Id)
            .FirstOrDefaultAsync(ct);

        if (adminId == Guid.Empty)
        {
            throw new InvalidOperationException(
                "SupportChat:AdminUserId is not configured and no active admin user was found.");
        }

        _supportAdminUserId = adminId;
        return adminId;
    }

    private async Task<User> GetUserAsync(Guid userId, CancellationToken ct) =>
        await dbContext.Users.AsNoTracking().FirstOrDefaultAsync(x => x.Id == userId, ct)
        ?? throw new KeyNotFoundException("User not found.");

    private async Task<bool> IsSupportStaffAsync(Guid userId, CancellationToken ct)
    {
        var user = await GetUserAsync(userId, ct);
        if (permissionService.IsSuperAdmin(user.RoleId))
        {
            return true;
        }

        return await permissionService.HasPermissionAsync(
            user.Id,
            user.RoleId,
            AdminPermissions.ChatAccess,
            ct);
    }

    private async Task<bool> IsSuperAdminUserAsync(Guid userId, CancellationToken ct)
    {
        var roleId = await dbContext.Users
            .AsNoTracking()
            .Where(x => x.Id == userId)
            .Select(x => x.RoleId)
            .FirstOrDefaultAsync(ct);

        return permissionService.IsSuperAdmin(roleId);
    }

    private async Task<Guid> ResolveInboxOwnerIdAsync(Guid viewerUserId, CancellationToken ct)
    {
        if (!await IsSupportStaffAsync(viewerUserId, ct))
        {
            return viewerUserId;
        }

        return await GetSupportAdminUserIdAsync(ct);
    }

    public async Task<string?> GetSupportInboxOwnerIdForViewerAsync(
        string viewerUserId,
        CancellationToken ct = default)
    {
        var viewerId = ParseUserId(viewerUserId);
        if (!await IsSupportStaffAsync(viewerId, ct))
        {
            return null;
        }

        var supportAdminId = await GetSupportAdminUserIdAsync(ct);
        if (supportAdminId == viewerId)
        {
            return null;
        }

        return supportAdminId.ToString("D");
    }

    public async Task<ChatSupportAssignmentDto> ClaimSupportConversationAsync(
        string agentUserId,
        string customerUserId,
        CancellationToken ct = default)
    {
        var agentId = ParseUserId(agentUserId);
        var customerId = ParseUserId(customerUserId);

        if (!await IsSupportStaffAsync(agentId, ct))
        {
            throw new UnauthorizedAccessException("Chat access is required.");
        }

        await EnsureUserExistsAsync(customerId, ct);

        var active = await dbContext.ChatSupportAssignments
            .AsNoTracking()
            .FirstOrDefaultAsync(x => x.CustomerUserId == customerId && x.ReleasedAtUtc == null, ct);

        if (active is not null)
        {
            return await MapAssignmentDtoAsync(active, agentId, isNewAssignment: false, ct);
        }

        var assignment = await CreateSupportAssignmentAsync(agentId, customerId, ct);
        return await MapAssignmentDtoAsync(assignment, agentId, isNewAssignment: true, ct);
    }

    public async Task<ChatSupportAssignmentDto?> ReleaseSupportConversationAsync(
        string agentUserId,
        string customerUserId,
        CancellationToken ct = default)
    {
        var agentId = ParseUserId(agentUserId);
        var customerId = ParseUserId(customerUserId);

        var active = await dbContext.ChatSupportAssignments
            .FirstOrDefaultAsync(x => x.CustomerUserId == customerId && x.ReleasedAtUtc == null, ct);

        if (active is null)
        {
            return null;
        }

        var isSuperAdmin = await IsSuperAdminUserAsync(agentId, ct);
        if (active.AgentUserId != agentId && !isSuperAdmin)
        {
            return null;
        }

        active.ReleasedAtUtc = DateTime.UtcNow;
        await dbContext.SaveChangesAsync(ct);
        InvalidateSupportCaches(customerId, await GetSupportAdminUserIdAsync(ct));
        return await MapAssignmentDtoAsync(active, agentId, isNewAssignment: false, ct);
    }

    public async Task<ChatSupportAssignmentDto?> GetSupportAssignmentAsync(
        string viewerUserId,
        string customerUserId,
        CancellationToken ct = default)
    {
        var viewerId = ParseUserId(viewerUserId);
        var customerId = ParseUserId(customerUserId);

        if (!await IsSupportStaffAsync(viewerId, ct))
        {
            return null;
        }

        var active = await dbContext.ChatSupportAssignments
            .AsNoTracking()
            .FirstOrDefaultAsync(x => x.CustomerUserId == customerId && x.ReleasedAtUtc == null, ct);

        if (active is null)
        {
            return new ChatSupportAssignmentDto(
                customerId.ToString("D"),
                null,
                null,
                false,
                false,
                null,
                false);
        }

        return await MapAssignmentDtoAsync(active, viewerId, isNewAssignment: false, ct);
    }

    private async Task EnsureCanAccessSupportConversationAsync(
        Guid agentUserId,
        Guid customerUserId,
        CancellationToken ct)
    {
        if (!await IsSupportStaffAsync(agentUserId, ct))
        {
            return;
        }

        if (await IsSuperAdminUserAsync(agentUserId, ct))
        {
            return;
        }

        var assignment = await GetSupportAssignmentAsync(agentUserId.ToString("D"), customerUserId.ToString("D"), ct);
        if (assignment is { IsLockedByOtherAgent: true })
        {
            throw new InvalidOperationException("This conversation is being handled by another agent.");
        }
    }

    private async Task<(Guid FromUserId, Guid ToUserId)> ResolveSupportSendPartiesAsync(
        Guid actingUserId,
        Guid otherUserId,
        CancellationToken ct)
    {
        if (!await IsSupportStaffAsync(actingUserId, ct))
        {
            return (actingUserId, otherUserId);
        }

        var supportAdminId = await GetSupportAdminUserIdAsync(ct);
        var customerId = otherUserId == supportAdminId
            ? throw new ArgumentException("Invalid support conversation target.")
            : otherUserId;

        if (!await IsSuperAdminUserAsync(actingUserId, ct))
        {
            await EnsureCanAccessSupportConversationAsync(actingUserId, customerId, ct);
            await GetOrCreateSupportAssignmentAsync(actingUserId, customerId, ct);
        }

        return (supportAdminId, customerId);
    }

    private async Task<ChatSupportAssignment> GetOrCreateSupportAssignmentAsync(
        Guid agentUserId,
        Guid customerUserId,
        CancellationToken ct)
    {
        var active = await dbContext.ChatSupportAssignments
            .FirstOrDefaultAsync(x => x.CustomerUserId == customerUserId && x.ReleasedAtUtc == null, ct);

        if (active is not null)
        {
            if (active.AgentUserId != agentUserId
                && !await IsSuperAdminUserAsync(agentUserId, ct))
            {
                throw new InvalidOperationException("This conversation is being handled by another agent.");
            }

            return active;
        }

        return await CreateSupportAssignmentAsync(agentUserId, customerUserId, ct);
    }

    private async Task<ChatSupportAssignment> CreateSupportAssignmentAsync(
        Guid agentUserId,
        Guid customerUserId,
        CancellationToken ct)
    {
        var supportAdminId = await GetSupportAdminUserIdAsync(ct);
        var assignment = new ChatSupportAssignment
        {
            Id = Guid.NewGuid(),
            CustomerUserId = customerUserId,
            AgentUserId = agentUserId,
            AssignedAtUtc = DateTime.UtcNow,
        };

        await dbContext.ChatSupportAssignments.AddAsync(assignment, ct);
        await dbContext.SaveChangesAsync(ct);
        InvalidateSupportCaches(customerUserId, supportAdminId);
        return assignment;
    }

    private async Task<(Guid ViewerId, Guid OtherId)> ResolveSupportViewerPartiesAsync(
        Guid actingUserId,
        Guid otherUserId,
        CancellationToken ct)
    {
        if (!await IsSupportStaffAsync(actingUserId, ct))
        {
            return (actingUserId, otherUserId);
        }

        var supportAdminId = await GetSupportAdminUserIdAsync(ct);
        if (otherUserId == supportAdminId)
        {
            throw new ArgumentException("Invalid support conversation target.");
        }

        await EnsureCanAccessSupportConversationAsync(actingUserId, otherUserId, ct);
        return (supportAdminId, otherUserId);
    }

    private async Task<ChatSupportAssignmentDto> MapAssignmentDtoAsync(
        ChatSupportAssignment assignment,
        Guid viewerAgentId,
        bool isNewAssignment,
        CancellationToken ct)
    {
        var agent = await dbContext.Users.AsNoTracking()
            .Where(x => x.Id == assignment.AgentUserId)
            .Select(x => new { x.FullName })
            .FirstOrDefaultAsync(ct);

        var isSuperAdmin = await IsSuperAdminUserAsync(viewerAgentId, ct);
        var isAssignedToMe = assignment.AgentUserId == viewerAgentId;
        var isLockedByOtherAgent = !isSuperAdmin && !isAssignedToMe;
        return new ChatSupportAssignmentDto(
            assignment.CustomerUserId.ToString("D"),
            assignment.AgentUserId.ToString("D"),
            agent?.FullName,
            isAssignedToMe,
            isLockedByOtherAgent,
            UtcDateTimeHelper.FormatApiDateTime(assignment.AssignedAtUtc),
            isNewAssignment);
    }

    public async Task<ChatConversationDetailsDto> GetConversationDetailsAsync(
        string userId,
        string otherUserId,
        CancellationToken ct = default)
    {
        var actingUserId = ParseUserId(userId);
        var otherId = ParseUserId(otherUserId);
        await EnsureUserExistsAsync(otherId, ct);

        var (viewerId, partnerId) = await ResolveSupportViewerPartiesAsync(actingUserId, otherId, ct);
        var supportAdminId = await GetSupportAdminUserIdAsync(ct);
        var actingIsStaff = await IsSupportStaffAsync(actingUserId, ct);
        var isAgentSupportThread = actingIsStaff && viewerId == supportAdminId;
        var isCustomerSupportThread = !actingIsStaff && partnerId == supportAdminId;

        var messages = await dbContext.ChatMessages
            .AsNoTracking()
            .Where(m =>
                (m.FromUserId == viewerId && m.ToUserId == partnerId) ||
                (m.FromUserId == partnerId && m.ToUserId == viewerId))
            .OrderBy(m => m.SentAtUtc)
            .ToListAsync(ct);

        var utcNow = DateTime.UtcNow;

        if (!isAgentSupportThread && !isCustomerSupportThread)
        {
            var plain = messages.Select(m => MapToDto(m, utcNow)).ToList();
            return new ChatConversationDetailsDto(plain, [], null, null);
        }

        var customerId = isCustomerSupportThread ? viewerId : partnerId;
        var sessions = await BuildSupportSessionsAsync(customerId, ct);
        var annotated = AnnotateSupportMessages(messages, sessions, utcNow);
        var active = sessions.FirstOrDefault(x => x.IsActive);

        return new ChatConversationDetailsDto(
            annotated,
            sessions,
            active?.AgentUserId,
            active?.AgentName);
    }

    private async Task<IReadOnlyList<ChatSupportSessionDto>> BuildSupportSessionsAsync(
        Guid customerId,
        CancellationToken ct)
    {
        var assignments = await dbContext.ChatSupportAssignments
            .AsNoTracking()
            .Where(x => x.CustomerUserId == customerId)
            .OrderBy(x => x.AssignedAtUtc)
            .ToListAsync(ct);

        if (assignments.Count == 0)
        {
            return [];
        }

        var agentIds = assignments.Select(x => x.AgentUserId).Distinct().ToList();
        var agentNames = await dbContext.Users
            .AsNoTracking()
            .Where(x => agentIds.Contains(x.Id))
            .ToDictionaryAsync(x => x.Id, x => x.FullName, ct);

        return assignments
            .Select(assignment => new ChatSupportSessionDto(
                assignment.AgentUserId.ToString("D"),
                agentNames.GetValueOrDefault(assignment.AgentUserId) ?? assignment.AgentUserId.ToString("D"),
                UtcDateTimeHelper.FormatApiDateTime(assignment.AssignedAtUtc),
                assignment.ReleasedAtUtc is null
                    ? null
                    : UtcDateTimeHelper.FormatApiDateTime(assignment.ReleasedAtUtc.Value),
                assignment.ReleasedAtUtc is null))
            .ToList();
    }

    private List<ChatMessageDto> AnnotateSupportMessages(
        IReadOnlyList<ChatMessage> messages,
        IReadOnlyList<ChatSupportSessionDto> sessions,
        DateTime utcNow)
    {
        if (sessions.Count == 0)
        {
            return messages.Select(m => MapToDto(m, utcNow)).ToList();
        }

        var sessionRanges = sessions
            .Select(session => new
            {
                session.AgentUserId,
                session.AgentName,
                AssignedAt = DateTime.Parse(session.AssignedAtUtc, null, System.Globalization.DateTimeStyles.RoundtripKind),
                ReleasedAt = session.ReleasedAtUtc is null
                    ? (DateTime?)null
                    : DateTime.Parse(session.ReleasedAtUtc, null, System.Globalization.DateTimeStyles.RoundtripKind),
            })
            .ToList();

        return messages
            .Select(message =>
            {
                var dto = MapToDto(message, utcNow);
                var match = sessionRanges.FirstOrDefault(session =>
                    message.SentAtUtc >= session.AssignedAt
                    && (session.ReleasedAt is null || message.SentAtUtc < session.ReleasedAt));

                if (match is null)
                {
                    return dto;
                }

                return dto with
                {
                    SupportAgentId = match.AgentUserId,
                    SupportAgentName = match.AgentName,
                };
            })
            .ToList();
    }

    private async Task<IReadOnlyDictionary<Guid, ChatSupportAssignment>> LoadActiveAssignmentsAsync(
        IReadOnlyCollection<Guid> customerIds,
        CancellationToken ct)
    {
        if (customerIds.Count == 0)
        {
            return new Dictionary<Guid, ChatSupportAssignment>();
        }

        var rows = await dbContext.ChatSupportAssignments
            .AsNoTracking()
            .Where(x => customerIds.Contains(x.CustomerUserId) && x.ReleasedAtUtc == null)
            .ToListAsync(ct);

        return rows.ToDictionary(x => x.CustomerUserId);
    }

    private void InvalidateSupportCaches(Guid customerId, Guid supportAdminId)
    {
        cache.Remove(ChatCacheKeys.Inbox(supportAdminId));
        cache.Remove(ChatCacheKeys.Inbox(customerId));
        cache.Remove(ChatCacheKeys.Thread(supportAdminId, customerId));
        cache.Remove(ChatCacheKeys.Thread(customerId, supportAdminId));
        cache.Remove(ChatCacheKeys.Unread(supportAdminId));
    }
}
