#ifndef _KEYBOARD_UPCO_H
// uint8_t translate_key( uint8_t asc);

#include <stdint.h>

#define translate_key(a) (key_translate[(a)])

void putch( char c) __z88dk_fastcall;
void putstr( char *s) __z88dk_fastcall;
void crlf() __z88dk_fastcall;

static const uint8_t key_translate[] = {
  // new keyscan with row in bits 5:3 and column in bits 2:0
  0xb3,				/* 0 -> SST */
  0xb2,				/* 1 -> BST */
  0xb1,				/* 2 -> GTO */
  0xb0,				/* 3 -> F */
  0xb4,				/* 4 -> G */
  0x00,				/* 5    n/a */
  0x00,				/* 6    n/a */
  0x00,				/* 7    n/a */
  0x43,				/* 8 -> X/Y */
  0x42,				/* 9 -> RDN */
  0x41,				/* 10 -> STO */
  0x40,				/* 11 -> RCL */
  0x44,				/* 12 -> E+ */
  0x00,				/* 13    n/a */
  0x00,				/* 14    n/a */
  0x00,				/* 15    n/a */
  0xd3,				/* 16 -> ENTER */
  0x00,				/* 17    n/a */
  0xd1,				/* 18 -> CHS */
  0xd0,				/* 19 -> EEX */
  0xd4,				/* 20 -> CLX */
  0x00,				/* 21    n/a */
  0x00,				/* 22    n/a */
  0x00,				/* 23    n/a */
  0x63,				/* 24 -> - */
  0x62,				/* 25 -> 7 */
  0x61,				/* 26 -> 8 */
  0x60,				/* 27 -> 9 */
  0x00,				/* 28    n/a */
  0x00,				/* 29    n/a */
  0x00,				/* 30    n/a */
  0x00,				/* 31    n/a */
  0xa3,				/* 32 -> + */
  0xa2,				/* 33 -> 4 */
  0xa1,				/* 34 -> 5 */
  0xa0,				/* 35 -> 6 */
  0x00,				/* 36    n/a */
  0x00,				/* 37    n/a */
  0x00,				/* 38    n/a */
  0x00,				/* 39    n/a */
  0x73,				/* 40 -> x */
  0x72,				/* 41 -> 1 */
  0x71,				/* 42 -> 2 */
  0x70,				/* 43 -> 3 */
  0x00,				/* 44    n/a */
  0x00,				/* 45    n/a */
  0x00,				/* 46    n/a */
  0x00,				/* 45    n/a */
  0x93,				/* 48 -> / */
  0x92,				/* 49 -> 0 */
  0x91,				/* 50 -> . */
  0x90				/* 51 -> R/S */
};
  
#endif
#define _KEYBOARD_UPCO_H
