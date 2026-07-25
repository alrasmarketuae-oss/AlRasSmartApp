-- Removes duplicate Categories rows (same NameEn).
-- Keeps the row with the lowest CategoryId; reassigns Products to the kept row.
-- Known duplicates in your DB: Canned (18, 44), Pulses (21, 46).
-- Backup the database before running.

SET NOCOUNT ON;

-- Preview duplicates (run alone first if you want to inspect)
SELECT
    c.CategoryId,
    c.NameEn,
    c.ImgPath,
    (SELECT COUNT(*) FROM Products p WHERE p.CategoryId = c.CategoryId) AS ProductCount,
    CASE
        WHEN c.CategoryId = d.KeepId THEN N'KEEP'
        ELSE N'DELETE'
    END AS Action
FROM Categories c
INNER JOIN (
    SELECT NameEn, MIN(CategoryId) AS KeepId
    FROM Categories
    GROUP BY NameEn
    HAVING COUNT(*) > 1
) d ON c.NameEn = d.NameEn
ORDER BY c.NameEn, c.CategoryId;

BEGIN TRANSACTION;

BEGIN TRY
    ;WITH DuplicateGroups AS (
        SELECT NameEn, MIN(CategoryId) AS KeepId
        FROM Categories
        GROUP BY NameEn
        HAVING COUNT(*) > 1
    ),
    ToRemove AS (
        SELECT c.CategoryId AS RemoveId, d.KeepId
        FROM Categories c
        INNER JOIN DuplicateGroups d ON c.NameEn = d.NameEn
        WHERE c.CategoryId <> d.KeepId
    )
    UPDATE p
    SET p.CategoryId = tr.KeepId
    FROM Products p
    INNER JOIN ToRemove tr ON p.CategoryId = tr.RemoveId;

    ;WITH DuplicateGroups AS (
        SELECT NameEn, MIN(CategoryId) AS KeepId
        FROM Categories
        GROUP BY NameEn
        HAVING COUNT(*) > 1
    )
    DELETE c
    FROM Categories c
    INNER JOIN DuplicateGroups d ON c.NameEn = d.NameEn
    WHERE c.CategoryId <> d.KeepId;

    COMMIT TRANSACTION;

    PRINT N'Duplicate categories removed successfully.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    THROW;
END CATCH;

-- Verify: should return no rows
SELECT NameEn, COUNT(*) AS Cnt
FROM Categories
GROUP BY NameEn
HAVING COUNT(*) > 1;
