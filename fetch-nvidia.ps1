<#
.SYNOPSIS
    Fail-closed NVIDIA DLL fetch + SHA-256 verification for the obs-mfg-ready
    pre-release package.

.DESCRIPTION
    Downloads the NVIDIA runtime DLLs that cannot be redistributed, verifies every
    byte against SHA256SUMS.txt, and places each one into the package tree.

    Fail-closed rules:
      * A target with no manifest entry aborts the run.
      * A target whose official source is not confirmed is BLOCKED and aborts the
        run before any download. It is never skipped silently.
      * A download failure or a hash mismatch is retried up to -MaxRetries, then
        aborts. A file is only written after its hash is verified.
      * There is no manual file path: the operator cannot point the script at a
        hand-downloaded DLL.

    nvngx_dlssnr.dll (v310.8) is the BLOCKED target: its official public endpoint
    is UNCONFIRMED. Until that is resolved and the Confirmed flag below is flipped,
    it requires the explicit -AllowUnconfirmedSource -UnconfirmedSourceUrl override.

.PARAMETER DestRoot
    Package root that receives the files. Defaults to the release root two levels
    above this script (B in this repo).

.PARAMETER ManifestPath
    SHA256SUMS.txt to trust. Defaults to the copy beside this script.

.PARAMETER MaxRetries
    Attempts per target before failing closed. Default 3.

.PARAMETER OfflineSourceDir
    CI / test seam only: read each target from this local directory by file name
    and skip the network. Not part of the user-facing flow.

.PARAMETER AllowUnconfirmedSource
    Explicit override that unlocks the BLOCKED target. Requires -UnconfirmedSourceUrl.

.PARAMETER UnconfirmedSourceUrl
    Endpoint to use for the BLOCKED target when the override is given. Use only
    once the official endpoint is confirmed.
#>
[CmdletBinding()]
param(
    [string]$DestRoot,
    [string]$ManifestPath,
    [int]$MaxRetries = 3,
    [string]$OfflineSourceDir,
    [switch]$AllowUnconfirmedSource,
    [string]$UnconfirmedSourceUrl
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# $PSScriptRoot is not populated while parameter defaults are evaluated on
# Windows PowerShell 5.1, so resolve the path defaults here in the body.
if (-not $DestRoot) { $DestRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot) }
if (-not $ManifestPath) { $ManifestPath = Join-Path $PSScriptRoot 'SHA256SUMS.txt' }

# Target table. The SHA-256 in SHA256SUMS.txt is the authority, not the URL: a
# changed or wrong endpoint fails closed at verification.
#   Confirmed=$false  => BLOCKED, requires the explicit override below.
$Targets = @(
    [pscustomobject]@{
        Path      = 'obs-portable/bin/64bit/nvngx_dlss.dll'
        Version   = '310.9.1'
        Url       = 'https://github.com/NVIDIA/DLSS/releases/download/v310.9.1/nvngx_dlss.dll'
        Confirmed = $true
        Note      = 'NVIDIA DLSS official release asset (documented endpoint; hash-pinned)'
    },
    [pscustomobject]@{
        Path      = 'obs-portable/bin/64bit/OptiScaler/streamline/nvngx_dlssg.dll'
        Version   = '310.9.1'
        Url       = 'https://github.com/NVIDIA-RTX/Streamline/releases/download/v2.14.1/nvngx_dlssg.dll'
        Confirmed = $true
        Note      = 'NVIDIA Streamline official release asset (documented endpoint; hash-pinned)'
    },
    [pscustomobject]@{
        Path      = 'obs-portable/bin/64bit/nvngx_dlssnr.dll'
        Version   = '310.8'
        Url       = 'TODO: official NVIDIA DLSS-NR 310.8 endpoint UNCONFIRMED'
        Confirmed = $false
        Note      = 'BLOCKED - public endpoint unconfirmed; override required'
    }
)

function Read-HashManifest {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "SHA256 manifest not found: $Path. Nothing was downloaded."
    }
    $map = @{}
    $lineNo = 0
    foreach ($line in [System.IO.File]::ReadAllLines($Path)) {
        $lineNo++
        $text = $line.Trim()
        if ($text.Length -eq 0 -or $text.StartsWith('#')) { continue }
        $match = [regex]::Match($text, '^([0-9a-fA-F]{64})[ \t]+\*?(.+)$')
        if (-not $match.Success) {
            throw "Malformed SHA256SUMS.txt line ${lineNo}: $line"
        }
        $relative = $match.Groups[2].Value.Trim().Replace('\', '/')
        $map[$relative] = $match.Groups[1].Value.ToLowerInvariant()
    }
    return $map
}

function Get-TargetDestination {
    param([string]$Root, [string]$Relative)
    return (Join-Path $Root ($Relative -replace '/', '\'))
}

function Resolve-TargetSource {
    param($Target, [string]$OfflineDir, [bool]$AllowBlocked, [string]$BlockedUrl)
    if (-not $Target.Confirmed -and -not $AllowBlocked) {
        throw "BLOCKED: $($Target.Path) v$($Target.Version) has no confirmed official source. Nothing was downloaded."
    }
    if ($OfflineDir) {
        # CI/test seam: the offline directory supplies bytes for every target, so no
        # URL is needed even for the BLOCKED one (the override flag still gates it).
        $local = Join-Path $OfflineDir ([System.IO.Path]::GetFileName($Target.Path))
        if (-not (Test-Path -LiteralPath $local -PathType Leaf)) {
            throw "source file missing: $local"
        }
        return [pscustomobject]@{ Kind = 'file'; Value = $local }
    }
    if (-not $Target.Confirmed -and [string]::IsNullOrWhiteSpace($BlockedUrl)) {
        throw "BLOCKED: -AllowUnconfirmedSource requires -UnconfirmedSourceUrl. Nothing was downloaded."
    }
    $url = if ($Target.Confirmed) { $Target.Url } else { $BlockedUrl }
    return [pscustomobject]@{ Kind = 'url'; Value = $url }
}

function Get-ExistingHash {
    param([string]$Path)
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}

function Invoke-Fetch {
    $hashes = Read-HashManifest -Path $ManifestPath

    # Fail closed on a BLOCKED source before touching the network or the disk.
    if (-not $OfflineSourceDir) {
        foreach ($t in $Targets) {
            if (-not $t.Confirmed -and -not $AllowUnconfirmedSource) {
                throw "BLOCKED: $($t.Path) v$($t.Version) has no confirmed official source. Nothing was downloaded. Confirm the endpoint, or pass -AllowUnconfirmedSource -UnconfirmedSourceUrl <url> explicitly."
            }
            if (-not $t.Confirmed -and [string]::IsNullOrWhiteSpace($UnconfirmedSourceUrl)) {
                throw "BLOCKED: -AllowUnconfirmedSource requires -UnconfirmedSourceUrl. Nothing was downloaded."
            }
        }
    }

    $fetched = 0
    $present = 0
    foreach ($t in $Targets) {
        if (-not $hashes.ContainsKey($t.Path)) {
            throw "SHA256SUMS.txt has no entry for $($t.Path). Nothing was placed."
        }
        $expected = $hashes[$t.Path]
        $dest = Get-TargetDestination -Root $DestRoot -Relative $t.Path

        if (Test-Path -LiteralPath $dest -PathType Leaf) {
            if ((Get-ExistingHash -Path $dest) -eq $expected) {
                Write-Host "OK       $($t.Path) (present, hash verified)"
                $present++
                continue
            }
            Write-Host "STALE    $($t.Path) (present, hash mismatch; re-fetching)"
        }

        $attempt = 0
        $placed = $false
        $lastError = $null
        while ($attempt -lt $MaxRetries -and -not $placed) {
            $attempt++
            $temp = [System.IO.Path]::GetTempFileName()
            try {
                Write-Host ("GET      {0} (attempt {1}/{2})" -f $t.Path, $attempt, $MaxRetries)
                $source = Resolve-TargetSource -Target $t -OfflineDir $OfflineSourceDir -AllowBlocked ([bool]$AllowUnconfirmedSource) -BlockedUrl $UnconfirmedSourceUrl
                if ($source.Kind -eq 'file') {
                    Copy-Item -LiteralPath $source.Value -Destination $temp -Force
                }
                else {
                    Invoke-WebRequest -Uri $source.Value -OutFile $temp -UseBasicParsing -ErrorAction Stop
                }
                $actual = Get-ExistingHash -Path $temp
                if ($actual -ne $expected) {
                    throw "hash mismatch for $($t.Path): expected $expected got $actual"
                }
                $parent = Split-Path -Parent $dest
                if (-not (Test-Path -LiteralPath $parent)) {
                    New-Item -ItemType Directory -Force -Path $parent | Out-Null
                }
                Move-Item -LiteralPath $temp -Destination $dest -Force
                $placed = $true
                $fetched++
                Write-Host "VERIFIED $($t.Path)"
            }
            catch {
                $lastError = $_.Exception.Message
                Write-Warning ("attempt {0}/{1} failed for {2}: {3}" -f $attempt, $MaxRetries, $t.Path, $lastError)
            }
            finally {
                if (Test-Path -LiteralPath $temp) {
                    Remove-Item -LiteralPath $temp -Force -ErrorAction SilentlyContinue
                }
            }
        }

        if (-not $placed) {
            throw "FAILED $($t.Path) after $MaxRetries attempt(s): $lastError. Aborting (fail-closed)."
        }
    }

    Write-Host "fetch-nvidia: $fetched fetched, $present already present; all $($Targets.Count) targets verified."
}

try {
    Invoke-Fetch
    exit 0
}
catch {
    [Console]::Error.WriteLine("fetch-nvidia ABORTED: " + $_.Exception.Message)
    exit 1
}
