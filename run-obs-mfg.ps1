param([switch]$ValidateOnly)
$ErrorActionPreference = 'Stop'
# 4x package: persistent OBS producer/projector policy; quality remains owner-judged.
Write-Output '4x OBS MFG - persistent producer/projector policy'
$bin = Join-Path $PSScriptRoot 'obs-portable\bin\64bit'
$exe = Join-Path $bin 'obs64.exe'
$asi = Join-Path $bin 'OptiScaler\plugins\XeFGUnlock.asi'
# Immutable payload keeps exact pins: binaries, model/SDK/ASI and the projector policy.
$expected = @{
    'ObsProjector.ini' = 'edb807015d5ec1c22c024cdbe20ae5c5d934ebf21bb5ec903c9b6e419d39dc05'
    'winmm.dll' = '4b2997b1ed9f6cc98befafc740f197916f6296672263fbe189bd27960c8aeba8'
    'dlss5-feed.addon64' = '1b4ba127370c4609ace1183e8dbd8af4f789e02cc07e6b8cef456c60802ed0ee'
    'nvngx_dlssnr.dll' = 'e67dee209320cdafe0e93e45675d7aa34323a53acc57a72b2e40a181581c989a'
    'nvngx_dlss.dll' = '3975567b8943c53acce397f2b72380092f84f162d00b0d2c7d08a1025c563983'
    'OptiScaler\libxess_fg.dll' = 'ec5e0c65e075570c6ede72618bb666d0be0c2e10b2ea9762c0fe8cb8e375ab27'
    'OptiScaler\plugins\XeFGUnlock.asi' = '3337ea197720d573aacf920231ed515d08324dba67d9966be32e1a2584cdbdb8'
}
foreach ($file in $expected.Keys) {
    $p = Join-Path $bin $file
    if (-not (Test-Path $p -PathType Leaf)) { throw "Candidate file missing: $file. Nothing was launched." }
    if ((Get-FileHash $p -Algorithm SHA256).Hash -ne $expected[$file]) {
        throw "Candidate hash mismatch: $file. Nothing was launched."
    }
}
if (-not (Test-Path $exe -PathType Leaf)) { throw 'Candidate OBS executable is missing.' }
# ReShade presets are runtime state: ReShade autosaves user changes, so exact bytes cannot
# be pinned. Validate the required configured chain instead of freezing user selections.
function Read-Preset([string]$name) {
    $path = Join-Path $bin $name
    if (-not (Test-Path $path -PathType Leaf)) { throw "Preset missing: $name. Nothing was launched." }
    $sections = @{ '' = @{} }
    $current = ''
    foreach ($line in [System.IO.File]::ReadAllLines($path)) {
        $text = $line.Trim()
        if ($text.Length -eq 0 -or $text.StartsWith(';')) { continue }
        if ($text.StartsWith('[')) {
            $current = $text.Trim('[', ']')
            if (-not $sections.ContainsKey($current)) { $sections[$current] = @{} }
            continue
        }
        $split = $text.IndexOf('=')
        if ($split -lt 0) { continue }
        $sections[$current][$text.Substring(0, $split).Trim()] = $text.Substring($split + 1).Trim()
    }
    return $sections
}
function Test-EffectDefinition($preset, [string]$section, [string]$definition) {
    if (-not $preset.ContainsKey($section)) { return $false }
    $value = $preset[$section]['PreprocessorDefinitions']
    if (-not $value) { return $false }
    return @($value -split '[,;]' | ForEach-Object { $_.Trim() }) -contains $definition
}
$inputPreset = Read-Preset 'ObsInputChain.ini'
$sorting = @($inputPreset['']['TechniqueSorting'] -split ',')
$chain = @('Lumenite_Kernel@lumenite_Kernel.fx', 'DLSS5_Feed@DLSS5_Feed.fx', 'Lumenite_TRAA@lumenite_TRAA.fx')
$positions = @($chain | ForEach-Object { [array]::IndexOf($sorting, $_) })
if ($positions -contains -1) {
    throw 'Preset contract violation: ObsInputChain.ini is missing a required chain technique in TechniqueSorting. Nothing was launched.'
}
if (-not ($positions[0] -lt $positions[1] -and $positions[1] -lt $positions[2])) {
    throw 'Preset contract violation: ObsInputChain.ini TechniqueSorting is not in the required Lumenite_Kernel -> DLSS5_Feed -> Lumenite_TRAA order. Nothing was launched.'
}
if (-not (Test-EffectDefinition $inputPreset 'lumenite_Kernel.fx' 'IMAGE_SPACE=0')) {
    throw 'Preset contract violation: ObsInputChain.ini is missing lumenite_Kernel.fx PreprocessorDefinitions=IMAGE_SPACE=0. Nothing was launched.'
}
if (-not (Test-EffectDefinition $inputPreset 'DLSS5_Feed.fx' 'DLSS5_MV_PROVIDER=3')) {
    throw 'Preset contract violation: ObsInputChain.ini is missing DLSS5_Feed.fx PreprocessorDefinitions=DLSS5_MV_PROVIDER=3. Nothing was launched.'
}
$outputPreset = Read-Preset 'ReShadePreset-nofx.ini'
if (-not $outputPreset[''].ContainsKey('Techniques')) {
    throw 'Preset contract violation: ReShadePreset-nofx.ini has no Techniques entry. Nothing was launched.'
}
foreach ($enabled in @($outputPreset['']['Techniques'] -split ',')) {
    $technique = $enabled.Trim()
    if ($technique -eq 'Lumenite_Kernel@lumenite_Kernel.fx' -or $technique -eq 'DLSS5_Feed@DLSS5_Feed.fx') {
        throw "Preset contract violation: output preset enables input-chain technique $technique. Nothing was launched."
    }
}
# XeFGUnlock.ini is runtime config for the ASI (the plugin may rewrite it), so exact bytes
# cannot be pinned. Validate the 2..6x unlock contract using the section name actually
# present in the file: UnlockMFG=true, MaxInterpolatedFrames=5 (menu up to 6x) and
# ExtraPacing=true, which is what fixed pacing above 2x.
$unlockPath = Join-Path $bin 'OptiScaler\plugins\XeFGUnlock.ini'
if (-not (Test-Path $unlockPath -PathType Leaf)) {
    throw 'Candidate file missing: XeFGUnlock.ini. Nothing was launched.'
}
$unlock = Read-Preset 'OptiScaler\plugins\XeFGUnlock.ini'
$unlockSection = $null
foreach ($candidate in @($unlock.Keys)) {
    if ($unlock[$candidate].ContainsKey('UnlockMFG')) { $unlockSection = $candidate; break }
}
if ($null -eq $unlockSection) {
    throw 'Candidate config violation: XeFGUnlock.ini has no UnlockMFG entry. Nothing was launched.'
}
$unlockValues = $unlock[$unlockSection]
if ($unlockValues['UnlockMFG'] -ne 'true') {
    throw "Candidate config violation: XeFGUnlock.ini [$unlockSection] UnlockMFG=$($unlockValues['UnlockMFG']) (expected true). Nothing was launched."
}
if ($unlockValues['MaxInterpolatedFrames'] -ne '5') {
    throw "Candidate config violation: XeFGUnlock.ini [$unlockSection] MaxInterpolatedFrames=$($unlockValues['MaxInterpolatedFrames']) (expected 5 for the 2..6x unlock). Nothing was launched."
}
if ($unlockValues['ExtraPacing'] -ne 'true') {
    throw "Candidate config violation: XeFGUnlock.ini [$unlockSection] ExtraPacing=$($unlockValues['ExtraPacing']) (expected true). Nothing was launched."
}
# OptiScaler.ini is runtime state (the plugin rewrites it), so exact bytes are NOT
# pinned. Validate the DLSS-candidate rock contract by parsed values instead:
# FGInput=Upscaler, FGOutput=XeFG, [XeFG]InterpolationCount=3, AdaMfgUnlock absent.
$rockPath = Join-Path $bin 'OptiScaler.ini'
if (-not (Test-Path $rockPath -PathType Leaf)) {
    throw 'Candidate file missing: OptiScaler.ini. Nothing was launched.'
}
$rock = Read-Preset 'OptiScaler.ini'
function Get-RockValue([string]$section, [string]$key) {
    if ($rock.ContainsKey($section) -and $rock[$section].ContainsKey($key)) { return $rock[$section][$key] }
    return $null
}
$fgSection = $null
foreach ($candidate in @($rock.Keys)) {
    if ($rock[$candidate].ContainsKey('FGInput') -or $rock[$candidate].ContainsKey('FGOutput')) { $fgSection = $candidate; break }
}
if ($null -eq $fgSection) {
    throw 'OptiScaler rock-state violation: no FGInput/FGOutput entry found (expected the DLSS-candidate rock: FGInput=Upscaler, FGOutput=XeFG). Nothing was launched.'
}
if ((Get-RockValue $fgSection 'FGInput') -ne 'Upscaler') {
    throw "OptiScaler rock-state violation: [$fgSection] FGInput=$(Get-RockValue $fgSection 'FGInput') (expected Upscaler for the DLSS-candidate rock). Nothing was launched."
}
if ((Get-RockValue $fgSection 'FGOutput') -ne 'XeFG') {
    throw "OptiScaler rock-state violation: [$fgSection] FGOutput=$(Get-RockValue $fgSection 'FGOutput') (expected XeFG for the DLSS-candidate rock). Nothing was launched."
}
if ((Get-RockValue 'XeFG' 'InterpolationCount') -ne '3') {
    throw "OptiScaler rock-state violation: [XeFG] InterpolationCount=$(Get-RockValue 'XeFG' 'InterpolationCount') (expected 3 for 4x). Nothing was launched."
}
foreach ($candidate in @($rock.Keys)) {
    if ($rock[$candidate].ContainsKey('AdaMfgUnlock')) {
        throw "OptiScaler rock-state violation: [$candidate] AdaMfgUnlock is present (expected absent for the DLSS-candidate rock). Nothing was launched."
    }
}
# DLSS-G + Streamline pair for the XeFG path: nvngx_dlssg.dll 310.9.1 and the
# sl.* shims at their pinned versions.
$slDir = Join-Path $bin 'OptiScaler\streamline'
$slExpected = @{
    'nvngx_dlssg.dll' = '310.9.1.0'
    'sl.common.dll' = '2.14.1.0'
    'sl.dlss_g.dll' = '2.14.1.0'
    'sl.interposer.dll' = '2.14.1.0'
    'sl.pcl.dll' = '2.14.1.0'
    'sl.reflex.dll' = '2.14.1.0'
}
foreach ($file in $slExpected.Keys) {
    $p = Join-Path $slDir $file
    if (-not (Test-Path $p -PathType Leaf)) { throw "Candidate file missing: OptiScaler\streamline\$file. Nothing was launched." }
    $actual = ([System.Diagnostics.FileVersionInfo]::GetVersionInfo($p).FileVersion -replace ',', '.')
    if ($actual -ne $slExpected[$file]) {
        throw "Candidate version mismatch: OptiScaler\streamline\$file is $actual (expected $($slExpected[$file])). Nothing was launched."
    }
}
if ($ValidateOnly) {
    Write-Output 'Validated: 2..6x unlock cap, runtime pins, local OBS policy and preset chain; no process started.'
    return
}
$running = @(Get-CimInstance Win32_Process -Filter "name='obs64.exe'")
if ($running.Count) {
    throw "OBS is already running (PID $($running.ProcessId -join ', ')). Refusing to start a second instance; nothing was launched or closed."
}
$p = Start-Process -FilePath $exe -ArgumentList '--portable','--multi','--disable-updater' -WorkingDirectory $bin -PassThru
Write-Output "4x OBS MFG PID $($p.Id). Close OBS normally. Local policy does not depend on launcher environment."
$p.WaitForExit()
exit $p.ExitCode
