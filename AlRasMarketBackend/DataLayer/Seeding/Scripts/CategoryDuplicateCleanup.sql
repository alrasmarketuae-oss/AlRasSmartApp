-- Preview duplicate categories (same name, case-insensitive)
SELECT
    LOWER(LTRIM(RTRIM(NameEn))) AS NameKey,
    COUNT(*) AS DuplicateCount,
    MIN(CategoryId) AS KeepId,
    STRING_AGG(CAST(CategoryId AS varchar(10)), ', ') WITHIN GROUP (ORDER BY CategoryId) AS AllIds
FROM Categories
GROUP BY LOWER(LTRIM(RTRIM(NameEn)))
HAVING COUNT(*) > 1
ORDER BY NameKey;

BEGIN TRANSACTION;

-- 1) Point products to the keeper (lowest CategoryId per name)
UPDATE p
SET p.CategoryId = map.KeepId
FROM Products p
INNER JOIN Categories c ON c.CategoryId = p.CategoryId
INNER JOIN (
    SELECT
        LOWER(LTRIM(RTRIM(NameEn))) AS NameKey,
        MIN(CategoryId) AS KeepId
    FROM Categories
    GROUP BY LOWER(LTRIM(RTRIM(NameEn)))
) map ON map.NameKey = LOWER(LTRIM(RTRIM(c.NameEn)))
WHERE p.CategoryId <> map.KeepId;

-- 2) Delete duplicate category rows (keep lowest CategoryId)
DELETE c
FROM Categories c
INNER JOIN (
    SELECT
        LOWER(LTRIM(RTRIM(NameEn))) AS NameKey,
        MIN(CategoryId) AS KeepId
    FROM Categories
    GROUP BY LOWER(LTRIM(RTRIM(NameEn)))
) map ON map.NameKey = LOWER(LTRIM(RTRIM(c.NameEn)))
WHERE c.CategoryId <> map.KeepId;

-- Verify: should return no rows
SELECT
    LOWER(LTRIM(RTRIM(NameEn))) AS NameKey,
    COUNT(*) AS DuplicateCount
FROM Categories
GROUP BY LOWER(LTRIM(RTRIM(NameEn)))
HAVING COUNT(*) > 1;

COMMIT TRANSACTION;
