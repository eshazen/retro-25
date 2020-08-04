#ifndef _DISKEY_H
//
// hardware keyboard/display function interface
// declarations for assembly functions in diskey_sw.asm
//
void vfd_display( unsigned char* hl) __z88dk_fastcall;
void vfd_init()  __z88dk_fastcall;
void umon_display( unsigned char* hl) __z88dk_fastcall;
void umon_hex( unsigned char* hl) __z88dk_fastcall;
int umon_kbscan()  __z88dk_fastcall;
int umon_kbuff()  __z88dk_fastcall;   // (not currently used)
int umon_switches()  __z88dk_fastcall;
int umon_serial()  __z88dk_fastcall;
void umon_blank()  __z88dk_fastcall;
int umon_getc()  __z88dk_fastcall;
void umon_putc( unsigned char hl)  __z88dk_fastcall;
void umon_jump( unsigned int hl)  __z88dk_fastcall;
#define _DISKEY_H
#endif
