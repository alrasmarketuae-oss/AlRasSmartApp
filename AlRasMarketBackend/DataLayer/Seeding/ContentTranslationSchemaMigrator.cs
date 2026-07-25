using DataLayer.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace DataLayer.Seeding;

public static class ContentTranslationSchemaMigrator
{
    public static async Task EnsureAsync(IRasAlSouqDbContext db, CancellationToken cancellationToken = default)
    {
        var context = (DbContext)db;
        var connection = context.Database.GetDbConnection();
        await SqlSchemaHelper.OpenIfNeededAsync(connection, cancellationToken).ConfigureAwait(false);

        if (await SqlSchemaHelper.TableExistsAsync(connection, "ContentTranslations", cancellationToken)
                .ConfigureAwait(false))
        {
            return;
        }

        var orderIdType = await SqlSchemaHelper.GetColumnSqlTypeAsync(connection, "Orders", "Id", cancellationToken)
            .ConfigureAwait(false)
            ?? throw new InvalidOperationException("Cannot create ContentTranslations: dbo.Orders.Id was not found.");

        var sql = string.Format(CreateTableTemplate, orderIdType);
        await SqlSchemaHelper.ExecuteBatchAsync(connection, sql, cancellationToken).ConfigureAwait(false);
    }

    private const string CreateTableTemplate = """
        CREATE TABLE dbo.ContentTranslations (
            Id UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_ContentTranslations PRIMARY KEY,
            Scope NVARCHAR(20) NOT NULL,
            ProductId UNIQUEIDENTIFIER NULL,
            OrderId {0} NULL,
            Field NVARCHAR(40) NOT NULL,
            TextAr NVARCHAR(MAX) NULL,
            TextEn NVARCHAR(MAX) NULL,
            SourceLanguage NVARCHAR(5) NOT NULL,
            SourceHash NVARCHAR(64) NOT NULL,
            UpdatedAtUtc DATETIME2 NOT NULL CONSTRAINT DF_ContentTranslations_UpdatedAtUtc DEFAULT SYSUTCDATETIME(),
            CONSTRAINT FK_ContentTranslations_Product FOREIGN KEY (ProductId)
                REFERENCES dbo.Products(ProductId) ON DELETE CASCADE,
            -- NO ACTION: SQL Server rejects CASCADE here (multiple cascade paths via Orders).
            CONSTRAINT FK_ContentTranslations_Order FOREIGN KEY (OrderId)
                REFERENCES dbo.Orders(Id) ON DELETE NO ACTION,
            CONSTRAINT CK_ContentTranslations_Scope CHECK (Scope IN (N'Product', N'Order')),
            CONSTRAINT CK_ContentTranslations_Owner CHECK (
                (Scope = N'Product' AND ProductId IS NOT NULL AND OrderId IS NULL)
                OR (Scope = N'Order' AND OrderId IS NOT NULL AND ProductId IS NULL)
            )
        );

        CREATE UNIQUE INDEX UX_ContentTranslations_Product_Field
            ON dbo.ContentTranslations (ProductId, Field)
            WHERE ProductId IS NOT NULL;

        CREATE UNIQUE INDEX UX_ContentTranslations_Order_Field
            ON dbo.ContentTranslations (OrderId, Field)
            WHERE OrderId IS NOT NULL;

        CREATE INDEX IX_ContentTranslations_ProductId ON dbo.ContentTranslations (ProductId)
            WHERE ProductId IS NOT NULL;

        CREATE INDEX IX_ContentTranslations_Scope_Field ON dbo.ContentTranslations (Scope, Field);
        """;
}
