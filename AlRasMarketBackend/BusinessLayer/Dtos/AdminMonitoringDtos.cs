namespace BusinessLayer.Dtos;

public sealed class AdminMonitoringOverviewDto
{
    public DateTime ServerUtcNow { get; set; }
    public bool PrometheusReachable { get; set; }
    public string Range { get; set; } = "1h";
    public AdminMonitoringSnapshotDto Snapshot { get; set; } = new();
    public AdminMonitoringSeriesDto Series { get; set; } = new();
    public List<AdminMonitoringTargetDto> Targets { get; set; } = [];
}

public sealed class AdminMonitoringSnapshotDto
{
    public double HttpRequestsPerSec { get; set; }
    public double Http5xxPerSec { get; set; }
    public double HttpP95Seconds { get; set; }
    public double HttpP50Seconds { get; set; }
    public bool RedisUp { get; set; }
    public double? RedisMemoryBytes { get; set; }
    public double? ApiWorkingSetBytes { get; set; }
    public double? ApiCpuPercent { get; set; }
}

public sealed class AdminMonitoringSeriesDto
{
    public List<AdminMonitoringPointDto> HttpRequestsPerSec { get; set; } = [];
    public List<AdminMonitoringPointDto> Http5xxPerSec { get; set; } = [];
    public List<AdminMonitoringPointDto> HttpP95Seconds { get; set; } = [];
    public List<AdminMonitoringPointDto> HttpP50Seconds { get; set; } = [];
}

public sealed class AdminMonitoringPointDto
{
    public DateTime T { get; set; }
    public double V { get; set; }
}

public sealed class AdminMonitoringTargetDto
{
    public string Job { get; set; } = string.Empty;
    public string Instance { get; set; } = string.Empty;
    public string Health { get; set; } = "unknown";
}
