/*
    Zeroes every supplier's wallet balance.

    Balance is NOT stored as a single number — it is the SUM of all rows in the
    Balances ledger for a user (deposits positive, withdrawals negative).
    So "زَتصفير الرصيد" = make that SUM equal 0.

    Pick ONE option below.

    NOTE:
      - DESTRUCTIVE / irreversible. Take a backup first.
      - The API caches the balance for ~30 minutes (Redis/memory). After running
        this, restart the backend or wait for the cache to expire so "رصيدي"
        shows 0. Deleting the Redis keys "supplier-balance:*" also works.
*/

-------------------------------------------------------------------------------
-- OPTION A (recommended): wipe the whole ledger. Every balance becomes 0.
-- Also clears the per-order deposit/withdrawal history.
-------------------------------------------------------------------------------
BEGIN TRANSACTION;
BEGIN TRY
    DELETE FROM Balances;
    PRINT CONCAT('Balances rows deleted: ', @@ROWCOUNT);

    COMMIT TRANSACTION;
    PRINT 'DONE: all balances zeroed (ledger cleared).';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    PRINT CONCAT('FAILED, rolled back. Error: ', ERROR_MESSAGE());
    THROW;
END CATCH;


/*
-------------------------------------------------------------------------------
-- OPTION B (keep history): add an adjusting entry per user equal to the
-- negative of their current balance, so the SUM becomes 0 but past rows stay.
-- Uncomment this block and comment OPTION A above if you prefer this.
-------------------------------------------------------------------------------
BEGIN TRANSACTION;
BEGIN TRY
    INSERT INTO Balances (Id, UserId, OrderId, BalanceAmount, EntryType, ReasonEn, ReasonAr, CreatedAtUtc)
    SELECT
        REPLACE(CONVERT(varchar(36), NEWID()), '-', ''),   -- 32-char id like the app
        b.UserId,
        NULL,
        -SUM(b.BalanceAmount),                              -- offset to zero
        2,                                                 -- 2 = Withdrawal
        'Balance reset to zero',
        N'تصفير الرصيد',
        GETUTCDATE()
    FROM Balances b
    GROUP BY b.UserId
    HAVING SUM(b.BalanceAmount) <> 0;

    PRINT CONCAT('Adjusting entries inserted: ', @@ROWCOUNT);

    COMMIT TRANSACTION;
    PRINT 'DONE: all balances zeroed (history kept).';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    PRINT CONCAT('FAILED, rolled back. Error: ', ERROR_MESSAGE());
    THROW;
END CATCH;
*/
