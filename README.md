<div align="center">
  <sub>Susemi style test bundle, pinned hashes, copy in and go</sub>
</div>

<br />

<div align="center">

# OBS DLSS5 MFG Ready

Tested portable OBS payload with 2x to 6x frame gen. Copy it in, validate, launch.

[![Latest pre-release](https://img.shields.io/badge/Download-latest-green?style=for-the-badge&logo=github&logoColor=white)](https://github.com/grim-susemi/obs-dlss5-mfg-ready/releases/latest)
[![Rollback notes](https://img.shields.io/badge/Docs-rollback-blue?style=for-the-badge&logo=github&logoColor=white)](docs/RELEASE-NOTES-ko.md)
[![OptiScaler Susemi](https://img.shields.io/badge/OptiScaler-Susemi-purple?style=for-the-badge&logo=github&logoColor=white)](https://github.com/grim-susemi/OptiScaler-Susemi)

</div>

> [!NOTE]
> This repo is not an OptiScaler fork. OptiScaler source stays upstream, this ships a tested OBS bundle only. Binaries go out through [Releases](https://github.com/grim-susemi/obs-dlss5-mfg-ready/releases), never through git history.

## What this is

It's a portable OBS bundle with pinned hashes. Pick your count from the menu and it sticks after save and restart.

Default output is XeFG. DLSS MFG on RTX 4090 ships as an unofficial unlock candidate, for testing only.

## Install, first timer edition

You'll need portable OBS and about five minutes. Nothing here touches your system, files land under your OBS folder only.

1. Download the zip. Grab `obs-dlss5-mfg-ready-prerelease.zip` (about 302 MB) from the [latest pre-release page](https://github.com/grim-susemi/obs-dlss5-mfg-ready/releases/latest). That's the only file you need.
2. Unzip it anywhere. Downloads is fine. You'll see a folder containing `run-obs-mfg.cmd`, `run-obs-mfg.ps1`, and an `obs-portable` folder. Keep that window open.
3. Back up, then copy. Close OBS completely, it must not be running. Copy your own portable OBS folder next to itself and call the copy `obs-backup`, that's your undo button. Then copy the unzipped `obs-portable` folder over your real portable OBS folder and say yes to overwrite. The files land exactly here:

```
obs-portable/bin/64bit/winmm.dll
obs-portable/bin/64bit/OptiScaler.ini
obs-portable/bin/64bit/OptiScaler/plugins/XeFGUnlock.ini
obs-portable/bin/64bit/OptiScaler/plugins/XeFGUnlock.asi
obs-portable/bin/64bit/OptiScaler/streamline/ (6 DLLs, incl. nvngx_dlssg.dll 310.9.1)
obs-portable/bin/64bit/ObsInputChain.ini
obs-portable/config/obs-studio/plugin_config/obs-websocket/config.json
```

4. Run the safety check. Open PowerShell in your portable OBS folder and type `.\run-obs-mfg.ps1 -ValidateOnly`, then hit enter. It checks every file and starts nothing.
5. Success looks like this. You'll see the line `Validated: 2..6x unlock cap, runtime pins, local OBS policy and preset chain; no process started.` Type `$LASTEXITCODE` and it prints `0`. Now double-click `run-obs-mfg.cmd` and OBS opens. Open the frame gen menu, pick 2x, save, restart OBS, and your pick is still there. That's it working.
6. If it fails, one command undoes it. Close OBS, open a terminal in the folder holding both copies, and run `robocopy obs-backup obs-portable /MIR`. Type the names exactly in that order, it mirrors your backup back. Rerun the check from step 4 and it should pass again.

Two minutes of prep saves most headaches. Turn off the NVIDIA App override for OBS, add an antivirus exception for the portable folder, pull other injectors and overlays, save then restart after each menu change, and keep this portable only.

## Support

| Item | Status |
|---|---|
| RTX 4090 | Verified on this build |
| 20 / 30 / 50 series | Unverified, feedback welcome |
| 240Hz panel at 6x | SDK builds and schedules about 360/s from 60 fps source. A 240Hz panel can't show all 360, PASS covers gen plus schedule |
| 4x and up | Same deal, presents pass panel refresh, capped by what yours can draw |
| MFG path | Unofficial unlock, never official Blackwell support |
| Nukem FSR 3.1 swap, FFX swap | 2x only, 3x to 6x Unsupported |

> [!CAUTION]
> Don't edit the INI while OBS runs. It rewrites it on exit and your edits get lost. Protected A stays untouched.

## Links

* Latest pre-release: [releases/latest](https://github.com/grim-susemi/obs-dlss5-mfg-ready/releases/latest)
* Full notes and rollback: [docs/RELEASE-NOTES-ko.md](docs/RELEASE-NOTES-ko.md)
* Receipts and proof: [docs/RELEASE-RECEIPT.md](docs/RELEASE-RECEIPT.md), [docs/evidence/](docs/evidence/)
* Upstream FROM: [OptiScaler-Susemi](https://github.com/grim-susemi/OptiScaler-Susemi)

---

## 한국어 요약

포터블 OBS에 덮어 복사하는 테스트된 번들, 해시 고정, 메뉴에서 2x부터 6x 선택. 기본 출력은 XeFG, RTX 4090 DLSS MFG는 비공식 언락 취급.

설치 6단계: 1) [최신 pre-release](https://github.com/grim-susemi/obs-dlss5-mfg-ready/releases/latest)에서 `obs-dlss5-mfg-ready-prerelease.zip` 받기, 2) 압축 풀기 (`run-obs-mfg.cmd`와 `obs-portable` 폴더 확인), 3) OBS 완전 종료 후 내 OBS 폴더를 `obs-backup`으로 복사해 두고 받은 `obs-portable` 덮어쓰기, 4) PowerShell에서 `.\run-obs-mfg.ps1 -ValidateOnly` 실행, 5) `Validated: 2..6x ...` 메시지와 `$LASTEXITCODE` 0 확인 후 `run-obs-mfg.cmd` 더블클릭, 메뉴에서 2x 고르고 저장 재시작해도 유지되면 성공, 6) 실패하면 OBS 끄고 두 복사본이 있는 폴더에서 `robocopy obs-backup obs-portable /MIR` 한 방으로 되돌린 뒤 4단계 재확인.

| 항목 | 상태 |
|---|---|
| RTX 4090 | 실측 검증 |
| 20 / 30 / 50 시리즈 | 미검증, 제보 환영 |
| 240Hz 패널에서 6x | SDK가 약 360/s 생성, 스케줄까지가 PASS, 패널이 전부 표시한다는 뜻이 아님 |
| MFG 경로 | 비공식 언락 표기 유지 |
| Nukem FSR 3.1, FFX 스왑 | 2x만 지원, 3x부터 6x는 Unsupported |

주의: OBS 켠 채로 INI 수정 금지, 종료 시 덮어씀. Protected A는 손대지 않음. 전체 문안은 [docs/RELEASE-NOTES-ko.md](docs/RELEASE-NOTES-ko.md).
