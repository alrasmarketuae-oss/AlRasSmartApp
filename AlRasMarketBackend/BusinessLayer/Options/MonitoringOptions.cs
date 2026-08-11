namespace BusinessLayer.Options;

public sealed class MonitoringOptions
{
    public const string SectionName = "Monitoring";

    /// <summary>Prometheus HTTP API base URL (docker: http://prometheus:9090).</summary>
    public string PrometheusUrl { get; set; } = "http://prometheus:9090";
}
