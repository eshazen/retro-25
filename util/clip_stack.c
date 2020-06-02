//
// read retro-25 registers to X11 clipboard
//

// #define DEBUG

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <strings.h>
#include <unistd.h>
#include <ctype.h>

#include "sio_cmd.h"

static int fd;

#define BUFR 256

char* decode_reg( char *p)
{
  static char res[20];
  char *r = res;
  // null-terminate the string
  char *s;
  for( s=p; !iscntrl(*s); s++)
    ;
  *s = '\0';
#ifdef DEBUG
  printf("RAW: %s\n", p);
#endif
  if( p[0] == '9')		/* first is the sign */
    *r++ = '-';
  // now output the digits with the decimal after the first
  *r++ = p[1];
  *r++ = '.';
  for( int i=0; i<9; i++)
    *r++ = p[2+i];
  *r++ = 'E';
  int expo = (p[12]-'0')*10 + (p[13]-'0');
#ifdef DEBUG
  printf("Expo = %d\n", expo);
#endif  
  if( p[11] == '9') {
    *r++ = '-';
    *r++ = (100-expo)/10 + '0';
    *r++ = (100-expo)%10 + '0';
  } else {
    *r++ = '+';
    *r++ = p[12];
    *r++ = p[13];
  }
  *r++ = '\0';
  return res;
}

int main( int argc, char*argv[] )
{
  char *port = "/dev/ttyUSB0";
  char *reg = argv[1];
  char *regs = "XYZTR";
  char *p;
  char cmd;
  char ch;
  int offset;
  char buff[BUFR];

  if( (fd = sio_open( port, B19200)) < 0) {
    printf("Error opening serial port %s\n", port);
    exit( 1);
  }

  // a digit 1-4 works too for X-T
  if( argc < 2) {
    cmd = 'S';
    offset = 2;
  } else if( isdigit( *reg)) {
    cmd = 'S';
    offset = 1+*reg-'0';
  } else if( (p = index( regs, toupper(*reg)))) {
    if( p-regs < 4) {		/* stack register */
      cmd = 'S';
      offset = 2+p-regs;		/* offset is 2 for X etc */
    } else {
      cmd = 'R';
      if( !isdigit( reg[1])) {
	printf("Expecting digit 0-7 in %s\n", reg);
	exit(1);
      }
      offset = reg[1] - '0';
    }
  }

#ifdef DEBUG
  printf("cmd = '%c' offset = %d\n", cmd, offset);
#endif  

  flush( fd);

  send_break( fd);
  expect( fd, '>', "looking for > prompt");

  send( fd, cmd);
  expect( fd, cmd, "echo command");

  p = buff;

  do {
    ch = receive( fd);
#ifdef DEBUG
    //    printf("RX char: '%c'\n", ch);
#endif    
    if( ch == '$')
      *p++ = '\0';
    else
      *p++ = ch;
    if( p-buff >= BUFR) {
      printf("Buffer overflow receiving data!\n");
      exit( 1);
    }
    //    putchar( ch);
  } while( ch != '$');

  // now parse the buffer and display
  p = buff;
  if( !offset) {
    p = decode_reg( buff);
  } else {
    // skip past <offset> newlines
#ifdef DEBUG
    printf("Skipping %d newlines\n", offset);
#endif    
    while( offset--) {
      while( !iscntrl( *p))
	++p;
      while( iscntrl( *p))
	++p;
    }
    p = decode_reg( p);
  }
  //  sprintf( buff, "/usr/bin/echo \"%s\"|/usr/bin/xclip -r", p);
  //  system( buff);
  printf("%s", p);
}

