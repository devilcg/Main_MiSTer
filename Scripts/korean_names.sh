#!/bin/bash

# =====================================================
# MiSTer Korean Game Names Script
# Usage: OSD → Scripts → korean_names.sh
# Source: https://github.com/tentacleteam/romlistkr
# License: MIT (tentacleteam)
# =====================================================

BASE_URL="https://raw.githubusercontent.com/tentacleteam/romlistkr/master/ES-gamelist"
TMP_DIR="/tmp/romlistkr"
GAMES_DIR="/media/fat/games"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

STEP=0
step() { STEP=$((STEP+1)); echo -e "${CYAN}[${STEP}] $1${NC}"; }
ok()   { echo -e "    ${GREEN}OK${NC} $1"; }
fail() { echo -e "    ${RED}FAIL${NC} $1"; }
info() { echo -e "    ${YELLOW}$1${NC}"; }

echo ""
echo -e "${CYAN}=====================================${NC}"
echo -e "${CYAN}  MiSTer Korean Game Names Script   ${NC}"
echo -e "${CYAN}=====================================${NC}"
echo ""

# ── Step 1: Internet check ─────────────────────────
step "Checking internet connection..."
if ! ping -c 1 -W 3 8.8.8.8 > /dev/null 2>&1 && ! curl -sk --max-time 10 https://github.com > /dev/null 2>&1; then
    fail "No internet. Please check your network connection."
    exit 1
fi
ok "Connected."

# ── Step 2: Python check ───────────────────────────
step "Checking Python 3..."
if ! command -v python3 > /dev/null 2>&1; then
    fail "Python 3 not found."
    exit 1
fi
PYTHON_VER=$(python3 --version 2>&1)
ok "$PYTHON_VER"

# ── Step 3: Download XML data ──────────────────────
step "Downloading romlistkr game data..."
mkdir -p "$TMP_DIR"

declare -A SYSTEMS=(
    ["nes"]="NES"
    ["snes"]="SNES"
    ["megadrive"]="MegaDrive"
    ["neogeo"]="NeoGeo"
    ["gb"]="Gameboy"
    ["gbc"]="Gameboy"
    ["gba"]="GBA"
    ["pcengine"]="TGFX16"
    ["msx"]="MSX"
    ["mastersystem"]="SMS"
    ["sega32x"]="S32X"
    ["arcade"]="__arcade__"
)

DOWNLOAD_OK=0
DOWNLOAD_FAIL=0
for sys in "${!SYSTEMS[@]}"; do
    url="${BASE_URL}/${sys}/gamelist.xml"
    out="${TMP_DIR}/${sys}.xml"
    if curl -sk --max-time 30 "$url" -o "$out" && [ -s "$out" ]; then
        DOWNLOAD_OK=$((DOWNLOAD_OK+1))
    else
        rm -f "$out"
        DOWNLOAD_FAIL=$((DOWNLOAD_FAIL+1))
        info "Skipped: $sys (not available)"
    fi
done
ok "Downloaded ${DOWNLOAD_OK} system(s). (skipped: ${DOWNLOAD_FAIL})"

# ── Step 4: Parse & generate names.txt ────────────
step "Parsing game names..."

python3 << 'PYEOF'
import os
import xml.etree.ElementTree as ET

TMP_DIR   = "/tmp/romlistkr"
GAMES_DIR = "/media/fat/games"

# romlistkr system → MiSTer path mapping
SYSTEM_MAP = {
    "nes":          os.path.join(GAMES_DIR, "NES"),
    "snes":         os.path.join(GAMES_DIR, "SNES"),
    "megadrive":    os.path.join(GAMES_DIR, "MegaDrive"),
    "neogeo":       os.path.join(GAMES_DIR, "NeoGeo"),
    "gb":           os.path.join(GAMES_DIR, "Gameboy"),
    "gbc":          os.path.join(GAMES_DIR, "Gameboy"),
    "gba":          os.path.join(GAMES_DIR, "GBA"),
    "pcengine":     os.path.join(GAMES_DIR, "TGFX16"),
    "msx":          os.path.join(GAMES_DIR, "MSX"),
    "mastersystem": os.path.join(GAMES_DIR, "SMS"),
    "sega32x":      os.path.join(GAMES_DIR, "S32X"),
    "arcade":       "/media/fat",  # arcade names.txt는 루트에
}

def parse_xml(xml_path):
    """XML에서 {rom_name: korean_name} 딕셔너리 반환"""
    entries = {}
    try:
        tree = ET.parse(xml_path)
        root = tree.getroot()
        for game in root.findall("game"):
            path_el = game.find("path")
            name_el = game.find("name")
            if path_el is None or name_el is None:
                continue
            raw_path = path_el.text or ""
            name     = name_el.text or ""
            if not raw_path or not name:
                continue
            # ./Super Mario Bros (USA).zip → Super Mario Bros (USA)
            rom = os.path.splitext(os.path.basename(raw_path))[0]
            if rom:
                entries[rom] = name
    except Exception as e:
        print(f"    Parse error: {e}")
    return entries

total_names = 0
applied_systems = []

for sys_name, mister_path in SYSTEM_MAP.items():
    xml_file = os.path.join(TMP_DIR, f"{sys_name}.xml")
    if not os.path.exists(xml_file):
        continue

    entries = parse_xml(xml_file)
    if not entries:
        print(f"    SKIP {sys_name}: no entries")
        continue

    # 기존 names.txt 읽기 (있으면 병합)
    names_file = os.path.join(mister_path, "names.txt")
    existing = {}
    if os.path.exists(names_file):
        with open(names_file, "r", encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if ": " in line:
                    k, _, v = line.partition(": ")
                    existing[k.strip()] = v.strip()

    # 신규 항목 병합
    merged = {**existing, **entries}

    # 디렉토리 생성 및 저장
    os.makedirs(mister_path, exist_ok=True)
    with open(names_file, "w", encoding="utf-8") as f:
        for rom, krname in sorted(merged.items()):
            f.write(f"{rom}: {krname}\n")

    new_count = len(entries)
    total_names += new_count
    applied_systems.append((sys_name, new_count))
    print(f"    OK  {sys_name:<14} {new_count:>5}개 → {names_file}")

print(f"\n    Total: {total_names:,}개 게임명 적용")
PYEOF

PYTHON_EXIT=$?
if [ $PYTHON_EXIT -ne 0 ]; then
    fail "Python script failed."
    exit 1
fi

# ── Done ───────────────────────────────────────────
echo ""
echo -e "${GREEN}=====================================${NC}"
echo -e "${GREEN}  Korean game names applied!         ${NC}"
echo -e "${GREEN}  Source: romlistkr (MIT License)    ${NC}"
echo -e "${GREEN}=====================================${NC}"
echo ""
echo -e "${YELLOW}Restart MiSTer or reload the core to see changes.${NC}"
echo ""
