-- Reactivate listings that were auto-paused when the display window ended.
-- Public visibility is already controlled by DisplayExpiresAtUtc in catalog queries.

UPDATE p
SET p.Status = 2,
    p.UpdatedAt = GETUTCDATE()
FROM Products p
WHERE p.ProductTypeId <> 3
  AND p.Status = 3
  AND p.Quantity > 0
  AND p.DisplayExpiresAtUtc IS NOT NULL
  AND p.DisplayExpiresAtUtc <= GETUTCDATE();
