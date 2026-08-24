# Deploy Al Ras backend to Contabo VPS
# Usage (PowerShell):
#   .\deploy\deploy-to-vps.ps1
#   .\deploy\deploy-to-vps.ps1 -Services api
#   .\deploy\deploy-to-vps.ps1 -Services "api,clip"

param(
    [string]$HostName = "169.58.68.26",
    [string]$User = "alrasmarket",
    [string]$RemotePath = "/opt/alrasmarket/app",
    [string]$IdentityFile = "$env:USERPROFILE\.ssh\id_ed25519",
    [string]$KeyPassphrase = "Alrasmarketuae",
    # Comma-separated: api,clip,nginx,redis,qdrant — empty = full stack
    [string]$Services = "api"
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
if (-not (Test-Path (Join-Path $Root "docker-compose.yml"))) {
    throw "Run from repo: expected docker-compose.yml under $Root"
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

$tar = Join-Path $env:TEMP "alras-backend-deploy.tar.gz"
if (Test-Path $tar) { Remove-Item $tar -Force }

Write-Host "==> Packing backend..." -ForegroundColor Cyan
Push-Location $Root
tar -czf $tar `
    --exclude=bin --exclude=obj --exclude=.vs --exclude=.git `
    --exclude=scripts/tmp-world-data --exclude=.nuget-cache `
    --exclude=deploy/certbot `
    .
Pop-Location
Write-Host "    Archive: $([math]::Round((Get-Item $tar).Length / 1MB, 1)) MB"

Write-Host "==> Uploading to ${User}@${HostName}:$RemotePath ..." -ForegroundColor Cyan
scp @sshArgs $tar "${User}@${HostName}:${RemotePath}/backend.tar.gz"
if ($LASTEXITCODE -ne 0) { throw "scp failed" }

$serviceList = if ([string]::IsNullOrWhiteSpace($Services)) { "" } else { $Services.Replace(",", " ") }
$remoteCmd = @"
set -e
cd '$RemotePath'
# Windows-built archives can contain duplicate members / metadata headers.
# --overwrite replaces existing source files instead of aborting the deploy.
tar --overwrite --no-same-owner -xzf backend.tar.gz
rm -f backend.tar.gz
# Stale path from before ProductAdoRepository moved to DataLayer.
rm -f BusinessLayer/DataAccess/ProductAdoRepository.cs
rmdir BusinessLayer/DataAccess 2>/dev/null || true
# Stale AI assistant paths before Services/AiAssistant (+ Mcp) move.
rm -f BusinessLayer/Services/AiAssistantToolsService.cs
rm -f BusinessLayer/Services/AiAssistantAppService.cs
rm -f BusinessLayer/Services/AiAssistantKnowledgeSource.cs
rm -f BusinessLayer/Services/QdrantAiKnowledgeIndex.cs
rm -f BusinessLayer/Services/OpenAiTextEmbeddingService.cs
rm -f BusinessLayer/Services/AiKnowledgeBootstrapHostedService.cs
rm -f BusinessLayer/Services/AiAssistantMcpToolsService.cs
rm -f BusinessLayer/Services/AiAssistantMcpToolLoop.cs
rm -rf BusinessLayer/Services/Mcp
# Stale image-search services before Services/ImageSearch move.
rm -f BusinessLayer/Services/ClipHttpEmbeddingService.cs
rm -f BusinessLayer/Services/OpenAiCatalogImageEmbeddingService.cs
rm -f BusinessLayer/Services/QdrantProductImageVectorIndex.cs
rm -f BusinessLayer/Services/ProductImageIndexingQueue.cs
rm -f BusinessLayer/Services/ProductImageVectorIndexingProcessor.cs
# Stale interfaces before Interfaces/AiAssistant and Interfaces/ImageSearch move.
rm -f BusinessLayer/Interfaces/IAiAssistantServices.cs
rm -f BusinessLayer/Interfaces/IAiAssistantMcpServices.cs
rm -f BusinessLayer/Interfaces/IImageEmbeddingService.cs
rm -f BusinessLayer/Interfaces/IProductImageIndexingQueue.cs
rm -f BusinessLayer/Interfaces/IProductImageVectorIndex.cs
# Stale Grafana cookie-proxy helper removed when monitoring moved into the dashboard.
rm -f BusinessLayer/Services/MonitoringAccessService.cs
# Stale supplier wallet / IBAN / withdrawal stack (removed from codebase).
rm -f BusinessLayer/Caching/SupplierBalanceCacheVersions.cs
rm -f BusinessLayer/Dtos/FinanceDtos.cs
rm -f BusinessLayer/Services/FinanceAppService.cs
rm -f BusinessLayer/Services/SupplierBalanceService.cs
rm -f DataLayer/Interfaces/IBalanceDataAccess.cs
rm -f DataLayer/Models/Balance.cs
rm -f DataLayer/Models/UserIban.cs
rm -f DataLayer/Models/WithdrawalRequest.cs
rm -f DataLayer/Repositories/BalanceDataAccess.cs
rm -f DataLayer/Seeding/BalanceSchemaMigrator.cs
rm -f DataLayer/Seeding/UserIbanSchemaMigrator.cs
rm -f DataLayer/Seeding/WithdrawalRequestSchemaMigrator.cs
rm -f RasAlSouqPresentaionLayer/Controllers/AdminFinanceController.cs
rm -f RasAlSouqPresentaionLayer/Controllers/SupplierBalanceController.cs
rm -f deploy/zero-all-balances.sql
# Stale legacy OffersOnRequests / OffersOnNegotiable stack (superseded by Orders).
rm -f BusinessLayer/Services/OffersAppService.cs
rm -f DataLayer/Models/Offer.cs
rm -f DataLayer/Models/OfferOnNegotiable.cs
rm -f DataLayer/Models/OfferOnRequestDocument.cs
rm -f DataLayer/Models/OfferOnRequestImage.cs
rm -f DataLayer/Models/OfferStatus.cs
rm -f DataLayer/Seeding/OfferSchemaMigrator.cs
rm -f RasAlSouqPresentaionLayer/Controllers/OffersController.cs
mkdir -p deploy/certbot/conf deploy/certbot/www
echo '==> Building & restarting...'
if [ -n '$serviceList' ]; then
  docker compose up -d --build --no-deps $serviceList
else
  docker compose up -d --build
fi
# Ensure Redis stays up (api-only deploys must not leave cache missing).
docker compose up -d redis
# Nginx caches old api container IPs after api recreate.
docker compose restart nginx
docker compose ps
echo DONE
"@

Write-Host "==> Remote build..." -ForegroundColor Cyan
ssh @sshArgs "${User}@${HostName}" $remoteCmd
if ($LASTEXITCODE -ne 0) { throw "remote deploy failed" }

Remove-Item $tar -Force -ErrorAction SilentlyContinue
Write-Host "==> Deploy finished." -ForegroundColor Green
Write-Host "Health: http://${HostName}/api/health"
