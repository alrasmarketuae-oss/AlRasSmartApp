-- Ensures OrderStatus rows 1–6 exist (fixes FK_Orders_Status on order insert).
-- Run once on RasAlSouqDb if POST /api/Orders fails with FK_Orders_Status.

SET IDENTITY_INSERT dbo.OrderStatus ON;

IF NOT EXISTS (SELECT 1 FROM dbo.OrderStatus WHERE Id = 1)
    INSERT INTO dbo.OrderStatus (Id, Name) VALUES (1, N'Ordered');
ELSE
    UPDATE dbo.OrderStatus SET Name = N'Ordered' WHERE Id = 1;

IF NOT EXISTS (SELECT 1 FROM dbo.OrderStatus WHERE Id = 2)
    INSERT INTO dbo.OrderStatus (Id, Name) VALUES (2, N'Approved');
ELSE
    UPDATE dbo.OrderStatus SET Name = N'Approved' WHERE Id = 2;

IF NOT EXISTS (SELECT 1 FROM dbo.OrderStatus WHERE Id = 3)
    INSERT INTO dbo.OrderStatus (Id, Name) VALUES (3, N'Paid');
ELSE
    UPDATE dbo.OrderStatus SET Name = N'Paid' WHERE Id = 3;

IF NOT EXISTS (SELECT 1 FROM dbo.OrderStatus WHERE Id = 4)
    INSERT INTO dbo.OrderStatus (Id, Name) VALUES (4, N'Shipping');
ELSE
    UPDATE dbo.OrderStatus SET Name = N'Shipping' WHERE Id = 4;

IF NOT EXISTS (SELECT 1 FROM dbo.OrderStatus WHERE Id = 5)
    INSERT INTO dbo.OrderStatus (Id, Name) VALUES (5, N'Delivered');
ELSE
    UPDATE dbo.OrderStatus SET Name = N'Delivered' WHERE Id = 5;

IF NOT EXISTS (SELECT 1 FROM dbo.OrderStatus WHERE Id = 6)
    INSERT INTO dbo.OrderStatus (Id, Name) VALUES (6, N'Cancelled');
ELSE
    UPDATE dbo.OrderStatus SET Name = N'Cancelled' WHERE Id = 6;

SET IDENTITY_INSERT dbo.OrderStatus OFF;

SELECT Id, Name FROM dbo.OrderStatus ORDER BY Id;
