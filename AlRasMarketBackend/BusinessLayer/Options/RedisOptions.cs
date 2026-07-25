namespace BusinessLayer.Options;

public sealed class RedisOptions
{
    public const string SectionName = "Redis";

    /// <summary>When false, tiered cache uses in-memory only.</summary>
    public bool Enabled { get; set; }

    /// <summary>StackExchange.Redis connection string, e.g. localhost:6379 or host:port,password=...</summary>
    public string ConnectionString { get; set; } = "localhost:6379";

    /// <summary>Prefix for all Redis keys (multi-app / multi-env isolation).</summary>
    public string InstanceName { get; set; } = "alras:";
}
