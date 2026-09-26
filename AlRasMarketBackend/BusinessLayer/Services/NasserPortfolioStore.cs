using System.Globalization;
using System.Text.RegularExpressions;
using BusinessLayer.Interfaces;
using Microsoft.Data.Sqlite;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;

namespace BusinessLayer.Services;

public sealed class NasserPortfolioStore : INasserPortfolioStore
{
    private static readonly Regex ImageName = new(@"^[a-f0-9]{32}\.(jpg|png)$", RegexOptions.Compiled);

    private readonly string _connectionString;
    private readonly string _imagesDir;
    private readonly SemaphoreSlim _writeLock = new(1, 1);
    private readonly ILogger<NasserPortfolioStore> _logger;

    public NasserPortfolioStore(IConfiguration configuration, ILogger<NasserPortfolioStore> logger)
    {
        _logger = logger;
        var root = configuration["NasserPortfolio:DataPath"];
        if (string.IsNullOrWhiteSpace(root))
        {
            root = Path.Combine(AppContext.BaseDirectory, "nasser-portfolio-data");
        }

        root = Path.GetFullPath(root);
        _imagesDir = Path.Combine(root, "images");
        Directory.CreateDirectory(_imagesDir);
        _connectionString = new SqliteConnectionStringBuilder
        {
            DataSource = Path.Combine(root, "nasser-portfolio.db"),
            Mode = SqliteOpenMode.ReadWriteCreate,
            Cache = SqliteCacheMode.Shared
        }.ToString();

        EnsureSchema();
    }

    private void EnsureSchema()
    {
        using var conn = new SqliteConnection(_connectionString);
        conn.Open();
        using var cmd = conn.CreateCommand();
        cmd.CommandText = """
            PRAGMA journal_mode=WAL;
            CREATE TABLE IF NOT EXISTS conversations (
                id TEXT PRIMARY KEY,
                created_at TEXT NOT NULL,
                last_at TEXT NOT NULL,
                ip TEXT, country TEXT, user_agent TEXT, locale TEXT, phone TEXT,
                message_count INTEGER NOT NULL DEFAULT 0,
                image_count INTEGER NOT NULL DEFAULT 0,
                preview TEXT
            );
            CREATE TABLE IF NOT EXISTS messages (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                conversation_id TEXT NOT NULL,
                role TEXT NOT NULL,
                text TEXT NOT NULL,
                image_file TEXT,
                created_at TEXT NOT NULL
            );
            CREATE INDEX IF NOT EXISTS ix_messages_conversation ON messages(conversation_id, id);
            CREATE INDEX IF NOT EXISTS ix_conversations_last ON conversations(last_at DESC);
            CREATE TABLE IF NOT EXISTS leads (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                created_at TEXT NOT NULL,
                phone TEXT NOT NULL,
                name TEXT, source TEXT, locale TEXT, ip TEXT, country TEXT, user_agent TEXT, conversation_id TEXT
            );
            CREATE INDEX IF NOT EXISTS ix_leads_created ON leads(created_at DESC);
            """;
        cmd.ExecuteNonQuery();
    }

    private async Task<SqliteConnection> OpenAsync(CancellationToken ct)
    {
        var conn = new SqliteConnection(_connectionString);
        await conn.OpenAsync(ct).ConfigureAwait(false);
        return conn;
    }

    private static string Now() => DateTimeOffset.UtcNow.ToString("O", CultureInfo.InvariantCulture);

    private static DateTimeOffset ParseDate(string value) =>
        DateTimeOffset.Parse(value, CultureInfo.InvariantCulture, DateTimeStyles.RoundtripKind);

    private static string? Trim(string? value, int max) =>
        string.IsNullOrWhiteSpace(value) ? null : value.Length > max ? value[..max] : value;

    private static string ImageExt(byte[]? bytes) =>
        bytes is { Length: >= 8 } && bytes[0] == 0x89 && bytes[1] == 0x50 ? "png" : "jpg";

    private async Task<string?> SaveImageAsync(byte[]? bytes, string ext, CancellationToken ct)
    {
        if (bytes is not { Length: > 0 })
        {
            return null;
        }

        var name = $"{Guid.NewGuid():N}.{ext}";
        await File.WriteAllBytesAsync(Path.Combine(_imagesDir, name), bytes, ct).ConfigureAwait(false);
        return name;
    }

    public async Task RecordExchangeAsync(NasserExchangeRecord record, CancellationToken cancellationToken = default)
    {
        var conversationId = Trim(record.ConversationId, 64);
        if (conversationId is null)
        {
            return;
        }

        var userImage = await SaveImageAsync(record.UserImageJpeg, ImageExt(record.UserImageJpeg), cancellationToken).ConfigureAwait(false);
        var assistantImage = await SaveImageAsync(record.AssistantImagePng, ImageExt(record.AssistantImagePng), cancellationToken).ConfigureAwait(false);
        var imageCount = (userImage is null ? 0 : 1) + (assistantImage is null ? 0 : 1);
        var now = Now();

        await _writeLock.WaitAsync(cancellationToken).ConfigureAwait(false);
        try
        {
            await using var conn = await OpenAsync(cancellationToken).ConfigureAwait(false);
            await using var tx = (SqliteTransaction)await conn.BeginTransactionAsync(cancellationToken).ConfigureAwait(false);

            await using (var upsert = conn.CreateCommand())
            {
                upsert.Transaction = tx;
                upsert.CommandText = """
                    INSERT INTO conversations (id, created_at, last_at, ip, country, user_agent, locale, phone, message_count, image_count, preview)
                    VALUES ($id, $now, $now, $ip, $country, $ua, $locale, $phone, 2, $images, $preview)
                    ON CONFLICT(id) DO UPDATE SET
                        last_at = $now,
                        ip = COALESCE($ip, ip),
                        country = COALESCE($country, country),
                        user_agent = COALESCE($ua, user_agent),
                        locale = $locale,
                        phone = COALESCE($phone, phone),
                        message_count = message_count + 2,
                        image_count = image_count + $images;
                    """;
                upsert.Parameters.AddWithValue("$id", conversationId);
                upsert.Parameters.AddWithValue("$now", now);
                upsert.Parameters.AddWithValue("$ip", (object?)Trim(record.Visitor.Ip, 64) ?? DBNull.Value);
                upsert.Parameters.AddWithValue("$country", (object?)Trim(record.Visitor.Country, 8) ?? DBNull.Value);
                upsert.Parameters.AddWithValue("$ua", (object?)Trim(record.Visitor.UserAgent, 400) ?? DBNull.Value);
                upsert.Parameters.AddWithValue("$locale", record.Locale);
                upsert.Parameters.AddWithValue("$phone", (object?)Trim(record.Phone, 32) ?? DBNull.Value);
                upsert.Parameters.AddWithValue("$images", imageCount);
                upsert.Parameters.AddWithValue(
                    "$preview",
                    (object?)Trim(string.IsNullOrWhiteSpace(record.UserText) ? "[image]" : record.UserText, 160) ?? DBNull.Value);
                await upsert.ExecuteNonQueryAsync(cancellationToken).ConfigureAwait(false);
            }

            await InsertMessageAsync(conn, tx, conversationId, "user", record.UserText, userImage, now, cancellationToken)
                .ConfigureAwait(false);
            await InsertMessageAsync(conn, tx, conversationId, "assistant", record.AssistantText, assistantImage, now, cancellationToken)
                .ConfigureAwait(false);

            await tx.CommitAsync(cancellationToken).ConfigureAwait(false);
        }
        catch (Exception ex) when (ex is not OperationCanceledException)
        {
            _logger.LogWarning(ex, "Failed to record Nasser portfolio chat exchange.");
        }
        finally
        {
            _writeLock.Release();
        }
    }

    private static async Task InsertMessageAsync(
        SqliteConnection conn,
        SqliteTransaction tx,
        string conversationId,
        string role,
        string text,
        string? imageFile,
        string now,
        CancellationToken ct)
    {
        await using var cmd = conn.CreateCommand();
        cmd.Transaction = tx;
        cmd.CommandText = """
            INSERT INTO messages (conversation_id, role, text, image_file, created_at)
            VALUES ($c, $role, $text, $img, $now);
            """;
        cmd.Parameters.AddWithValue("$c", conversationId);
        cmd.Parameters.AddWithValue("$role", role);
        cmd.Parameters.AddWithValue("$text", text ?? string.Empty);
        cmd.Parameters.AddWithValue("$img", (object?)imageFile ?? DBNull.Value);
        cmd.Parameters.AddWithValue("$now", now);
        await cmd.ExecuteNonQueryAsync(ct).ConfigureAwait(false);
    }

    public async Task RecordLeadAsync(NasserLeadRecord record, CancellationToken cancellationToken = default)
    {
        await _writeLock.WaitAsync(cancellationToken).ConfigureAwait(false);
        try
        {
            await using var conn = await OpenAsync(cancellationToken).ConfigureAwait(false);
            await using var cmd = conn.CreateCommand();
            cmd.CommandText = """
                INSERT INTO leads (created_at, phone, name, source, locale, ip, country, user_agent, conversation_id)
                VALUES ($now, $phone, $name, $source, $locale, $ip, $country, $ua, $conv);
                UPDATE conversations SET phone = $phone WHERE id = $conv;
                """;
            cmd.Parameters.AddWithValue("$now", Now());
            cmd.Parameters.AddWithValue("$phone", Trim(record.Phone, 32) ?? string.Empty);
            cmd.Parameters.AddWithValue("$name", (object?)Trim(record.Name, 120) ?? DBNull.Value);
            cmd.Parameters.AddWithValue("$source", (object?)Trim(record.Source, 32) ?? DBNull.Value);
            cmd.Parameters.AddWithValue("$locale", (object?)Trim(record.Locale, 8) ?? DBNull.Value);
            cmd.Parameters.AddWithValue("$ip", (object?)Trim(record.Ip, 64) ?? DBNull.Value);
            cmd.Parameters.AddWithValue("$country", (object?)Trim(record.Country, 8) ?? DBNull.Value);
            cmd.Parameters.AddWithValue("$ua", (object?)Trim(record.UserAgent, 400) ?? DBNull.Value);
            cmd.Parameters.AddWithValue("$conv", (object?)Trim(record.ConversationId, 64) ?? DBNull.Value);
            await cmd.ExecuteNonQueryAsync(cancellationToken).ConfigureAwait(false);
        }
        catch (Exception ex) when (ex is not OperationCanceledException)
        {
            _logger.LogWarning(ex, "Failed to record Nasser portfolio lead.");
        }
        finally
        {
            _writeLock.Release();
        }
    }

    private const string ConversationColumns =
        "id, created_at, last_at, ip, country, user_agent, locale, phone, message_count, image_count, preview";

    private static NasserConversationSummary ReadConversation(SqliteDataReader r) => new(
        r.GetString(0),
        ParseDate(r.GetString(1)),
        ParseDate(r.GetString(2)),
        r.IsDBNull(3) ? null : r.GetString(3),
        r.IsDBNull(4) ? null : r.GetString(4),
        r.IsDBNull(5) ? null : r.GetString(5),
        r.IsDBNull(6) ? null : r.GetString(6),
        r.IsDBNull(7) ? null : r.GetString(7),
        r.GetInt32(8),
        r.GetInt32(9),
        r.IsDBNull(10) ? null : r.GetString(10));

    public async Task<NasserPage<NasserConversationSummary>> ListConversationsAsync(
        int page,
        int pageSize,
        string? search,
        CancellationToken cancellationToken = default)
    {
        page = Math.Max(1, page);
        pageSize = Math.Clamp(pageSize, 1, 100);
        var term = string.IsNullOrWhiteSpace(search) ? null : $"%{search.Trim()}%";
        const string where = """
            WHERE $term IS NULL
               OR ip LIKE $term OR phone LIKE $term OR preview LIKE $term OR country LIKE $term
               OR id IN (SELECT conversation_id FROM messages WHERE text LIKE $term)
            """;

        await using var conn = await OpenAsync(cancellationToken).ConfigureAwait(false);

        int total;
        await using (var count = conn.CreateCommand())
        {
            count.CommandText = $"SELECT COUNT(*) FROM conversations {where};";
            count.Parameters.AddWithValue("$term", (object?)term ?? DBNull.Value);
            total = Convert.ToInt32(await count.ExecuteScalarAsync(cancellationToken).ConfigureAwait(false));
        }

        var items = new List<NasserConversationSummary>();
        await using (var cmd = conn.CreateCommand())
        {
            cmd.CommandText = $"""
                SELECT {ConversationColumns} FROM conversations {where}
                ORDER BY last_at DESC LIMIT $take OFFSET $skip;
                """;
            cmd.Parameters.AddWithValue("$term", (object?)term ?? DBNull.Value);
            cmd.Parameters.AddWithValue("$take", pageSize);
            cmd.Parameters.AddWithValue("$skip", (page - 1) * pageSize);
            await using var r = await cmd.ExecuteReaderAsync(cancellationToken).ConfigureAwait(false);
            while (await r.ReadAsync(cancellationToken).ConfigureAwait(false))
            {
                items.Add(ReadConversation(r));
            }
        }

        return new NasserPage<NasserConversationSummary>(items, total, page, pageSize);
    }

    public async Task<NasserConversationDetail?> GetConversationAsync(string id, CancellationToken cancellationToken = default)
    {
        await using var conn = await OpenAsync(cancellationToken).ConfigureAwait(false);

        NasserConversationSummary? summary = null;
        await using (var cmd = conn.CreateCommand())
        {
            cmd.CommandText = $"SELECT {ConversationColumns} FROM conversations WHERE id = $id;";
            cmd.Parameters.AddWithValue("$id", id);
            await using var r = await cmd.ExecuteReaderAsync(cancellationToken).ConfigureAwait(false);
            if (await r.ReadAsync(cancellationToken).ConfigureAwait(false))
            {
                summary = ReadConversation(r);
            }
        }

        if (summary is null)
        {
            return null;
        }

        var messages = new List<NasserStoredMessage>();
        await using (var cmd = conn.CreateCommand())
        {
            cmd.CommandText = """
                SELECT id, role, text, image_file, created_at FROM messages
                WHERE conversation_id = $id ORDER BY id;
                """;
            cmd.Parameters.AddWithValue("$id", id);
            await using var r = await cmd.ExecuteReaderAsync(cancellationToken).ConfigureAwait(false);
            while (await r.ReadAsync(cancellationToken).ConfigureAwait(false))
            {
                messages.Add(new NasserStoredMessage(
                    r.GetInt64(0),
                    r.GetString(1),
                    r.GetString(2),
                    r.IsDBNull(3) ? null : r.GetString(3),
                    ParseDate(r.GetString(4))));
            }
        }

        return new NasserConversationDetail(summary, messages);
    }

    public async Task<bool> DeleteConversationAsync(string id, CancellationToken cancellationToken = default)
    {
        var detail = await GetConversationAsync(id, cancellationToken).ConfigureAwait(false);
        if (detail is null)
        {
            return false;
        }

        await _writeLock.WaitAsync(cancellationToken).ConfigureAwait(false);
        try
        {
            await using var conn = await OpenAsync(cancellationToken).ConfigureAwait(false);
            await using var cmd = conn.CreateCommand();
            cmd.CommandText = "DELETE FROM messages WHERE conversation_id = $id; DELETE FROM conversations WHERE id = $id;";
            cmd.Parameters.AddWithValue("$id", id);
            await cmd.ExecuteNonQueryAsync(cancellationToken).ConfigureAwait(false);
        }
        finally
        {
            _writeLock.Release();
        }

        foreach (var file in detail.Messages.Select(m => m.ImageFile).OfType<string>())
        {
            var path = ResolveImagePath(file);
            if (path is not null)
            {
                File.Delete(path);
            }
        }

        return true;
    }

    public async Task<NasserPage<NasserLeadRecord>> ListLeadsAsync(
        int page,
        int pageSize,
        CancellationToken cancellationToken = default)
    {
        page = Math.Max(1, page);
        pageSize = Math.Clamp(pageSize, 1, 100);
        await using var conn = await OpenAsync(cancellationToken).ConfigureAwait(false);

        int total;
        await using (var count = conn.CreateCommand())
        {
            count.CommandText = "SELECT COUNT(*) FROM leads;";
            total = Convert.ToInt32(await count.ExecuteScalarAsync(cancellationToken).ConfigureAwait(false));
        }

        var items = new List<NasserLeadRecord>();
        await using (var cmd = conn.CreateCommand())
        {
            cmd.CommandText = """
                SELECT id, created_at, phone, name, source, locale, ip, country, user_agent, conversation_id
                FROM leads ORDER BY id DESC LIMIT $take OFFSET $skip;
                """;
            cmd.Parameters.AddWithValue("$take", pageSize);
            cmd.Parameters.AddWithValue("$skip", (page - 1) * pageSize);
            await using var r = await cmd.ExecuteReaderAsync(cancellationToken).ConfigureAwait(false);
            while (await r.ReadAsync(cancellationToken).ConfigureAwait(false))
            {
                items.Add(new NasserLeadRecord
                {
                    Id = r.GetInt64(0),
                    CreatedAt = ParseDate(r.GetString(1)),
                    Phone = r.GetString(2),
                    Name = r.IsDBNull(3) ? null : r.GetString(3),
                    Source = r.IsDBNull(4) ? null : r.GetString(4),
                    Locale = r.IsDBNull(5) ? null : r.GetString(5),
                    Ip = r.IsDBNull(6) ? null : r.GetString(6),
                    Country = r.IsDBNull(7) ? null : r.GetString(7),
                    UserAgent = r.IsDBNull(8) ? null : r.GetString(8),
                    ConversationId = r.IsDBNull(9) ? null : r.GetString(9)
                });
            }
        }

        return new NasserPage<NasserLeadRecord>(items, total, page, pageSize);
    }

    public async Task<NasserStats> GetStatsAsync(CancellationToken cancellationToken = default)
    {
        await using var conn = await OpenAsync(cancellationToken).ConfigureAwait(false);
        await using var cmd = conn.CreateCommand();
        cmd.CommandText = """
            SELECT
              (SELECT COUNT(*) FROM conversations),
              (SELECT COUNT(*) FROM messages),
              (SELECT COUNT(*) FROM messages WHERE image_file IS NOT NULL),
              (SELECT COUNT(*) FROM leads),
              (SELECT COUNT(*) FROM conversations WHERE last_at >= $today);
            """;
        cmd.Parameters.AddWithValue(
            "$today",
            new DateTimeOffset(DateTime.UtcNow.Date, TimeSpan.Zero).ToString("O", CultureInfo.InvariantCulture));
        await using var r = await cmd.ExecuteReaderAsync(cancellationToken).ConfigureAwait(false);
        await r.ReadAsync(cancellationToken).ConfigureAwait(false);
        return new NasserStats(r.GetInt32(0), r.GetInt32(1), r.GetInt32(2), r.GetInt32(3), r.GetInt32(4));
    }

    public string? ResolveImagePath(string fileName)
    {
        if (string.IsNullOrWhiteSpace(fileName) || !ImageName.IsMatch(fileName))
        {
            return null;
        }

        var path = Path.Combine(_imagesDir, fileName);
        return File.Exists(path) ? path : null;
    }
}
