#include <string.h>

#include "hangul_font.h"
#include "charrom.h"
#include "generated/hangul_font_data.h"

namespace {

constexpr uint32_t HANGUL_BASE = 0xAC00;
constexpr uint32_t HANGUL_LAST = 0xD7A3;
constexpr uint8_t HANGUL_SLOT_FIRST = 151;
constexpr uint8_t HANGUL_SLOT_LAST = 255;
constexpr size_t HANGUL_SLOT_COUNT = HANGUL_SLOT_LAST - HANGUL_SLOT_FIRST + 1;

struct GlyphCacheEntry
{
	uint32_t codepoint = 0;
	uint32_t stamp = 0;
	bool valid = false;
};

GlyphCacheEntry glyph_cache[HANGUL_SLOT_COUNT];
uint32_t glyph_stamp = 1;

bool decode_cont(const char ch)
{
	return (static_cast<unsigned char>(ch) & 0xC0) == 0x80;
}

uint8_t alloc_hangul_slot(uint32_t codepoint)
{
	size_t best = 0;
	uint32_t oldest = UINT32_MAX;

	for (size_t i = 0; i < HANGUL_SLOT_COUNT; i++)
	{
		if (glyph_cache[i].valid && glyph_cache[i].codepoint == codepoint)
		{
			glyph_cache[i].stamp = glyph_stamp++;
			return static_cast<uint8_t>(HANGUL_SLOT_FIRST + i);
		}

		if (!glyph_cache[i].valid)
		{
			best = i;
			oldest = 0;
			break;
		}

		if (glyph_cache[i].stamp < oldest)
		{
			oldest = glyph_cache[i].stamp;
			best = i;
		}
	}

	const size_t index = codepoint - HANGUL_BASE;
	memcpy(charfont[HANGUL_SLOT_FIRST + best], hangul_font8x8[index], 8);
	glyph_cache[best].codepoint = codepoint;
	glyph_cache[best].stamp = glyph_stamp++;
	glyph_cache[best].valid = true;

	return static_cast<uint8_t>(HANGUL_SLOT_FIRST + best);
}

} // namespace

bool osd_decode_utf8_char(const char **src, uint32_t *codepoint)
{
	const unsigned char *s = reinterpret_cast<const unsigned char*>(*src);
	if (!s || !*s)
	{
		return false;
	}

	if (*s < 0x80)
	{
		*codepoint = *s++;
		*src = reinterpret_cast<const char*>(s);
		return true;
	}

	if ((*s & 0xE0) == 0xC0 && decode_cont(s[1]))
	{
		const uint32_t cp = (static_cast<uint32_t>(s[0] & 0x1F) << 6) |
			(static_cast<uint32_t>(s[1] & 0x3F));
		if (cp >= 0x80)
		{
			*codepoint = cp;
			*src = reinterpret_cast<const char*>(s + 2);
			return true;
		}
	}

	if ((*s & 0xF0) == 0xE0 && decode_cont(s[1]) && decode_cont(s[2]))
	{
		const uint32_t cp = (static_cast<uint32_t>(s[0] & 0x0F) << 12) |
			(static_cast<uint32_t>(s[1] & 0x3F) << 6) |
			(static_cast<uint32_t>(s[2] & 0x3F));
		if (cp >= 0x800)
		{
			*codepoint = cp;
			*src = reinterpret_cast<const char*>(s + 3);
			return true;
		}
	}

	if ((*s & 0xF8) == 0xF0 && decode_cont(s[1]) && decode_cont(s[2]) && decode_cont(s[3]))
	{
		const uint32_t cp = (static_cast<uint32_t>(s[0] & 0x07) << 18) |
			(static_cast<uint32_t>(s[1] & 0x3F) << 12) |
			(static_cast<uint32_t>(s[2] & 0x3F) << 6) |
			(static_cast<uint32_t>(s[3] & 0x3F));
		if (cp >= 0x10000 && cp <= 0x10FFFF)
		{
			*codepoint = cp;
			*src = reinterpret_cast<const char*>(s + 4);
			return true;
		}
	}

	*codepoint = '?';
	*codepoint = *s;
	*src = reinterpret_cast<const char*>(s + 1);
	return true;
}

int osd_utf8_length(const char *src)
{
	int len = 0;
	uint32_t codepoint = 0;

	while (osd_decode_utf8_char(&src, &codepoint))
	{
		len++;
	}

	return len;
}

const char *osd_utf8_advance(const char *src, int count)
{
	uint32_t codepoint = 0;
	while (count-- > 0 && osd_decode_utf8_char(&src, &codepoint))
	{
	}

	return src;
}

void osd_utf8_copy_range(char *dst, size_t dst_size, const char *src, int start_char, int max_chars)
{
	if (!dst_size)
	{
		return;
	}

	const char *start = osd_utf8_advance(src, start_char);
	const char *end = osd_utf8_advance(start, max_chars);
	size_t len = static_cast<size_t>(end - start);
	if (len >= dst_size)
	{
		len = dst_size - 1;
	}

	memcpy(dst, start, len);
	dst[len] = 0;
}

void osd_encode_display_bytes(char *dst, size_t dst_size, const char *src, int start_char, int max_chars)
{
	if (!dst_size)
	{
		return;
	}

	const char *cur = osd_utf8_advance(src, start_char);
	size_t pos = 0;
	uint32_t codepoint = 0;

	while (max_chars-- > 0 && pos + 1 < dst_size && osd_decode_utf8_char(&cur, &codepoint))
	{
		if (codepoint >= HANGUL_BASE && codepoint <= HANGUL_LAST)
		{
			dst[pos++] = static_cast<char>(alloc_hangul_slot(codepoint));
			continue;
		}

		if (codepoint < 256)
		{
			dst[pos++] = static_cast<char>(codepoint);
			continue;
		}

		dst[pos++] = '?';
	}

	dst[pos] = 0;
}

const unsigned char *osd_get_glyph(uint32_t codepoint)
{
	if (codepoint < 256)
	{
		return charfont[static_cast<uint8_t>(codepoint)];
	}

	if (codepoint >= HANGUL_BASE && codepoint <= HANGUL_LAST)
	{
		return charfont[alloc_hangul_slot(codepoint)];
	}

	if (codepoint == 0x00A0)
	{
		return charfont[static_cast<uint8_t>(' ')];
	}

	return charfont[static_cast<uint8_t>('?')];
}
