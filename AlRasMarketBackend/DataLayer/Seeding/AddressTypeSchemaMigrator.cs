using DataLayer.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace DataLayer.Seeding;

/// <summary>
/// AddressTypes lookup (tinyint) and structured address fields + map coordinates.
/// </summary>
public static class AddressTypeSchemaMigrator
{
    public static async Task EnsureAsync(IRasAlSouqDbContext db, CancellationToken cancellationToken = default)
    {
        var context = (DbContext)db;
        var connection = context.Database.GetDbConnection();
        await SqlSchemaHelper.OpenIfNeededAsync(connection, cancellationToken).ConfigureAwait(false);

        await SqlSchemaHelper.ExecuteBatchAsync(
            connection,
            """
            IF OBJECT_ID(N'dbo.AddressTypes', N'U') IS NULL
            BEGIN
                CREATE TABLE dbo.AddressTypes
                (
                    Id TINYINT NOT NULL CONSTRAINT PK_AddressTypes PRIMARY KEY,
                    NameEn VARCHAR(50) NOT NULL,
                    NameAr NVARCHAR(50) NOT NULL
                );

                INSERT INTO dbo.AddressTypes (Id, NameEn, NameAr) VALUES
                    (1, 'Company', N'شركة'),
                    (2, 'Warehouse', N'مستودع'),
                    (3, 'Shop', N'محل'),
                    (4, 'Home', N'منزل');
            END
            ELSE
            BEGIN
                IF COL_LENGTH(N'dbo.AddressTypes', N'NameAr') IS NULL
                    ALTER TABLE dbo.AddressTypes ADD NameAr NVARCHAR(50) NULL;

                IF NOT EXISTS (SELECT 1 FROM dbo.AddressTypes WHERE Id = 1)
                    INSERT INTO dbo.AddressTypes (Id, NameEn, NameAr) VALUES (1, 'Company', N'شركة');
                IF NOT EXISTS (SELECT 1 FROM dbo.AddressTypes WHERE Id = 2)
                    INSERT INTO dbo.AddressTypes (Id, NameEn, NameAr) VALUES (2, 'Warehouse', N'مستودع');
                IF NOT EXISTS (SELECT 1 FROM dbo.AddressTypes WHERE Id = 3)
                    INSERT INTO dbo.AddressTypes (Id, NameEn, NameAr) VALUES (3, 'Shop', N'محل');
                IF NOT EXISTS (SELECT 1 FROM dbo.AddressTypes WHERE Id = 4)
                    INSERT INTO dbo.AddressTypes (Id, NameEn, NameAr) VALUES (4, 'Home', N'منزل');

                UPDATE dbo.AddressTypes SET NameEn = 'Company', NameAr = N'شركة' WHERE Id = 1;
                UPDATE dbo.AddressTypes SET NameEn = 'Warehouse', NameAr = N'مستودع' WHERE Id = 2;
                UPDATE dbo.AddressTypes SET NameEn = 'Shop', NameAr = N'محل' WHERE Id = 3;
                UPDATE dbo.AddressTypes SET NameEn = 'Home', NameAr = N'منزل' WHERE Id = 4;
            END
            """,
            cancellationToken).ConfigureAwait(false);

        await EnsureAddressColumnAsync(connection, "AddressTypeId", "TINYINT NULL", cancellationToken)
            .ConfigureAwait(false);

        await SqlSchemaHelper.ExecuteBatchAsync(
            connection,
            """
            UPDATE dbo.Addresses SET AddressTypeId = 4 WHERE AddressTypeId IS NULL;

            IF EXISTS (
                SELECT 1 FROM sys.columns
                WHERE object_id = OBJECT_ID(N'dbo.Addresses')
                  AND name = N'AddressTypeId'
                  AND is_nullable = 1)
            BEGIN
                ALTER TABLE dbo.Addresses ALTER COLUMN AddressTypeId TINYINT NOT NULL;
            END

            IF NOT EXISTS (
                SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Addresses_AddressTypes')
            BEGIN
                ALTER TABLE dbo.Addresses ADD CONSTRAINT FK_Addresses_AddressTypes
                    FOREIGN KEY (AddressTypeId) REFERENCES dbo.AddressTypes(Id);
            END
            """,
            cancellationToken).ConfigureAwait(false);

        await EnsureAddressColumnAsync(connection, "Area", "NVARCHAR(150) NULL", cancellationToken).ConfigureAwait(false);
        await EnsureAddressColumnAsync(connection, "Street", "NVARCHAR(200) NULL", cancellationToken).ConfigureAwait(false);
        await EnsureAddressColumnAsync(connection, "Building", "NVARCHAR(200) NULL", cancellationToken).ConfigureAwait(false);
        await EnsureAddressColumnAsync(connection, "FloorNo", "NVARCHAR(20) NULL", cancellationToken).ConfigureAwait(false);
        await EnsureAddressColumnAsync(connection, "UnitNo", "NVARCHAR(50) NULL", cancellationToken).ConfigureAwait(false);
        await EnsureAddressColumnAsync(connection, "Landmark", "NVARCHAR(255) NULL", cancellationToken).ConfigureAwait(false);
        await EnsureAddressColumnAsync(connection, "PostalCode", "NVARCHAR(30) NULL", cancellationToken).ConfigureAwait(false);
        await EnsureAddressColumnAsync(connection, "ContactPerson", "NVARCHAR(150) NULL", cancellationToken).ConfigureAwait(false);
        await EnsureAddressColumnAsync(connection, "MobileNumber", "NVARCHAR(30) NULL", cancellationToken).ConfigureAwait(false);
        await EnsureAddressColumnAsync(connection, "DeliveryInstructions", "NVARCHAR(500) NULL", cancellationToken).ConfigureAwait(false);
        await EnsureAddressColumnAsync(connection, "Latitude", "DECIMAL(10,7) NULL", cancellationToken).ConfigureAwait(false);
        await EnsureAddressColumnAsync(connection, "Longitude", "DECIMAL(10,7) NULL", cancellationToken).ConfigureAwait(false);

        await EnsureTableColumnAsync(connection, "Orders", "DeliveryLatitude", "DECIMAL(10,7) NULL", cancellationToken)
            .ConfigureAwait(false);
        await EnsureTableColumnAsync(connection, "Orders", "DeliveryLongitude", "DECIMAL(10,7) NULL", cancellationToken)
            .ConfigureAwait(false);
        await EnsureTableColumnAsync(connection, "PendingOrders", "DeliveryLatitude", "DECIMAL(10,7) NULL", cancellationToken)
            .ConfigureAwait(false);
        await EnsureTableColumnAsync(connection, "PendingOrders", "DeliveryLongitude", "DECIMAL(10,7) NULL", cancellationToken)
            .ConfigureAwait(false);

        await WidenNvarcharAsync(connection, "Orders", "DeliveryAddressLine", 1000, cancellationToken)
            .ConfigureAwait(false);
        await WidenNvarcharAsync(connection, "PendingOrders", "DeliveryAddressLine", 1000, cancellationToken)
            .ConfigureAwait(false);
    }

    private static async Task EnsureAddressColumnAsync(
        System.Data.Common.DbConnection connection,
        string columnName,
        string sqlType,
        CancellationToken cancellationToken) =>
        await EnsureTableColumnAsync(connection, "Addresses", columnName, sqlType, cancellationToken)
            .ConfigureAwait(false);

    private static async Task EnsureTableColumnAsync(
        System.Data.Common.DbConnection connection,
        string tableName,
        string columnName,
        string sqlType,
        CancellationToken cancellationToken)
    {
        if (await SqlSchemaHelper.ColumnExistsAsync(connection, tableName, columnName, cancellationToken)
                .ConfigureAwait(false))
        {
            return;
        }

        await SqlSchemaHelper.ExecuteBatchAsync(
            connection,
            $"ALTER TABLE dbo.[{tableName}] ADD [{columnName}] {sqlType};",
            cancellationToken).ConfigureAwait(false);
    }

    private static async Task WidenNvarcharAsync(
        System.Data.Common.DbConnection connection,
        string tableName,
        string columnName,
        int maxLength,
        CancellationToken cancellationToken)
    {
        if (!await SqlSchemaHelper.ColumnExistsAsync(connection, tableName, columnName, cancellationToken)
                .ConfigureAwait(false))
        {
            return;
        }

        var current = await SqlSchemaHelper.GetColumnSqlTypeAsync(connection, tableName, columnName, cancellationToken)
            .ConfigureAwait(false);
        if (string.IsNullOrWhiteSpace(current) || current.Contains("MAX", StringComparison.OrdinalIgnoreCase))
        {
            return;
        }

        var match = System.Text.RegularExpressions.Regex.Match(current, @"nvarchar\((\d+)\)", System.Text.RegularExpressions.RegexOptions.IgnoreCase);
        if (match.Success && int.TryParse(match.Groups[1].Value, out var length) && length >= maxLength)
        {
            return;
        }

        await SqlSchemaHelper.ExecuteBatchAsync(
            connection,
            $"ALTER TABLE dbo.[{tableName}] ALTER COLUMN [{columnName}] NVARCHAR({maxLength}) NULL;",
            cancellationToken).ConfigureAwait(false);
    }
}
