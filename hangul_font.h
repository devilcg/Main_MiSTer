#ifndef HANGUL_FONT_H
#define HANGUL_FONT_H

#include <stddef.h>
#include <stdint.h>

bool osd_decode_utf8_char(const char **src, uint32_t *codepoint);
int osd_utf8_length(const char *src);
const char *osd_utf8_advance(const char *src, int count);
void osd_utf8_copy_range(char *dst, size_t dst_size, const char *src, int start_char, int max_chars);
void osd_encode_display_bytes(char *dst, size_t dst_size, const char *src, int start_char, int max_chars);
const unsigned char *osd_get_glyph(uint32_t codepoint);

#endif
