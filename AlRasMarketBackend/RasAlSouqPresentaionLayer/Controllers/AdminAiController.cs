using BusinessLayer.Constants;
using BusinessLayer.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using RasAlSouqPresentaionLayer.Authorization;

namespace RasAlSouqPresentaionLayer.Controllers;

[Route("api/admin/ai")]
[ApiController]
[Authorize(Roles = "Admin,Employee")]
public sealed class AdminAiController(IAiKnowledgeIndexer knowledgeIndexer) : ControllerBase
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
}
