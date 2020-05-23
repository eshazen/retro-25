Working version pushed to github on 2020-05-23

Compile using sdcc in z88dk per makefile.  Produces
main-9000.hex which must be loaded by some sort of bootloader
to 0x9000 in RAM.

Some notes about the code:

Pure C with a bit of assembly for keyboard / display control.

Works great at 16MHz CPU clock with no wait states... within 20%
or so of original hardware speed.

Originally the code would also run under unix as a pure C application,
or under a Z80 emulator.  There are some lingering #ifdef UNIX_TERM
and such, but most of this code has been removed and it now works
only as a pure Z80 application on the target hardware.

