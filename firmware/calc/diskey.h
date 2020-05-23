#ifndef _DISKEY_H
//
// hardware keyboard/display function interface
// declarations for assembly functions in diskey_sw.asm
//
void umon_display( unsigned char* hl) __z88dk_fastcall;
void umon_hex( unsigned char* hl) __z88dk_fastcall;
int umon_kbscan()  __z88dk_fastcall;
int umon_kbuff()  __z88dk_fastcall;
int umon_switches()  __z88dk_fastcall;
void umon_blank()  __z88dk_fastcall;
#define _DISKEY_H
#endif
