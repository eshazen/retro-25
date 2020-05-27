/* sio_cmd.c - support library for command-driven serial communications
 *
 * sio_open()           -  open serial port and set mode
 * sio_open_trace()     -  ditto, with trace file
 * sio_cmd()            -  send a command, retrieve response
 */


#define DEBUG

#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <termios.h>
#include <stdio.h>
#include <ctype.h>
#include <unistd.h>
#include <strings.h>
#include <string.h>
#include <stdlib.h>
        
#include "sio_cmd.h"

static FILE *tfp = NULL;

void send( int fd, unsigned char ch) {
  unsigned char sch;

  sch = ch;
  //send start char
  write( fd, &sch, 1);
}


void flush( int fd) {
  char rch;
  int res;
  
  do {
    res = read( fd, &rch, 1);
  } while( res > 0);
}


uint8_t receive( int fd) {
  int res;
  unsigned char rch;

  do {
    res = read( fd, &rch, 1);
  } while( res != 1);

  return rch;
}

void expect( int fd, unsigned char ch, char *msg) {
  uint8_t rch;

  rch = receive( fd);
  
  if( rch != ch) {
    printf("Error, expected 0x%02x, got 0x%02x\n", ch, rch);
    printf("While sending: %s\n", msg);
    exit( 1);
  }
}





/*
 * send break for 0.25-0.5s
 */
void send_break( int fd)
{
  tcsendbreak(fd,0);
}


/*
 * open <dev>     (/dev/ttySxx port) for serial I/O
 * open <tracef>  for ascii trace dump of serial comm's
 * return fd or -1 on error
 */

int sio_open_trace( char *dev, char *tracef, speed_t baud) {
  int fd;

  if( (fd = sio_open( dev, baud)) < 0)
    return fd;

  if( (tfp = fopen( tracef, "w")) == NULL) {
    close( fd);
    return -1;
  }

  return fd;
}
    


/*
 * open <dev>     (/dev/ttySxx port) for serial I/O
 * return fd or -1 on error
 */
int sio_open( char *dev, speed_t baud) {

  struct termios oldtio,newtio;
  int fd;
        
  /* open device for non-blocking I/O */
  fd = open(dev, O_RDWR | O_NOCTTY);
  //  fd = open(MODEMDEVICE, O_RDWR | O_NOCTTY | O_NONBLOCK); 
  if (fd <0) {
    perror(dev);
    return( -1);
  }
        
  tcgetattr(fd,&oldtio); /* save current port settings */
        
  bzero(&newtio, sizeof(newtio));

  /* set baud rate, 8 bits, no modem control, enable reading */
  newtio.c_cflag = baud | CS8 | CLOCAL | CREAD;
  newtio.c_iflag = 0;   /* raw input */
  newtio.c_oflag = 0;   /* raw output */
        
  /* set input mode (non-canonical, no echo,...) */
  newtio.c_lflag = 0;
         
  /* flush the line and activate new settings */
  tcflush(fd, TCIFLUSH);
  tcsetattr(fd,TCSANOW,&newtio);

  return fd;
}


//
// Send a command string to board, wait for return string terminated by '>'
// Return pointer to static buffer containing return string or NULL on error
//
char *sio_cmd( int fd, char *s)
{
  char cmd;
  int i, res, nc;
  char rch, *p;

  static char buf[SIO_BUF_MAX];

  if( strlen(s) == 0) return NULL;

  // strip any trailing control chars
  for( p = s+strlen(s)-1; iscntrl(*p); --p)
    *p = '\0';
  
  // send the string, followed by \r
  write( fd, s, strlen(s));
  cmd = '\r';
  write( fd, &cmd, 1);

  // if tracing, output the sent string
  if( tfp)
    fprintf( tfp, "Send: %s\n", s);

  //  usleep( 500000);

  // read until we see the prompt
  rch = ' ';
  nc = 0;
  do {
    res = read( fd, &rch, 1);
    if( res == 1) {
      buf[nc++] = rch;
    }
    if( nc == SIO_BUF_MAX) {
      printf("BUffer overflow!\n");
      exit( 1);
    }
  } while( rch != '>');
  buf[nc++] = '\0';


  // if tracing, format the received string, taking special care
  // of control characters
  if( tfp) {
    fprintf( tfp, "Recv: ");
    for( i=0; i<nc; i++) {
      if( !iscntrl( buf[i]))
	putc( buf[i], tfp);
      else {
	switch( buf[i]) {
	case '\r':
	case '\n':
	  fprintf( tfp, "\n      ");
	  break;
	case '\0':
	  break;
	default:
	  fprintf( tfp, "?[%02x]", buf[i]);
	}
      }
    }
    fprintf( tfp, "\n");
  }

  if( rch > 0)
    return( buf);
  else
    return( NULL);
}



// dump a string in hex for debug

void dump_string( char *s)
{
  char *p;

  for( p=s; *p; ++p) {
    printf("[%02x] '%c'\n", *p, *p<0x20 ? '-' : *p);
  }
}
