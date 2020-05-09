//
// HP-25 simulator
// irrelevant stuff stripped out
//

// #include <inttypes.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <z80.h>

#include "diskey.h"
#include "keyboard_upco.h"

// not sure if this is right!
#define __USE_RAM	32	// our highest model 33c has 32 units

static int global_display_enable = 1;

#include "rom_25.h"
#include "np25_hack_standalone.h"

static volatile uint8_t _pgm_run=1;

//________________________________________________________________________________

void flash_write(uint8_t bank, char *src, int cnt) {
  char buff[60];
  sprintf( buff, "flash_write( %d, ..., %d)\r\n", bank, cnt);
  putstr( buff);
#ifdef UNIX_TERM
  if( (fp = fopen( "flash.dat", "wb")) != NULL)
    fwrite( src, 1, cnt, fp);
  fclose( fp);
  dump_stack();
#endif  
}

void flash_read( uint8_t bank, char *dst, int cnt) {

  char buff[60];
  sprintf( buff, "flash_read( %d, ..., %d)\r\n", bank, cnt);
  putstr( buff);
#ifdef UNIX_TERM

  if( (fp = fopen( "flash.dat", "rb")) != NULL) {
    fread( dst, 1, cnt, fp);
    putstr("Read from flash\r\n");
    fclose( fp);
    dump_stack();
  }
  //  while (idx--) ((char*) act_reg->ram)[idx+RAM_OFFSET] = *((char*) (0x1040+idx));
  
#endif  
}


  //________________________________________________________________________________
  int main() {

#ifndef Z80
  set_conio_terminal_mode();
#endif
  
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

#ifdef UPCO
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
      
#else
  while (!done) {
    if (kbhit()) {
      c = getch();

      switch (c) {
      case ']':
	dump_stack();
	break;
      case 27: 			/* exit on ESC */
	done = 1; 
	// just save everything
	flash_write(0, (char*)&_act_reg, sizeof( _act_reg));
	break;
      case '\\': 		/* Power cycle on '\' */
	putstr("Power cycle\r\n");
	woodstock_new_processor();
	_pgm_run = 0;
	break;
      case '=':			/* pgm/run on "=" */
	woodstock_set_ext_flag (3, _pgm_run ^= 1);		// pgm-run toggle
	//	if (_pgm_run) flash_write(0xfc00, (char*)_act_reg.ram, WSIZE*__USE_RAM);
	break;
      default:
	if ( translate_key(c)) {
	  woodstock_press_key( translate_key(c));
	  //	  release_in = 10;
	  release_in = 5;	  
	}//if
	break;
      }//switch
      c = 0;
    }//if
    if (!woodstock_execute_instruction()) break;
    if (release_in) {
      if (release_in == 1) woodstock_release_key();
      release_in--;
    }//if
    //    usleep(300);
  }//while
#endif
    

  return 0;

}
