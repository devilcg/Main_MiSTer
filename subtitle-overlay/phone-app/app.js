'use strict';

// ── 상태 ────────────────────────────────────────────────────────────────────
let stream      = null;
let captureLoop = null;
let lastText    = '';
let shotCount   = 0;
let sentCount   = 0;

// ── DOM ─────────────────────────────────────────────────────────────────────
const video      = document.getElementById('video');
const canvas     = document.getElementById('canvas');
const ctx        = canvas.getContext('2d');
const elTrans    = document.getElementById('translation');
const elOrig     = document.getElementById('original');
const elStatus   = document.getElementById('status');
const elTimer    = document.getElementById('timerLabel');
const elStart    = document.getElementById('btnStart');
const elStop     = document.getElementById('btnStop');

// ── 설정 로드/저장 ─────────────────────────────────────────────────────────
function loadSettings() {
  document.getElementById('misterIp').value = localStorage.getItem('misterIp') || '';
  document.getElementById('apiKey').value   = localStorage.getItem('apiKey')   || '';
}
function saveSettings() {
  localStorage.setItem('misterIp', document.getElementById('misterIp').value.trim());
  localStorage.setItem('apiKey',   document.getElementById('apiKey').value.trim());
}
loadSettings();

// ── 카메라 시작 ─────────────────────────────────────────────────────────────
async function startCamera() {
  try {
    stream = await navigator.mediaDevices.getUserMedia({
      video: { facingMode: 'environment', width: { ideal: 1280 }, height: { ideal: 720 } },
      audio: false,
    });
    video.srcObject = stream;
    return true;
  } catch (e) {
    setStatus('카메라 권한이 필요합니다: ' + e.message, 'err');
    return false;
  }
}

// ── 프레임 캡처 → base64 ────────────────────────────────────────────────────
function captureFrame() {
  const w = video.videoWidth  || 1280;
  const h = video.videoHeight || 720;
  canvas.width  = Math.min(w, 960);   // 너무 크면 API 비용 증가
  canvas.height = Math.round(h * (canvas.width / w));
  ctx.drawImage(video, 0, 0, canvas.width, canvas.height);
  return canvas.toDataURL('image/jpeg', 0.85).split(',')[1]; // base64 only
}

// ── Claude Vision API 호출 ──────────────────────────────────────────────────
async function translateFrame(base64) {
  const apiKey = document.getElementById('apiKey').value.trim();
  if (!apiKey) throw new Error('API Key 없음');

  const prompt = `이 이미지는 레트로 게임 화면입니다.
화면에서 일본어 텍스트(대화, 메뉴, 자막 등)를 찾아 한국어로 번역하세요.

규칙:
1. 일본어 텍스트가 없으면 반드시 {"found":false} 만 반환
2. 있으면 {"found":true,"original":"원문","translation":"한국어 번역"} 반환
3. 캐릭터 이름은 음역 유지 (예: 루피, 나루토)
4. JSON만 반환, 설명 없음`;

  const res = await fetch('https://api.anthropic.com/v1/messages', {
    method: 'POST',
    headers: {
      'Content-Type':      'application/json',
      'x-api-key':         apiKey,
      'anthropic-version': '2023-06-01',
    },
    body: JSON.stringify({
      model: 'claude-haiku-4-5-20251001',
      max_tokens: 256,
      messages: [{
        role: 'user',
        content: [
          { type: 'image', source: { type: 'base64', media_type: 'image/jpeg', data: base64 } },
          { type: 'text',  text: prompt },
        ],
      }],
    }),
  });

  if (!res.ok) {
    const err = await res.text();
    throw new Error(`Claude API ${res.status}: ${err}`);
  }

  const data = await res.json();
  const text = data.content?.[0]?.text || '';

  // JSON 파싱
  const match = text.match(/\{[\s\S]*\}/);
  if (!match) throw new Error('응답 파싱 실패: ' + text);
  return JSON.parse(match[0]);
}

// ── MiSTer로 자막 전송 ──────────────────────────────────────────────────────
async function sendToMiSTer(text) {
  const ip = document.getElementById('misterIp').value.trim();
  if (!ip) return false;

  try {
    const res = await fetch(`http://${ip}:18765/subtitle`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ text }),
    });
    return res.ok;
  } catch (e) {
    console.warn('[send] MiSTer 전송 실패:', e.message);
    return false;
  }
}

// ── 한 사이클 처리 ──────────────────────────────────────────────────────────
async function processCycle() {
  shotCount++;
  elTimer.textContent = `${shotCount}컷 / ${sentCount}전송`;

  let base64;
  try {
    base64 = captureFrame();
  } catch (e) {
    setStatus('캡처 오류: ' + e.message, 'err');
    return;
  }

  setStatus('<span class="dot"></span>분석 중...');

  try {
    const result = await translateFrame(base64);

    if (!result.found) {
      setStatus('일본어 없음', 'ok');
      elOrig.textContent = '';
      return;
    }

    const translation = result.translation || '';
    const original    = result.original    || '';

    elTrans.textContent = translation;
    elOrig.textContent  = original;

    // 동일 텍스트 반복 전송 방지
    if (translation === lastText) {
      setStatus('중복 — 전송 스킵', '');
      return;
    }
    lastText = translation;

    const ok = await sendToMiSTer(translation);
    if (ok) {
      sentCount++;
      setStatus(`✓ MiSTer 전송 완료 (${sentCount}회)`, 'ok');
    } else {
      setStatus('⚠ MiSTer 전송 실패 (IP 확인)', 'err');
    }

  } catch (e) {
    setStatus('오류: ' + e.message, 'err');
    console.error(e);
  }
}

// ── 시작/정지 ────────────────────────────────────────────────────────────────
async function startCapture() {
  saveSettings();

  if (!document.getElementById('apiKey').value.trim()) {
    setStatus('API Key를 입력하세요', 'err');
    return;
  }

  if (!stream) {
    const ok = await startCamera();
    if (!ok) return;
  }

  if (captureLoop) return;

  const ms = parseInt(document.getElementById('interval').value, 10);

  elStart.disabled = true;
  elStop.classList.add('active');
  setStatus('실행 중...', 'ok');

  // 첫 프레임 즉시 처리
  await processCycle();
  captureLoop = setInterval(processCycle, ms);
}

function stopCapture() {
  if (captureLoop) { clearInterval(captureLoop); captureLoop = null; }
  elStart.disabled = false;
  elStop.classList.remove('active');
  setStatus('정지됨');
}

// ── 유틸 ─────────────────────────────────────────────────────────────────────
function setStatus(msg, cls = '') {
  elStatus.innerHTML  = msg;
  elStatus.className  = cls;
}
