using System.Security.Claims;
using BusinessLayer.Dtos;
using BusinessLayer.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace RasAlSouqPresentaionLayer.Controllers;

/// <summary>
/// Stripe checkout, webhook, and refund endpoints — same flow as Restaurant.Business.
/// </summary>
[Route("api/[controller]")]
[ApiController]
public class PaymentsController(
    IPaymentsAppService paymentsAppService,
    IAdminAuditLogAppService auditLogAppService,
    ILogger<PaymentsController> logger) : ControllerBase
{
    /// <summary>
    /// Mobile — create Stripe Checkout session for a pending online order.
    /// </summary>
    [Authorize]
    [HttpPost("CreateStripeCheckout")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> CreateStripeCheckout(
        [FromBody] CreateStripeCheckoutRequest request,
        CancellationToken cancellationToken)
    {
        var userId = GetUserId();
        if (userId is null)
        {
            return Unauthorized(new { message = "Invalid token." });
        }

        try
        {
            var response = await paymentsAppService.CreateStripeCheckoutAsync(new CreateStripeCheckoutInput
            {
                UserId = userId,
                OrderId = request.OrderId,
                Currency = request.Currency,
                Amount = request.Amount,
                Client = request.Client
            }, cancellationToken);

            return Ok(new
            {
                sessionId = response.SessionId,
                checkoutUrl = response.CheckoutUrl,
                currency = response.Currency,
                amount = response.Amount
            });
        }
        catch (UnauthorizedAccessException ex)
        {
            return Unauthorized(new { message = ex.Message });
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Failed to create Stripe checkout session.");
            return BadRequest(new { message = ex.Message });
        }
    }

    /// <summary>
    /// Stripe webhook — verifies signature before marking payment complete.
    /// </summary>
    [AllowAnonymous]
    [HttpPost("StripeWebhook")]
    public async Task<IActionResult> StripeWebhook(CancellationToken cancellationToken)
    {
        if (!Request.Headers.TryGetValue("Stripe-Signature", out var signature))
        {
            return BadRequest(new { message = "Stripe-Signature header is missing." });
        }

        Request.EnableBuffering();
        Request.Body.Position = 0;
        var json = await new StreamReader(Request.Body).ReadToEndAsync(cancellationToken);
        Request.Body.Position = 0;

        try
        {
            await paymentsAppService.HandleWebhookAsync(json, signature.ToString(), cancellationToken);
            return Ok();
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Failed to process Stripe webhook.");
            return BadRequest(new { message = ex.Message });
        }
    }

    /// <summary>
    /// Mobile — poll checkout status after returning from Stripe.
    /// </summary>
    [Authorize]
    [HttpGet("CheckoutStatus")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> GetCheckoutStatus([FromQuery] string sessionId, CancellationToken cancellationToken)
    {
        var userId = GetUserId();
        if (userId is null)
        {
            return Unauthorized(new { message = "Invalid token." });
        }

        if (string.IsNullOrWhiteSpace(sessionId))
        {
            return BadRequest(new { status = "invalid" });
        }

        try
        {
            var status = await paymentsAppService.GetCheckoutStatusAsync(userId, sessionId, cancellationToken);
            return Ok(new
            {
                status = status.Status,
                orderGroupId = status.OrderGroupId,
                orderStatusId = status.OrderStatusId
            });
        }
        catch (UnauthorizedAccessException ex)
        {
            return Unauthorized(new { message = ex.Message });
        }
    }

    /// <summary>
    /// Admin — refund a cancelled or return-approved online order to the original payment method.
    /// </summary>
    [Authorize(Roles = "Admin")]
    [HttpPost("ManualRefund/{orderId:long}")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> ManualRefund(long orderId, CancellationToken cancellationToken)
    {
        try
        {
            var result = await paymentsAppService.RefundCancelledOrderAsync(orderId, cancellationToken);
            await auditLogAppService.WriteAsync(
                AdminAuditActions.OrderRefund,
                AdminAuditEntityTypes.Order,
                orderId.ToString(),
                $"Refunded order #{orderId}",
                new
                {
                    result.OrderGroupId,
                    result.RefundId,
                    result.RefundedAtUtc
                },
                cancellationToken);
            return Ok(new
            {
                message = "Refund completed successfully at the original payment method.",
                orderGroupId = result.OrderGroupId,
                refundId = result.RefundId,
                refundedAtUtc = result.RefundedAtUtc
            });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
    }

    private string? GetUserId() =>
        User.FindFirst("EntityId")?.Value ?? User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
}

public sealed class CreateStripeCheckoutRequest
{
    public string OrderId { get; set; } = string.Empty;
    public string? Currency { get; set; }
    public decimal? Amount { get; set; }
    public string? Client { get; set; }
}
