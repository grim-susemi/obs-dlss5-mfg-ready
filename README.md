<div align="center">
  <sub>Susemi style test bundle, pinned hashes, copy in and go</sub>
</div>

<br />

<div align="center">

# OBS DLSS5 MFG Ready

Tested overlay payload for installed OBS with 2x to 6x frame gen. Overlay it, validate, launch.

[![Latest pre-release](https://img.shields.io/badge/Download-latest-green?style=for-the-badge&logo=github&logoColor=white)](https://github.com/grim-susemi/obs-dlss5-mfg-ready/releases/latest)
[![Rollback notes](https://img.shields.io/badge/Docs-rollback-blue?style=for-the-badge&logo=github&logoColor=white)](docs/RELEASE-NOTES-ko.md)
[![OptiScaler Susemi](https://img.shields.io/badge/OptiScaler-Susemi-purple?style=for-the-badge&logo=github&logoColor=white)](https://github.com/grim-susemi/OptiScaler-Susemi)

</div>

> [!NOTE]
> This repo is not an OptiScaler fork. OptiScaler source stays upstream, this ships a tested overlay payload for installed OBS only. Binaries go out through [Releases](https://github.com/grim-susemi/obs-dlss5-mfg-ready/releases), never through git history.

## What this is

It's an overlay payload for installed OBS with pinned hashes. Pick your count from the menu and it sticks after save and restart.

Default output is XeFG. DLSS MFG on RTX 4090 ships as an unofficial unlock candidate, for testing only.

## Install, first timer edition

You need installed OBS and about five minutes. This overwrites files inside your OBS install, so back up first.

1. Download the zip. Grab `obs-dlss5-mfg-ready-prerelease.zip` (about 416 MB) and `SHA256SUMS.txt` from the [latest pre-release page](https://github.com/grim-susemi/obs-dlss5-mfg-ready/releases/latest). Check the zip hash against `SHA256SUMS.txt` before you unpack.
2. Back up, then overlay. Close OBS completely, it must not be running. Copy your OBS install folder aside as your rollback copy. Then overlay the payload from the zip onto your install path. Every path below starts at that install path (for example `C:\Program Files\obs-studio`, or your custom path if you installed elsewhere):

```
bin/64bit/winmm.dll
bin/64bit/OptiScaler.ini
bin/64bit/OptiScaler/plugins/XeFGUnlock.ini
bin/64bit/OptiScaler/plugins/XeFGUnlock.asi
bin/64bit/OptiScaler/streamline/ (6 DLLs, incl. nvngx_dlssg.dll 310.9.1)
bin/64bit/ObsInputChain.ini
config/obs-studio/plugin_config/obs-websocket/config.json
```

3. Run the one-click check. From the package root, run `install-one-click.cmd`. It verifies hashes, fetches the NVIDIA DLLs it may not ship, checks each hash, then runs `run-obs-mfg.ps1 -ValidateOnly` and starts nothing. Success looks like this. You'll see the line `Validated: 2..6x unlock cap, runtime pins, local OBS policy and preset chain; no process started.` Type `$LASTEXITCODE` and it prints `0`. Don't launch on anything else.
4. Launch and confirm. Open OBS, pick 2x in the frame gen menu, save, restart OBS, and your pick is still there with presented output. That's it working.

If it fails, copy back. With OBS closed, copy your rollback files over the install paths they came from, rehash, then rerun install-one-click until it exits 0.

Two minutes of prep saves most headaches. Turn off the NVIDIA App override for OBS, add an antivirus exception for the OBS install folder, pull other injectors and overlays, save then restart after each menu change, and keep this as an overlay on installed OBS only.

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

설치된 OBS에 덮어 씌우는 테스트된 오버레이, 해시 고정, 메뉴에서 2x부터 6x 선택. 기본 출력은 XeFG, RTX 4090 DLSS MFG는 비공식 언락 취급.

설치 4단계: 1) [최신 pre-release](https://github.com/grim-susemi/obs-dlss5-mfg-ready/releases/latest)에서 `obs-dlss5-mfg-ready-prerelease.zip`(약 416 MB)과 `SHA256SUMS.txt`를 받아 해시 대조, 2) OBS 완전 종료 후 설치 폴더를 백업해 두고 zip의 payload를 설치 경로(예: `C:\Program Files\obs-studio`, 커스텀 설치면 해당 경로)에 file-map대로 덮어 복사, 3) 패키지 루트에서 `install-one-click` 실행(해시 검증과 ValidateOnly, exit 0이어야 함), 0이 아니면 실행 금지, 4) OBS 실행, 메뉴에서 2x 고르고 저장, 재시작해도 유지되고 presented가 찍히면 성공.

실패하면 OBS를 끄고 백업 파일을 제자리 경로에 복사, 재해시 후 install-one-click이 0으로 끝날 때까지 재확인.

| 항목 | 상태 |
|---|---|
| RTX 4090 | 실측 검증 |
| 20 / 30 / 50 시리즈 | 미검증, 제보 환영 |
| 240Hz 패널에서 6x | SDK가 약 360/s 생성, 스케줄까지가 PASS, 패널이 전부 표시한다는 뜻이 아님 |
| MFG 경로 | 비공식 언락 표기 유지 |
| Nukem FSR 3.1, FFX 스왑 | 2x만 지원, 3x부터 6x는 Unsupported |

주의: OBS 켠 채로 INI 수정 금지, 종료 시 덮어씀. Protected A는 손대지 않음. 전체 문안은 [docs/RELEASE-NOTES-ko.md](docs/RELEASE-NOTES-ko.md).
