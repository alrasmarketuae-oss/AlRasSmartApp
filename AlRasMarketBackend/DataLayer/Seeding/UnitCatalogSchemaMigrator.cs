using DataLayer.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace DataLayer.Seeding;

/// <summary>
/// Ensures every catalog unit exists in dbo.Units. Existing rows (and their Ids)
/// are never touched; only missing units are appended by name so historical
/// products keep their original UnitId references.
/// </summary>
public static class UnitCatalogSchemaMigrator
{
    // Canonical UnitNameEn values expected by the app. Display order is handled
    // client-side, so only presence matters here.
    private static readonly string[] Units =
    [
        "Ton",
        "Gram",
        "Kilogram",
        "Carton",
        "Bag",
        "Dozen",
        "Box",
        "Piece",
        "Packet",
        "Bundle",
        "Drum",
        "Bottle",
        "Tin",
        "Sack",
        "Case",
        "Pallet",
        "Liter",
        "Ml",
        "Jar",
    ];

    public static async Task EnsureAsync(IRasAlSouqDbContext db, CancellationToken cancellationToken = default)
    {
        var context = (DbContext)db;
        var connection = context.Database.GetDbConnection();
        await SqlSchemaHelper.OpenIfNeededAsync(connection, cancellationToken).ConfigureAwait(false);

        foreach (var unit in Units)
        {
            var escaped = unit.Replace("'", "''");
            await SqlSchemaHelper.ExecuteBatchAsync(
                connection,
                $"""
                IF NOT EXISTS (SELECT 1 FROM dbo.Units WHERE UnitNameEn = N'{escaped}')
                    INSERT INTO dbo.Units (UnitNameEn) VALUES (N'{escaped}');
                """,
                cancellationToken).ConfigureAwait(false);
        }
    }
}
