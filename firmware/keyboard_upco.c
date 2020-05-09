
#include "umon.h"
#include "keyboard_upco.h"
#include "diskey.h"

void putch( char c)    __z88dk_fastcall
{
    __asm
    jp  UMON_putch
    __endasm;
}

void putstr( char *s)    __z88dk_fastcall
{
    __asm
    jp  UMON_puts
    __endasm;
}

void crlf()    __z88dk_fastcall
{
    __asm
    jp UMON_crlf
    __endasm;
}

