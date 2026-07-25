using DataLayer.Models;

namespace DataLayer.Seeding;

/// <summary>Canonical product categories (order matches marketing / API expectations).</summary>
public static class CanonicalCategories
{
    public static readonly Category[] Seed =
    {
        new() { CategoryId = 1, NameEn = "Herbs", NameAr = "أعشاب", ImgPath = "/images/categories/herbs.jpg" },
        new() { CategoryId = 2, NameEn = "Pulses", NameAr = "بقوليات", ImgPath = "/images/categories/pulses.jpg" },
        new() { CategoryId = 3, NameEn = "Spices", NameAr = "توابل", ImgPath = "/images/categories/spices.jpg" },
        new() { CategoryId = 4, NameEn = "Nuts", NameAr = "مكسرات", ImgPath = "/images/categories/nuts.jpg" },
        new() { CategoryId = 5, NameEn = "Coffee", NameAr = "قهوة", ImgPath = "/images/categories/coffee.jpg" },
        new() { CategoryId = 6, NameEn = "Cardamom", NameAr = "الهيل", ImgPath = "/images/categories/cardamom.jpg" },
        new() { CategoryId = 7, NameEn = "Cocoa", NameAr = "كاكو", ImgPath = "/images/categories/cocoa.jpg" },
        new() { CategoryId = 8, NameEn = "Acids", NameAr = "أحماض", ImgPath = "/images/categories/acids.jpg" },
        new() { CategoryId = 9, NameEn = "Milk", NameAr = "حليب", ImgPath = "/images/categories/milk.jpg" },
        new() { CategoryId = 10, NameEn = "Dates", NameAr = "تمور", ImgPath = "/images/categories/dates.jpg" },
        new() { CategoryId = 11, NameEn = "Sugar", NameAr = "سكر", ImgPath = "/images/categories/sugar.jpg" },
        new() { CategoryId = 12, NameEn = "Rice", NameAr = "أرز", ImgPath = "/images/categories/rice.jpg" },
        new() { CategoryId = 13, NameEn = "Sweets", NameAr = "حلويات", ImgPath = "/images/categories/sweets.jpg" },
        new() { CategoryId = 14, NameEn = "Canned", NameAr = "معلبات", ImgPath = "/images/categories/canned-foods.jpg" },
        new() { CategoryId = 15, NameEn = "Flour", NameAr = "طحين", ImgPath = "/images/categories/flour.jpg" },
        new() { CategoryId = 16, NameEn = "Beauty", NameAr = "تجميل", ImgPath = "/images/categories/beauty.jpg" },
        new() { CategoryId = 17, NameEn = "Poultry", NameAr = "دواجن", ImgPath = "/images/categories/poultry.jpg" },
        new() { CategoryId = 18, NameEn = "Frozen Foods", NameAr = "مجمدات", ImgPath = "/images/categories/frozen-foods.jpg" }
    };
}
