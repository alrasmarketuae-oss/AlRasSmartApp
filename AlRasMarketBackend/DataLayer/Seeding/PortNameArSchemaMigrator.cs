using DataLayer.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace DataLayer.Seeding;

/// <summary>
/// Adds Ports.PortNameAr and seeds UAE + key Gulf/major port Arabic names by UnLocode.
/// Full world backfill: run DatabaseScripts/add_port_name_ar.sql and/or Admin POST ports/backfill-arabic.
/// </summary>
public static class PortNameArSchemaMigrator
{
    public static async Task EnsureAsync(IRasAlSouqDbContext db, CancellationToken cancellationToken = default)
    {
        var context = (DbContext)db;
        var connection = context.Database.GetDbConnection();
        await SqlSchemaHelper.OpenIfNeededAsync(connection, cancellationToken).ConfigureAwait(false);

        if (!await SqlSchemaHelper.ColumnExistsAsync(connection, "Ports", "PortNameAr", cancellationToken)
                .ConfigureAwait(false))
        {
            await SqlSchemaHelper.ExecuteBatchAsync(
                connection,
                """
                ALTER TABLE dbo.Ports
                ADD PortNameAr NVARCHAR(255) NULL;
                """,
                cancellationToken).ConfigureAwait(false);
        }

        // Seed only missing Arabic names (idempotent).
        await SqlSchemaHelper.ExecuteBatchAsync(
            connection,
            """
            UPDATE p
            SET p.PortNameAr = v.PortNameAr
            FROM dbo.Ports p
            INNER JOIN (VALUES
                (N'AEABU', N'أبو البخوش'),
                (N'AEAUH', N'أبو ظبي'),
                (N'AEAMU', N'أبو موسى'),
                (N'AEARP', N'ميناء أحمد بن راشد'),
                (N'AEAJM', N'عجمان'),
                (N'AEFJR', N'الفجيرة'),
                (N'AEJAZ', N'ميناء الجزيرة'),
                (N'AEAJP', N'ميناء الجير'),
                (N'AERUW', N'الرويس'),
                (N'AEDAS', N'جزيرة داس'),
                (N'AEDBP', N'دبا'),
                (N'AEDXB', N'دبي'),
                (N'AEEND', N'إسناد'),
                (N'AEFAT', N'محطة فاتح'),
                (N'AEFRP', N'الميناء الحر'),
                (N'AEHZP', N'ميناء الحمرية المنطقة الحرة'),
                (N'AEHSN', N'حصيان'),
                (N'AEHTL', N'محطة الحليلة'),
                (N'AEJEA', N'جبل علي'),
                (N'AEQWE', N'المنطقة الحرة بجبل علي'),
                (N'AEJED', N'جبل الظنة'),
                (N'AEKLB', N'كلباء'),
                (N'AEKLF', N'خورفكان'),
                (N'AEMKH', N'ميناء خالد'),
                (N'AEKHL', N'ميناء خليفة'),
                (N'AEMRP', N'ميناء راشد'),
                (N'AEMSA', N'ميناء صقر'),
                (N'AEMZD', N'ميناء زايد'),
                (N'AERFA', N'المرفأ'),
                (N'AEMUB', N'محطة مبارك'),
                (N'AEMBS', N'جزيرة المبرز'),
                (N'AEAMF', N'مصفح'),
                (N'AEPRA', N'ميناء راشد'),
                (N'AERKP', N'ميناء رأس الخيمة خور'),
                (N'AERMC', N'مدينة رأس الخيمة البحرية'),
                (N'AERKT', N'رأس الخيمة'),
                (N'AERWP', N'ميناء الرويس'),
                (N'AESID', N'جزيرة السعديات'),
                (N'AESHJ', N'الشارقة'),
                (N'AEDUJ', N'نخلة جميرا'),
                (N'AEULR', N'أم النار'),
                (N'AEQIW', N'أم القيوين'),
                (N'AEYAS', N'جزيرة ياس'),
                (N'AEZUR', N'جزيرة زركوه'),
                (N'SAJED', N'جدة'),
                (N'SADMM', N'الدمام'),
                (N'SAJUB', N'الجبيل'),
                (N'SARTA', N'رأس تنورة'),
                (N'QADOH', N'الدوحة'),
                (N'OMSLL', N'صلالة'),
                (N'OMSOH', N'صحار'),
                (N'OMMCT', N'مسقط'),
                (N'KWSWK', N'الشويخ'),
                (N'KWSAA', N'الشعيبة'),
                (N'EGPSD', N'بورسعيد'),
                (N'EGALY', N'الإسكندرية'),
                (N'INBOM', N'مومباي'),
                (N'SGSIN', N'سنغافورة'),
                (N'CNSGH', N'شنغهاي'),
                (N'NLRTM', N'روتردام'),
                (N'USNYC', N'نيويورك'),
                (N'USLAX', N'لوس أنجلوس')
            ) AS v(UnLocode, PortNameAr)
                ON p.UnLocode = v.UnLocode
            WHERE p.PortNameAr IS NULL OR LTRIM(RTRIM(p.PortNameAr)) = N'';
            """,
            cancellationToken).ConfigureAwait(false);
    }
}
