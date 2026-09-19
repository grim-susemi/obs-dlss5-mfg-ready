# clean-install-20260919T111854-final — FINAL 트리(pre-release) 클린 설치 재검증 영수증

task `st_01a0b774` · 2026-09-19 11:18:54 ~ 11:20:11 KST · GPU 레인 단독 사용(OBS 1회 기동) ·
범위: B `C:/omo-research/obs-mfg-ready` **FINAL 트리** — launcher `9df6f49e`, scene `dbe2f857`,
rock OptiScaler.ini `6488623d`, installer `evidence/pre-release-installer/` → 테스트 디렉터리.
A `obs-dlss5-feeder-fixture` 무접촉.

1차 PASS(task `st_01a0b761`, `evidence/clean-install-20260919T110051/`) 이후 변경분:
**launcher** `0d513211…` → `9df6f49e…` (st_01a0b76e: rock 계약 + dlssg/sl 버전 검사), **scene**
`61543a4d…` → `dbe2f857…` (st_01a0b76c: F1 QA fixture 참조 제거). 본 영수증은 이 둘을 포함한
최종 트리로 클린 설치 → ValidateOnly → 기동 전체 재실행 결과다.

## 0. 결론 — PASS

빈 dest에 패키지 설치(offline seam) → installer 내부 + 별도 `-ValidateOnly` 각각 **exit 0** →
launcher로 **OBS 1회 기동**(PID 30332) → 저장된 fullscreen projector(monitor 0, 2560x1440) 위에서
**`presented:4 fgEnabled:1` (XeFG rock 4x) 1회 확정** + **`DLSS-NR evaluate succeeded` 1회** →
**정상 종료(launcher exit 0, memory leaks 0)**. device fault 0 · crash 0 · obs64 잔여 0.

- **B 무접촉 증명**: 검증 전후 B 트리 전체 3369 파일 SHA-256 맵 완전 동일,
  digest `cd0355de4142df1c12914cdd473ec5f7c6787d0dbbfc774c429cd9b2c2423e9f` (before = after).
  본 영수증 디렉터리 `evidence/clean-install-20260919T111854-final/` 외 B 변경 0.
- **A 무접촉**: B 밖 파일 쓰기 0 (테스트 디렉터리 `C:/omo-research/obs-mfg-clean-20260919T111854-final`).
- **신규 launcher 검사(rock 계약, streamline dlssg/sl 버전)가 dest에서 3회 전부 통과**:
  설치 내부 ValidateOnly · 별도 ValidateOnly · 실제 기동 전 가드.

## 1. 절차 요약

| 단계 | 명령/대상 | 결과 |
|---|---|---|
| 스테이징 | B → `TEST/package`(릴리스 번들 재구성), `TEST/offline-src`(NVIDIA DLL 3종), `TEST/dest`(빈) | **2161 파일/660,462,491 B** 로지컬 (복사 2157 + hardlink 4), 제외 51건/237,375,266 B |
| installer selftest | `package/tests/Invoke-Tests.ps1` | **TOTAL: 26 passed, 0 failed**, exit 0 |
| 설치 A(기본/네트워크) | `install-one-click.ps1 -PackageRoot package -DestRoot dest` | **fail-closed exit 1** — `BLOCKED: obs-portable/bin/64bit/nvngx_dlssnr.dll v310.8 has no confirmed official source. Nothing was downloaded.` → rollback → dest 파일 0 (빈 디렉터리 골격 113개만 잔존) |
| 설치 B(offline seam) | `+ -OfflineSourceDir offline-src -AllowUnconfirmedSource -MaxRetries 3` | **exit 0** — copy 2161 → fetch 3/3 verified → 내부 ValidateOnly exit 0 → INSTALL OK. dest 2164 파일/892,720,875 B |
| ValidateOnly(별도) | `dest/run-obs-mfg.ps1 -ValidateOnly` | **exit 0** — `Validated: 2..6x unlock cap, runtime pins, local OBS policy and preset chain; no process started.` |
| 기동(1회) | `dest/run-obs-mfg.ps1` → obs64 `--portable --multi --disable-updater` | **PASS** (§4) |

## 2. 해시 — 입력/핀 및 fetch 대상

검증 전 B 스냅샷에서 전부 일치(`stage-manifest.json → bKeyPins`, 드리프트 0):

| 파일 | SHA-256 |
|---|---|
| `run-obs-mfg.ps1` (**신규 launcher**) | `9df6f49eaf621ffa772cb73fb10b728451961cf6ca013aa1145f2c44aadaf8ee` |
| `…/basic/scenes/제목_없음.json` (**신규 scene**) | `dbe2f857cf82ac293ef1805ca05e38e7a4e82fc4948a1688a17c57a9504a2dc7` |
| `obs-portable/bin/64bit/OptiScaler.ini` (rock) | `6488623d4e9591b7191139097bcf9810e84d238e45c7aab9d8ce16b4655c3db6` |
| `obs-portable/bin/64bit/ObsProjector.ini` | `edb807015d5ec1c22c024cdbe20ae5c5d934ebf21bb5ec903c9b6e419d39dc05` |
| `obs-portable/bin/64bit/winmm.dll` | `4b2997b1ed9f6cc98befafc740f197916f6296672263fbe189bd27960c8aeba8` |
| `obs-portable/bin/64bit/dlss5-feed.addon64` | `1b4ba127370c4609ace1183e8dbd8af4f789e02cc07e6b8cef456c60802ed0ee` |
| `…/OptiScaler/plugins/XeFGUnlock.asi` | `3337ea197720d573aacf920231ed515d08324dba67d9966be32e1a2584cdbdb8` |
| `…/OptiScaler/plugins/XeFGUnlock.ini` | `185d1d94e6da082c63339f4452d23df81a2ec70662e30fc7cf5c943f1231bc54` |
| `…/plugin_config/obs-websocket/config.json` (rock) | `f335c8a9bdd7d442b66c26da5938280fd424969968573cfb7bbcbdf79f46a2e2` |

fetch 대상 3종(offline-src 공급 → dest 설치 후 재해시, `SHA256SUMS.txt`와 전부 일치):

| dest 경로 | SHA-256 |
|---|---|
| `obs-portable/bin/64bit/nvngx_dlss.dll` | `3975567b8943c53acce397f2b72380092f84f162d00b0d2c7d08a1025c563983` |
| `…/OptiScaler/streamline/nvngx_dlssg.dll` (310.9.1.0) | `ff6e90eb78b827927dff5b4ecc6b1c870c2e9bca29ed9f48c7d348cc9e170b82` |
| `obs-portable/bin/64bit/nvngx_dlssnr.dll` | `e67dee209320cdafe0e93e45675d7aa34323a53acc57a72b2e40a181581c989a` |

설치 후 dest의 launcher/lockstep 핀(`install.json → destPins`) 전부 일치 —
launcher `9df6f49e…`, scene `dbe2f857…`, rock `6488623d…` 포함, mismatch 0.

## 3. 설치 산출물

- dest 트리: **2173 파일 / digest `fc3581396847a4077b9fbe31709e48c09c5604fd6d2cddf52b67f1336cb0b0f1`** (`dest-tree-after.json`).
- 구조 비교(`after.json → destCompare`): staged 2161 중 missing 1·mismatch 1, extras 13 — 전부 설명됨:
  - extras: fetch DLL 3 + 런타임 로그/프로파일러 9 (OBS log, OptiScaler.log, dlss5-feed.log, XeFGUnlock.log, ReShade.log/.log1, nvngx*.log 2, scene `.bak`, profiler csv)
  - missing 1: 기존 `profiler_data/2026-09-19 09-41-30.csv.gz` — OBS 기동 시 prune, 신규 profiler csv 생성(§6 F4)
  - mismatch 1: scene JSON — OBS 종료 시 `saved_projectors` 재저장(§6 F3). **B 씬 `dbe2f857` 불변.**
- fixture QA gif(`evidence/st_01a0b123/output-short.gif`)는 **스테이징하지 않음** — 신규 scene이 QA 소스를 제거했으므로 불필요(§6 F1). dest extras에서도 사라짐(1차: 14 → 이번: 13).

## 4. 기동 증거 (1회, 단독 GPU)

- identity: owned **obs64 PID 30332**, exe `C:\omo-research\obs-mfg-clean-20260919T111854-final\dest\obs-portable\bin\64bit\obs64.exe`,
  cmdline `--portable --multi --disable-updater`, launcher stdout `4x OBS MFG PID 30332` — launcher exit **0**.
- OBS log `…/config/obs-studio/logs/2026-09-19 11-19-52.txt` (`obs-log.txt`로 복사, sha256 `4213ffe8515f77286ac33e61bcfbfa1961f806d51b73f9c5896760314792be0c`):
  `Startup complete` 11:19:58.364 → `Shutting down` 11:20:08.829 → `Number of memory leaks: 0`.
- **fullscreen projector**: 장면 컬렉션의 저장값(`saved_projectors`, monitor 0)으로 기동 시 자동 복원 —
  hwnd `14882698`, rect **[0,0,2560,1440]**(fullscreen), `OBS projector policy: persistent true valid true target 2560x1440`
  수락, swapchain `2561x1440`. (loopback ws `OpenSourceProjector` 요청은 1차와 동일하게 code 207 `not ready`로 거부 — 중복 프로젝터 없음, §6 F2.)
- **XeFG rock 4x** (`OptiScaler.log`, 원문 추출 `presented-lines.txt`):
  ```
  [11:20:05.175808] [I] … present status: … SUCCESS (0) presented:1 fgEnabled:0            (워밍업)
  [11:20:05.369552] [I] … WARNING_TOO_FEW_FRAMES (3) presented:1 fgEnabled:1               (워밍업)
  [11:20:05.382505] [I] … SUCCESS (0) presented:4 fgEnabled:1                             ← rock 4x 확정 1회
  ```
  (`Activate SetEnabled: true` ×2, `Interpolation count changed -1 -> 3`, init `interp:5`, swapchain created)
- **NR 성공** (`nr-lines.txt`): `[11:20:04.998783] [I] DlssNr_Dx12::State::Run DLSS-NR evaluate succeeded: 1 dispatches at 2561x1440, passes 1` (1회,
  feed: `first frame fed` 11:19:59.078 / `session open` 11:20:01.433).
- fault: `887A00xx` 0 · `Device Remove/Reset` 0 · `Couldn't create XeLL` 0 · crash 파일 0 (`fault-scan.json`).
- close: projector WM_CLOSE(11:20:08) → main WM_CLOSE(11:20:08) → **graceful, launcherExitCode 0**,
  obs64 잔여 0, ws 포트 4475 closed.
- 임시 ws enable은 **test dir 전용**(loopback): patch `f335c8a9 → 521b81f0`, 종료 후 **byte-exact `f335c8a9` 복원**(`matchesPrePatch: true`).
- scene 계약(설치 직후, `scene-check.json`): dest scene sha256 `dbe2f857…` 일치 · `current_scene/program = PS5 Capture` ·
  sources = dshow `PS5 Capture (Hagibis 4K)` + scene `PS5 Capture` 2건 · QA fixture 참조 0건 · `saved_projectors` monitor 0 — **PASS**.

## 5. 경계 / 디스크

- B: 읽기만. `evidence/clean-install-20260919T111854-final/` 영수증 추가 외 쓰기 0. A 무접촉. 전역 변경 0(레지스트리/드라이버/GPU 설정 무접촉).
  B의 `config/obs-studio/crashes/Crash 2026-09-18*.txt` 8건은 기존 파일(B digest로 불변 증명된 상태)이며 dest crash 0.
- no raw dumps: 원본 로그는 테스트 디렉터리에 그대로, 영수증에는 매칭 라인/해시만 추출.
- 스테이징 용량 절약: 300MB+ 파일은 hardlink 4개(avcodec, AMD FFX FG, libxess, libcef)로 중복 바이트 0,
  evidence/raw 로그·crash·`.bak/.orig` 51개(237MB, fetch 대상 3종 232MB 포함) 제외. dest의 857MB는 installer 자체 산출물(검증 대상).
- 테스트 디렉터리 `C:/omo-research/obs-mfg-clean-20260919T111854-final`(1.7GB, dest 857MB)은 점검용으로 잔존 — B 의존성 없이 삭제 가능.

## 6. 발견 / 한계

- **F1 (완료 확인)**: 1차의 QA fixture 상대경로 결함은 scene `dbe2f857`(st_01a0b76c)에서 해소 —
  dest 설치본에서 QA 참조 0건, 기동/종료에 "No such file" 없음(1차의 F1 재발 0). 본 재실행에서는 fixture 스테이징을 제거.
- **F2**: ws `OpenSourceProjector` 요청 code 207(not ready) 재현 — 프로젝터는 저장값으로 fullscreen 복원되어 있어 요청은 no-op. 중복 프로젝터/중복 창 0.
- **F3**: test dir의 scene JSON이 종료 시 재저장(`saved_projectors: []`, sha256 `ed330dc1…`) — 프로젝터를 OBS보다 먼저 닫았기 때문. **B 씬 불변.**
- **F4**: 기존 profiler csv.gz 1개가 런타임에 정리되고 신규 세션 csv 생성 — 관측 기록.
- **L1 (미검증)**: dlss/doc 공식 URL의 실제 네트워크 fetch는 이번 범위에서도 미검증. 기본 경로는 dlssnr
  엔드포인트 미확정으로 **설계상 fail-closed**(§1 설치 A, 다운로드 전 중단)이며, 설치는 README가 명시한
  CI/테스트 seam(`-OfflineSourceDir` + `-AllowUnconfirmedSource`)으로 수행 — 공급 DLL 3종 해시는 manifest와 일치.
- **L2**: 세션 길이 약 16초(11:19:52~11:20:08, 판정 조건 충족 후 +3초 안정화 뒤 종료). `presented:4`/NR 각 1회 표본 = 요구된 ONE 표본.
  지속 구동·화질·pacing은 미측정(별도 범위).
- **L3 (범위)**: launcher 회귀 테스트(`tests/launcher-validate-regression.ps1`, 9/9)는 st_01a0b76e에서 수행된 그대로이며
  본 재실행에서 반복하지 않음 — 본 영수증의 launcher 검증은 실설치 dest에서의 3회 실행(설치 내부/별도 ValidateOnly/기동 가드)이다.

## 7. 증적 파일 (본 디렉터리)

`RECEIPT.md`(본문) · `verify.py`(오케스트레이터, 본 재실행용으로 launcher/scene 핀·fixture 스킵 반영) ·
`state.json` · `stage-manifest.json` · `b-tree-before.json`/`b-tree-after.json`(B 전체 해시 맵, digest 동일) ·
`dest-tree-after.json` · `scene-check.json`(수정 씬 계약) · `installer-selftest.log`+`selftest.json`(26/26) ·
`netfail-install.log`+`netfail.json`(fail-closed+rollback) · `install.log`+`install.json`(INSTALL OK) ·
`validate-only.log`+`validate-only.json`(exit 0) · `launch.json`(기동 전체 상태) · `timeline.jsonl` ·
`presented-lines.txt` · `nr-lines.txt` · `misc-lines.txt` · `fault-scan.json` · `launcher.out.log` ·
`obs-log.txt` · `after.json`(post-run 해시·B 무접촉·ws 복원).

원본 런타임 로그(테스트 디렉터리): `dest/obs-portable/bin/64bit/{OptiScaler.log, dlss5-feed.log, OptiScaler/plugins/XeFGUnlock.log}`,
`dest/obs-portable/config/obs-studio/logs/2026-09-19 11-19-52.txt`.

---
**판정: PASS — FINAL 트리(launcher `9df6f49e` + scene `dbe2f857`)는 클린 설치·검증·1회 기동에서
XeFG rock 4x 1회 presented + NR 1회 성공, fault 0, graceful close, B/A 무접촉을 만족한다.**
