/*

Eric Hazen May 2020

Based on Eric Smith's work, and Chris Chung's "Nonpariel Physical"

$Id: proc_woodstock.h 686 2005-05-26 09:06:45Z eric $
Copyright 1995, 2003, 2004, 2005 Eric L. Smith <eric@brouhaha.com>

Nonpareil is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License version 2 as
published by the Free Software Foundation.  Note that I am not
granting permission to redistribute or modify Nonpareil under the
terms of any later version of the General Public License.

Nonpareil is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program (in the file "COPYING"); if not, write to the
Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston,
MA 02111, USA.
*/


//
// This is the main program for the Retro-25 calculator
// 

#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

#include <z80.h>

#include "diskey.h"
#include "key_translate.h"

// not sure if this is right!
#define __USE_RAM	32	// our highest model 33c has 32 units

// flag to turn display on and off with "power" switch
// <FIXME> currently requires a keypress before it is recognized
static int global_display_enable = 1;

#include "rom_25.h"

// for historical reasons most of the code is in here...
#include "np25_hack_standalone.h"

#ifdef UMON_SERVER
void umon_crlf() {
  umon_putc( '\r');
  umon_putc( '\n');	  
}

// receive char as hex
uint8_t umon_tohex1( uint8_t ch) {
  if( isdigit(ch))
    return ch-'0';
  else if( isxdigit(ch))
    return toupper(ch)-'A'+10;
  else
    return 0;
}

// read 4 hex characters
uint16_t umon_ghex4() {
  uint16_t v = 0;
  for( uint8_t i=0; i<4; i++)
    v = (v << 4) | umon_tohex1( umon_getc());
  return v;
}

// send low nibble as hex character
void umon_phex1( uint8_t v) {
  v &= 15;
  if( v < 10)
    umon_putc( v + '0');
  else
    umon_putc( v - 10 + 'A');
}

// send 16-bit hex value
void umon_phex4( uint16_t v) {
  umon_phex1( (v >> 12));
  umon_phex1( (v >> 8));
  umon_phex1( (v >> 4));
  umon_phex1( v);
}

// some info to help locate things in assembly
struct {
  uint16_t jump_to;		/* UMON jump address 0x8121 */
  uint16_t jump_back;		/* return address filled in by assembly */
  uint16_t regs;		/* address of registers */
  uint16_t ram;			/* address of RAM */
} reg_info;
#endif


static volatile uint8_t _pgm_run=1;

//________________________________________________________________________________

void flash_write(uint8_t bank, char *src, int cnt) {
  //  char buff[60];
  //  sprintf( buff, "flash_write( %d, ..., %d)\r\n", bank, cnt);
  //  putstr( buff);
}

void flash_read( uint8_t bank, char *dst, int cnt) {

  //  char buff[60];
  //  sprintf( buff, "flash_read( %d, ..., %d)\r\n", bank, cnt);
  //  putstr( buff);
}


  //________________________________________________________________________________
  int main() {

#define RAM_OFFSET	(7*9)
#define RAM_SIZE	(7*7)		// 49 program steps

  woodstock_clear_memory();
  woodstock_set_rom( 2);
  woodstock_new_processor();

#ifdef UNIX_TERM
  //______ load from flash, we just need the status config, but we load everything since
  //       we might need to write it back and flash always write in full blocks
  uint8_t idx = RAM_SIZE + 1 + 12;	// 49 program steps + config byte + 12 byte greeting

  // try to load from flash / file?
  flash_read(0xfc00, (char*)&_act_reg, sizeof( _act_reg));

  printf("Sizeof( _act_reg) = %d\n", sizeof( _act_reg));

#endif

  uint8_t done=0;
  uint8_t c=0;
  uint8_t release_in=0;
  uint16_t key=0;

  uint16_t switches;
  uint16_t last_sw;

  uint16_t chr;
  unsigned char *adrs;
  uint8_t nregs;
  uint8_t rw;
  uint8_t stop;

  woodstock_set_ext_flag (3, _pgm_run);		// set run mode

#ifdef UMON_SERVER
  reg_info.jump_to = 0x8121;
  reg_info.jump_back = 0x9000;
  reg_info.regs = (uint16_t) & _act_reg;
  reg_info.ram = (uint16_t) & _act_reg.ram;
#endif
  
  while(1) {
    if( umon_serial()) {	/* check for serial action (break) */
      while( umon_serial())	/* wait for break to end */
	;
#ifdef UMON_SERVER
      umon_putc( '>');		/* send a prompt */
      chr = umon_getc();
      umon_putc( chr);		/* echo char */
      rw = 0;			/* default:  read */
      stop = 0;			/* flag to exit loops */
      nregs = 8;		/* default number of registers */
      adrs = 0;			/* default: invalid address */
      /*
       * commands:  S,R,P  - read stack, regs, program
       *              M,Q  - write regs, program
       */
      switch( toupper( chr)) {
      case 'J':
	umon_jump( (uint16_t) &reg_info);	/* jump to umon state saver */
	break;
      case 'I':			/* get addresses */
	umon_phex4( (uint16_t) &_act_reg);
	umon_crlf();
	umon_phex4( (uint16_t) &_act_reg.ram);
	umon_crlf();
	umon_phex4( (uint16_t) &_act_reg.ram + 14*9);
	umon_crlf();
	break;
      case 'S':			/* read stack */
	adrs = (unsigned char *) &_act_reg;
	break;
      case 'M':			/* write memories */
	rw = 1;
      case 'R':			/* read memories */
	adrs = (unsigned char *) &_act_reg.ram;
	break;
      case 'Q':			/* write PGM */
	rw = 1;
      case 'P':			/* read PGM */
	nregs = 7;		/* PGM is only 7 regs */
	adrs = (unsigned char *) &_act_reg.ram + 14*9;
      }
      
      if( adrs) {
	for( uint8_t i=0; i<nregs; i++) {
	  adrs += 14;
	  for( uint8_t k=0; k<14; k++) {
	    --adrs;
	    if( rw) {		/* writing */
	      chr = umon_getc(); /* get a char */
	      umon_putc( chr);	 /* echo back */
	      if( iscntrl(chr)) { /* bail out if control */
		stop = 1;
		break;
	      } else {		/* cvt from hex and write */
		*adrs = umon_tohex1( chr);
	      }
	    } else {		/* reading */
	      umon_phex1( *adrs);
	    }
	  }
	  adrs += 14;
	  if( !rw) umon_crlf();
	  if( stop) break;
	}
	umon_putc( '$');
      } else {
	umon_putc( '?');
      }
#endif      

#ifdef UMON_JUMP
      umon_jump( (uint16_t) &reg_info);	/* jump to umon state saver */
#endif
    }

    key = umon_kbscan();
    
    if( key)
      woodstock_press_key( translate_key(key & 0xff));
    else
      woodstock_release_key();
    

    switches = umon_switches();

    // handle PGM/RUN switch
    woodstock_set_ext_flag (3, switches & 1);

    // power switch just controls display for now
    global_display_enable = switches & 2;

    last_sw = switches;
    if (!woodstock_execute_instruction()) break;

  }
  return 0;

}
