# Downloads NuGet packages with curl.exe when dotnet restore fails with TLS/decryption errors.
# Usage (run each command on its own line):
#   cd "d:\nasser mostafa\Ras Al souq\AlRasMarketBackend"
#   powershell -ExecutionPolicy Bypass -File .\restore-packages.ps1
#   dotnet restore RasAlSouqPresentaionLayer.slnx
#   dotnet build RasAlSouqPresentaionLayer.slnx

$ErrorActionPreference = "Stop"
$failures = @()

$root = $PSScriptRoot
$cacheDir = Join-Path $root ".nuget-cache"
New-Item -ItemType Directory -Force -Path $cacheDir | Out-Null

Add-Type -AssemblyName System.IO.Compression.FileSystem

function Install-Package {
    param(
        [string]$Id,
        [string]$Version
    )

    $idLower = $Id.ToLowerInvariant()
    $nupkgName = "$idLower.$Version.nupkg"
    $nupkgPath = Join-Path $cacheDir $nupkgName

    if (Test-Path $nupkgPath) {
        $size = (Get-Item $nupkgPath).Length
        if ($size -gt 1024) {
            Write-Host "  skip $Id $Version"
            return
        }

        Remove-Item $nupkgPath -Force
    }

    $url = "https://api.nuget.org/v3-flatcontainer/$idLower/$Version/$nupkgName"
    Write-Host "  get  $Id $Version"

    & curl.exe --http1.1 --fail --location --retry 5 --retry-delay 3 --output $nupkgPath $url
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path $nupkgPath)) {
        $script:failures += "$Id $Version"
        Write-Warning "  FAIL $Id $Version"
        return
    }

    $size = (Get-Item $nupkgPath).Length
    if ($size -lt 1024) {
        Remove-Item $nupkgPath -Force
        $script:failures += "$Id $Version"
        Write-Warning "  FAIL $Id $Version (invalid size)"
        return
    }
}

# Package id + version pairs required by the updated backend.
$packages = @(
    @{ Id = "Azure.Core"; Version = "1.38.0" },
    @{ Id = "Azure.Identity"; Version = "1.11.4" },
    @{ Id = "Google.Apis"; Version = "1.69.0" },
    @{ Id = "Google.Apis.Auth"; Version = "1.69.0" },
    @{ Id = "Google.Apis.Core"; Version = "1.69.0" },
    @{ Id = "Humanizer.Core"; Version = "2.14.1" },
    @{ Id = "Konscious.Security.Cryptography.Argon2"; Version = "1.3.1" },
    @{ Id = "Konscious.Security.Cryptography.Blake2"; Version = "1.1.1" },
    @{ Id = "Microsoft.AspNetCore.Authentication.JwtBearer"; Version = "8.0.14" },
    @{ Id = "Microsoft.Bcl.AsyncInterfaces"; Version = "6.0.0" },
    @{ Id = "Microsoft.CodeAnalysis.Common"; Version = "4.5.0" },
    @{ Id = "Microsoft.CodeAnalysis.CSharp"; Version = "4.5.0" },
    @{ Id = "Microsoft.CodeAnalysis.CSharp.Workspaces"; Version = "4.5.0" },
    @{ Id = "Microsoft.CodeAnalysis.Workspaces.Common"; Version = "4.5.0" },
    @{ Id = "Microsoft.Data.SqlClient"; Version = "5.2.2" },
    @{ Id = "Microsoft.Data.SqlClient.SNI.runtime"; Version = "5.2.0" },
    @{ Id = "Microsoft.EntityFrameworkCore"; Version = "8.0.14" },
    @{ Id = "Microsoft.EntityFrameworkCore.Abstractions"; Version = "8.0.14" },
    @{ Id = "Microsoft.EntityFrameworkCore.Analyzers"; Version = "8.0.14" },
    @{ Id = "Microsoft.EntityFrameworkCore.Design"; Version = "8.0.14" },
    @{ Id = "Microsoft.EntityFrameworkCore.Relational"; Version = "8.0.14" },
    @{ Id = "Microsoft.EntityFrameworkCore.SqlServer"; Version = "8.0.14" },
    @{ Id = "Microsoft.Extensions.ApiDescription.Server"; Version = "8.0.14" },
    @{ Id = "Microsoft.Extensions.Caching.Abstractions"; Version = "8.0.0" },
    @{ Id = "Microsoft.Extensions.Caching.Memory"; Version = "8.0.1" },
    @{ Id = "Microsoft.Extensions.Configuration"; Version = "8.0.0" },
    @{ Id = "Microsoft.Extensions.Configuration.Abstractions"; Version = "8.0.0" },
    @{ Id = "Microsoft.Extensions.Configuration.Binder"; Version = "8.0.2" },
    @{ Id = "Microsoft.Extensions.DependencyInjection"; Version = "8.0.1" },
    @{ Id = "Microsoft.Extensions.DependencyInjection.Abstractions"; Version = "8.0.2" },
    @{ Id = "Microsoft.Extensions.DependencyModel"; Version = "8.0.2" },
    @{ Id = "Microsoft.Extensions.Diagnostics"; Version = "8.0.1" },
    @{ Id = "Microsoft.Extensions.Diagnostics.Abstractions"; Version = "8.0.1" },
    @{ Id = "Microsoft.Extensions.Http"; Version = "8.0.1" },
    @{ Id = "Microsoft.Extensions.Logging"; Version = "8.0.1" },
    @{ Id = "Microsoft.Extensions.Logging.Abstractions"; Version = "8.0.2" },
    @{ Id = "Microsoft.Extensions.Options"; Version = "8.0.2" },
    @{ Id = "Microsoft.Extensions.Options.ConfigurationExtensions"; Version = "8.0.0" },
    @{ Id = "Microsoft.Extensions.Primitives"; Version = "8.0.0" },
    @{ Id = "Microsoft.Identity.Client"; Version = "4.61.3" },
    @{ Id = "Microsoft.Identity.Client.Extensions.Msal"; Version = "4.61.3" },
    @{ Id = "Microsoft.IdentityModel.Abstractions"; Version = "8.3.1" },
    @{ Id = "Microsoft.IdentityModel.JsonWebTokens"; Version = "8.3.1" },
    @{ Id = "Microsoft.IdentityModel.Logging"; Version = "8.3.1" },
    @{ Id = "Microsoft.IdentityModel.Protocols"; Version = "8.3.1" },
    @{ Id = "Microsoft.IdentityModel.Protocols.OpenIdConnect"; Version = "8.3.1" },
    @{ Id = "Microsoft.IdentityModel.Tokens"; Version = "8.3.1" },
    @{ Id = "Microsoft.OpenApi"; Version = "1.6.22" },
    @{ Id = "Microsoft.SqlServer.Server"; Version = "1.0.0" },
    @{ Id = "Mono.TextTemplating"; Version = "2.2.1" },
    @{ Id = "Newtonsoft.Json"; Version = "13.0.3" },
    @{ Id = "SixLabors.ImageSharp"; Version = "3.1.12" },
    @{ Id = "Stripe.net"; Version = "51.1.0" },
    @{ Id = "Swashbuckle.AspNetCore"; Version = "7.2.0" },
    @{ Id = "Swashbuckle.AspNetCore.Swagger"; Version = "7.2.0" },
    @{ Id = "Swashbuckle.AspNetCore.SwaggerGen"; Version = "7.2.0" },
    @{ Id = "Swashbuckle.AspNetCore.SwaggerUI"; Version = "7.2.0" },
    @{ Id = "System.CodeDom"; Version = "7.0.0" },
    @{ Id = "System.Composition"; Version = "6.0.0" },
    @{ Id = "System.Composition.AttributedModel"; Version = "6.0.0" },
    @{ Id = "System.Composition.Convention"; Version = "6.0.0" },
    @{ Id = "System.Composition.Hosting"; Version = "6.0.0" },
    @{ Id = "System.Composition.Runtime"; Version = "6.0.0" },
    @{ Id = "System.Composition.TypedParts"; Version = "6.0.0" },
    @{ Id = "System.Configuration.ConfigurationManager"; Version = "8.0.0" },
    @{ Id = "System.IdentityModel.Tokens.Jwt"; Version = "8.3.1" },
    @{ Id = "System.Management"; Version = "7.0.2" },
    @{ Id = "System.Memory.Data"; Version = "1.0.2" },
    @{ Id = "System.Runtime.Caching"; Version = "6.0.0" },
    @{ Id = "System.Security.Cryptography.ProtectedData"; Version = "8.0.0" }
)

Write-Host "Downloading packages to $cacheDir"
foreach ($package in $packages) {
    Install-Package -Id $package.Id -Version $package.Version
}

Write-Host ""
if ($failures.Count -gt 0) {
    Write-Warning "Some packages failed. Re-run this script to retry:"
    $failures | ForEach-Object { Write-Warning "  $_" }
} else {
    Write-Host "All packages downloaded."
}

Write-Host ""
Write-Host "Next run:"
Write-Host "  dotnet restore RasAlSouqPresentaionLayer.slnx"
Write-Host "  dotnet build RasAlSouqPresentaionLayer.slnx"
