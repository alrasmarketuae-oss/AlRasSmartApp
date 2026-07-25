-- Offer listings must not auto-pause when the discount window ends.
-- Discount expiry only restores full price (handled in app code).
-- Clear display expiry for existing offer products and reactivate wrongly paused offers.

UPDATE p
SET p.DisplayExpiresAtUtc = NULL
FROM Products p
WHERE p.ProductTypeId = 3
  AND p.DisplayExpiresAtUtc IS NOT NULL;

UPDATE p
SET p.Status = 2,
    p.UpdatedAt = GETUTCDATE()
FROM Products p
WHERE p.ProductTypeId = 3
  AND p.IsApproved = 1
  AND p.Status = 3
  AND p.DisplayExpiresAtUtc IS NULL;
