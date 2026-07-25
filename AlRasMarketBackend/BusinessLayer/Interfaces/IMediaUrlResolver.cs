namespace BusinessLayer.Interfaces;

public interface IMediaUrlResolver
{
    /// <summary>Canonical relative key stored in DB, e.g. /product-images/x.jpg</summary>
    string ToStorageKey(string? pathOrUrl);

    /// <summary>Absolute public URL for clients (CDN when configured, else API origin).</summary>
    string ToPublicUrl(string? storedPath);
}
