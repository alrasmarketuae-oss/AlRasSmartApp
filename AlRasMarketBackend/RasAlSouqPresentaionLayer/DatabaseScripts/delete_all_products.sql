/*
================================================================================
  delete_all_products.sql
  يحذف كل المنتجات (الإعلانات) من قاعدة البيانات، مع كل ما يرتبط بها:
  صور / فيديوهات / مستندات / ترجمات / طلبات / عروض / سلة / مدفوعات معلقة...

  يُبقي: المستخدمين، الأقسام، الدول، المدن، الموانئ، البانرات، الإعدادات.

  تحذير: عملية لا رجعة فيها. خذ Backup قبل التشغيل.
  ضع @Confirm = 1 للتنفيذ الفعلي.
================================================================================
*/

SET NOCOUNT ON;
SET XACT_ABORT ON;

-- غيّر اسم القاعدة إن لزم
-- USE [YourDatabaseName];
-- GO

DECLARE @Confirm BIT = 0; -- ضع 1 للتنفيذ

IF @Confirm <> 1
BEGIN
    RAISERROR(N'لم يُنفَّذ شيء: عيّن @Confirm = 1 بعد أخذ نسخة احتياطية.', 16, 1);
    RETURN;
END;

PRINT N'=== قبل الحذف ===';
SELECT N'Products' AS [Table], COUNT(*) AS Cnt FROM dbo.Products;
IF OBJECT_ID(N'dbo.ProductImages', N'U') IS NOT NULL
    SELECT N'ProductImages' AS [Table], COUNT(*) AS Cnt FROM dbo.ProductImages;
IF OBJECT_ID(N'dbo.Orders', N'U') IS NOT NULL
    SELECT N'Orders' AS [Table], COUNT(*) AS Cnt FROM dbo.Orders;

BEGIN TRY
    BEGIN TRANSACTION;

    ------------------------------------------------------------
    -- 1) Offer-on-request assets (قبل حذف الطلبات/العروض)
    ------------------------------------------------------------
    IF OBJECT_ID(N'dbo.OfferOnRequestImages', N'U') IS NOT NULL
        DELETE FROM dbo.OfferOnRequestImages;

    IF OBJECT_ID(N'dbo.OfferOnRequestDocuments', N'U') IS NOT NULL
        DELETE FROM dbo.OfferOnRequestDocuments;

    IF OBJECT_ID(N'dbo.OffersOnRequests', N'U') IS NOT NULL
        DELETE FROM dbo.OffersOnRequests;

    IF OBJECT_ID(N'dbo.OffersOnNegotiable', N'U') IS NOT NULL
        DELETE FROM dbo.OffersOnNegotiable;

    IF OBJECT_ID(N'dbo.Offers', N'U') IS NOT NULL
        DELETE FROM dbo.Offers;

    ------------------------------------------------------------
    -- 2) Order children ثم Orders (مرتبطة بـ ProductId)
    ------------------------------------------------------------
    IF OBJECT_ID(N'dbo.OrderStatusHistories', N'U') IS NOT NULL
        DELETE FROM dbo.OrderStatusHistories;

    IF OBJECT_ID(N'dbo.OrderStatusHistory', N'U') IS NOT NULL
        DELETE FROM dbo.OrderStatusHistory;

    IF OBJECT_ID(N'dbo.OrderImages', N'U') IS NOT NULL
        DELETE FROM dbo.OrderImages;

    IF OBJECT_ID(N'dbo.OrderVideos', N'U') IS NOT NULL
        DELETE FROM dbo.OrderVideos;

    IF OBJECT_ID(N'dbo.OrderReturns', N'U') IS NOT NULL
        DELETE FROM dbo.OrderReturns;

    IF OBJECT_ID(N'dbo.PendingPayments', N'U') IS NOT NULL
        DELETE FROM dbo.PendingPayments;

    IF OBJECT_ID(N'dbo.InternationalShipments', N'U') IS NOT NULL
        DELETE FROM dbo.InternationalShipments;

    IF OBJECT_ID(N'dbo.Orders', N'U') IS NOT NULL
        DELETE FROM dbo.Orders;

    IF OBJECT_ID(N'dbo.PendingOrderItems', N'U') IS NOT NULL
        DELETE FROM dbo.PendingOrderItems;

    IF OBJECT_ID(N'dbo.PendingOrders', N'U') IS NOT NULL
        DELETE FROM dbo.PendingOrders;

    ------------------------------------------------------------
    -- 3) Cart
    ------------------------------------------------------------
    IF OBJECT_ID(N'dbo.CartItems', N'U') IS NOT NULL
        DELETE FROM dbo.CartItems;

    ------------------------------------------------------------
    -- 4) Product media + translations
    ------------------------------------------------------------
    IF OBJECT_ID(N'dbo.ProductImages', N'U') IS NOT NULL
        DELETE FROM dbo.ProductImages;

    IF OBJECT_ID(N'dbo.ProductDocuments', N'U') IS NOT NULL
        DELETE FROM dbo.ProductDocuments;

    IF OBJECT_ID(N'dbo.ProductVideos', N'U') IS NOT NULL
        DELETE FROM dbo.ProductVideos;

    IF OBJECT_ID(N'dbo.ContentTranslations', N'U') IS NOT NULL
        DELETE FROM dbo.ContentTranslations
        WHERE Scope = N'Product' OR ProductId IS NOT NULL;

    ------------------------------------------------------------
    -- 5) Products
    ------------------------------------------------------------
    DELETE FROM dbo.Products;

    COMMIT TRANSACTION;

    PRINT N'=== بعد الحذف ===';
    SELECT N'Products' AS [Table], COUNT(*) AS Cnt FROM dbo.Products;
    IF OBJECT_ID(N'dbo.ProductImages', N'U') IS NOT NULL
        SELECT N'ProductImages' AS [Table], COUNT(*) AS Cnt FROM dbo.ProductImages;
    IF OBJECT_ID(N'dbo.Orders', N'U') IS NOT NULL
        SELECT N'Orders' AS [Table], COUNT(*) AS Cnt FROM dbo.Orders;

    PRINT N'تم حذف كل المنتجات بنجاح.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    DECLARE @Err NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR(@Err, 16, 1);
END CATCH;
GO
