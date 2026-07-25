using BusinessLayer.Constants;
using BusinessLayer.Dtos;
using BusinessLayer.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using RasAlSouqPresentaionLayer.Authorization;

namespace RasAlSouqPresentaionLayer.Controllers;

[Route("api/admin/employees")]
[ApiController]
[Authorize(Roles = "Admin")]
public class AdminEmployeesController(IAdminEmployeesAppService adminEmployeesAppService) : ControllerBase
{
    [HttpGet("permissions")]
    public ActionResult<IReadOnlyList<AdminPermissionDefinitionDto>> GetPermissionDefinitions()
    {
        return Ok(adminEmployeesAppService.GetPermissionDefinitions());
    }

    [HttpGet]
    public async Task<IActionResult> GetEmployees(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20,
        [FromQuery] string? search = null,
        CancellationToken cancellationToken = default)
    {
        var result = await adminEmployeesAppService.GetEmployeesAsync(page, pageSize, search, cancellationToken);
        return Ok(result);
    }

    [HttpGet("{employeeId}")]
    public async Task<IActionResult> GetEmployee(string employeeId, CancellationToken cancellationToken)
    {
        try
        {
            var result = await adminEmployeesAppService.GetEmployeeByIdAsync(employeeId, cancellationToken);
            return Ok(result);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
    }

    [HttpPost]
    public async Task<IActionResult> CreateEmployee(
        [FromBody] CreateAdminEmployeeRequest request,
        CancellationToken cancellationToken)
    {
        try
        {
            var result = await adminEmployeesAppService.CreateEmployeeAsync(request, cancellationToken);
            return Ok(result);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPut("{employeeId}")]
    public async Task<IActionResult> UpdateEmployee(
        string employeeId,
        [FromBody] UpdateAdminEmployeeRequest request,
        CancellationToken cancellationToken)
    {
        try
        {
            var result = await adminEmployeesAppService.UpdateEmployeeAsync(employeeId, request, cancellationToken);
            return Ok(result);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
    }

    [HttpDelete("{employeeId}")]
    public async Task<IActionResult> DeleteEmployee(string employeeId, CancellationToken cancellationToken)
    {
        try
        {
            await adminEmployeesAppService.DeleteEmployeeAsync(employeeId, cancellationToken);
            return Ok(new { message = "Employee deleted." });
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
    }
}
