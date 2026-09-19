# Ada MFG unlock candidate install - B deployed at winmm 4b2997b1 (st_01a0b608)

2026-09-19 04:48 KST, `C:/omo-research/obs-mfg-ready/evidence/dlss-mfg-unlock-20260919T043108/install/`.
This is the integration manifest for the approved RTX 40 Ada MFG unlock candidate (st_01a0b607 gate PASS).
It records the exact paths/hashes of what is now installed in B. No runtime PASS is claimed here -
the sequential native-DLSS GPU matrix is the next task. `baseline/` in the parent directory is the
st_01a0b5ff preflight capture; this `install/` supplements it with the install preimages and receipts.

## 1. Deployed B state (after install)

| path | before | after | note |
|---|---|---|---|
| `obs-portable/bin/64bit/winmm.dll` | `f103e38a...26762d` | `4b2997b1ed9f6cc98befafc740f197916f6296672263fbe189bd27960c8aeba8` | MFG candidate; 26,226,176 B; byte-identical to the st602 Release-RTX40-MFG product (`cmp`) |
| `run-obs-mfg.ps1` | `ff3e8805...deae6` | `0d51321138fc3f9352fdeabcfa7d2039fa3671edc0cfcc662b5d74b340a65986` | only line 11 changed: winmm pin `f103e38a -> 4b2997b1`; 6802 B |
| `C:/omo-research/obs-mainhdr/evidence/input-chain-b095/HASHES.json` | `40fc7732...861dc` (rev5) | `591900a6ee8e46a900b0fc47f7de340851e53928576990048f931f5aa661bc69` (rev6) | stage authority manifest; updated entries only (section 4) |

Candidate provenance: `staged/input-chain-b095/opti-source/x64/Release-RTX40-MFG/OptiScaler.dll`
`4b2997b1...`, built by st_01a0b602 (`evidence/st_01a0b602-summary.json` `ceea194b...`, exit 0,
MSBuild `/p:OptiScalerRtx40Mfg=true`), gate st_01a0b607 PASS for integration
(record `.omo/senpi-task/tasks/st_01a0b607.json` `474c0aea...`; record `st_01a0b602.json` `29af2ba0...`).
Control `opti-source/x64/Release/OptiScaler.dll` remains `f103e38a...` (untouched, rollback source).

## 2. Guard contract preserved (checks.json: 67 passed / 0 failed)

- cap5 unlock launcher contract still required: `XeFGUnlock.ini` `185d1d94...` (`UnlockMFG=true`,
  `MaxInterpolatedFrames=5`, `ExtraPacing=true`); ASI `XeFGUnlock.asi` `3337ea19...` unchanged.
- launcher pins re-verified against live files (winmm `4b2997b1...`, ObsProjector `edb80701...`,
  addon64 `1b4ba127...`, NR `e67dee20...`, SR `3975567b...`, libxess_fg `ec5e0c65...`, ASI `3337ea19...`).
- rock config byte-identical: `OptiScaler.ini` `6488623d...c3db6` (`[FrameGen] Enabled=true`,
  `FGInput=Upscaler`, `FGOutput=XeFG`) with all 10 owner-accepted `[DlssNr]` keys unchanged.
  `[DLSSG] InterpolationCount` stays `auto`; no `AdaMfgUnlock` key was added (next task).
- A protection: A `OptiScaler.ini` `f66b2787...` and A `winmm.dll` `1d23c708...` unchanged and
  mtime-older than the task; A never touched/launched, no owner/A process closed.
- B closed: obs64 count 0, no listeners 4455/4475; no OBS launch beyond `-ValidateOnly`.
- full B tree delta = exactly the two files above (2709 -> 2709 entries; install dir excluded);
  no file added or removed.

## 3. Candidate provenance (verified against the build receipt before install; no rebuild)

- candidate DLL `4b2997b1...` (26,226,176 B) == live st602 Release-RTX40-MFG output; stage dir
  contains only the expected `OptiScaler.dll`/`.exp`/`.lib`
- source tree: same input-chain-b095 tree as the f103 count fix (`XeFG_Dx12.cpp` `6840388f...`,
  `Config.cpp` `6fd61043...`), fresh full compile; MFG code gated by `#if defined(OPTISCALER_RTX40_MFG)`
- gate st_01a0b607: build exit 0; mfg_unlock 13/13 incl. disk-invariant runtime image patch
  (`nvngx_dlssg.dll` `ff6e90eb...` before==after); imgui 11 / home 5 / policy 2 / launcher 13 PASS;
  control untouched; MFG strings present; no B writes

## 4. Manifest rev5 -> rev6 (updated entries only)

`revision/supersedes/generated`; `state.installedPayloadWinmm` + `stageCandidateMfgUnlock` +
`mfgUnlockInstalled`; `payload[winmm]` sha+bytes+provenance; `payload[run-obs-mfg.ps1]`
sha+provenance+lineage; `launcherPins.winmm.dll`; `buildOutputs` (Release `sameAsDelivered=false`
as the non-MFG control + new Release-RTX40-MFG entry). Everything else preserved verbatim
(pins, preset contract, preservation, receipts).

## 5. Validation evidence

- `launcher-validate.log` + `launcher-validate.exit` and `launcher-validate-final.log` +
  `launcher-validate-final.exit`: `powershell -File run-obs-mfg.ps1 -ValidateOnly` exit 0,
  `Validated: 2..6x unlock cap, runtime pins, local OBS policy and preset chain; no process started.`
- `checks.json` (67/0), `before-tree.json` / `after-tree.json`, `receipt.json`
- patches: `launcher-fix.patch` `67efc9ad...`, `manifest-fix.patch` `d1389603...` (both rehearsed
  byte-exact on scratch copies against the preimages before the real apply)
- preimages: `preimages/winmm.dll` (f103), `preimages/run-obs-mfg.ps1` (ff3e8805),
  `preimages/HASHES.json.preimage` (rev5), plus `OptiScaler.ini.preimage` (6488623d) and
  `XeFGUnlock.ini.preimage` (185d1d94)
- `SHA256SUMS.txt` covers all of the above; `sha256sum -c` passes

## 6. Rollback / handoff

- Rollback to f103: `ROLLBACK.md` (copy preimages back + rehash + ValidateOnly; B must be CLOSED).
- GPU matrix handoff: `HANDOFF.md`; next task sets `FGOutput=dlssg` + `FGNvngxReplacement=none` +
  `[DLSSG] AdaMfgUnlock=true` + per-count `InterpolationCount` on CLOSED B with preimages.

STOP at integration handoff. No final all-PASS claim, no owner request, no plugin work.
