#!/bin/bash

# =====================================================
# MiSTer 한글 OSD 자동 업데이트 스크립트
# 사용법: OSD → Scripts → korean_update.sh
# 출처: https://github.com/devilcg/Main_MiSTer
# =====================================================

REPO="devilcg/Main_MiSTer"
INSTALL_PATH="/media/fat/MiSTer"
BACKUP_DIR="/media/fat/MiSTer_Backups"
API_URL="https://api.github.com/repos/${REPO}/releases/latest"

# 색상 출력
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo ""
echo -e "${CYAN}=====================================${NC}"
echo -e "${CYAN}  MiSTer 한글 OSD 업데이트 스크립트 ${NC}"
echo -e "${CYAN}=====================================${NC}"
echo ""

# 인터넷 연결 확인
if ! curl -s --max-time 5 https://api.github.com > /dev/null 2>&1; then
    echo -e "${RED}[오류] 인터넷 연결을 확인해주세요.${NC}"
    exit 1
fi

echo -e "${CYAN}최신 릴리즈 정보를 가져오는 중...${NC}"

# GitHub API로 최신 릴리즈 정보 가져오기
RELEASE_JSON=$(curl -s --max-time 15 "$API_URL")

if [ -z "$RELEASE_JSON" ]; then
    echo -e "${RED}[오류] GitHub API 응답 없음.${NC}"
    exit 1
fi

LATEST_TAG=$(echo "$RELEASE_JSON" | grep '"tag_name"' | head -1 | cut -d'"' -f4)
DOWNLOAD_URL=$(echo "$RELEASE_JSON" | grep '"browser_download_url"' | grep 'MiSTer"' | head -1 | cut -d'"' -f4)
RELEASE_DATE=$(echo "$RELEASE_JSON" | grep '"published_at"' | head -1 | cut -d'"' -f4 | cut -c1-10)

if [ -z "$LATEST_TAG" ] || [ -z "$DOWNLOAD_URL" ]; then
    echo -e "${RED}[오류] 릴리즈 정보를 파싱할 수 없습니다.${NC}"
    exit 1
fi

echo -e "  최신 버전: ${GREEN}${LATEST_TAG}${NC} (${RELEASE_DATE})"

# 현재 설치된 버전 확인 (바이너리 날짜로 비교)
CURRENT_DATE=""
if [ -f "$INSTALL_PATH" ]; then
    CURRENT_DATE=$(date -r "$INSTALL_PATH" '+%Y-%m-%d %H:%M')
    echo -e "  현재 설치: ${YELLOW}${CURRENT_DATE}${NC}"
fi

# 최신 릴리즈 날짜와 현재 파일 날짜 비교
RELEASE_TS=$(date -d "$RELEASE_DATE" '+%s' 2>/dev/null || date -j -f '%Y-%m-%d' "$RELEASE_DATE" '+%s' 2>/dev/null)
CURRENT_TS=0
if [ -f "$INSTALL_PATH" ]; then
    CURRENT_TS=$(date -r "$INSTALL_PATH" '+%s')
fi

if [ "$CURRENT_TS" -ge "$RELEASE_TS" ] 2>/dev/null; then
    echo ""
    echo -e "${GREEN}이미 최신 한글 버전입니다.${NC}"
    echo ""
    exit 0
fi

echo ""
echo -e "${YELLOW}새 버전이 있습니다. 업데이트를 진행합니다...${NC}"
echo ""

# 백업 디렉토리 생성
mkdir -p "$BACKUP_DIR"

# 현재 바이너리 백업
if [ -f "$INSTALL_PATH" ]; then
    BACKUP_FILE="${BACKUP_DIR}/MiSTer_$(date '+%Y%m%d_%H%M%S')"
    cp "$INSTALL_PATH" "$BACKUP_FILE"
    echo -e "  백업 완료: ${BACKUP_FILE}"
fi

# 새 바이너리 다운로드
TMP_FILE="/tmp/MiSTer_korean_new"
echo -e "  다운로드 중..."

if ! curl -L --max-time 60 --progress-bar "$DOWNLOAD_URL" -o "$TMP_FILE"; then
    echo -e "${RED}[오류] 다운로드 실패.${NC}"
    rm -f "$TMP_FILE"
    exit 1
fi

# 파일 크기 확인 (최소 500KB)
FILE_SIZE=$(wc -c < "$TMP_FILE")
if [ "$FILE_SIZE" -lt 500000 ]; then
    echo -e "${RED}[오류] 다운로드된 파일이 너무 작습니다 (손상 가능).${NC}"
    rm -f "$TMP_FILE"
    exit 1
fi

# 설치
cp "$TMP_FILE" "$INSTALL_PATH"
chmod +x "$INSTALL_PATH"
rm -f "$TMP_FILE"

echo -e "  설치 완료!"
echo ""
echo -e "${GREEN}=====================================${NC}"
echo -e "${GREEN}  한글 OSD 업데이트 완료!            ${NC}"
echo -e "${GREEN}  버전: ${LATEST_TAG}                ${NC}"
echo -e "${GREEN}=====================================${NC}"
echo ""
echo -e "${YELLOW}MiSTer를 재시작합니다...${NC}"
sleep 2

# MiSTer 재시작
sync
reboot
