-- =============================================================================
-- Ras Al Souq — Categories bilingual names (NameAr)
-- Run once on SQL Server. Safe to re-run (idempotent checks).
-- =============================================================================

IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID(N'dbo.Categories') AND name = N'NameAr')
BEGIN
    ALTER TABLE dbo.Categories
    ADD NameAr NVARCHAR(255) NOT NULL
        CONSTRAINT DF_Categories_NameAr DEFAULT N'';
END
GO

-- Canonical Arabic labels (only fill when still empty)
UPDATE dbo.Categories SET NameAr = N'أعشاب'     WHERE NameEn = N'Herbs'         AND LTRIM(RTRIM(NameAr)) = N'';
UPDATE dbo.Categories SET NameAr = N'بقوليات'    WHERE NameEn = N'Pulses'        AND LTRIM(RTRIM(NameAr)) = N'';
UPDATE dbo.Categories SET NameAr = N'توابل'      WHERE NameEn = N'Spices'        AND LTRIM(RTRIM(NameAr)) = N'';
UPDATE dbo.Categories SET NameAr = N'مكسرات'     WHERE NameEn = N'Nuts'          AND LTRIM(RTRIM(NameAr)) = N'';
UPDATE dbo.Categories SET NameAr = N'قهوة'       WHERE NameEn = N'Coffee'        AND LTRIM(RTRIM(NameAr)) = N'';
UPDATE dbo.Categories SET NameAr = N'الهيل'      WHERE NameEn = N'Cardamom'      AND LTRIM(RTRIM(NameAr)) = N'';
UPDATE dbo.Categories SET NameAr = N'كاكو'       WHERE NameEn = N'Cocoa'         AND LTRIM(RTRIM(NameAr)) = N'';
UPDATE dbo.Categories SET NameAr = N'أحماض'      WHERE NameEn = N'Acids'         AND LTRIM(RTRIM(NameAr)) = N'';
UPDATE dbo.Categories SET NameAr = N'حليب'       WHERE NameEn = N'Milk'          AND LTRIM(RTRIM(NameAr)) = N'';
UPDATE dbo.Categories SET NameAr = N'تمور'      WHERE NameEn = N'Dates'         AND LTRIM(RTRIM(NameAr)) = N'';
UPDATE dbo.Categories SET NameAr = N'سكر'       WHERE NameEn = N'Sugar'         AND LTRIM(RTRIM(NameAr)) = N'';
UPDATE dbo.Categories SET NameAr = N'أرز'        WHERE NameEn = N'Rice'          AND LTRIM(RTRIM(NameAr)) = N'';
UPDATE dbo.Categories SET NameAr = N'حلويات'     WHERE NameEn = N'Sweets'        AND LTRIM(RTRIM(NameAr)) = N'';
UPDATE dbo.Categories SET NameAr = N'معلبات'     WHERE NameEn IN (N'Canned', N'Canned Foods') AND LTRIM(RTRIM(NameAr)) = N'';
UPDATE dbo.Categories SET NameAr = N'طحين'       WHERE NameEn = N'Flour'         AND LTRIM(RTRIM(NameAr)) = N'';
UPDATE dbo.Categories SET NameAr = N'تجميل'      WHERE NameEn = N'Beauty'        AND LTRIM(RTRIM(NameAr)) = N'';
UPDATE dbo.Categories SET NameAr = N'دواجن'      WHERE NameEn = N'Poultry'       AND LTRIM(RTRIM(NameAr)) = N'';
UPDATE dbo.Categories SET NameAr = N'مجمدات'     WHERE NameEn = N'Frozen Foods'  AND LTRIM(RTRIM(NameAr)) = N'';

-- Fallback: copy English name for any custom category still missing Arabic
UPDATE dbo.Categories
SET NameAr = NameEn
WHERE LTRIM(RTRIM(NameAr)) = N'';
GO

-- Optional: verify
SELECT CategoryId, NameEn, NameAr, ImgPath, IsHide, CommissionPercent
FROM dbo.Categories
ORDER BY CategoryId;
GO
