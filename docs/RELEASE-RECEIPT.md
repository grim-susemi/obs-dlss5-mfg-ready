# RELEASE-RECEIPT — obs-dlss5-mfg-ready pre-release

발행: 2026-09-19 11:30 KST · task st_01a0b77e

## 패키지

* zip: `obs-dlss5-mfg-ready-prerelease.zip`
* sha256: `f4001787357f4acda20b15b38c3ec632a605066e0383ae348d4d8a1e85fc2325`
* bytes: 316,448,946
* entries: 2161
* 스테이징: 2161 파일 / 660,462,491 B (상위 소스 FINAL 트리에서 재구성)
* 제외: 51건 / 237,375,266 B
  * auto-fetch NVIDIA 3종 (재배포 금지): `nvngx_dlss.dll` 58,956,912 B / `nvngx_dlssnr.dll` 165,840,496 B / `streamline/nvngx_dlssg.dll` 7,460,976 B
  * 런타임 로그/크래시 덤프/백업 48건

## 실행한 검증 (이 패키지)

| 단계 | 명령 | 결과 |
|---|---|---|
| installer selftest | `package/tests/Invoke-Tests.ps1` | TOTAL: 26 passed, 0 failed, exit 0 |
| clean-install(오프라인 소스) | `install-one-click.ps1 -OfflineSourceDir ... -AllowUnconfirmedSource` | exit 0 — copy 2161, fetch 3/3 hash-verified, ValidateOnly exit 0 |
| 별도 ValidateOnly | `test-dest/run-obs-mfg.ps1 -ValidateOnly` | exit 0 — `Validated: 2..6x unlock cap, runtime pins, local OBS policy and preset chain; no process started.` |
| 기본(네트워크) 설치 | `install-one-click.ps1` | exit 1 fail-closed — `BLOCKED: .../nvngx_dlssnr.dll v310.8 ... Nothing was downloaded.` → 롤백, dest 파일 0 |

## 핵심 해시 (zip 내부)

| 패키지 경로 | SHA-256 |
|---|---|
| `run-obs-mfg.ps1` | `9df6f49eaf621ffa772cb73fb10b728451961cf6ca013aa1145f2c44aadaf8ee` |
| `run-obs-mfg.cmd` | `59ba5e2a78b0d7321c16cf0ef779b8b000ddc7b2868b15dc5e37c03bce6180df` |
| `install-one-click.ps1` | `e05aa35f976c9d376f1686f263664422c716b7547bbd0cacc124b0166f8c883b` |
| `fetch-nvidia.ps1` | `57b1bf3d4c2100225e8b1b0165356c6481b9990578e6dd106b3b5361b30c9fb2` |
| `SHA256SUMS.txt` | `e7e68c26b39cfeb1094688ceb4a5832d062262e9fcb5d2ed47607d77a7f113ef` |
| `tests/Invoke-Tests.ps1` | `3e38596439996cd8b508334899b8bc2b422112bbbc8c86df39f0be96e2174902` |

## 업로드 후 검증 (에셋 재다운로드)

이 영수증의 아래 `## 업로드 검증` 절은 릴리스 업로드 후 실제 에셋을 다시 받아 계산한 해시로 채운다.

## 업로드 검증 (에셋 재다운로드, 2026-09-19 11:32 KST)

* 릴리스 URL: https://github.com/grim-susemi/obs-dlss5-mfg-ready/releases/tag/v0.9.0-prerelease
* tag: `v0.9.0-prerelease` · prerelease: **True** · latest: **None**
* 재다운로드한 `obs-dlss5-mfg-ready-prerelease.zip`:
  * sha256: `f4001787357f4acda20b15b38c3ec632a605066e0383ae348d4d8a1e85fc2325`
  * bytes: 316,448,946
  * 로컬 빌드와 일치: **True**
* 에셋 목록: `obs-dlss5-mfg-ready-prerelease.zip` (316,448,946 B, sha256 `f4001787357f4acda20b15b38c3ec632a605066e0383ae348d4d8a1e85fc2325`)
