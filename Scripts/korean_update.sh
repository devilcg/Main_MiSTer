#!/bin/bash

# =====================================================
# MiSTer Korean OSD Auto-Update Script
# Usage: OSD → Scripts → korean_update.sh
# Source: https://github.com/devilcg/Main_MiSTer
# =====================================================

REPO="devilcg/Main_MiSTer"
INSTALL_PATH="/media/fat/MiSTer"
BACKUP_DIR="/media/fat/MiSTer_Backups"
API_URL="https://api.github.com/repos/${REPO}/releases/latest"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

STEP=0
step() {
    STEP=$((STEP + 1))
    echo -e "${CYAN}[${STEP}] $1${NC}"
}
ok()   { echo -e "    ${GREEN}OK${NC} $1"; }
fail() { echo -e "    ${RED}FAIL${NC} $1"; }

echo ""
echo -e "${CYAN}=====================================${NC}"
echo -e "${CYAN}  MiSTer Korean OSD Update Script   ${NC}"
echo -e "${CYAN}=====================================${NC}"
echo ""

# ── Step 1: Internet check ─────────────────────────
step "Checking internet connection..."
if ! ping -c 1 -W 3 8.8.8.8 > /dev/null 2>&1; then
    fail "No internet. Please check your network connection."
    exit 1
fi
ok "Network reachable."

step "Checking GitHub API access..."
if ! curl -sk --max-time 10 https://api.github.com > /dev/null 2>&1; then
    fail "Cannot reach GitHub API (api.github.com)."
    echo -e "    ${YELLOW}Tip: Check DNS or try: echo 'nameserver 8.8.8.8' > /etc/resolv.conf${NC}"
    exit 1
fi
ok "GitHub API reachable."

# ── Step 3: Fetch latest release info ──────────────
step "Fetching latest release info from GitHub..."
RELEASE_JSON=""
for i in 1 2 3; do
    RELEASE_JSON=$(curl -sk --max-time 30 "$API_URL")
    [ -n "$RELEASE_JSON" ] && break
    echo -e "    ${YELLOW}Retrying... (${i}/3)${NC}"
    sleep 3
done

if [ -z "$RELEASE_JSON" ]; then
    fail "No response from GitHub API."
    exit 1
fi

LATEST_TAG=$(echo "$RELEASE_JSON" | grep '"tag_name"' | head -1 | cut -d'"' -f4)
DOWNLOAD_URL=$(echo "$RELEASE_JSON" | grep '"browser_download_url"' | grep 'MiSTer"' | head -1 | cut -d'"' -f4)
RELEASE_PUBLISHED=$(echo "$RELEASE_JSON" | grep '"published_at"' | head -1 | cut -d'"' -f4)
RELEASE_DATE=$(echo "$RELEASE_PUBLISHED" | cut -c1-10)

if [ -z "$LATEST_TAG" ] || [ -z "$DOWNLOAD_URL" ]; then
    fail "Failed to parse release info."
    exit 1
fi
ok "Latest: ${LATEST_TAG} (${RELEASE_DATE})"

# ── Step 4: Version check ──────────────────────────
step "Checking installed version..."
RELEASE_TS=$(date -d "$RELEASE_PUBLISHED" '+%s' 2>/dev/null || date -j -f '%Y-%m-%dT%H:%M:%SZ' "$RELEASE_PUBLISHED" '+%s' 2>/dev/null || echo 0)
CURRENT_TS=0
if [ -f "$INSTALL_PATH" ]; then
    CURRENT_TS=$(stat -c '%Y' "$INSTALL_PATH" 2>/dev/null || echo 0)
    CURRENT_DATE=$(date -d "@${CURRENT_TS}" '+%Y-%m-%d %H:%M' 2>/dev/null || echo "unknown")
    ok "Installed: ${CURRENT_DATE}"
else
    ok "No existing installation found."
fi

if [ "$CURRENT_TS" -ge "$RELEASE_TS" ] 2>/dev/null; then
    echo ""
    echo -e "${GREEN}Already up to date. Nothing to do.${NC}"
    echo ""
    exit 0
fi

echo ""
echo -e "${YELLOW}  New version available!${NC}"
echo ""

# ── Step 5: Backup ─────────────────────────────────
step "Backing up current binary..."
mkdir -p "$BACKUP_DIR"
if [ -f "$INSTALL_PATH" ]; then
    BACKUP_FILE="${BACKUP_DIR}/MiSTer_$(date '+%Y%m%d_%H%M%S')"
    cp "$INSTALL_PATH" "$BACKUP_FILE"
    ok "Saved to: ${BACKUP_FILE}"
else
    ok "Skipped (no existing binary)."
fi

# ── Step 6: Download ───────────────────────────────
step "Downloading new binary..."
TMP_FILE="/tmp/MiSTer_korean_new"
if ! curl -Lk --max-time 60 --progress-bar "$DOWNLOAD_URL" -o "$TMP_FILE"; then
    fail "Download failed."
    rm -f "$TMP_FILE"
    exit 1
fi

FILE_SIZE=$(wc -c < "$TMP_FILE")
if [ "$FILE_SIZE" -lt 500000 ]; then
    fail "Downloaded file is too small (possibly corrupted)."
    rm -f "$TMP_FILE"
    exit 1
fi
ok "Downloaded ($(( FILE_SIZE / 1024 )) KB)."

# ── Step 7: Install ────────────────────────────────
step "Installing..."
cp "$TMP_FILE" "$INSTALL_PATH"
chmod +x "$INSTALL_PATH"
rm -f "$TMP_FILE"
ok "Installed to: ${INSTALL_PATH}"

# ── Done ───────────────────────────────────────────
echo ""
echo -e "${GREEN}=====================================${NC}"
echo -e "${GREEN}  Update complete!                   ${NC}"
echo -e "${GREEN}  Version: ${LATEST_TAG}             ${NC}"
echo -e "${GREEN}=====================================${NC}"
echo ""
echo -e "${YELLOW}Rebooting MiSTer in 3 seconds...${NC}"
sleep 3

sync
reboot
