using DataLayer.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace DataLayer.Seeding;

public static class ShippingPhoneRevealSchemaMigrator
{
    public static async Task EnsureAsync(IRasAlSouqDbContext db, CancellationToken cancellationToken = default)
    {
        var context = (DbContext)db;
        var connection = context.Database.GetDbConnection();
        await SqlSchemaHelper.OpenIfNeededAsync(connection, cancellationToken).ConfigureAwait(false);

        if (await SqlSchemaHelper.TableExistsAsync(connection, "ShippingPhoneReveals", cancellationToken)
                .ConfigureAwait(false))
        {
            return;
        }

        var userIdType = await SqlSchemaHelper.GetColumnSqlTypeAsync(connection, "Users", "Id", cancellationToken)
            .ConfigureAwait(false)
            ?? throw new InvalidOperationException("Cannot create ShippingPhoneReveals: dbo.Users.Id was not found.");

        var postIdType = await SqlSchemaHelper.GetColumnSqlTypeAsync(
                connection, "InternationalShippingPosts", "Id", cancellationToken)
            .ConfigureAwait(false)
            ?? "BIGINT";

        var sql = string.Format(CreateTableTemplate, userIdType, postIdType);
        await SqlSchemaHelper.ExecuteBatchAsync(connection, sql, cancellationToken).ConfigureAwait(false);
    }

    private const string CreateTableTemplate = """
        CREATE TABLE dbo.ShippingPhoneReveals (
            Id UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_ShippingPhoneReveals PRIMARY KEY,
            ViewerUserId {0} NOT NULL,
            ShippingCompanyUserId {0} NOT NULL,
            PostId {1} NOT NULL,
            CreatedAtUtc DATETIME2 NOT NULL CONSTRAINT DF_ShippingPhoneReveals_CreatedAtUtc DEFAULT SYSUTCDATETIME(),
            CONSTRAINT FK_ShippingPhoneReveals_Viewer FOREIGN KEY (ViewerUserId) REFERENCES dbo.Users(Id),
            CONSTRAINT FK_ShippingPhoneReveals_Company FOREIGN KEY (ShippingCompanyUserId) REFERENCES dbo.Users(Id),
            CONSTRAINT FK_ShippingPhoneReveals_Post FOREIGN KEY (PostId) REFERENCES dbo.InternationalShippingPosts(Id)
        );

        CREATE INDEX IX_ShippingPhoneReveals_Viewer_CreatedAt
            ON dbo.ShippingPhoneReveals (ViewerUserId, CreatedAtUtc DESC);
        CREATE INDEX IX_ShippingPhoneReveals_Company_CreatedAt
            ON dbo.ShippingPhoneReveals (ShippingCompanyUserId, CreatedAtUtc DESC);
        CREATE INDEX IX_ShippingPhoneReveals_PostId
            ON dbo.ShippingPhoneReveals (PostId);
        """;
}
