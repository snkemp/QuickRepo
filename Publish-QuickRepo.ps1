<#
.SYNOPSIS
    Publishes the QuickRepo module to the PowerShell Gallery.

.DESCRIPTION
    Runs pre-flight checks, executes the Pester test suite, then publishes
    QuickRepo to PSGallery (or a custom repository).

    Required: $env:PSGALLERY_API_KEY or -ApiKey parameter.

.PARAMETER ApiKey
    Your PSGallery API key. Defaults to $env:PSGALLERY_API_KEY.

.PARAMETER Repository
    Target PowerShell repository name. Defaults to 'PSGallery'.

.PARAMETER BumpVersion
    Which version segment to auto-increment before publishing:
    None (default), Patch, Minor, or Major.

.PARAMETER SkipTests
    Skip the Pester test run. Not recommended.

.PARAMETER WhatIf
    Show what would happen without actually publishing.

.EXAMPLE
    .\Publish-QuickRepo.ps1 -ApiKey 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'

.EXAMPLE
    .\Publish-QuickRepo.ps1 -BumpVersion Patch

.EXAMPLE
    .\Publish-QuickRepo.ps1 -WhatIf
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [string] $ApiKey = $env:PSGALLERY_API_KEY,
    [string] $Repository = 'PSGallery',
    [ValidateSet('None', 'Patch', 'Minor', 'Major')]
    [string] $BumpVersion = 'None',
    [switch] $SkipTests
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Windows PowerShell 5.1 has broken PowerShellGet/TLS stack; re-launch in pwsh 7 if available
if ($PSVersionTable.PSEdition -eq 'Desktop') {
    $pwsh = Get-Command pwsh -ErrorAction SilentlyContinue
    if ($pwsh) {
        $passArgs = $PSBoundParameters.GetEnumerator() | ForEach-Object {
            if ($_.Value -is [switch]) { if ($_.Value) { "-$($_.Key)" } }
            else { "-$($_.Key)"; $_.Value }
        }
        & $pwsh.Source -NoProfile -ExecutionPolicy Bypass -File $PSCommandPath @passArgs
        exit $LASTEXITCODE
    }
    # pwsh not found — fall back and force TLS 1.2 for nuget.exe
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
}

$moduleRoot = Join-Path $PSScriptRoot 'QuickRepo'
$manifestPath = Join-Path $moduleRoot   'QuickRepo.psd1'

# ── helpers ───────────────────────────────────────────────────────────────────
function Write-Step ([string]$msg) { Write-Host "  $msg" -ForegroundColor Cyan }
function Write-Ok   ([string]$msg) { Write-Host "  OK  $msg" -ForegroundColor Green }
function Write-Fail ([string]$msg) { Write-Host "  FAIL $msg" -ForegroundColor Red }

Write-Host "`nQuickRepo publish pipeline" -ForegroundColor White
Write-Host "─────────────────────────────────────────" -ForegroundColor DarkGray

# ── 1. validate manifest exists ───────────────────────────────────────────────
Write-Step 'Checking module manifest...'
if (-not (Test-Path $manifestPath)) {
    Write-Fail "Manifest not found at $manifestPath"
    exit 1
}
$manifest = Import-PowerShellDataFile $manifestPath
Write-Ok "Version: $($manifest.ModuleVersion)"

# ── 2. optional version bump ──────────────────────────────────────────────────
if ($BumpVersion -ne 'None') {
    Write-Step "Bumping $BumpVersion version..."
    $current = [version]$manifest.ModuleVersion
    $newVer = switch ($BumpVersion) {
        'Patch' { [version]::new($current.Major, $current.Minor, $current.Build + 1) }
        'Minor' { [version]::new($current.Major, $current.Minor + 1, 0) }
        'Major' { [version]::new($current.Major + 1, 0, 0) }
    }

    if ($PSCmdlet.ShouldProcess($manifestPath, "Bump version $current -> $newVer")) {
        Update-ModuleManifest -Path $manifestPath -ModuleVersion $newVer
        Write-Ok "Version bumped to $newVer"
    }
}

# ── 3. validate manifest ──────────────────────────────────────────────────────
Write-Step 'Validating manifest...'
$testResult = Test-ModuleManifest -Path $manifestPath -ErrorAction Stop
Write-Ok "Manifest valid — $($testResult.Name) v$($testResult.Version)"

# ── 4. run Pester tests ───────────────────────────────────────────────────────
if (-not $SkipTests) {
    Write-Step 'Running Pester tests...'

    if (-not (Get-Module Pester -ListAvailable | Where-Object { $_.Version -ge '5.0' })) {
        Write-Host '  Pester 5 not found. Installing...' -ForegroundColor Yellow
        Install-Module -Name Pester -MinimumVersion 5.0 -Force -Scope CurrentUser -SkipPublisherCheck
    }

    $pesterConfig = New-PesterConfiguration @{
        Run        = @{ Path = Join-Path $moduleRoot 'Tests'; PassThru = $true }
        Output     = @{ Verbosity = 'Detailed' }
        TestResult = @{
            Enabled      = $true
            OutputPath   = Join-Path $PSScriptRoot 'TestResults.xml'
            OutputFormat = 'NUnitXml'
        }
    }

    $result = Invoke-Pester -Configuration $pesterConfig

    if ($result.FailedCount -gt 0) {
        Write-Fail "$($result.FailedCount) test(s) failed. Aborting publish."
        exit 1
    }
    Write-Ok "$($result.PassedCount) test(s) passed."
}
else {
    Write-Host '  WARNING: Tests skipped.' -ForegroundColor Yellow
}

# ── 5. check API key ──────────────────────────────────────────────────────────
if (-not $ApiKey) {
    Write-Fail 'No API key provided. Set $env:PSGALLERY_API_KEY or pass -ApiKey.'
    exit 1
}

# ── 5a. ensure PowerShellGet 2+ (v1 uses nuget.exe which breaks TLS 1.2) ──────
# ── 5a. ensure PowerShellGet 2+ (v1 uses nuget.exe which breaks TLS 1.2) ──────
$psget = Get-Module PowerShellGet -ListAvailable | Sort-Object Version -Descending | Select-Object -First 1
if ($psget.Version.Major -lt 2) {
    Write-Step 'Upgrading PowerShellGet to v2+ (required for TLS 1.2 support)...'
    Install-Module PowerShellGet -MinimumVersion 2.0 -Force -Scope CurrentUser -AllowClobber
}
$psget = Get-Module PowerShellGet -ListAvailable | Sort-Object Version -Descending | Select-Object -First 1
Import-Module PowerShellGet -MinimumVersion 2.0 -Force
Write-Ok "PowerShellGet v$((Get-Module PowerShellGet).Version) loaded."

# ── 6. publish ────────────────────────────────────────────────────────────────
Write-Step "Publishing to '$Repository'..."

$publishParams = @{
    Path        = $moduleRoot
    NuGetApiKey = $ApiKey
    Repository  = $Repository
    Verbose     = $VerbosePreference -eq 'Continue'
}

if ($PSCmdlet.ShouldProcess("QuickRepo v$($manifest.ModuleVersion)", "Publish to $Repository")) {
    try {
        Publish-Module @publishParams -ErrorAction Stop
        Write-Ok "Published QuickRepo v$($manifest.ModuleVersion) to $Repository"
    }
    catch {
        Write-Fail "Failed to publish: $_"
        exit 1
    }
}
else {
    Write-Host '  WhatIf: Publish-Module would have run here.' -ForegroundColor DarkGray
}

Write-Host "`nDone.`n" -ForegroundColor Green
