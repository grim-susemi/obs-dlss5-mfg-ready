# obs-dlss5-mfg-ready

OBS 포터블용 **DLSS5 / XeFG MFG pre-release** 배포 저장소.

* 이 저장소는 [OptiScaler-Susemi](https://github.com/grim-susemi/OptiScaler-Susemi) **포크가 아니다.** OptiScaler 소스는 링크로만 안내한다.
* 바이너리 배포는 [Releases](../../releases) 에셋으로만 한다. 번들 페이로드는 git 히스토리에 넣지 않는다.
* 이 저장소가 답하는 것은 하나다: **어떤 바이트를 테스트했고, 무엇이 통과했고, 어떻게 롤백하는가.**

## 다운로드

1. [Releases](../../releases) 에서 `obs-dlss5-mfg-ready-prerelease.zip` (약 302 MB) 를 받는다.
2. OBS를 닫는다.
3. zip을 풀어 원하는 설치 폴더에 둔다.
4. 설치 폴더에서 `run-obs-mfg.ps1 -ValidateOnly` 가 exit 0 인지 확인한 뒤 `run-obs-mfg.cmd` 로 실행한다.

원클릭 설치를 쓰려면 같은 폴더에서:

```
install-one-click.cmd -DestRoot <설치 폴더>
```

기본 경로는 `nvngx_dlssnr.dll` (310.8) 공식 공개 엔드포인트 미확정으로 **fail-closed 중단**된다. 자세한 내용과 옵션은 [docs/RELEASE-NOTES-ko.md](docs/RELEASE-NOTES-ko.md) 의 "설치 (3단계)" / "패키지에서 제외된 것" 을 참고한다.

## 저장소 내용

| 경로 | 설명 |
|---|---|
| `docs/RELEASE-NOTES-ko.md` | 릴리스 노트 전문 (지원/한계/롤백/해시/검증) |
| `docs/RELEASE-RECEIPT.md` | 이 배포의 스테이징·설치·검증 영수증 |
| `docs/evidence/` | 연구 트리에서 복사한 근거 영수증 (clean-install, 2x~6x 매트릭스, 설치/롤백 문서) |
| `install-one-click.ps1` / `.cmd` | 복사 → NVIDIA fetch/검증 → ValidateOnly → 실패 시 롤백 설치기 |
| `fetch-nvidia.ps1` | 재배포 금지 NVIDIA DLL 해시 검증 fetch (fail-closed) |
| `SHA256SUMS.txt` | auto-fetch 3종의 기대 해시 (신뢰 기준) |
| `run-obs-mfg.ps1` / `.cmd` | 패키지 launcher (동일 해시 사본, 참조용) |

## 검증 핵심 (요약)

* 패키지 구성: **2,161 파일 / 660,462,491 B**, 제외 51건 (NVIDIA DLL 3종 + 런타임 로그/크래시/백업 237,375,266 B)
* installer selftest: `TOTAL: 26 passed, 0 failed`
* clean-install 드레스 리허설: fetch 3/3 해시 일치, ValidateOnly exit 0
* 기본 네트워크 설치: `BLOCKED` fail-closed (다운로드 전 중단) + 롤백 확인
* RTX 4090 실측 매트릭스 2x~6x / NR `1->1800` / 저장·재시작 회귀는 `docs/evidence/` 참조

## 한계 (정직 표기)

* RTX 4090 검증. 20/30/50 시리즈는 **미검증**.
* 검증 패널은 2560x1440 239Hz(240Hz급). 6x의 "360/s" 는 SDK 생성/스케줄 기준이며 360Hz 표시 주장이 아니다.
* DLSS MFG 경로는 **비공식 언락 후보**다. 공식 Blackwell 지원으로 표기하지 않는다.
* `nvngx_dlssnr.dll` (310.8) 은 공식 공개 엔드포인트 미확정으로 **BLOCKED**.
* 공식 엔드포인트 2종은 문서화된 URL이며, 이번 배포 작업에서 네트워크 실검증은 하지 않았다(첫 실행이 엔드포인트 확인, hash pin 으로 fail-closed).

전체 문안은 [docs/RELEASE-NOTES-ko.md](docs/RELEASE-NOTES-ko.md).
