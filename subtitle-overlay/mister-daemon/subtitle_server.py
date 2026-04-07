#!/usr/bin/env python3
"""
MiSTer Subtitle Server
======================
- GET  /              → 폰 웹앱 서빙
- GET  /app.js        → 웹앱 JS 서빙
- POST /translate     → 이미지(base64) 수신 → Claude API → 번역 → OSD + 응답
- GET  /config        → 현재 설정 확인
- POST /config        → API Key 저장

MiSTer 시작 시 자동 실행 (/media/fat/linux/user-startup.sh 에 추가):
  python3 /media/fat/Scripts/subtitle_server.py &
"""

import socket
import os
import json
import mimetypes
import urllib.request
import urllib.error
from http.server import HTTPServer, BaseHTTPRequestHandler
from pathlib import Path

UNIX_SOCK   = "/tmp/mister_subtitle.sock"
HTTP_PORT   = 18765
CONFIG_FILE = Path("/media/fat/Scripts/subtitle_config.json")

_HERE      = Path(__file__).parent
STATIC_DIR = _HERE / "phone-app"
if not STATIC_DIR.exists():
    STATIC_DIR = _HERE.parent / "phone-app"


# ── 설정 로드/저장 ────────────────────────────────────────────────────────────

def load_config() -> dict:
    if CONFIG_FILE.exists():
        try:
            return json.loads(CONFIG_FILE.read_text())
        except Exception:
            pass
    return {"api_key": ""}

def save_config(cfg: dict):
    CONFIG_FILE.parent.mkdir(parents=True, exist_ok=True)
    CONFIG_FILE.write_text(json.dumps(cfg, indent=2))


# ── MiSTer OSD 소켓 전송 ──────────────────────────────────────────────────────

def send_to_osd(text: str) -> bool:
    try:
        sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        sock.settimeout(2)
        sock.connect(UNIX_SOCK)
        sock.sendall(text.encode("utf-8"))
        sock.close()
        return True
    except Exception as e:
        print(f"[osd] 소켓 전송 실패: {e}")
        return False


# ── Claude API 호출 (서버사이드) ──────────────────────────────────────────────

CLAUDE_PROMPT = """이 이미지는 레트로 게임 화면입니다.
화면에서 일본어 텍스트(대화, 메뉴, 자막 등)를 찾아 한국어로 번역하세요.

규칙:
1. 일본어 텍스트가 없으면 {"found":false} 만 반환
2. 있으면 {"found":true,"original":"원문","translation":"한국어 번역"} 반환
3. 캐릭터 이름은 음역 유지 (예: 루피, 나루토)
4. JSON만 반환, 설명 없음"""

def call_claude(api_key: str, image_b64: str) -> dict:
    payload = json.dumps({
        "model": "claude-haiku-4-5-20251001",
        "max_tokens": 256,
        "messages": [{
            "role": "user",
            "content": [
                {"type": "image", "source": {
                    "type": "base64",
                    "media_type": "image/jpeg",
                    "data": image_b64
                }},
                {"type": "text", "text": CLAUDE_PROMPT},
            ]
        }]
    }).encode("utf-8")

    req = urllib.request.Request(
        "https://api.anthropic.com/v1/messages",
        data=payload,
        headers={
            "Content-Type":      "application/json",
            "x-api-key":         api_key,
            "anthropic-version": "2023-06-01",
        },
        method="POST",
    )

    with urllib.request.urlopen(req, timeout=15) as resp:
        body = json.loads(resp.read())

    text = body["content"][0]["text"].strip()
    match_start = text.find("{")
    match_end   = text.rfind("}") + 1
    if match_start == -1:
        return {"found": False}
    return json.loads(text[match_start:match_end])


# ── 정적 파일 서빙 ────────────────────────────────────────────────────────────

def serve_static(handler, rel_path: str):
    target = (STATIC_DIR / rel_path).resolve()
    try:
        target.relative_to(STATIC_DIR.resolve())
    except ValueError:
        handler.send_response(403)
        handler.end_headers()
        return

    if not target.exists() or not target.is_file():
        handler.send_response(404)
        handler.end_headers()
        handler.wfile.write(b"Not found")
        return

    mime, _ = mimetypes.guess_type(str(target))
    data = target.read_bytes()
    handler.send_response(200)
    handler.send_header("Content-Type", mime or "application/octet-stream")
    handler.send_header("Content-Length", str(len(data)))
    handler.send_header("Cache-Control", "no-cache")
    handler.end_headers()
    handler.wfile.write(data)


# ── HTTP 핸들러 ───────────────────────────────────────────────────────────────

class SubtitleHandler(BaseHTTPRequestHandler):

    def log_message(self, fmt, *args):
        print(f"[HTTP] {args[0]} {args[1]}")

    def do_GET(self):
        path = self.path.split("?")[0]
        if path in ("/", "/index.html"):
            serve_static(self, "index.html")
        elif path in ("/app.js", "/manifest.json"):
            serve_static(self, path.lstrip("/"))
        elif path == "/config":
            cfg = load_config()
            # API Key는 앞 8자만 노출
            safe = {**cfg, "api_key": cfg["api_key"][:8] + "..." if cfg["api_key"] else ""}
            self._json(200, safe)
        else:
            self.send_response(404)
            self.end_headers()

    def do_OPTIONS(self):
        self.send_response(200)
        self._cors()
        self.end_headers()

    def do_POST(self):
        length = int(self.headers.get("Content-Length", 0))
        body   = self.rfile.read(length)

        try:
            data = json.loads(body)
        except Exception:
            self._json(400, {"error": "invalid json"})
            return

        # ── POST /config: API Key 저장 ──
        if self.path == "/config":
            api_key = data.get("api_key", "").strip()
            if not api_key:
                self._json(400, {"error": "api_key required"})
                return
            cfg = load_config()
            cfg["api_key"] = api_key
            save_config(cfg)
            print(f"[config] API Key 저장됨")
            self._json(200, {"ok": True})
            return

        # ── POST /translate: 이미지 번역 + OSD ──
        if self.path == "/translate":
            image_b64 = data.get("image", "").strip()
            if not image_b64:
                self._json(400, {"error": "image required"})
                return

            cfg     = load_config()
            api_key = cfg.get("api_key", "")
            if not api_key:
                self._json(503, {"error": "API Key 미설정 — 설정 탭에서 입력하세요"})
                return

            try:
                result = call_claude(api_key, image_b64)
            except urllib.error.HTTPError as e:
                err = e.read().decode("utf-8", errors="replace")
                print(f"[claude] API 오류 {e.code}: {err}")
                self._json(502, {"error": f"Claude API {e.code}"})
                return
            except Exception as e:
                print(f"[claude] 오류: {e}")
                self._json(502, {"error": str(e)})
                return

            if result.get("found"):
                translation = result.get("translation", "")
                send_to_osd(translation)
                print(f"[subtitle] {result.get('original','')} → {translation}")
                self._json(200, result)
            else:
                self._json(200, {"found": False})
            return

        self.send_response(404)
        self.end_headers()

    def _json(self, code: int, obj: dict):
        body = json.dumps(obj, ensure_ascii=False).encode("utf-8")
        self.send_response(code)
        self._cors()
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def _cors(self):
        self.send_header("Access-Control-Allow-Origin",  "*")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")


# ── 메인 ─────────────────────────────────────────────────────────────────────

def main():
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
    except Exception:
        ip = "?.?.?.?"

    cfg = load_config()
    key_status = "설정됨" if cfg.get("api_key") else "미설정 (웹앱 설정 탭에서 입력)"

    print(f"\n=== MiSTer Subtitle Server ===")
    print(f"  폰 웹앱 : http://{ip}:{HTTP_PORT}/")
    print(f"  API Key : {key_status}")
    print(f"  정적파일: {STATIC_DIR}")
    print(f"==============================\n")

    HTTPServer(("0.0.0.0", HTTP_PORT), SubtitleHandler).serve_forever()


if __name__ == "__main__":
    main()
