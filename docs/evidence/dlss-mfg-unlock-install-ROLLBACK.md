# Rollback - MFG unlock candidate install (st_01a0b608) to the previous f103 state

Target prior state (the state before this install, as of the st5cf install and the st_01a0b5ff preflight):

| file | prior hash |
|---|---|
| `obs-portable/bin/64bit/winmm.dll` | `f103e38a16f126c4c1b68f2dc9d90ee20f73ad78866b01081f2f035d6b26762d` |
| `run-obs-mfg.ps1` | `ff3e88052efcfa4f82b5efc3a1ad0cebc570aeac4a29c844ae911dccf81deae6` (the f103 launcher, cap5 contract) |
| `C:/omo-research/obs-mainhdr/evidence/input-chain-b095/HASHES.json` | `40fc773235d875f54d78437a2644cee4d68e611f2b9acacccdd65579539861dc` (rev5) |

Preimages (byte copies, verified identical at capture time) live in this directory:

- `preimages/winmm.dll` = f103e38a... (26,211,840 B)
- `preimages/run-obs-mfg.ps1` = ff3e8805... (pins f103 at line 11)
- `preimages/HASHES.json.preimage` = 40fc7732... (rev5)

Independent copies also remain on disk untouched:
- f103 payload: `C:/omo-research/obs-mainhdr/staged/input-chain-b095/opti-source/x64/Release/OptiScaler.dll` (= f103e38a)
- unlock configs: `baseline/OptiScaler.ini.preimage` (6488623d) + `baseline/XeFGUnlock.ini.preimage` (185d1d94) in the parent directory

## Rollback procedure (only while B is CLOSED)

OptiScaler rewrites `OptiScaler.ini` on exit, so never do this with `obs64.exe` running.

```
rem 0) prove B is closed (expect 0; never close owner/A processes)
powershell -NoProfile -Command "@(Get-CimInstance Win32_Process -Filter \"name='obs64.exe'\").Count"

rem 1) restore the f103 core payload and the ff3e launcher (they must be restored together:
rem    each launcher pins the winmm hash exactly, so a lone restore fails -ValidateOnly)
copy /Y "C:\omo-research\obs-mfg-ready\evidence\dlss-mfg-unlock-20260919T043108\install\preimages\winmm.dll" "C:\omo-research\obs-mfg-ready\obs-portable\bin\64bit\winmm.dll"
copy /Y "C:\omo-research\obs-mfg-ready\evidence\dlss-mfg-unlock-20260919T043108\install\preimages\run-obs-mfg.ps1" "C:\omo-research\obs-mfg-ready\run-obs-mfg.ps1"

rem 2) restore the stage authority manifest rev5 (or keep rev6 and record the rollback there)
copy /Y "C:\omo-research\obs-mfg-ready\evidence\dlss-mfg-unlock-20260919T043108\install\preimages\HASHES.json.preimage" "C:\omo-research\obs-mainhdr\evidence\input-chain-b095\HASHES.json"

rem 3) verify
certutil -hashfile "C:\omo-research\obs-mfg-ready\obs-portable\bin\64bit\winmm.dll" SHA256        rem expect f103e38a...
certutil -hashfile "C:\omo-research\obs-mfg-ready\run-obs-mfg.ps1" SHA256                         rem expect ff3e8805...
certutil -hashfile "C:\omo-research\obs-mainhdr\evidence\input-chain-b095\HASHES.json" SHA256      rem expect 40fc7732...
powershell -NoProfile -ExecutionPolicy Bypass -File "C:\omo-research\obs-mfg-ready\run-obs-mfg.ps1" -ValidateOnly
rem expect exit 0 + "Validated: 2..6x unlock cap, runtime pins, local OBS policy and preset chain; no process started."
```

Notes:

- This install did NOT change `OptiScaler.ini`, `XeFGUnlock.ini`, presets, NR keys, capture or A;
  the rollback therefore only restores the three files above. The `baseline/` ini preimages exist
  only as an extra safety copy from the st_01a0b5ff preflight.
- The rollback pair was dry-run rehearsed on scratch copies (`checks.json`: preimage winmm -> f103e38a,
  preimage launcher -> ff3e8805 with its pin line reading f103e38a) before being documented here.
- Never close or kill owner/A processes during rollback; check the obs64 path if any process exists.
