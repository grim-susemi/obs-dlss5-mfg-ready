# HANDOFF - FINAL 2..6 매트릭스 runtime 검증 완료 (owner-ready)

task st_01a0b5d6 · 2026-09-19 03:50~04:04 KST · **FINAL 후보(f103) 단일 시퀀스, count별 owned 1세션(2->3->4->5->6), 전부 PASS**
증적 루트: `C:/omo-research/obs-mfg-ready/evidence/final-2to6-matrix/`

## 0. 결과 요약 (Korean per-count)

| count | request([XeFG]InterpolationCount) | **actual presented** (FGHooks FGPresent, fgEnabled:1) | 표본 | ASI pacing | NR | close/restore | 판정 |
|---|---|---|---|---|---|---|---|
| 2x | 1 (INI 149ee1c8) | `presented:2` 2회 (03:54:36.850 / 03:55:06.793) | 30.0s | N/A (ASI는 2X 초과만 pacing; 카운터 미방출) | 1800 dispatches | exit 0 / 6488623d | **PASS** |
| 3x | 2 (INI 173514df) | `presented:3` 2회 (03:55:42.298 / 03:56:12.241) | 29.9s | `3X` 5회, 0 refused | 1800 | exit 0 / 6488623d | **PASS** |
| 4x | 3 (rock 6488623d, no-op) | `presented:4` 2회 (03:56:39.831 / 03:57:09.775) | 29.8s | `4X` 6회, 0 refused | 1800 | exit 0 / 6488623d | **PASS** |
| 5x | 4 (INI 2498e009) | `presented:5` 2회 (03:57:36.074 / 03:58:06.016) | 29.9s | `5X` 6회, 0 refused | 1800 | exit 0 / 6488623d | **PASS** |
| 6x | 5 (INI 663ae033) | `presented:6` 2회 (03:58:31.493 / 03:59:02.367) | 30.8s | `6X` 6회, 0 refused | 1800 | exit 0 / 6488623d | **PASS** |

각 행 공통: `XeFG_Dx12::Activate SetEnabled: true ... SUCCESS`, `Interpolation count changed -1 -> N-1`, clamp-warn 0,
`887A00xx`/`Device Remove/Reset`/`Couldn't create XeLL`/`EvaluateState !FGEnabled`/crash **0**, device-loss 0,
feed 1800 delivered + `shut down cleanly`, OBS leaks 0, `hashDiff {}`/`configKeyDiff {}`.
메뉴/캡만으로 PASS 아님 - 위 값은 전부 해당 세션 로그의 실제 present 라인.

- 6x 구분: 소스 ~54~60fps x6 = ~360fps 상당(pacing target 2.76ms/frame) vs 패널 2560x1440 **239Hz**
  (preflight videoControllers). 본 증거는 SDK가 소스프레임당 6프레임을 생성/스케줄했다는 실제 present 증거이며,
  360 distinct fps의 지속 표시를 주장하지 않음(패널 한계).
- 2x pacing N/A: ASI 시작 라인 `XeFG pacing: generated frames are paced above 2X`;
  2x는 pacing 카운터 미방출(설계). 3x+는 실카운터 0 refused로 확인.

## 1. save/restart/transition regression (regression/REGRESSION.md)

- **over-cap volatile live** (request 6 > cap 5): clamp WARN `setting to max: 5` 1회 + `changed -1 -> 5` + `presented:6`;
  세션 중/종료 후 INI 136d7bdd(요청 6 그대로) - **silent INI rewrite to cap 없음**, accepted는 5만(7X 위장 없음).
- **save/restart 지속성**: 요청 5로 run1 -> 편집 없이 run2 재시작: 둘 다 `changed -1 -> 5`, clamp-warn 0, `presented:6`;
  두 세션 `Config::SaveXeFG` 저장 라인 기록 + INI 663ae033 불변.
- **transition back**: 5 -> 3 patch가 rock과 byte-identical(6488623d), 세션 `changed -1 -> 3`/`presented:4`, 종료 후 rock 유지.
- `rejected setter` live 재현 불가(요청>max는 setter 전에 clamp; 요청 6 -> setter(5) success로 확인) - FINAL 소스
  unit test(`RunSetterRejectKeepsAcceptedStateAndSuccessAdvances`) PASS로 커버, `runtime cap volatile`은 unit+live 양쪽 확인.

## 2. 무결성 (final-state.json, frozenAllMatch=true)

- B core `winmm.dll` **f103e38a...** / launcher `ff3e8805...` / manifest rev5 `40fc7732...` / rock INI `6488623d...`(InterpolationCount=3)
  / XeFGUnlock.ini `185d1d94...`(cap5) / ASI `3337ea19...` / ws config `f335c8a9...`(server_enabled=false) / ObsProjector `edb80701...`
  / payloads(addon 1b4ba127, dlssnr e67dee20, dlss 3975567b, libxess_fg ec5e0c65) 전부 **FINAL 그대로**.
- NR10키(Enabled=true/Passes=auto/Intensity=2.0/TransferStrength=2.0/LocalStructure=auto/LocalTone=0.19/SkinToneEnabled=false/
  WhitePointScale=2.04/MaxRatio=1.5/WorkingScale=auto) + `[FrameGen] Enabled=true`, FGInput=Upscaler, FGOutput=XeFG 불변.
- **A**(obs-dlss5-feeder-fixture) ini `f66b2787...` 불변, A 무접촉/미기동. **B closed(obs64 0)**. 4475/4455 리스너 0.
- 매트릭스 중 crash 0 (최신 crash 파일은 01-34-19, 매트릭스 이전). baseline: launcher ValidateOnly exit 0,
  launcher regression all-pass, count unit test PASS (summary/baseline-regressions.json).

## 3. owner 확인 필요 (owner motion)

1. **시각 품질/실사용 판정**: 2x~6x 각 count의 실제 화면 품질(owner 육안) - 자동 수치로 대체 불가.
2. **메뉴 경로 실조작(잔여 st5bf UI QA)**: OptiScaler overlay MFG 콤보로 2X..6X 선택 -> Save Settings -> 재시작 시
   actual presented 확인, close/reopen 중 overlay 거동 - 본 런타임 작업은 메뉴 자동화 없이 INI 요청 경로+live presented로만 검증함.
3. 실사용 조합 선택(어느 count를 일상 사용할지) 후 plugin release PLAN 작성(본 call에서는 계획 없음).

## 4. 한계 / 정직 표기

- `count-2-attempt1-tooling/`은 도구(증적 경로/마일스톤 kind) 버그로 superseded. attempt1 세션 자체는 presented:2 + 정상 종료였고
  본 매트릭스 행은 fixed-tooling attempt2 증거를 사용. (attempt1은 삭제하지 않고 보존)
- 메뉴 "Save Settings" 버튼 자체는 미입력(no focus/foreground 원칙). 버튼 경로는 unit test + live 저장 경로 해시로만 커버.
- 2x pacing 카운터 없음은 실패가 아니라 ASI 설계(2X 초과 pacing).
- 재현/검증: 각 디렉터리의 RECEIPT.md/runtime.json/close.json/timeline.txt/extracted-summary.json + 원본 로그
  (`obs-portable/bin/64bit/{OptiScaler.log, dlss5-feed.log, OptiScaler/plugins/XeFGUnlock.log}`,
  `obs-portable/config/obs-studio/logs/2026-09-19 03-5x-xx.txt`). matrix-summary.json = 기계가독 표.
