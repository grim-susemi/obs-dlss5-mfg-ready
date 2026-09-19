# RELEASE-NOTES-ko.md — obs-dlss5-mfg-ready pre-release (초안 → 발행용)

> 이 파일은 GitHub Release 본문으로 그대로 붙이는 발행용 문안이다. 상단 초안 문구("DRAFT. Don't publish")는 발행 승인("프리릴리즈 가자")으로 해소됐다.
> 에셋과 함께 게시되는 영수증 요약: `RELEASE-RECEIPT.md` (repo `docs/`).

# OBS DLSS5 MFG Ready (pre-release)

OBS 포터블 그대로 복사해서 실행. 검증된 해시와 롤백 포함. 이 저장소는 OptiScaler 포크가 아니라 **별도 릴리스 저장소**다. OptiScaler 소스는 링크로만 안내한다.

* 2x부터 6x까지 원클릭 선택. 메뉴에서 고르고 저장하면 재시작 후에도 유지
* 기본은 XeFG. 실측 통과한 안정 경로
* DLSS MFG는 4090 비공식 언락 후보. 실험용으로 별도 제공
* Nukem FSR 3.1 교체와 FFX 교체는 2x만 지원. 3x부터 6x는 미지원
* NR 유지. 매 카운트 1->1800 디스패치 확인
* ValidateOnly는 rock INI, dlssg 310.9.1, sl.*까지 확인. 0이 아니면 실행하지 말 것

## 설치 전 체크 (자주 나오는 실패 5종)

- NVIDIA App 오버라이드 끄기
- 백신 예외 등록
- 다른 로더, 오버레이 제거
- 메뉴 변경 후 저장하고 재시작
- 포터블에만 설치

## 설치 (3단계)

1. OBS를 닫는다
2. 패키지를 덮어 복사하고 `run-obs-mfg.ps1 -ValidateOnly`가 0으로 끝나는지 확인
3. `run-obs-mfg.cmd`로 바로 실행

### 원클릭 설치 (install-one-click)

패키지 루트에 `install-one-click.ps1` / `install-one-click.cmd` / `fetch-nvidia.ps1` / `SHA256SUMS.txt`가 함께 들어 있다. `install-one-click.cmd -DestRoot <설치 폴더>` 한 번으로 복사 → NVIDIA DLL fetch/검증 → ValidateOnly → 실패 시 롤백까지 자동이다.

**중요 — 기본 경로는 fail-closed로 멈춘다.** 아래 "BLOCKED" 항목의 `nvngx_dlssnr.dll` 공식 공개 엔드포인트가 확정되지 않아, 기본 실행은 다운로드 전에 의도적으로 중단된다(설치 전 상태로 롤백). NR DLL까지 자동 설치하려면 운영자가 확인한 엔드포인트를 명시해야 한다:

```
install-one-click.cmd -DestRoot <설치 폴더> -AllowUnconfirmedSource -UnconfirmedSourceUrl <확인한-공식-URL>
```

해시 핀이 신뢰 기준(trust anchor)이라 URL이 틀리거나 바뀌면 다운로드된 바이트가 거부되고 설치가 실패한다. 수동 DLL 복사 경로는 제공하지 않는다.

## 지원과 한계 (정직 표기)

| 항목 | 상태 |
|---|---|
| RTX 4090 | 실측 검증 (2x~6x 매트릭스, NR 1->1800, 저장/재시작 회귀) |
| 20/30/50 시리즈 | 미검증, 피드백 환영 |
| 240Hz 패널에서 6x | SDK가 360/s 생성, 스케줄까지가 PASS. 패널이 360장을 다 보여준다는 뜻이 아님 |
| DLSS 3x~6x 화질 | 3x~6x 육안 승인 대기. 캐릭터 가장자리 노이즈 관찰 기록 있음 |
| MFG 경로 | 비공식 언락 표기 유지. 공식 지원처럼 적지 않음 |
| Save Settings 오버레이 버튼 | 파일/재시작 지속은 증명, 버튼 경로 수동 확인 남음 |

> [!CAUTION]
> OBS가 켜진 채로 INI를 고치지 말 것. 종료 시 덮어쓴다. Protected A는 손대지 않는다.

## 롤백

롤백은 OBS를 닫고 preimage 복사 후 재해시, ValidateOnly 재확인.

| 복원 대상 | 복원 값 | 기대 SHA-256 |
|---|---|---|
| `run-obs-mfg.ps1` | f103-era launcher preimage | `ff3e88052efcfa4f82b5efc3a1ad0cebc570aeac4a29c844ae911dccf81deae6` |
| `obs-portable/bin/64bit/winmm.dll` | f103 preimage | `f103e38a16f126c4c1b68f2dc9d90ee20f73ad78866b01081f2f035d6b26762d` |
| `obs-portable/bin/64bit/OptiScaler.ini` | rock preimage | `6488623d4e9591b7191139097bcf9810e84d238e45c7aab9d8ce16b4655c3db6` |
| `HASHES.json` (stage authority rev6, 리포 외부) | rev5 preimage | `40fc773235d875f54d78437a2644cee4d68e611f2b9acacccdd65579539861dc` |

f103/XeFG era로 완전히 되돌리려면 `winmm.dll`과 launcher를 위 preimage로 복원한다. 이번 배포본 core는 MFG era `4b2997b1` 하나만 포함한다(변형 혼용 없음). 롤백 후 각 대상 파일을 `certutil -hashfile "<path>" SHA256`으로 재해시하고 `run-obs-mfg.ps1 -ValidateOnly`로 확인한다.

## 발행물 해시 (SHA-256)

릴리스 에셋 `obs-dlss5-mfg-ready-prerelease.zip`:

| 파일 | SHA-256 | 바이트 |
|---|---|---|
| `obs-dlss5-mfg-ready-prerelease.zip` | `f4001787357f4acda20b15b38c3ec632a605066e0383ae348d4d8a1e85fc2325` | `316,448,946` |

zip 안의 핵심 파일 (zip에서 풀린 그대로의 해시):

| 패키지 경로 | SHA-256 | 바이트 |
|---|---|---|
| `run-obs-mfg.ps1` | `9df6f49eaf621ffa772cb73fb10b728451961cf6ca013aa1145f2c44aadaf8ee` | 9668 |
| `run-obs-mfg.cmd` | `59ba5e2a78b0d7321c16cf0ef779b8b000ddc7b2868b15dc5e37c03bce6180df` | 184 |
| `obs-portable/bin/64bit/winmm.dll` | `4b2997b1ed9f6cc98befafc740f197916f6296672263fbe189bd27960c8aeba8` | 26,226,176 |
| `obs-portable/bin/64bit/OptiScaler.ini` | `6488623d4e9591b7191139097bcf9810e84d238e45c7aab9d8ce16b4655c3db6` | — |
| `obs-portable/bin/64bit/ObsProjector.ini` | `edb807015d5ec1c22c024cdbe20ae5c5d934ebf21bb5ec903c9b6e419d39dc05` | — |
| `obs-portable/bin/64bit/dlss5-feed.addon64` | `1b4ba127370c4609ace1183e8dbd8af4f789e02cc07e6b8cef456c60802ed0ee` | — |
| `obs-portable/bin/64bit/OptiScaler/plugins/XeFGUnlock.asi` | `3337ea197720d573aacf920231ed515d08324dba67d9966be32e1a2584cdbdb8` | — |
| `obs-portable/bin/64bit/OptiScaler/plugins/XeFGUnlock.ini` | `185d1d94e6da082c63339f4452d23df81a2ec70662e30fc7cf5c943f1231bc54` | — |
| `obs-portable/config/obs-studio/basic/scenes/제목_없음.json` | `dbe2f857cf82ac293ef1805ca05e38e7a4e82fc4948a1688a17c57a9504a2dc7` | — |
| `obs-portable/config/obs-studio/plugin_config/obs-websocket/config.json` | `f335c8a9bdd7d442b66c26da5938280fd424969968573cfb7bbcbdf79f46a2e2` | — |

검증 명령: `certutil -hashfile "<path>" SHA256` (PowerShell: `Get-FileHash <path> -Algorithm SHA256`).

## 패키지에서 제외된 것 / NVIDIA DLL (재배포 금지)

아래 3개 DLL은 재배포 금지라서 zip에 들어 있지 않다. 오직 `fetch-nvidia.ps1`의 해시 검증 fetch로만 설치된다.

| 대상 경로 | SHA-256 | 버전 | 소스 상태 |
|---|---|---|---|
| `obs-portable/bin/64bit/nvngx_dlss.dll` | `3975567b8943c53acce397f2b72380092f84f162d00b0d2c7d08a1025c563983` | 310.9.1 | NVIDIA DLSS 공식 릴리스 자산 (문서화된 엔드포인트, 해시 핀) |
| `obs-portable/bin/64bit/OptiScaler/streamline/nvngx_dlssg.dll` | `ff6e90eb78b827927dff5b4ecc6b1c870c2e9bca29ed9f48c7d348cc9e170b82` | 310.9.1 | NVIDIA Streamline 공식 릴리스 자산 (문서화된 엔드포인트, 해시 핀, 단일 사본) |
| `obs-portable/bin/64bit/nvngx_dlssnr.dll` | `e67dee209320cdafe0e93e45675d7aa34323a53acc57a72b2e40a181581c989a` | 310.8 | **BLOCKED — 공식 공개 엔드포인트 미확정** |

`dlssnr`은 공식 공개 엔드포인트가 확인될 때까지 기본 설치가 fail-closed로 중단된다. 임의 URL이나 추측 DLL을 넣지 말 것.

## 검증 영수증 (이 패키지로 실행한 검사)

* 패키지 구성: 상위 소스 트리(FINAL)에서 **2,161 파일 / 660,462,491 B** 로지컬 스테이징, 제외 51건/237,375,266 B(위 NVIDIA 3종 + 런타임 로그/크래시/백업). 로그·크래시 덤프는 배포본에 들어가지 않는다.
* installer selftest: `TOTAL: 26 passed, 0 failed` (exit 0) — 이 패키지의 `tests/Invoke-Tests.ps1`
* clean-install 드레스 리허설(테스트 폴더 한정, 임시 오프라인 소스): copy 2161 → fetch 3/3 verified(해시 일치) → 내부 ValidateOnly exit 0 → 별도 ValidateOnly exit 0 (`Validated: 2..6x unlock cap, runtime pins, local OBS policy and preset chain; no process started.`)
* 기본(네트워크) 경로: **exit 1 fail-closed** — `BLOCKED: obs-portable/bin/64bit/nvngx_dlssnr.dll v310.8 has no confirmed official source. Nothing was downloaded.` → 롤백으로 설치 전 상태 복원 확인.
* 본 배포는 위 검사들 외에 실제 기동/렌더를 수행하지 않았다. 런타임 매트릭스는 아래 출처 영수증에 있다.

### 실측 근거 (research repo 영수증)

* XeFG 2x~6x: `presented:2`~`presented:6` 실측, ASI pacing, NR `1->1800`, 저장/재시작 회귀
* DLSS 경로 2x~6x: `numFramesToGenerate=1..5`, `SetTagForFrame` 진행, FGPresent/Reflex 흐름 (XeFG식 `presented:N` 문자열 없음)
* 1회 클린 설치 기동: 빈 트리 설치 → `presented:4 fgEnabled:1` 1회 + `DLSS-NR evaluate succeeded` 1회 → 정상 종료, crash/device fault 0
* Nukem/FFX 교체 경로: 2x PASS, 3x~6x Unsupported

## 한계와 남은 확인 (정직 표기)

* 공식 엔드포인트 2종은 문서화된 URL이지만 **이 배포 작업에서 네트워크 fetch로 실검증하지 않았다.** 첫 실제 실행이 엔드포인트 확인이 되며, 틀렸으면 해시 핀 때문에 fail-closed로 멈춘다(잘못된 바이트 설치 없음).
* `nvngx_dlssnr` 310.8은 공개 엔드포인트 미확정 → BLOCKED. 확인 후 `Confirmed=$true`로 전환.
* 20/30/50 시리즈 미검증(240Hz급 패널 단일 구성). 240Hz vs 360 cadence 주장 없음.
* DLSS 3x~6x 화질/고스팅 육안 승인 대기.
* Save Settings 오버레이 버튼 경로 수동 QA 남음.
* 이 포크/패키지와 OptiScaler 업스트림은 별개다. 소스/이슈는 업스트림에서 확인.

## Protected A / 비파괴 원칙

이 배포 작업에서 보호 대상 A(`obs-dlss5-feeder-fixture`)와 기존 연구 트리는 변경하지 않았다. 발행물은 별도 저장소와 릴리스 에셋으로만 존재하며, 시스템/드라이버/레지스트리 전역 변경은 없다. 설치 스크립트는 지정한 `DestRoot` 밖에 쓰지 않는다.
