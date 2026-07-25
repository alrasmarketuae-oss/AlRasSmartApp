/*
  Category-only ads should have ProductTypeId = NULL (Type empty in dashboard).
  The mobile app now sends ProductTypeName = 'Categories'; the API clears the type.

  To fix one ad that was saved as Retail by mistake, run for that product only:
*/
-- UPDATE dbo.Products
-- SET ProductTypeId = NULL
-- WHERE ProductId = 'YOUR-PRODUCT-GUID-HERE'
--   AND CategoryId IS NOT NULL;
