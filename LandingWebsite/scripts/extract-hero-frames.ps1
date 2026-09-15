# Re-extract high-quality hero scroll frames from the source clip.
# Place the source video at: public/hero/intro.mp4
# Usage:
#   powershell -File .\scripts\extract-hero-frames.ps1

param(
    [string]$InputVideo = "",
    [int]$Width = 1920,
    [int]$Fps = 6,
    # JPEG quality 2 = near-lossless (ffmpeg scale 2..31, lower is better)
    [int]$JpegQuality = 2
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
$Video = if ($InputVideo) { $InputVideo } else { Join-Path $Root "public\hero\intro.mp4" }
$OutDir = Join-Path $Root "public\hero\frames"
$FfmpegCandidates = @(
    (Join-Path $Root ".tools\ffmpeg\ffmpeg-master-latest-win64-gpl-shared\bin\ffmpeg.exe"),
    "ffmpeg"
)

if (-not (Test-Path $Video)) {
    throw "Source video not found: $Video`nCopy intro.mp4 to public/hero/ then re-run."
}

$ff = $FfmpegCandidates | Where-Object {
    if ($_ -eq "ffmpeg") { Get-Command ffmpeg -ErrorAction SilentlyContinue } else { Test-Path $_ }
} | Select-Object -First 1

if (-not $ff) { throw "ffmpeg not found. Install ffmpeg or restore LandingWebsite/.tools/ffmpeg." }

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
Remove-Item (Join-Path $OutDir "frame-*.jpg") -Force -ErrorAction SilentlyContinue

Write-Host "==> Extracting frames from $Video ($Width px, $Fps fps, q:v $JpegQuality)..."
& $ff -y -i $Video -vf "fps=$Fps,scale=${Width}:-2:flags=lanczos" -q:v $JpegQuality (Join-Path $OutDir "frame-%03d.jpg")
if ($LASTEXITCODE -ne 0) { throw "ffmpeg failed" }

$files = Get-ChildItem (Join-Path $OutDir "frame-*.jpg") | Sort-Object Name
if ($files.Count -lt 1) { throw "No frames written" }

Add-Type -AssemblyName System.Drawing
$probe = [System.Drawing.Image]::FromFile($files[0].FullName)
$w = $probe.Width
$h = $probe.Height
$probe.Dispose()

$meta = @{
    count = $files.Count
    pad = 3
    basePath = "/hero/frames/frame-"
    ext = ".jpg"
    width = $w
    height = $h
} | ConvertTo-Json
Set-Content -Path (Join-Path $Root "public\hero\frames.json") -Value $meta -Encoding UTF8

$totalMb = [math]::Round((($files | Measure-Object Length -Sum).Sum / 1MB), 2)
Write-Host "==> Wrote $($files.Count) frames at ${w}x${h} (~$totalMb MB). Update FRAME_COUNT in HeroScrollFrames.jsx if needed."
