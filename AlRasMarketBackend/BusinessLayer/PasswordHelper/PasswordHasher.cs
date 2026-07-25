using System.Security.Cryptography;
using System.Text;
using BusinessLayer.Interfaces;
using Konscious.Security.Cryptography;

namespace BusinessLayer.PasswordHelper;

public class PasswordHasher : IPasswordHasher
{
    public string HashPassword(string password)
    {
        var salt = RandomNumberGenerator.GetBytes(16);
        using var argon2 = new Argon2id(Encoding.UTF8.GetBytes(password))
        {
            Salt = salt,
            DegreeOfParallelism = 4,
            Iterations = 3,
            MemorySize = 65536
        };

        var hash = argon2.GetBytes(32);
        return $"{Convert.ToBase64String(salt)}.{Convert.ToBase64String(hash)}";
    }

    public bool VerifyPassword(string password, string hashedPassword)
    {
        var parts = hashedPassword.Split('.');
        if (parts.Length != 2)
        {
            return false;
        }

        var salt = Convert.FromBase64String(parts[0]);
        var storedHash = Convert.FromBase64String(parts[1]);
        using var argon2 = new Argon2id(Encoding.UTF8.GetBytes(password))
        {
            Salt = salt,
            DegreeOfParallelism = 4,
            Iterations = 3,
            MemorySize = 65536
        };
        var computedHash = argon2.GetBytes(32);
        return CryptographicOperations.FixedTimeEquals(storedHash, computedHash);
    }
}
