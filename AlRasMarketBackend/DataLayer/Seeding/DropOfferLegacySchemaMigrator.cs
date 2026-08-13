using DataLayer.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace DataLayer.Seeding;

/// <summary>
/// Drops legacy offer tables superseded by Orders (OfferOnRequest* → OffersOnRequests → OffersOnNegotiable → OfferStatuses).
/// Order matters because of foreign keys.
/// </summary>
public static class DropOfferLegacySchemaMigrator
{
    public static async Task EnsureAsync(IRasAlSouqDbContext db, CancellationToken cancellationToken = default)
    {
        var context = (DbContext)db;
        var connection = context.Database.GetDbConnection();
        await SqlSchemaHelper.OpenIfNeededAsync(connection, cancellationToken).ConfigureAwait(false);

        const string sql = """
            IF OBJECT_ID(N'dbo.OfferOnRequestImages', N'U') IS NOT NULL
                DROP TABLE dbo.OfferOnRequestImages;

            IF OBJECT_ID(N'dbo.OfferOnRequestDocuments', N'U') IS NOT NULL
                DROP TABLE dbo.OfferOnRequestDocuments;

            IF OBJECT_ID(N'dbo.OffersOnRequests', N'U') IS NOT NULL
                DROP TABLE dbo.OffersOnRequests;

            IF OBJECT_ID(N'dbo.OffersOnNegotiable', N'U') IS NOT NULL
                DROP TABLE dbo.OffersOnNegotiable;

            IF OBJECT_ID(N'dbo.OfferStatuses', N'U') IS NOT NULL
                DROP TABLE dbo.OfferStatuses;
            """;

        await SqlSchemaHelper.ExecuteBatchAsync(connection, sql, cancellationToken).ConfigureAwait(false);
    }
}
