-- Adds PortId to Orders for booking orders (selected port).
IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID(N'dbo.Orders') AND name = N'PortId'
)
BEGIN
    ALTER TABLE dbo.Orders ADD PortId INT NULL;
END
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Orders_Ports'
)
AND EXISTS (SELECT 1 FROM sys.tables WHERE name = N'Ports')
AND EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID(N'dbo.Orders') AND name = N'PortId'
)
BEGIN
    ALTER TABLE dbo.Orders
        ADD CONSTRAINT FK_Orders_Ports FOREIGN KEY (PortId) REFERENCES dbo.Ports(Id);
END
GO
