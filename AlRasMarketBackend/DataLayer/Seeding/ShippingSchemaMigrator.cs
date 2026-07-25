using DataLayer.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace DataLayer.Seeding;

/// <summary>Creates ShipmentStatuses + InternationalShipments if missing (idempotent, no DROP).</summary>
public static class ShippingSchemaMigrator
{
    public static async Task EnsureAsync(IRasAlSouqDbContext db, CancellationToken cancellationToken = default)
    {
        var context = (DbContext)db;
        var connection = context.Database.GetDbConnection();
        await SqlSchemaHelper.OpenIfNeededAsync(connection, cancellationToken).ConfigureAwait(false);

        await SqlSchemaHelper.ExecuteBatchAsync(connection, ShipmentStatusesBatch, cancellationToken).ConfigureAwait(false);

        if (await SqlSchemaHelper.TableExistsAsync(connection, "InternationalShipments", cancellationToken).ConfigureAwait(false))
        {
            return;
        }

        var orderIdType = await SqlSchemaHelper.GetColumnSqlTypeAsync(connection, "Orders", "Id", cancellationToken)
            .ConfigureAwait(false);
        var providerUserIdType = await SqlSchemaHelper.GetColumnSqlTypeAsync(connection, "Users", "Id", cancellationToken)
            .ConfigureAwait(false);

        if (orderIdType is null || providerUserIdType is null)
        {
            throw new InvalidOperationException(
                "Cannot create InternationalShipments: dbo.Orders.Id or dbo.Users.Id was not found.");
        }

        var createShipmentsSql = string.Format(
            CreateInternationalShipmentsTemplate,
            orderIdType,
            providerUserIdType);

        await SqlSchemaHelper.ExecuteBatchAsync(connection, createShipmentsSql, cancellationToken).ConfigureAwait(false);
    }

    private const string ShipmentStatusesBatch = """
        IF OBJECT_ID(N'dbo.ShipmentStatuses', N'U') IS NULL
        BEGIN
            CREATE TABLE dbo.ShipmentStatuses (
                Id TINYINT NOT NULL PRIMARY KEY,
                NameEn VARCHAR(50) NOT NULL,
                NameAr NVARCHAR(50) NOT NULL
            );

            INSERT INTO dbo.ShipmentStatuses (Id, NameEn, NameAr) VALUES
                (1, N'Pending', N'قيد الانتظار'),
                (2, N'InDelivery', N'قيد التوصيل'),
                (3, N'Completed', N'مكتمل'),
                (4, N'Late', N'متأخر');
        END
        ELSE IF NOT EXISTS (SELECT 1 FROM dbo.ShipmentStatuses)
        BEGIN
            INSERT INTO dbo.ShipmentStatuses (Id, NameEn, NameAr) VALUES
                (1, N'Pending', N'قيد الانتظار'),
                (2, N'InDelivery', N'قيد التوصيل'),
                (3, N'Completed', N'مكتمل'),
                (4, N'Late', N'متأخر');
        END
        """;

    private const string CreateInternationalShipmentsTemplate = """
        CREATE TABLE dbo.InternationalShipments (
            Id BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
            ShipmentCode VARCHAR(20) NOT NULL,
            OrderId {0} NOT NULL,
            ProviderUserId {1} NOT NULL,
            StatusId TINYINT NOT NULL CONSTRAINT DF_InternationalShipments_StatusId DEFAULT 1,
            CreatedAt DATETIME NOT NULL CONSTRAINT DF_InternationalShipments_CreatedAt DEFAULT GETUTCDATE(),
            UpdatedAt DATETIME NULL,
            CONSTRAINT FK_InternationalShipments_Orders FOREIGN KEY (OrderId) REFERENCES dbo.Orders(Id),
            CONSTRAINT FK_InternationalShipments_ProviderUser FOREIGN KEY (ProviderUserId) REFERENCES dbo.Users(Id),
            CONSTRAINT FK_InternationalShipments_Status FOREIGN KEY (StatusId) REFERENCES dbo.ShipmentStatuses(Id)
        );

        CREATE UNIQUE INDEX IX_InternationalShipments_ShipmentCode
            ON dbo.InternationalShipments(ShipmentCode);

        CREATE INDEX IX_InternationalShipments_ProviderUserId
            ON dbo.InternationalShipments(ProviderUserId);

        CREATE INDEX IX_InternationalShipments_OrderId
            ON dbo.InternationalShipments(OrderId);
        """;
}
