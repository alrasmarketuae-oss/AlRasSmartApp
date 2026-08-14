namespace DataLayer.Models;

public static class ContentTranslationScopes
{
    public const string Product = "Product";
    public const string Order = "Order";
    public const string User = "User";
}

public static class ContentTranslationFields
{
    public const string Name = "Name";
    public const string Description = "Description";
    public const string RetailDescription = "RetailDescription";
    public const string SupplierNotes = "SupplierNotes";
    public const string ShippingDescription = "ShippingDescription";
    public const string OfferNotes = "OfferNotes";
    public const string FullName = "FullName";
    public const string CompanyName = "CompanyName";
}

/// <summary>AI bilingual store for product text, order offer notes, and user names.</summary>
public class ContentTranslation
{
    public Guid Id { get; set; }

    /// <summary><see cref="ContentTranslationScopes"/>.</summary>
    public string Scope { get; set; } = string.Empty;

    public Guid? ProductId { get; set; }

    public long? OrderId { get; set; }

    public Guid? UserId { get; set; }

    /// <summary><see cref="ContentTranslationFields"/>.</summary>
    public string Field { get; set; } = string.Empty;

    public string? TextAr { get; set; }

    public string? TextEn { get; set; }

    /// <summary>ar or en — language of the user-entered source text.</summary>
    public string SourceLanguage { get; set; } = "en";

    /// <summary>Hash of the source text to skip re-translation when unchanged.</summary>
    public string SourceHash { get; set; } = string.Empty;

    public DateTime UpdatedAtUtc { get; set; } = DateTime.UtcNow;

    public Product? Product { get; set; }

    public Order? Order { get; set; }

    public User? User { get; set; }
}
