# CLAUDE.md — MiSTer 한글 OSD 프로젝트

## Git 규칙
- push는 항상 `git push devilcg master` 사용 (origin은 upstream MiSTer-devel)
- 커밋 후 자동으로 push까지 진행
- force push 금지

## 작업 흐름
1. 코드 수정
2. 문법 검증 (`bash -n` 또는 `tsc --noEmit`)
3. 로직 테스트 (로컬에서 가능한 부분만)
4. git commit + push
5. README.md 업데이트 (기능 추가/변경 시)
6. 릴리즈 반영 필요 시 사용자에게 확인 후 진행

## 릴리즈 규칙
- 릴리즈는 GitHub Actions 워크플로우(upstream 변경 시 자동) 또는 수동 생성
- 릴리즈 assets: `MiSTer`, `korean_update.sh`, `korean_names.sh`
- 릴리즈 노트 변경 시 README.md도 함께 업데이트
- 스크립트만 변경된 경우 → 기존 릴리즈에 `gh release upload`로 파일 교체

## Scripts 작성 규칙
- 단계별 진행 표시 필수: `[1] ... [2] ... [N]`
- OK / FAIL 명확히 표시
- 인터넷 체크: ping + curl 이중 확인
- 영문 메시지 사용
- 출처 있는 데이터 사용 시 스크립트 상단과 완료 메시지에 출처 표기

## 프로젝트 구조
- `Scripts/korean_update.sh` — 한글 OSD 바이너리 자동 업데이트
- `Scripts/korean_names.sh` — romlistkr 기반 한글 게임명 적용 (MIT, 텐타클팀)
- `.github/workflows/korean-build.yml` — 자동 빌드/릴리즈
