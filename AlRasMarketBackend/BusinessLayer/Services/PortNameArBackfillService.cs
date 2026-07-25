using BusinessLayer.Interfaces;
using DataLayer.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace BusinessLayer.Services;

public sealed class PortNameArBackfillService(
    IRasAlSouqDbContext db,
    IOpenAiVisionService openAi) : IPortNameArBackfillService
{
    public async Task<PortNameArBackfillResult> BackfillAsync(
        int batchSize = 40,
        int maxBatches = 5,
        CancellationToken cancellationToken = default)
    {
        batchSize = Math.Clamp(batchSize, 1, 80);
        maxBatches = Math.Clamp(maxBatches, 1, 50);

        var remainingBefore = await CountMissingAsync(cancellationToken);
        if (remainingBefore == 0)
        {
            return new PortNameArBackfillResult
            {
                RemainingBefore = 0,
                Updated = 0,
                BatchesRun = 0,
                RemainingAfter = 0,
                Message = "All ports already have PortNameAr."
            };
        }

        var updated = 0;
        var batchesRun = 0;

        for (var i = 0; i < maxBatches; i++)
        {
            var batch = await db.Ports
                .AsTracking()
                .Where(p => p.PortNameAr == null || p.PortNameAr == string.Empty)
                .OrderBy(p => p.Id)
                .Take(batchSize)
                .ToListAsync(cancellationToken);

            if (batch.Count == 0)
            {
                break;
            }

            batchesRun++;

            var items = batch
                .Select(p => new PortNameTranslationItem
                {
                    Id = p.Id,
                    NameEn = p.PortNameEn,
                    UnLocode = p.UnLocode
                })
                .ToList();

            IReadOnlyDictionary<int, string> translations;
            try
            {
                translations = await openAi.TranslatePortNamesToArabicAsync(items, cancellationToken);
            }
            catch (Exception ex)
            {
                var remainingAfterError = await CountMissingAsync(cancellationToken);
                return new PortNameArBackfillResult
                {
                    RemainingBefore = remainingBefore,
                    Updated = updated,
                    BatchesRun = batchesRun,
                    RemainingAfter = remainingAfterError,
                    Message = $"Stopped after OpenAI error: {ex.Message}"
                };
            }

            var batchUpdated = 0;
            foreach (var port in batch)
            {
                if (!translations.TryGetValue(port.Id, out var nameAr)
                    || string.IsNullOrWhiteSpace(nameAr))
                {
                    continue;
                }

                port.PortNameAr = nameAr.Trim();
                batchUpdated++;
            }

            if (batchUpdated > 0)
            {
                await db.SaveChangesAsync(cancellationToken);
                updated += batchUpdated;
            }

            // Brief pause between batches to stay within rate limits.
            if (i < maxBatches - 1 && batch.Count == batchSize)
            {
                await Task.Delay(800, cancellationToken);
            }
        }

        var remainingAfter = await CountMissingAsync(cancellationToken);
        return new PortNameArBackfillResult
        {
            RemainingBefore = remainingBefore,
            Updated = updated,
            BatchesRun = batchesRun,
            RemainingAfter = remainingAfter,
            Message = remainingAfter == 0
                ? "Backfill complete."
                : $"Updated {updated} port(s). Call again to continue ({remainingAfter} remaining)."
        };
    }

    private Task<int> CountMissingAsync(CancellationToken cancellationToken) =>
        db.Ports.CountAsync(
            p => p.PortNameAr == null || p.PortNameAr == string.Empty,
            cancellationToken);
}
