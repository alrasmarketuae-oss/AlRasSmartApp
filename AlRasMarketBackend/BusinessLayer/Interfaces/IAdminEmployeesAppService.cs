using BusinessLayer.Dtos;

namespace BusinessLayer.Interfaces;

public interface IAdminEmployeesAppService
{
    IReadOnlyList<AdminPermissionDefinitionDto> GetPermissionDefinitions();
    Task<AdminEmployeesListResponseDto> GetEmployeesAsync(
        int page,
        int pageSize,
        string? search,
        CancellationToken ct = default);
    Task<AdminEmployeeDetailDto> GetEmployeeByIdAsync(string employeeId, CancellationToken ct = default);
    Task<AdminEmployeeDetailDto> CreateEmployeeAsync(CreateAdminEmployeeRequest request, CancellationToken ct = default);
    Task<AdminEmployeeDetailDto> UpdateEmployeeAsync(string employeeId, UpdateAdminEmployeeRequest request, CancellationToken ct = default);
    Task DeleteEmployeeAsync(string employeeId, CancellationToken ct = default);
}
