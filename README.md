# Main_MiSTer 한글 OSD 빌드 (Korean OSD Fork)

> **이 저장소는 [MiSTer-devel/Main_MiSTer](https://github.com/MiSTer-devel/Main_MiSTer)의 한글 패치 포크입니다.**
> 공식 upstream 업데이트가 있을 때마다 자동으로 빌드되어 릴리즈에 업로드됩니다.

---

## 한글 패치 내용

- **OSD 한글 파일명 표시** — 게임 목록에서 한글 파일명 깨짐 없이 표시
- **메뉴 한국어 로컬라이제이션** — OSD 메뉴 한국어 지원
- **Galmuri8 비트맵 폰트** — MiSTer OSD에 최적화된 한글 픽셀 폰트 적용

---

## 설치 방법

### 방법 1 — 자동 업데이트 스크립트 (권장)

1. [`Scripts/korean_update.sh`](Scripts/korean_update.sh) 파일을 SD카드의 `/media/fat/Scripts/` 폴더에 복사
2. MiSTer OSD → **Scripts** → `korean_update.sh` 실행
3. 아래와 같이 단계별로 진행 상황이 표시됩니다

```
=====================================
  MiSTer Korean OSD Update Script
=====================================

[1] Checking internet connection...
    OK Connected.
[2] Fetching latest release info from GitHub...
    OK Latest: korean-final-260405 (2026-04-05)
[3] Checking installed version...
    OK Installed: 2026-04-04 02:35
    New version available!
[4] Backing up current binary...
    OK Saved to: /media/fat/MiSTer_Backups/MiSTer_20260406_103000
[5] Downloading new binary...
    ################################ 100.0%
    OK Downloaded (1094 KB).
[6] Installing...
    OK Installed to: /media/fat/MiSTer

=====================================
  Update complete!
  Version: korean-final-260405
=====================================

Rebooting MiSTer in 3 seconds...
```

### 방법 2 — 수동 설치

1. [Releases](https://github.com/devilcg/Main_MiSTer/releases/latest) 에서 최신 `MiSTer` 파일 다운로드
2. SD카드 루트(`/media/fat/MiSTer`)에 복사하여 덮어쓰기
3. MiSTer 재시작

---

## 자동 빌드

GitHub Actions가 **매일 00:00 KST**에 upstream 변경을 감지합니다.

| 상태 | 설명 |
|------|------|
| 새 upstream 커밋 있음 | 한글 패치 rebase → 빌드 → 릴리즈 자동 생성 |
| 변경 없음 | 스킵 |
| rebase 충돌 | GitHub 이슈 자동 생성으로 알림 |

[![Korean OSD Auto Build](https://github.com/devilcg/Main_MiSTer/actions/workflows/korean-build.yml/badge.svg)](https://github.com/devilcg/Main_MiSTer/actions/workflows/korean-build.yml)

---

## 빌드 환경

- 기반: `MiSTer-devel/Main_MiSTer` 공식 upstream
- 컴파일러: `arm-none-linux-gnueabihf-gcc` 10.2
- 빌드: GitHub Actions (ubuntu-latest)

---

## 원본 저장소

This repo is a Korean-localized fork of the official MiSTer main binary.
For the original repository, wiki, and documentation:

- **원본**: [MiSTer-devel/Main_MiSTer](https://github.com/MiSTer-devel/Main_MiSTer)
- **위키**: [MiSTer Wiki](https://github.com/MiSTer-devel/Wiki_MiSTer/wiki)
- **컴파일 가이드**: [MiSTer Compile Guide](https://mister-devel.github.io/MkDocs_MiSTer/developer/mistercompile/#general-prerequisites-for-arm-cross-compiling)
