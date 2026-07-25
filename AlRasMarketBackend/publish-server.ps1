$ErrorActionPreference = "Stop"

$root = $PSScriptRoot
$output = Join-Path $root "publish-output"

Write-Host "Publishing Ras Al Souq API to: $output"

if (Test-Path $output) {
    Remove-Item $output -Recurse -Force
}

dotnet publish (Join-Path $root "RasAlSouqPresentaionLayer\RasAlSouqPresentaionLayer.csproj") `
    -c Release `
    -o $output

$requiredFiles = @(
    "RasAlSouqPresentaionLayer.dll",
    "Microsoft.Data.SqlClient.dll",
    "Microsoft.EntityFrameworkCore.SqlServer.dll"
)

foreach ($file in $requiredFiles) {
    $path = Join-Path $output $file
    if (-not (Test-Path $path)) {
        throw "Publish is incomplete. Missing required file: $file"
    }
}

Write-Host ""
Write-Host "Publish completed successfully."
Write-Host "Upload ALL files from this folder to the server:"
Write-Host "  $output"
Write-Host ""
Write-Host "Do not upload only RasAlSouqPresentaionLayer.dll — include every DLL in the folder."
