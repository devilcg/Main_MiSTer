#include <string.h>
#include <string>

#include "menu_locale.h"

struct MenuLocaleEntry
{
	const char *en;
	const char *ko;
};

static const MenuLocaleEntry kMenuLocaleTable[] =
{
	{"            exit", "            종료"},
	{"            back", "            뒤로"},
	{"        SPACE to exit", "      SPACE로 종료"},
	{"      Ctrl+ESC to exit", "   Ctrl+ESC로 종료"},
	{"Information", "정보"},
	{"Mouse mode ON", "마우스 모드 켜짐"},
	{"Mouse mode OFF", "마우스 모드 꺼짐"},
	{"Select INI", "INI 선택"},
	{"System", "시스템"},
	{"Video Processing", "비디오 처리"},
	{"Help", "도움말"},
	{"DIP Switches", "DIP 스위치"},
	{"UART Mode", "UART 모드"},
	{"UART MODE", "UART 모드"},
	{"UART Baud Rate", "UART 전송 속도"},
	{"Misc. Options", "기타 옵션"},
	{"Define buttons", "버튼 정의"},
	{"Button/Key remap", "버튼/키 재매핑"},
	{"About", "정보"},
	{"Locked", "잠김"},
	{"Config", "설정"},
	{"Load Config", "설정 불러오기"},
	{"Save Config", "설정 저장"},
	{"Load config", "설정 불러오기"},
	{"Save config", "설정 저장"},
	{"Drives", "드라이브"},
	{"Audio & Video", "오디오 및 비디오"},
	{"System Settings", "시스템 설정"},
	{"Lightgun Calibration", "라이트건 보정"},
	{"Warning!!!", "경고!!!"},
	{"BT Pairing", "블루투스 페어링"},
	{"Keyboard", "키보드"},
	{"Advanced", "고급"},
	{"Set Hotkey", "핫키 설정"},
	{"Cartridge Type", "카트리지 종류"},
	{" Core                      \x16", " 코어                      \x16"},
	{" Lock OSD", " OSD 잠금"},
	{" Button/Key remap          \x16", " 버튼/키 재매핑            \x16"},
	{" Reset player assignment", " 플레이어 할당 초기화"},
	{" Video processing          \x16", " 비디오 처리               \x16"},
	{" Reset settings", " 설정 초기화"},
	{" Save settings", " 설정 저장"},
	{" Help                      \x16", " 도움말                    \x16"},
	{" Reboot (hold \x16 cold reboot)", " 재부팅 (\x16 길게: 완전 재부팅)"},
	{" Load preset", " 프리셋 불러오기"},
	{" Reset to Defaults", " 기본값으로 초기화"},
	{"       Reset to apply", "       적용하려면 초기화"},
	{"Supported mapping:", "지원되는 매핑:"},
	{" Button(s)/Key(s) -> Key(s)", " 버튼/키 -> 키"},
	{"Button(s) -> Button(s)", "버튼 -> 버튼"},
	{"    F12 \x16 Advanced ", "    F12 \x16 고급 "},
	{"  Esc \x16 Clear ", "  Esc \x16 지우기 "},
	{"Enter \x16 Finish ", "Enter \x16 완료 "},
	{"     OK-hold \x16 Advanced  ", "     OK 길게 \x16 고급  "},
	{"     Menu \x16 Finish ", "     메뉴 \x16 완료 "},
	{"Menu-hold \x16 Clear  ", "메뉴 길게 \x16 지우기  "},
	{"Enter \x16 Finish", "Enter \x16 완료"},
	{" ESC \x16 Clear", " ESC \x16 지우기"},
	{"Press button(s) on joypad", "조이패드 버튼을 누르세요"},
	{"or key(s) on keyboard", "또는 키보드 키를 누르세요"},
	{"Press Keyboard key(s)", "키보드 키를 누르세요"},
	{"Esc \x16 Clear", "Esc \x16 지우기"},
	{"Menu-hold \x16 Clear", "메뉴 길게 \x16 지우기"},
	{"        Help requires", "       도움말 기능은"},
	{"        fb_terminal=1", "      fb_terminal=1 필요"},
	{"  If you see this, then you", "  이 화면이 보인다면"},
	{"  need to modify MiSTer.ini", "  MiSTer.ini를 수정해야 합니다"},
	{" Either disable framebuffer:", " 프레임버퍼를 끄거나:"},
	{"  or enable scaler on VGA:", " 또는 VGA 스케일러를 켜세요:"},
	{"  Use dpad/cursor to select", "  방향키/커서로 선택"},
	{"   Press any key to cancel", "    아무 키나 눌러 취소"},
	{"           Loading...", "          불러오는 중..."},
	{"          Saving...", "          저장 중..."},
	{" Change Soundfont          \x16", " 사운드폰트 변경           \x16"},
	{" Reset UART connection", " UART 연결 재설정"},
	{" Save", " 저장"},
	{"         Information", "           정보"},
	{"       Reset to default", "        기본값으로 초기화"},
	{"          Esc \x16 Cancel", "         Esc \x16 취소"},
	{"        Enter \x16 Finish", "        Enter \x16 완료"},
	{"    Menu-hold \x16 Cancel", "   메뉴 길게 \x16 취소"},
	{"          Clearing", "          지우는 중"},
	{"          Canceling", "          취소하는 중"},
	{"   Space/User \x16 Skip", "   Space/User \x16 건너뛰기"},
	{"   (can use 2-button combo)", "   (2버튼 조합 사용 가능)"},
	{"   You need to define this", "   이 항목을 먼저 정의해야"},
	{" joystick in Menu core first", " 메뉴 코어에서 조이스틱 설정"},
	{"      Press ESC/Enter", "      ESC/Enter를 누르세요"},
	{"         User \x16 Undefine", "         User \x16 해제"},
	{"          F12 \x16 Clear all", "         F12 \x16 모두 지우기"},
	{"    Do you want to setup", "    설정을 진행하시겠습니까"},
	{"    alternative buttons?", "    대체 버튼으로?"},
	{"           No", "           아니오"},
	{"           Yes", "            예"},
	{"           Cancel", "           취소"},
	{"          Finishing", "          마무리 중"},
	{"     Press key(s) to map to", "     매핑할 키를 누르세요"},
	{"        on a keyboard", "         키보드에서"},
	{"   Press button(s) to map to", "   매핑할 버튼을 누르세요"},
	{"        on the same pad", "       같은 패드에서"},
	{"    or key(s) on a keyboard", "   또는 키보드 키를 누르세요"},
	{"       Press button(s) ", "        버튼을 누르세요 "},
	{"     or key(s) to change", "     또는 변경할 키를 누르세요"},
	{" Esc \x16 Clear, Enter \x16 Finish", " Esc \x16 지우기, Enter \x16 완료"},
	{"     www.MiSTerFPGA.org", "     www.MiSTerFPGA.org"},
	{"      Enter unlock code", "      잠금 해제 코드를 입력"},
	{" Modify config             \x16", " 설정 수정                 \x16"},
	{" Load config               \x16", " 설정 불러오기             \x16"},
	{" Save config               \x16", " 설정 저장                 \x16"},
	{" MT32-pi                   \x16", " MT32-pi                   \x16"},
	{" Reset", "초기화"},
	{" Cold Boot", "콜드 부팅"},
	{" Startup config:", " 시작 설정:"},
	{" Other configs:", " 다른 설정:"},
	{" Default Config:", " 기본 설정:"},
	{" Reset Hanging Notes", " 멈춘 음표 초기화"},
	{"     Clearing the option", "      옵션을 지우는 중"},
	{" You have to reload the core", " 코어를 다시 불러와야"},
	{"    to use default value.", "    기본값이 적용됩니다."},
	{"    Unmounting the image", "     이미지를 언마운트 중"},
	{"        Clear the List?", "         목록을 지울까요?"},
	{"             No", "            아니오"},
	{"             Yes", "              예"},
	{"    Clearing the recents", "      최근 목록 지우는 중"},
	{"       Reset Minimig?", "       Minimig 초기화?"},
	{"       Reset settings?", "       설정을 초기화할까요?"},
	{"             yes", "             예"},
	{"             no", "          아니오"},
	{"  < EMPTY >", "  < 비어 있음 >"},
	{" Finish screen adjustment", " 화면 조정 완료"},
	{" Adjust screen position", " 화면 위치 조정"},
	{"        Storage: USB", "        저장소: USB"},
	{"      Switch to SD card", "      SD 카드로 전환"},
	{" No USB found, using SD card", " USB가 없어 SD 카드를 사용 중"},
	{"      Storage: SD card", "      저장소: SD 카드"},
	{"        Switch to USB", "        USB로 전환"},
	{" Remap keyboard            \x16", " 키보드 재매핑            \x16"},
	{" Define joystick buttons   \x16", " 조이스틱 버튼 정의        \x16"},
	{" Scripts                   \x16", " 스크립트                  \x16"},
	{"     Point to the edge of", "      화면 가장자리를 향해"},
	{"   screen and press trigger", "   트리거를 눌러 주세요"},
	{"         to confirm", "          확인해 주세요"},
	{"         Attention:", "           주의:"},
	{" This is dangerous operation!", " 위험한 작업입니다!"},
	{" Script has control over the", " 스크립트가 시스템 전체를"},
	{" whole system and may damage", " 제어하며 손상시킬 수 있습니다"},
	{" the files or settings, then", " 파일이나 설정이 망가지면"},
	{" MiSTer won't boot, so you", " MiSTer가 부팅되지 않을 수 있어"},
	{" will have to re-format the", " SD 카드를 다시 포맷하고"},
	{" SD card and fill with files", " 파일을 다시 채워 넣어야"},
	{" in order to use it again.", " 다시 사용할 수 있습니다."},
	{"  Do you want to continue?", "   계속 진행하시겠습니까?"},
	{"  Yes, and don't ask again", "  예, 다시 묻지 않음"},
	{"    No Bluetooth available", "   블루투스를 사용할 수 없음"},
	{"           Finish", "           완료"},
	{"             OK", "             확인"},
	{"   Delete all pairings...", "    모든 페어링 삭제..."},
	{"     Press key to change", "      변경할 키를 누르세요"},
	{"           finish", "            완료"},
	{"      on any keyboard", "       아무 키보드에서"},
	{"\n\n         Canceled!\n", "\n\n           취소됨!\n"},
	{"\n\n     No USB storage found\n   Falling back to SD card\n", "\n\n      USB 저장소 없음\n    SD 카드로 전환합니다\n"},
	{"\n\n       Mouse mode lock\n             ON", "\n\n      마우스 모드 고정\n            켜짐"},
	{"\n\n       Mouse mode lock\n             OFF", "\n\n      마우스 모드 고정\n            꺼짐"},
	{" New                       \x16", " 새로 만들기              \x16"},
	{" Delete", " 삭제"},
	{" Done", " 완료"},
	{"Minimig", "Minimig"},
	{" Drives                    \x16", " 드라이브                  \x16"},
	{" System                    \x16", " 시스템                    \x16"},
	{" Audio & Video             \x16", " 오디오 및 비디오          \x16"},
	{" Save configuration        \x16", " 설정 저장                 \x16"},
	{" Load configuration        \x16", " 설정 불러오기             \x16"},
	{"Cores", "코어"},
	{"Select", "선택"},
	{"Recent Cores", "최근 코어"},
	{"Recent Files", "최근 파일"},
	{"No network", "네트워크 없음"},
};

const char *menu_translate(const char *text)
{
	if (!text || !*text) return text;

	for (const auto &entry : kMenuLocaleTable)
	{
		if (!strcmp(text, entry.en)) return entry.ko;
	}

	struct FragmentEntry
	{
		const char *en;
		const char *ko;
	};

	static const FragmentEntry kFragmentTable[] =
	{
		{" Refresh Rate:    ", " 주사율:           "},
		{" Stereo Mix:      ", " 스테레오 믹스:    "},
		{" Swap Joysticks:  ", " 조이스틱 교체:    "},
		{" Swap Btn 2/3:    ", " 버튼 2/3 교체:    "},
		{" 25MHz Audio Fix: ", " 25MHz 오디오 보정:"},
		{" Scale:           ", " 스케일:           "},
		{" Define ", " 설정 "},
		{" buttons", " 버튼"},
		{" Link:            ", " 링크:             "},
		{" Type:                ", " 타입:             "},
		{" Vert filter: ", " 수직 필터: "},
		{" Scan filter: ", " 스캔 필터: "},
		{" Intl filter: ", " 인터레이스 필터: "},
		{" Gamma correction - ", " 감마 보정 - "},
		{" Joysticks swap: ", " 조이스틱 교체: "},
		{" Storage: USB", " 저장소: USB"},
		{" Storage: SD card", " 저장소: SD 카드"},
		{" Switch to SD card", " SD 카드로 전환"},
		{" Switch to USB", " USB로 전환"},
		{" Mouse mode ON", " 마우스 모드 켜짐"},
		{" Mouse mode OFF", " 마우스 모드 꺼짐"},
		{"Reset Minimig?", "Minimig 초기화?"},
		{"Reset settings?", "설정 초기화?"},
		{"Loading...", "불러오는 중..."},
		{"Saving...", "저장 중..."},
		{"Canceled!", "취소됨!"},
		{"Enable", "활성"},
		{"Disable", "비활성"},
		{"Variable", "가변"},
		{"Original", "원본"},
		{"Full Screen", "전체 화면"},
		{"From file", "파일에서"},
		{"Same as Horz", "수평과 동일"},
		{"Same as Vert", "수직과 동일"},
		{"On", "켜짐"},
		{"Off", "꺼짐"},
		{"Yes", "예"},
		{"No", "아니오"},
	};

	std::string translated(text);
	bool changed = false;

	for (const auto &entry : kFragmentTable)
	{
		size_t pos = 0;
		while ((pos = translated.find(entry.en, pos)) != std::string::npos)
		{
			translated.replace(pos, strlen(entry.en), entry.ko);
			pos += strlen(entry.ko);
			changed = true;
		}
	}

	if (!changed) return text;

	static std::string buffers[8];
	static size_t buffer_index = 0;
	buffers[buffer_index] = translated;
	const char *result = buffers[buffer_index].c_str();
	buffer_index = (buffer_index + 1) % 8;
	return result;
}
