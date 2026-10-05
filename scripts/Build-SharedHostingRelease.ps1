[CmdletBinding()]
param(
    [ValidateSet('Standard', 'WebrootFallback')]
    [string] $Layout = 'Standard',

    [string] $OutputDirectory = ''
)

$ErrorActionPreference = 'Stop'

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path

if ([string]::IsNullOrWhiteSpace($OutputDirectory)) {
    $OutputDirectory = Join-Path $projectRoot 'artifacts\shared-hosting-release'
}

$outputPath = [System.IO.Path]::GetFullPath($OutputDirectory)

if (Test-Path -LiteralPath $outputPath) {
    throw "Output already exists: $outputPath. Remove or rename it before building a new release."
}

function Copy-ReleaseDirectory {
    param(
        [Parameter(Mandatory)] [string] $Source,
        [Parameter(Mandatory)] [string] $Destination,
        [string[]] $Exclude = @()
    )

    New-Item -ItemType Directory -Path $Destination -Force | Out-Null

    $robocopyArguments = @(
        $Source,
        $Destination,
        '/E',
        '/COPY:DAT',
        '/DCOPY:DAT',
        '/R:1',
        '/W:1',
        '/NFL',
        '/NDL',
        '/NJH',
        '/NJS',
        '/NP'
    )

    foreach ($name in $Exclude) {
        $robocopyArguments += '/XD'
        $robocopyArguments += (Join-Path $Source $name)
    }

    & robocopy @robocopyArguments | Out-Null

    # Robocopy uses 0-7 for success (including copied files); 8+ is an error.
    if ($LASTEXITCODE -ge 8) {
        throw "Robocopy failed while copying $Source (exit code $LASTEXITCODE)."
    }
}

function Initialize-Core {
    param([Parameter(Mandatory)] [string] $CoreDirectory)

    New-Item -ItemType Directory -Path $CoreDirectory -Force | Out-Null
    Copy-ReleaseDirectory (Join-Path $projectRoot 'app') (Join-Path $CoreDirectory 'app')
    Copy-ReleaseDirectory (Join-Path $projectRoot 'vendor') (Join-Path $CoreDirectory 'vendor')
    Copy-ReleaseDirectory (Join-Path $projectRoot 'writable') (Join-Path $CoreDirectory 'writable') @('cache', 'debugbar', 'logs', 'session', 'uploads')

    foreach ($folder in 'cache', 'debugbar', 'logs', 'session', 'uploads') {
        New-Item -ItemType Directory -Path (Join-Path $CoreDirectory "writable\\$folder") -Force | Out-Null
    }

    Copy-Item (Join-Path $projectRoot 'deployment\env.production.template') (Join-Path $CoreDirectory '.env.production.template')
}

New-Item -ItemType Directory -Path $outputPath -Force | Out-Null

if ($Layout -eq 'Standard') {
    Initialize-Core (Join-Path $outputPath 'inlislite-core')
    Copy-ReleaseDirectory (Join-Path $projectRoot 'public') (Join-Path $outputPath 'public')
    Copy-Item (Join-Path $projectRoot 'deployment\standard-index.php') (Join-Path $outputPath 'public\index.php') -Force
    Copy-Item (Join-Path $projectRoot 'deployment\webroot.htaccess') (Join-Path $outputPath 'public\.htaccess') -Force

    @"
Upload inlislite-core beside (not inside) the public web directory.
Point the domain document root to the public directory in this package. The
included public/index.php expects those directories to remain siblings.
Rename inlislite-core/.env.production.template to .env and fill its values.
"@ | Set-Content -LiteralPath (Join-Path $outputPath 'DEPLOY.txt') -Encoding utf8
}
else {
    Copy-ReleaseDirectory (Join-Path $projectRoot 'public') $outputPath
    Initialize-Core (Join-Path $outputPath '__inlislite')
    Copy-Item (Join-Path $projectRoot 'deployment\webroot-index.php') (Join-Path $outputPath 'index.php') -Force
    Copy-Item (Join-Path $projectRoot 'deployment\webroot.htaccess') (Join-Path $outputPath '.htaccess') -Force
    Copy-Item (Join-Path $projectRoot 'deployment\private.htaccess') (Join-Path $outputPath '__inlislite\.htaccess') -Force

    @"
Upload the CONTENTS of this directory to the hosting web root (often public_html or htdocs).
Rename __inlislite/.env.production.template to .env and fill its values.
Do not use this fallback where the provider blocks .env files or CodeIgniter.
"@ | Set-Content -LiteralPath (Join-Path $outputPath 'DEPLOY.txt') -Encoding utf8
}

Write-Host "Release prepared: $outputPath"
