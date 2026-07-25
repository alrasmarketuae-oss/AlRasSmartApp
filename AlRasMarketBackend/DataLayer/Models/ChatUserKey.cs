namespace DataLayer.Models;

/// <summary>
/// Chat encryption keys. Public keys are shared; private keys are synced per account
/// so the same user can decrypt messages across devices.
/// </summary>
public class ChatUserKey
{
    public Guid UserId { get; set; }

    /// <summary>RSA public key as JWK JSON (RSA-OAEP-256). Field name kept for compatibility.</summary>
    public string PublicKeySpkiBase64 { get; set; } = string.Empty;

    /// <summary>
    /// Account private key as JWK JSON (sync across devices).
    /// For the configured support inbox user this is the shared support private key.
    /// </summary>
    public string? SupportPrivateKeyPkcs8Base64 { get; set; }

    public DateTime UpdatedAtUtc { get; set; }

    public User? User { get; set; }
}
