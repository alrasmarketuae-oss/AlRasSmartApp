using BusinessLayer.Constants;
using BusinessLayer.Dtos;
using BusinessLayer.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using RasAlSouqPresentaionLayer.Authorization;

namespace RasAlSouqPresentaionLayer.Controllers;

[Route("api/admin/ai")]
[ApiController]
[Authorize(Roles = "Admin,Employee")]
public sealed class AdminAiController(
    IAiKnowledgeIndexer knowledgeIndexer,
    IAiConversationStore conversationStore,
    IAdminChatReportAppService chatReportAppService) : ControllerBase
{
    /// <summary>
    /// Force a full re-embed + re-index of the AI knowledge base. Use after
    /// editing the knowledge source; normal deploys skip re-indexing unchanged content.
    /// </summary>
    [HttpPost("knowledge/reindex")]
    [RequireAdminPermission(AdminPermissions.ProductsManage)]
    public async Task<IActionResult> ReindexKnowledge(CancellationToken cancellationToken = default)
    {
        var result = await knowledgeIndexer.ReindexAsync(force: true, cancellationToken);
        return Ok(result);
    }

    [HttpGet("conversations")]
    [RequireAdminPermission(AdminPermissions.ChatAccess)]
    public async Task<ActionResult<AiConversationListPageDto>> ListConversations(
        [FromQuery] Guid? userId = null,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20,
        CancellationToken cancellationToken = default)
    {
        var result = await conversationStore.ListForAdminAsync(userId, page, pageSize, cancellationToken);
        return Ok(result);
    }

    [HttpGet("conversations/{conversationId:guid}/messages")]
    [RequireAdminPermission(AdminPermissions.ChatAccess)]
    public async Task<ActionResult<AiConversationMessagesPageDto>> GetConversationMessages(
        [FromRoute] Guid conversationId,
        [FromQuery] int limit = 50,
        [FromQuery] long? before = null,
        CancellationToken cancellationToken = default)
    {
        var page = await conversationStore.GetMessagesPageAsync(
            conversationId,
            limit,
            before,
            cancellationToken);
        return Ok(page);
    }

    [HttpPost("conversations/{conversationId:guid}/report")]
    [RequireAdminPermission(AdminPermissions.ChatAccess)]
    public async Task<ActionResult<AdminChatCompanyReportDto>> GenerateConversationReport(
        [FromRoute] Guid conversationId,
        [FromBody] AdminAiConversationReportRequest? request,
        CancellationToken cancellationToken = default)
    {
        var language = request?.Language ?? "ar";
        var result = await chatReportAppService.GenerateAiConversationReportAsync(
            conversationId,
            language,
            cancellationToken);
        return Ok(result);
    }
}
