/*
  Fix ads wrongly marked as "edit" after first create media uploads.
  Clears PendingProductChanges / UpdatedAt when the snapshot is NOT from a
  previously approved live ad (IsApproved=true in JSON).
*/
UPDATE dbo.Products
SET
    PendingProductChanges = NULL,
    UpdatedAt = NULL
WHERE IsApproved = 0
  AND Status <> 5 /* Rejected */
  AND (
        PendingProductChanges IS NOT NULL
        OR UpdatedAt IS NOT NULL
      )
  AND (
        PendingProductChanges IS NULL
        OR (
            PendingProductChanges NOT LIKE '%"isApproved":true%'
            AND PendingProductChanges NOT LIKE '%"IsApproved":true%'
        )
      );
GO
