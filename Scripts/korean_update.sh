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

echo ""
echo -e "${CYAN}=====================================${NC}"
echo -e "${CYAN}  MiSTer Korean OSD Update Script   ${NC}"
echo -e "${CYAN}=====================================${NC}"
echo ""

# Check internet connection
if ! ping -c 1 -W 3 8.8.8.8 > /dev/null 2>&1 && ! curl -s --max-time 10 https://api.github.com > /dev/null 2>&1; then
    echo -e "${RED}[Error] Please check your internet connection.${NC}"
    exit 1
fi

echo -e "${CYAN}Fetching latest release info...${NC}"

# Get latest release info via GitHub API
RELEASE_JSON=$(curl -s --max-time 15 "$API_URL")

if [ -z "$RELEASE_JSON" ]; then
    echo -e "${RED}[Error] No response from GitHub API.${NC}"
    exit 1
fi

LATEST_TAG=$(echo "$RELEASE_JSON" | grep '"tag_name"' | head -1 | cut -d'"' -f4)
DOWNLOAD_URL=$(echo "$RELEASE_JSON" | grep '"browser_download_url"' | grep 'MiSTer"' | head -1 | cut -d'"' -f4)
RELEASE_DATE=$(echo "$RELEASE_JSON" | grep '"published_at"' | head -1 | cut -d'"' -f4 | cut -c1-10)

if [ -z "$LATEST_TAG" ] || [ -z "$DOWNLOAD_URL" ]; then
    echo -e "${RED}[Error] Failed to parse release info.${NC}"
    exit 1
fi

echo -e "  Latest version: ${GREEN}${LATEST_TAG}${NC} (${RELEASE_DATE})"

# Check currently installed version (compare by binary date)
CURRENT_DATE=""
if [ -f "$INSTALL_PATH" ]; then
    CURRENT_DATE=$(date -r "$INSTALL_PATH" '+%Y-%m-%d %H:%M')
    echo -e "  Installed: ${YELLOW}${CURRENT_DATE}${NC}"
fi

# Compare release date with current file date
RELEASE_TS=$(date -d "$RELEASE_DATE" '+%s' 2>/dev/null || date -j -f '%Y-%m-%d' "$RELEASE_DATE" '+%s' 2>/dev/null)
CURRENT_TS=0
if [ -f "$INSTALL_PATH" ]; then
    CURRENT_TS=$(date -r "$INSTALL_PATH" '+%s')
fi

if [ "$CURRENT_TS" -ge "$RELEASE_TS" ] 2>/dev/null; then
    echo ""
    echo -e "${GREEN}Already up to date.${NC}"
    echo ""
    exit 0
fi

echo ""
echo -e "${YELLOW}New version available. Starting update...${NC}"
echo ""

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Backup current binary
if [ -f "$INSTALL_PATH" ]; then
    BACKUP_FILE="${BACKUP_DIR}/MiSTer_$(date '+%Y%m%d_%H%M%S')"
    cp "$INSTALL_PATH" "$BACKUP_FILE"
    echo -e "  Backup saved: ${BACKUP_FILE}"
fi

# Download new binary
TMP_FILE="/tmp/MiSTer_korean_new"
echo -e "  Downloading..."

if ! curl -L --max-time 60 --progress-bar "$DOWNLOAD_URL" -o "$TMP_FILE"; then
    echo -e "${RED}[Error] Download failed.${NC}"
    rm -f "$TMP_FILE"
    exit 1
fi

# Check file size (minimum 500KB)
FILE_SIZE=$(wc -c < "$TMP_FILE")
if [ "$FILE_SIZE" -lt 500000 ]; then
    echo -e "${RED}[Error] Downloaded file is too small (possibly corrupted).${NC}"
    rm -f "$TMP_FILE"
    exit 1
fi

# Install
cp "$TMP_FILE" "$INSTALL_PATH"
chmod +x "$INSTALL_PATH"
rm -f "$TMP_FILE"

echo -e "  Installation complete!"
echo ""
echo -e "${GREEN}=====================================${NC}"
echo -e "${GREEN}  Korean OSD update complete!        ${NC}"
echo -e "${GREEN}  Version: ${LATEST_TAG}             ${NC}"
echo -e "${GREEN}=====================================${NC}"
echo ""
echo -e "${YELLOW}Rebooting MiSTer...${NC}"
sleep 2

# Reboot MiSTer
sync
reboot
