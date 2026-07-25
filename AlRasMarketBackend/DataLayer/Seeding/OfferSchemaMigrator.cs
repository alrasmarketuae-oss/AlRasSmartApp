using DataLayer.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace DataLayer.Seeding;

/// <summary>
/// Ensures offer media tables exist (idempotent).
/// Production was missing OfferOnRequestImages / OfferOnRequestDocuments.
/// </summary>
public static class OfferSchemaMigrator
{
    public static async Task EnsureAsync(IRasAlSouqDbContext db, CancellationToken cancellationToken = default)
    {
        var context = (DbContext)db;
        var connection = context.Database.GetDbConnection();
        await SqlSchemaHelper.OpenIfNeededAsync(connection, cancellationToken).ConfigureAwait(false);

        if (!await SqlSchemaHelper.TableExistsAsync(connection, "OffersOnRequests", cancellationToken)
                .ConfigureAwait(false))
        {
            return;
        }

        if (!await SqlSchemaHelper.TableExistsAsync(connection, "OfferOnRequestImages", cancellationToken)
                .ConfigureAwait(false))
        {
            await SqlSchemaHelper.ExecuteBatchAsync(connection, CreateImagesTableSql, cancellationToken)
                .ConfigureAwait(false);
        }

        if (!await SqlSchemaHelper.TableExistsAsync(connection, "OfferOnRequestDocuments", cancellationToken)
                .ConfigureAwait(false))
        {
            await SqlSchemaHelper.ExecuteBatchAsync(connection, CreateDocumentsTableSql, cancellationToken)
                .ConfigureAwait(false);
        }

        // Allow fractional quantities on request offers (e.g. 5.5 tons).
        await SqlSchemaHelper.ExecuteBatchAsync(
            connection,
            """
            IF EXISTS (
                SELECT 1 FROM sys.columns
                WHERE object_id = OBJECT_ID(N'dbo.OffersOnRequests')
                  AND name = N'RequestedQuantity'
                  AND system_type_id <> TYPE_ID(N'decimal')
            )
            BEGIN
                ALTER TABLE dbo.OffersOnRequests
                ALTER COLUMN RequestedQuantity DECIMAL(18,3) NOT NULL;
            END
            """,
            cancellationToken).ConfigureAwait(false);
    }

    private const string CreateImagesTableSql = """
        CREATE TABLE dbo.OfferOnRequestImages (
            Id BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
            OfferId BIGINT NOT NULL,
            ImagePath NVARCHAR(500) NOT NULL,
            CreatedAt DATETIME NOT NULL CONSTRAINT DF_OfferOnRequestImages_CreatedAt DEFAULT GETUTCDATE(),
            CONSTRAINT FK_OfferOnRequestImages_Offer
                FOREIGN KEY (OfferId) REFERENCES dbo.OffersOnRequests(Id) ON DELETE CASCADE
        );

        CREATE INDEX IX_OfferOnRequestImages_OfferId ON dbo.OfferOnRequestImages (OfferId);
        """;

    private const string CreateDocumentsTableSql = """
        CREATE TABLE dbo.OfferOnRequestDocuments (
            Id BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
            OfferId BIGINT NOT NULL,
            DocumentPath NVARCHAR(500) NOT NULL,
            CreatedAt DATETIME NOT NULL CONSTRAINT DF_OfferOnRequestDocuments_CreatedAt DEFAULT GETUTCDATE(),
            CONSTRAINT FK_OfferOnRequestDocuments_Offer
                FOREIGN KEY (OfferId) REFERENCES dbo.OffersOnRequests(Id) ON DELETE CASCADE
        );

        CREATE INDEX IX_OfferOnRequestDocuments_OfferId ON dbo.OfferOnRequestDocuments (OfferId);
        """;
}
