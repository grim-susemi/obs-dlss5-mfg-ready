<#
.SYNOPSIS
    One-click installer for the obs-mfg-ready pre-release package.

.DESCRIPTION
    Copy bundled tree -> fetch + verify NVIDIA DLLs -> ValidateOnly -> report.
    Everything is fail-closed: any missing or failed file aborts the run, and a
    rollback restores the preimages captured before the copy.

    Phases:
      1. Preflight: refuse while OBS is running; require a real package tree.
      2. Snapshot: copy every destination file that will be overwritten into a
         preimage store (and record files that do not exist yet).
      3. Copy: overlay the bundled package tree onto DestRoot.
      4. Fetch: run fetch-nvidia.ps1 (downloads + SHA-256 verifies the NVIDIA DLLs).
      5. Validate: run the package launcher with -ValidateOnly and require exit 0.
      6. Report, or roll back and abort.

    There are no manual-file steps and no global changes: files are written only
    under DestRoot.

.PARAMETER PackageRoot
    Bundled package tree to copy from. Must contain an obs-portable directory.
    Defaults to this script's directory (the release root in the shipped layout).

.PARAMETER DestRoot
    Target install root (B). Defaults to two levels above this script.

.PARAMETER MaxRetries
    Passed to fetch-nvidia.ps1. Default 3.

.PARAMETER OfflineSourceDir
    CI / test seam only: passed to fetch-nvidia.ps1 to avoid the network.

.PARAMETER AllowUnconfirmedSource, UnconfirmedSourceUrl
    Passed to fetch-nvidia.ps1 for the BLOCKED nvngx_dlssnr.dll target.

.PARAMETER FetchManifestPath
    Passed to fetch-nvidia.ps1. Defaults to the SHA256SUMS.txt beside this script.

.PARAMETER ValidateScriptPath
    Launcher to run with -ValidateOnly. Defaults to <DestRoot>\run-obs-mfg.ps1.

.PARAMETER SkipProcessGuard
    CI / test seam only: skip the "OBS is running" check.
#>
[CmdletBinding()]
param(
    [string]$PackageRoot,
    [string]$DestRoot,
    [int]$MaxRetries = 3,
    [string]$OfflineSourceDir,
    [switch]$AllowUnconfirmedSource,
    [string]$UnconfirmedSourceUrl,
    [string]$FetchManifestPath,
    [string]$ValidateScriptPath,
    [switch]$SkipProcessGuard
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$FetchScript = Join-Path $PSScriptRoot 'fetch-nvidia.ps1'

# $PSScriptRoot is not populated while parameter defaults are evaluated on
# Windows PowerShell 5.1, so resolve the path defaults here in the body.
if (-not $PackageRoot) { $PackageRoot = $PSScriptRoot }
if (-not $DestRoot) { $DestRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot) }

function Fail-Preflight {
    param([string]$Message)
    [Console]::Error.WriteLine("install-one-click ABORTED: $Message")
    exit 1
}

# --- 1. preflight ---------------------------------------------------------
if (-not (Test-Path -LiteralPath $PackageRoot -PathType Container)) {
    Fail-Preflight "package root not found: $PackageRoot"
}
$PackageRoot = (Resolve-Path -LiteralPath $PackageRoot).Path
if (-not (Test-Path -LiteralPath (Join-Path $PackageRoot 'obs-portable') -PathType Container)) {
    Fail-Preflight "not a release package (no obs-portable under $PackageRoot)"
}
if (-not (Test-Path -LiteralPath $FetchScript -PathType Leaf)) {
    Fail-Preflight "fetch-nvidia.ps1 not found beside this script: $FetchScript"
}
if (-not (Test-Path -LiteralPath $DestRoot)) {
    New-Item -ItemType Directory -Force -Path $DestRoot | Out-Null
}
$DestRoot = (Resolve-Path -LiteralPath $DestRoot).Path
if ($PackageRoot -eq $DestRoot) {
    Fail-Preflight 'package root and destination root are the same directory'
}
if (-not $ValidateScriptPath) { $ValidateScriptPath = Join-Path $DestRoot 'run-obs-mfg.ps1' }
if (-not $FetchManifestPath) { $FetchManifestPath = Join-Path $PSScriptRoot 'SHA256SUMS.txt' }

if (-not $SkipProcessGuard) {
    $running = @(Get-CimInstance Win32_Process -Filter "name='obs64.exe'")
    if ($running.Count) {
        Fail-Preflight "OBS is running (PID $($running.ProcessId -join ', ')). Close OBS and re-run; nothing was changed."
    }
}

# --- 2. snapshot preimages ------------------------------------------------
$WorkDir = Join-Path $env:TEMP ('obs-mfg-install-' + [guid]::NewGuid().ToString('N'))
$PreimageDir = Join-Path $WorkDir 'preimages'
$AddedFile = Join-Path $WorkDir 'added.txt'
New-Item -ItemType Directory -Force -Path $PreimageDir | Out-Null
[System.IO.File]::WriteAllText($AddedFile, '')

function Get-RelativePath {
    param([string]$Root, [string]$FullName)
    return $FullName.Substring($Root.Length).TrimStart([char]'\', [char]'/')
}

function Invoke-Rollback {
    param([string]$Reason)
    Write-Warning "rolling back: $Reason"
    foreach ($relative in [System.IO.File]::ReadAllLines($AddedFile)) {
        if ([string]::IsNullOrWhiteSpace($relative)) { continue }
        $dest = Join-Path $DestRoot $relative
        if (Test-Path -LiteralPath $dest -PathType Leaf) {
            Remove-Item -LiteralPath $dest -Force -ErrorAction SilentlyContinue
        }
    }
    foreach ($preimage in @(Get-ChildItem -LiteralPath $PreimageDir -Recurse -File -Force)) {
        $relative = Get-RelativePath -Root $PreimageDir -FullName $preimage.FullName
        $dest = Join-Path $DestRoot $relative
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $dest) | Out-Null
        Copy-Item -LiteralPath $preimage.FullName -Destination $dest -Force
    }
    Write-Warning 'rollback complete: preimages restored'
}

function Read-ManifestTargets {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "SHA256SUMS.txt not found: $Path"
    }
    $targets = @()
    foreach ($line in [System.IO.File]::ReadAllLines($Path)) {
        $text = $line.Trim()
        if ($text.Length -eq 0 -or $text.StartsWith('#')) { continue }
        $match = [regex]::Match($text, '^[0-9a-fA-F]{64}[ \t]+\*?(.+)$')
        if ($match.Success) {
            $targets += $match.Groups[1].Value.Trim().Replace('\', '/') -replace '/', '\'
        }
    }
    return $targets
}

# Every path this install can write: bundled files plus the fetched NVIDIA targets.
$BundleFiles = @(Get-ChildItem -LiteralPath $PackageRoot -Recurse -File -Force)
$Touched = New-Object System.Collections.Generic.List[string]
foreach ($file in $BundleFiles) { $Touched.Add((Get-RelativePath -Root $PackageRoot -FullName $file.FullName)) }
foreach ($target in (Read-ManifestTargets -Path $FetchManifestPath)) {
    if (-not $Touched.Contains($target)) { $Touched.Add($target) }
}
foreach ($relative in $Touched) {
    $dest = Join-Path $DestRoot $relative
    if (Test-Path -LiteralPath $dest -PathType Leaf) {
        $preimage = Join-Path $PreimageDir $relative
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $preimage) | Out-Null
        Copy-Item -LiteralPath $dest -Destination $preimage -Force
    }
    else {
        Add-Content -LiteralPath $AddedFile -Value $relative
    }
}

# --- 3..5. copy -> fetch -> validate, all-or-nothing ----------------------
try {
    foreach ($file in $BundleFiles) {
        $relative = Get-RelativePath -Root $PackageRoot -FullName $file.FullName
        $dest = Join-Path $DestRoot $relative
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $dest) | Out-Null
        Copy-Item -LiteralPath $file.FullName -Destination $dest -Force
    }
    Write-Host "copy     : $($BundleFiles.Count) bundled file(s) overlaid on $DestRoot"

    $fetchArgs = @('-DestRoot', $DestRoot, '-ManifestPath', $FetchManifestPath, '-MaxRetries', "$MaxRetries")
    if ($OfflineSourceDir) { $fetchArgs += @('-OfflineSourceDir', $OfflineSourceDir) }
    if ($AllowUnconfirmedSource) { $fetchArgs += '-AllowUnconfirmedSource' }
    if ($UnconfirmedSourceUrl) { $fetchArgs += @('-UnconfirmedSourceUrl', $UnconfirmedSourceUrl) }

    $previous = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        & powershell -NoProfile -ExecutionPolicy Bypass -File $FetchScript @fetchArgs
        $fetchExit = $LASTEXITCODE
    }
    finally { $ErrorActionPreference = $previous }
    if ($fetchExit -ne 0) {
        throw "NVIDIA fetch/verify failed (exit $fetchExit)"
    }
    Write-Host 'fetch    : NVIDIA targets downloaded and SHA-256 verified'

    if (-not (Test-Path -LiteralPath $ValidateScriptPath -PathType Leaf)) {
        throw "validate script missing: $ValidateScriptPath"
    }
    $ErrorActionPreference = 'Continue'
    try {
        & powershell -NoProfile -ExecutionPolicy Bypass -File $ValidateScriptPath -ValidateOnly
        $validateExit = $LASTEXITCODE
    }
    finally { $ErrorActionPreference = $previous }
    if ($validateExit -ne 0) {
        throw "ValidateOnly failed (exit $validateExit)"
    }
    Write-Host 'validate : launcher -ValidateOnly exit 0'
}
catch {
    Invoke-Rollback $_.Exception.Message
    Remove-Item -LiteralPath $WorkDir -Recurse -Force -ErrorAction SilentlyContinue
    [Console]::Error.WriteLine('install-one-click ABORTED (fail-closed): ' + $_.Exception.Message)
    exit 1
}

# --- 6. report ------------------------------------------------------------
Remove-Item -LiteralPath $WorkDir -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "`nINSTALL OK: copied $($BundleFiles.Count) bundled file(s), NVIDIA targets verified, ValidateOnly exit 0."
Write-Host "Launch with: $DestRoot\run-obs-mfg.cmd"
exit 0
