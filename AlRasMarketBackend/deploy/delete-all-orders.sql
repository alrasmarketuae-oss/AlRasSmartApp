/*
    Deletes ALL orders and every row that depends on them.

    Order of deletion respects foreign keys:
      - ContentTranslations.OrderId is a RESTRICT FK -> must be cleared first.
      - The rest (Balances, InternationalShipments, OrderVideos, OrderImages,
        OrderStatusHistories, PendingPayments) are CASCADE, but we delete them
        explicitly so the script also works if the DB was created without cascade.

    Safe to run once. Wrapped in a transaction: nothing is committed if any step fails.
    NOTE: This is DESTRUCTIVE and irreversible. Take a backup first.
*/

SET NOCOUNT OFF;
SET XACT_ABORT ON;

BEGIN TRANSACTION;

BEGIN TRY
    -- 1) RESTRICT FK: order-scoped translations must go first.
    DELETE FROM ContentTranslations WHERE OrderId IS NOT NULL;
    PRINT CONCAT('ContentTranslations (order-scoped) deleted: ', @@ROWCOUNT);

    -- 2) Ledger rows tied to orders.
    DELETE FROM Balances WHERE OrderId IS NOT NULL;
    PRINT CONCAT('Balances (order-scoped) deleted: ', @@ROWCOUNT);

    -- 3) Payment sessions tied to orders.
    DELETE FROM PendingPayments WHERE OrderId IN (SELECT Id FROM Orders);
    PRINT CONCAT('PendingPayments deleted: ', @@ROWCOUNT);

    -- 4) International shipments created from orders.
    DELETE FROM InternationalShipments WHERE OrderId IN (SELECT Id FROM Orders);
    PRINT CONCAT('InternationalShipments deleted: ', @@ROWCOUNT);

    -- 5) Order media + status history.
    DELETE FROM OrderStatusHistories WHERE OrderId IN (SELECT Id FROM Orders);
    PRINT CONCAT('OrderStatusHistories deleted: ', @@ROWCOUNT);

    DELETE FROM OrderVideos WHERE OrderId IN (SELECT Id FROM Orders);
    PRINT CONCAT('OrderVideos deleted: ', @@ROWCOUNT);

    DELETE FROM OrderImages WHERE OrderId IN (SELECT Id FROM Orders);
    PRINT CONCAT('OrderImages deleted: ', @@ROWCOUNT);

    -- 6) Finally, the orders themselves.
    DELETE FROM Orders;
    PRINT CONCAT('Orders deleted: ', @@ROWCOUNT);

    -- Optional: restart the Orders identity so new orders start from 1.
    -- Comment this line out if you want IDs to keep counting up.
    DBCC CHECKIDENT ('Orders', RESEED, 0);

    COMMIT TRANSACTION;
    PRINT 'DONE: all orders removed and committed.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
    PRINT CONCAT('FAILED, rolled back. Error: ', ERROR_MESSAGE());
    THROW;
END CATCH;
