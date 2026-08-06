using DataLayer.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace DataLayer.Seeding;

public static class SystemSettingsSchemaMigrator
{
    public static async Task EnsureAsync(IRasAlSouqDbContext db, CancellationToken cancellationToken = default)
    {
        var context = (DbContext)db;
        var connection = context.Database.GetDbConnection();
        await SqlSchemaHelper.OpenIfNeededAsync(connection, cancellationToken).ConfigureAwait(false);

        if (!await SqlSchemaHelper.TableExistsAsync(connection, "SystemSettings", cancellationToken).ConfigureAwait(false))
        {
            await SqlSchemaHelper.ExecuteBatchAsync(connection, """
                CREATE TABLE dbo.SystemSettings (
                    Id TINYINT NOT NULL PRIMARY KEY,
                    RetailCommissionPercent DECIMAL(5,2) NOT NULL CONSTRAINT DF_SystemSettings_RetailCommission DEFAULT 0,
                    BookingCommissionPercent DECIMAL(5,2) NOT NULL CONSTRAINT DF_SystemSettings_BookingCommission DEFAULT 0,
                    RequestsCommissionPercent DECIMAL(5,2) NOT NULL CONSTRAINT DF_SystemSettings_RequestsCommission DEFAULT 0,
                    OffersCommissionPercent DECIMAL(5,2) NOT NULL CONSTRAINT DF_SystemSettings_OffersCommission DEFAULT 0,
                    ShippingCommissionPercent DECIMAL(5,2) NOT NULL CONSTRAINT DF_SystemSettings_ShippingCommission DEFAULT 0,
                    AppName NVARCHAR(200) NOT NULL CONSTRAINT DF_SystemSettings_AppName DEFAULT N'تطبيق الراس',
                    SupportEmail NVARCHAR(255) NULL,
                    PhoneNumber NVARCHAR(50) NULL,
                    LandlineNumber NVARCHAR(50) NULL,
                    Timezone NVARCHAR(100) NULL,
                    Address NVARCHAR(500) NULL,
                    FeaturedAdPriceAed DECIMAL(12,2) NOT NULL CONSTRAINT DF_SystemSettings_FeaturedAdPrice DEFAULT 0,
                    AdDisplayDurationDays INT NOT NULL CONSTRAINT DF_SystemSettings_AdDisplayDays DEFAULT 0,
                    UpdatedAt DATETIME NOT NULL CONSTRAINT DF_SystemSettings_UpdatedAt DEFAULT GETUTCDATE()
                );

                INSERT INTO dbo.SystemSettings (Id) VALUES (1);
                """, cancellationToken).ConfigureAwait(false);
        }

        // Rename legacy brand in existing settings rows used for outbound messages.
        await SqlSchemaHelper.ExecuteBatchAsync(connection, """
            IF OBJECT_ID(N'dbo.SystemSettings', N'U') IS NOT NULL
            BEGIN
                UPDATE dbo.SystemSettings
                SET AppName = N'تطبيق الراس الذكي',
                    UpdatedAt = GETUTCDATE()
                WHERE AppName IN (N'سوق الراس', N'راس السوق', N'Al Ras Market', N'Ras Al Souq', N'تطبيق الراس', N'Al Ras Smart');
            END
            """, cancellationToken).ConfigureAwait(false);
    }
}
