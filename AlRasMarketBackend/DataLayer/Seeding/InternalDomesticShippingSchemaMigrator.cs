using DataLayer.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace DataLayer.Seeding;

/// <summary>Creates InternalDomesticShipping table and seeds UAE emirates (idempotent).</summary>
public static class InternalDomesticShippingSchemaMigrator
{
    public static async Task EnsureAsync(IRasAlSouqDbContext db, CancellationToken cancellationToken = default)
    {
        var context = (DbContext)db;
        var connection = context.Database.GetDbConnection();
        await SqlSchemaHelper.OpenIfNeededAsync(connection, cancellationToken).ConfigureAwait(false);

        if (!await SqlSchemaHelper.TableExistsAsync(connection, "InternalDomesticShipping", cancellationToken)
                .ConfigureAwait(false))
        {
            await SqlSchemaHelper.ExecuteBatchAsync(connection, CreateTableBatch, cancellationToken)
                .ConfigureAwait(false);
        }

        await SqlSchemaHelper.ExecuteBatchAsync(connection, SeedEmiratesBatch, cancellationToken)
            .ConfigureAwait(false);

        if (!await SqlSchemaHelper.TableExistsAsync(connection, "InternalDomesticShippingConfig", cancellationToken)
                .ConfigureAwait(false))
        {
            await SqlSchemaHelper.ExecuteBatchAsync(connection, CreateConfigTableBatch, cancellationToken)
                .ConfigureAwait(false);
        }
        else
        {
            await SqlSchemaHelper.ExecuteBatchAsync(connection, EnsureConfigRowBatch, cancellationToken)
                .ConfigureAwait(false);
        }
    }

    private const string CreateConfigTableBatch = """
        CREATE TABLE dbo.InternalDomesticShippingConfig (
            Id TINYINT NOT NULL PRIMARY KEY,
            ExcessKgRateAed TINYINT NOT NULL CONSTRAINT DF_InternalDomesticShippingConfig_ExcessKgRateAed DEFAULT 0,
            UpdatedAt DATETIME NOT NULL CONSTRAINT DF_InternalDomesticShippingConfig_UpdatedAt DEFAULT GETUTCDATE()
        );

        INSERT INTO dbo.InternalDomesticShippingConfig (Id, ExcessKgRateAed, UpdatedAt)
        VALUES (1, 0, GETUTCDATE());
        """;

    private const string EnsureConfigRowBatch = """
        IF NOT EXISTS (SELECT 1 FROM dbo.InternalDomesticShippingConfig WHERE Id = 1)
        BEGIN
            INSERT INTO dbo.InternalDomesticShippingConfig (Id, ExcessKgRateAed, UpdatedAt)
            VALUES (1, 0, GETUTCDATE());
        END
        """;

    private const string CreateTableBatch = """
        CREATE TABLE dbo.InternalDomesticShipping (
            Id TINYINT NOT NULL PRIMARY KEY,
            EmirateNameEn VARCHAR(100) NOT NULL,
            EmirateNameAr NVARCHAR(100) NOT NULL,
            PriceAed DECIMAL(12,2) NOT NULL CONSTRAINT DF_InternalDomesticShipping_PriceAed DEFAULT 0,
            UpdatedAt DATETIME NOT NULL CONSTRAINT DF_InternalDomesticShipping_UpdatedAt DEFAULT GETUTCDATE()
        );

        CREATE UNIQUE INDEX IX_InternalDomesticShipping_EmirateNameEn
            ON dbo.InternalDomesticShipping(EmirateNameEn);
        """;

    private const string SeedEmiratesBatch = """
        IF NOT EXISTS (SELECT 1 FROM dbo.InternalDomesticShipping)
        BEGIN
            INSERT INTO dbo.InternalDomesticShipping (Id, EmirateNameEn, EmirateNameAr, PriceAed, UpdatedAt) VALUES
                (1, N'Abu Dhabi', N'أبو ظبي', 0, GETUTCDATE()),
                (2, N'Dubai', N'دبي', 0, GETUTCDATE()),
                (3, N'Sharjah', N'الشارقة', 0, GETUTCDATE()),
                (4, N'Ajman', N'عجمان', 0, GETUTCDATE()),
                (5, N'Umm Al Quwain', N'أم القيوين', 0, GETUTCDATE()),
                (6, N'Ras Al Khaimah', N'رأس الخيمة', 0, GETUTCDATE()),
                (7, N'Fujairah', N'الفجيرة', 0, GETUTCDATE());
        END
        """;
}
