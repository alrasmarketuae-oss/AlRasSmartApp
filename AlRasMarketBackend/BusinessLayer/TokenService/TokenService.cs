using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using BusinessLayer.Interfaces;
using DataLayer.Models;
using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;

namespace BusinessLayer.TokenService;

public class TokenService(IConfiguration configuration) : ITokenService
{
    private readonly IConfiguration _configuration = configuration;

    public string CreateToken(User user, IReadOnlyList<string>? permissionKeys = null)
    {
        var key = _configuration["JwtSettings:Key"] ?? throw new InvalidOperationException("Missing JwtSettings:Key");
        var issuer = _configuration["JwtSettings:Issuer"];
        var audience = _configuration["JwtSettings:Audience"];

        var claims = new List<Claim>
        {
            new(JwtRegisteredClaimNames.Sub, user.Id.ToString()),
            new("EntityId", user.Id.ToString()),
            new(JwtRegisteredClaimNames.Email, user.Email),
            new(ClaimTypes.Role, GetRoleName(user.RoleId)),
            new("fullName", user.FullName),
            new("imgPath", user.ImgPath ?? string.Empty),
            new(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString())
        };

        if (permissionKeys is { Count: > 0 })
        {
            foreach (var permission in permissionKeys)
            {
                claims.Add(new Claim("permission", permission));
            }
        }

        var signingKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(key));
        var creds = new SigningCredentials(signingKey, SecurityAlgorithms.HmacSha256);
        var descriptor = new SecurityTokenDescriptor
        {
            Subject = new ClaimsIdentity(claims),
            Expires = DateTime.UtcNow.AddYears(24),
            SigningCredentials = creds,
            Issuer = issuer,
            Audience = audience
        };

        var handler = new JwtSecurityTokenHandler();
        var token = handler.CreateToken(descriptor);
        return handler.WriteToken(token);
    }

    public string GetRoleName(byte roleId)
    {
        return roleId switch
        {
            1 => "Admin",
            2 => "Seller",
            3 => "Buyer",
            4 => "Employee",
            5 => "ShippingCompany",
            _ => "Unknown"
        };
    }
}
