# MiSTer 실시간 AI 자막 번역

게임 화면의 일본어 텍스트를 폰 카메라로 인식해 한국어 자막으로 OSD에 표시합니다.

## 구조

```
[폰 브라우저]                [MiSTer]
카메라 → Claude API       subtitle_server.py (HTTP :18765)
번역 결과 → HTTP POST  →       ↓
                         /tmp/mister_subtitle.sock
                               ↓
                         Main_MiSTer subtitle_poll()
                               ↓
                         Info() → OSD 자막 5초 표시
```

## 설치

### 1. MiSTer 빌드

`subtitle.cpp` / `subtitle.h` 가 Main_MiSTer에 포함됩니다.
기존 빌드 방식 그대로 빌드하세요.

### 2. Python 데몬 설치

MiSTer SD카드에 복사:
```
/media/fat/Scripts/subtitle_server.py
```

부팅 시 자동 실행 (`/media/fat/linux/user-startup.sh`에 추가):
```bash
python3 /media/fat/Scripts/subtitle_server.py &
```

### 3. 폰 웹앱

`phone-app/` 폴더를 웹서버로 서빙하거나,
MiSTer 데몬에 정적 파일 서빙 기능 추가 예정.

또는 같은 WiFi 환경에서 다른 PC에서 서빙:
```bash
cd phone-app && python3 -m http.server 8080
```
→ 폰에서 `http://[PC-IP]:8080` 접속

## 사용법

1. MiSTer와 폰이 같은 WiFi
2. 폰 브라우저에서 웹앱 접속
3. MiSTer IP, Anthropic API Key 입력
4. ▶ 시작 → 카메라를 TV 화면에 향하기
5. 일본어 감지 시 자동으로 MiSTer OSD에 한국어 자막 표시

## 비용

- Claude Haiku 기준 프레임당 약 $0.001~0.003
- 1.5초 간격, 1시간 플레이 ≈ 약 $7~10
