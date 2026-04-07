#!/usr/bin/env python3
"""
MiSTer Subtitle Server
======================
- GET  /          → 폰 웹앱 (index.html) 서빙
- GET  /app.js    → 웹앱 JS 서빙
- POST /subtitle  → 번역 텍스트 수신 → MiSTer Unix 소켓 전달

MiSTer 시작 시 자동 실행 (/media/fat/linux/user-startup.sh 에 추가):
  python3 /media/fat/Scripts/subtitle_server.py &
"""

import socket
import os
import json
import mimetypes
from http.server import HTTPServer, BaseHTTPRequestHandler
from pathlib import Path

UNIX_SOCK = "/tmp/mister_subtitle.sock"
HTTP_PORT = 18765

# 스크립트 위치 기준으로 static 파일 경로 결정
# MiSTer 배포 시: /media/fat/Scripts/phone-app/
# 개발 시: ../phone-app/
_HERE = Path(__file__).parent
STATIC_DIR = _HERE / "phone-app"
if not STATIC_DIR.exists():
    STATIC_DIR = _HERE.parent / "phone-app"


def send_to_mister(text: str) -> bool:
    try:
        sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        sock.settimeout(2)
        sock.connect(UNIX_SOCK)
        sock.sendall(text.encode("utf-8"))
        sock.close()
        return True
    except Exception as e:
        print(f"[subtitle] MiSTer 소켓 전송 실패: {e}")
        return False


def serve_static(handler, rel_path: str):
    """STATIC_DIR 내 파일 서빙"""
    target = (STATIC_DIR / rel_path).resolve()
    # 경로 이탈 방지
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


class SubtitleHandler(BaseHTTPRequestHandler):

    def log_message(self, fmt, *args):
        print(f"[HTTP] {args[0]} {args[1]}")

    # ── GET: 정적 파일 서빙 ───────────────────────────────────────────────
    def do_GET(self):
        path = self.path.split("?")[0]
        if path == "/" or path == "/index.html":
            serve_static(self, "index.html")
        elif path in ("/app.js", "/manifest.json"):
            serve_static(self, path.lstrip("/"))
        else:
            self.send_response(404)
            self.end_headers()

    # ── OPTIONS: CORS preflight ──────────────────────────────────────────
    def do_OPTIONS(self):
        self.send_response(200)
        self._cors()
        self.end_headers()

    # ── POST /subtitle: 번역 텍스트 수신 ─────────────────────────────────
    def do_POST(self):
        if self.path != "/subtitle":
            self.send_response(404)
            self.end_headers()
            return

        length = int(self.headers.get("Content-Length", 0))
        body = self.rfile.read(length)

        try:
            data = json.loads(body)
            text = data.get("text", "").strip()
        except Exception:
            text = body.decode("utf-8", errors="replace").strip()

        if not text:
            self.send_response(400)
            self._cors()
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(b'{"error":"empty text"}')
            return

        print(f"[subtitle] 수신: {text}")
        ok = send_to_mister(text)

        self.send_response(200 if ok else 503)
        self._cors()
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        self.wfile.write(json.dumps({"ok": ok, "text": text}).encode())

    def _cors(self):
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")


def main():
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
    except Exception:
        ip = "?.?.?.?"

    print(f"\n=== MiSTer Subtitle Server ===")
    print(f"  폰 웹앱:  http://{ip}:{HTTP_PORT}/")
    print(f"  정적파일: {STATIC_DIR}")
    print(f"  소켓:     {UNIX_SOCK}")
    print(f"==============================\n")

    server = HTTPServer(("0.0.0.0", HTTP_PORT), SubtitleHandler)
    server.serve_forever()


if __name__ == "__main__":
    main()
