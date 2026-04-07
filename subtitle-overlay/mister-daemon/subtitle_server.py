#!/usr/bin/env python3
"""
MiSTer Subtitle Server
=====================
폰 웹앱에서 번역 텍스트를 HTTP로 받아
Main_MiSTer Unix 소켓으로 전달합니다.

실행:
  python3 subtitle_server.py

MiSTer 시작 시 자동 실행 (/media/fat/linux/user-startup.sh 에 추가):
  python3 /media/fat/Scripts/subtitle_server.py &
"""

import socket
import os
import json
import threading
from http.server import HTTPServer, BaseHTTPRequestHandler

UNIX_SOCK = "/tmp/mister_subtitle.sock"
HTTP_PORT = 18765  # 폰 웹앱이 이 포트로 전송


def send_to_mister(text: str) -> bool:
    """Main_MiSTer Unix 소켓으로 자막 텍스트 전송"""
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


class SubtitleHandler(BaseHTTPRequestHandler):

    def log_message(self, fmt, *args):
        # 접근 로그 간소화
        print(f"[HTTP] {args[0]} {args[1]}")

    def do_OPTIONS(self):
        # CORS preflight (폰 브라우저)
        self.send_response(200)
        self._cors()
        self.end_headers()

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
        self.send_header("Access-Control-Allow-Methods", "POST, OPTIONS")


def main():
    # MiSTer IP 안내
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
    except Exception:
        ip = "?.?.?.?"

    print(f"\n=== MiSTer Subtitle Server ===")
    print(f"  HTTP 포트: {HTTP_PORT}")
    print(f"  MiSTer IP: {ip}")
    print(f"  폰 웹앱 URL: http://{ip}:{HTTP_PORT}/")
    print(f"  자막 엔드포인트: POST http://{ip}:{HTTP_PORT}/subtitle")
    print(f"==============================\n")

    server = HTTPServer(("0.0.0.0", HTTP_PORT), SubtitleHandler)
    print(f"대기 중...")
    server.serve_forever()


if __name__ == "__main__":
    main()
