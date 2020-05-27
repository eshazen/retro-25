//
// Load a program over serial port to Retro-25
// 
// usage:  load_prog <port> P|R <hex_string>
// e.g.    load_prog /dev/ttyUSB0 P `cat program.hex`
//         where "program.hex" was output by asm25.pl
//

#define DEBUG

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <strings.h>
#include <unistd.h>
#include <ctype.h>

#include "sio_cmd.h"

static int fd;

int main( int argc, char*argv[] )
{
  if( argc < 3) {
    printf("usage:  load_prog <port> P|R <hex_string>\n");
    exit(1);
  }

  char *port = argv[1];
  char *cmd = argv[2];
  char *hex = argv[3];
  char ch;

  if( (fd = sio_open( port, B19200)) < 0) {
    printf("Error opening serial port %s\n", port);
    exit( 1);
  }

  flush( fd);

  int nc = 0;

  if( toupper( *cmd) == 'P') {
    printf( "Programming...\n");
    send_break( fd);
    expect( fd, '>', "looking for > prompt");
    send( fd, 'Q');
    expect( fd, 'Q', "echo Q command");

    for( int i=0; i<strlen( hex); i++) {
      if( isxdigit( hex[i])) {
	putchar( hex[i]);
	fflush( stdout);
	send( fd, hex[i]);
	expect( fd, hex[i], "echo hex char");
	++nc;
      }
    }
    if( nc < 14*7) {
      send( fd, 0xd);
      expect( fd, 0xd, "echo 0xd");
    }
    expect( fd, '$', "terminating $");
  }

  printf("\n\nReading...\n");

  // read back
  send_break( fd);
  expect( fd, '>', "looking for > prompt");
  send( fd, 'P');
  expect( fd, 'P', "echo P command");

  // read to $
  do {
    ch = receive( fd);
    putchar( ch);
  } while( ch != '$');


}
