-- Run once on an existing RasAlSouq DB that already has Categories rows.
-- Renames legacy rows, inserts missing canonical categories, removes unused Cumin when safe.
-- Backup the database before running.

UPDATE Categories SET NameEn = N'Pulses', ImgPath = N'/images/categories/pulses.jpg' WHERE NameEn = N'Legumes';
UPDATE Categories SET NameEn = N'Canned', ImgPath = N'/images/categories/canned-foods.jpg' WHERE NameEn = N'Canned Foods';

IF NOT EXISTS (SELECT 1 FROM Categories WHERE NameEn = N'Coffee')
    INSERT INTO Categories (NameEn, ImgPath) VALUES (N'Coffee', N'/images/categories/coffee.jpg');
IF NOT EXISTS (SELECT 1 FROM Categories WHERE NameEn = N'Poultry')
    INSERT INTO Categories (NameEn, ImgPath) VALUES (N'Poultry', N'/images/categories/poultry.jpg');
IF NOT EXISTS (SELECT 1 FROM Categories WHERE NameEn = N'Frozen Foods')
    INSERT INTO Categories (NameEn, ImgPath) VALUES (N'Frozen Foods', N'/images/categories/frozen-foods.jpg');

DELETE FROM Categories
WHERE NameEn = N'Cumin'
  AND NOT EXISTS (SELECT 1 FROM Products P WHERE P.CategoryId = Categories.CategoryId);
