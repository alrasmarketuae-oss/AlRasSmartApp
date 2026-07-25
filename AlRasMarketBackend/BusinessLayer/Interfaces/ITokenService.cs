using DataLayer.Models;

namespace BusinessLayer.Interfaces;

public interface ITokenService
{
    string CreateToken(User user, IReadOnlyList<string>? permissionKeys = null);
    string GetRoleName(byte roleId);
}
