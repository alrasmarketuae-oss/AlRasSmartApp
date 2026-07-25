using DataLayer.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace DataLayer.Seeding;

/// <summary>Seeds missing roles (e.g. ShippingCompany) idempotently.</summary>
public static class RoleSchemaMigrator
{
    public static async Task EnsureAsync(IRasAlSouqDbContext db, CancellationToken cancellationToken = default)
    {
        var context = (DbContext)db;
        var connection = context.Database.GetDbConnection();
        await SqlSchemaHelper.OpenIfNeededAsync(connection, cancellationToken).ConfigureAwait(false);

        const string batch = """
            IF NOT EXISTS (SELECT 1 FROM dbo.Roles WHERE Id = 5)
                INSERT INTO dbo.Roles (Id, RoleName) VALUES (5, N'ShippingCompany');
            """;

        await SqlSchemaHelper.ExecuteBatchAsync(connection, batch, cancellationToken).ConfigureAwait(false);
    }
}
