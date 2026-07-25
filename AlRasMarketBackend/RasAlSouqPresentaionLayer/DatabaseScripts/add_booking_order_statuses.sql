-- Booking orders + order status workflow (Ordered → Approved → Paid → Shipping → Delivered)
-- Run once on existing RasAlSouq DB. Backup first.

-- Rename early statuses
UPDATE dbo.OrderStatus SET Name = N'Ordered' WHERE Id = 1;
UPDATE dbo.OrderStatus SET Name = N'Approved' WHERE Id = 2;
UPDATE dbo.OrderStatus SET Name = N'Paid' WHERE Id = 3;

-- Old Id=4 was Delivered, Id=5 was Cancelled → shift to new layout
IF EXISTS (SELECT 1 FROM dbo.OrderStatus WHERE Id = 5 AND Name IN (N'Cancelled', N'Cancelled'))
BEGIN
    SET IDENTITY_INSERT dbo.OrderStatus ON;
    IF NOT EXISTS (SELECT 1 FROM dbo.OrderStatus WHERE Id = 6)
        INSERT INTO dbo.OrderStatus (Id, Name) VALUES (6, N'Cancelled');
    SET IDENTITY_INSERT dbo.OrderStatus OFF;

    UPDATE dbo.Orders SET StatusId = 6 WHERE StatusId = 5;
END

IF EXISTS (SELECT 1 FROM dbo.OrderStatus WHERE Id = 4 AND Name IN (N'Delivered', N'Delivered'))
BEGIN
    SET IDENTITY_INSERT dbo.OrderStatus ON;
    IF NOT EXISTS (SELECT 1 FROM dbo.OrderStatus WHERE Id = 5)
        INSERT INTO dbo.OrderStatus (Id, Name) VALUES (5, N'Delivered');
    SET IDENTITY_INSERT dbo.OrderStatus OFF;

    UPDATE dbo.Orders SET StatusId = 5 WHERE StatusId = 4;
END

UPDATE dbo.OrderStatus SET Name = N'Shipping' WHERE Id = 4;

IF NOT EXISTS (SELECT 1 FROM dbo.OrderStatus WHERE Id = 5)
BEGIN
    SET IDENTITY_INSERT dbo.OrderStatus ON;
    INSERT INTO dbo.OrderStatus (Id, Name) VALUES (5, N'Delivered');
    SET IDENTITY_INSERT dbo.OrderStatus OFF;
END
ELSE
    UPDATE dbo.OrderStatus SET Name = N'Delivered' WHERE Id = 5;

IF NOT EXISTS (SELECT 1 FROM dbo.OrderStatus WHERE Id = 6)
BEGIN
    SET IDENTITY_INSERT dbo.OrderStatus ON;
    INSERT INTO dbo.OrderStatus (Id, Name) VALUES (6, N'Cancelled');
    SET IDENTITY_INSERT dbo.OrderStatus OFF;
END
ELSE
    UPDATE dbo.OrderStatus SET Name = N'Cancelled' WHERE Id = 6;
