//
// I/O support (temporary)
//
// define Z80PACK for simulator I/O on ports 1,2
// define UNIX_TERM for unix terminal I/O
//



#ifdef Z80PACK
#include <z80.h>
#endif

#include <stdint.h>
#include "keyboard.h"

uint8_t translate_key( uint8_t asc)
{
  for( uint8_t i=0; key_translate[2*i]; i++)
    if( key_translate[2*i] == asc)
      return( key_translate[2*i+1]);
  return 0;
}


#ifdef UNIX_TERM

#include <string.h>
#include <stdlib.h>

#include <unistd.h>
#include <sys/select.h>
#include <termios.h>


struct termios orig_termios;

void reset_terminal_mode() {
  tcsetattr(0, TCSANOW, &orig_termios);
}

void set_conio_terminal_mode() {
  struct termios new_termios;

  /* take two copies - one for now, one for later */
  tcgetattr(0, &orig_termios);
  memcpy(&new_termios, &orig_termios, sizeof(new_termios));

  /* register cleanup handler, and set the new terminal mode */
  atexit(reset_terminal_mode);
  cfmakeraw(&new_termios);
  tcsetattr(0, TCSANOW, &new_termios);
}

int kbhit() {
  struct timeval tv = { 0L, 0L };
  fd_set fds;
  FD_ZERO(&fds);
  FD_SET(0, &fds);
  return select(1, &fds, NULL, NULL, &tv);
}

int getch() {
  int r;
  unsigned char c;
  if ((r = read(0, &c, sizeof(c))) < 0) {
    return r;
  } else {
    return c;
  }
}

void putch( char c) {
  putchar( c);
}

void putstr( char *s) {
  while( *s)
    putch( *s++);
}

void crlf() {
  putchar('\r');
  putchar('\n');
}

#else


// replace with hardware keyboard input test
void reset_terminal_mode() { }
void set_conio_terminal_mode() { }

#ifdef Z80PACK

int kbhit() {
  return z80_inp(2);
}

int getch() {
  return z80_inp(1);
}

void putch( char c) {
  z80_outp(1, c);
}

void putstr( char *s) {
  while( *s)
    putch( *s++);
}

void crlf() {
  putch('\r');
  putch('\n');
}

#else

// dummy functions for later

int kbhit() {
  return 0;
}

int getch() {
  return -1;
}
#endif

#endif
