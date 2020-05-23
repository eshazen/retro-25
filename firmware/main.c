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

  woodstock_set_ext_flag (3, _pgm_run);		// set run mode

  while(1) {
    if( key = umon_kbscan() )
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
