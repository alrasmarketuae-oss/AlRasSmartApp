namespace BusinessLayer.Dtos;

public sealed record AdminPermissionDefinitionDto(
    string Key,
    string LabelAr,
    string LabelEn,
    string GroupKey,
    string GroupLabelAr,
    string GroupLabelEn);

public sealed record AdminEmployeeListItemDto(
    string Id,
    string FullName,
    string Email,
    string? PhoneNumber,
    bool IsActive,
    IReadOnlyList<string> Permissions,
    string CreatedAt);

public sealed record AdminEmployeesListResponseDto(
    IReadOnlyList<AdminEmployeeListItemDto> Items,
    int TotalCount,
    int Page,
    int PageSize,
    int TotalPages);

public sealed record AdminEmployeeDetailDto(
    string Id,
    string FullName,
    string Email,
    string? PhoneNumber,
    bool IsActive,
    IReadOnlyList<string> Permissions,
    string CreatedAt);

public sealed record CreateAdminEmployeeRequest(
    string FullName,
    string Email,
    string Password,
    string? PhoneNumber,
    IReadOnlyList<string> Permissions);

public sealed record UpdateAdminEmployeeRequest(
    string FullName,
    string? PhoneNumber,
    bool IsActive,
    IReadOnlyList<string> Permissions,
    string? NewPassword);
