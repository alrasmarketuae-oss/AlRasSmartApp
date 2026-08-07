# Install RAM alert monitoring on Contabo VPS
# Usage: .\deploy\monitoring\install-ram-alert-remote.ps1

param(
    [string]$HostName = "169.58.68.26",
    [string]$User = "alrasmarket",
    [string]$RemotePath = "/opt/alrasmarket/app",
    [string]$IdentityFile = "$env:USERPROFILE\.ssh\id_ed25519",
    [string]$KeyPassphrase = "Alrasmarketuae"
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$MonitoringDir = Join-Path $Root "deploy\monitoring"

if (-not (Test-Path (Join-Path $MonitoringDir "ram-alert.py"))) {
    throw "Expected monitoring scripts under $MonitoringDir"
}

$ask = Join-Path $env:TEMP "ssh-askpass-alras.cmd"
Set-Content -Path $ask -Value "@echo off`r`necho $KeyPassphrase" -Encoding ASCII
$env:SSH_ASKPASS = $ask
$env:SSH_ASKPASS_REQUIRE = "force"
$env:DISPLAY = "1"

$sshArgs = @(
    "-i", $IdentityFile,
    "-o", "IdentitiesOnly=yes",
    "-o", "PreferredAuthentications=publickey",
    "-o", "StrictHostKeyChecking=accept-new"
)

Write-Host "==> Uploading RAM monitoring scripts..." -ForegroundColor Cyan
scp @sshArgs `
    (Join-Path $MonitoringDir "ram-alert.py") `
    (Join-Path $MonitoringDir "ram-alert.env.example") `
    (Join-Path $MonitoringDir "install-ram-alert.sh") `
    "${User}@${HostName}:${RemotePath}/deploy/monitoring/"

$remoteCmd = @"
set -e
mkdir -p '$RemotePath/deploy/monitoring'
chmod +x '$RemotePath/deploy/monitoring/install-ram-alert.sh'
chmod +x '$RemotePath/deploy/monitoring/ram-alert.py'
bash '$RemotePath/deploy/monitoring/install-ram-alert.sh' '$RemotePath'
echo '==> Test run (will only send if RAM >= 90%):'
/usr/bin/python3 '$RemotePath/deploy/monitoring/ram-alert.py' || true
"@

Write-Host "==> Installing cron on remote server..." -ForegroundColor Cyan
ssh @sshArgs "${User}@${HostName}" $remoteCmd
Write-Host "==> RAM alert monitoring installed." -ForegroundColor Green
