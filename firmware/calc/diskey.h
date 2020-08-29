#ifndef _DISKEY_H
#define _DISKEY_H
//
// hardware keyboard/display function interface
// declarations for assembly functions in diskey_sw.asm
//
void vfd_display( unsigned char* hl) __z88dk_fastcall;
void vfd_set_state( unsigned char hl) __z88dk_fastcall;
void vfd_clr_state( unsigned char hl) __z88dk_fastcall;
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

// control codes to set in vfd_state
#define VFD_CTRL_BLANK 8
#define VFD_CTRL_FIL 0x20
#define VFD_CTRL_HV 0x10

#endif
