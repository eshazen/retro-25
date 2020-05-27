# Main calculator firmware

Compile using sdcc in z88dk per makefile.  Produces
`main-9000.hex` which must be loaded by some sort of bootloader
to `0x9000` in RAM.

Some notes about the code:

Pure C with a bit of assembly for keyboard / display control.

Works great at 16MHz CPU clock with no wait states... within 20%
or so of original hardware speed.

Originally the code would also run under unix as a pure C application,
or under a Z80 emulator.  There are some lingering `#ifdef UNIX_TERM`
and such, but most of this code has been removed and it now works
only as a pure Z80 application on the target hardware.

## Serial Port Support

There is a very simple-minded serial port server included in the
calculator code.  It polls for a "break" condition on the serial port
and then expects to communicate at 19200 baud.  Commands are as follows:

Command   | Description
-------   | -----------  
 `I    `  | Display location of stack, registers, program
 `S    `  | Display stack registers A,B,X,Y,Z,T,M1,M2
 `R    `  | Display storage registers R0-R7
 `P    `  | Display program storage
 `Mdddd`  | Write to storage registers
 `Qdddd`  | write to program storage
 `J    `  | Jump to monitor

`I`

Displays 3 4-digit hex values, which correspond to the starting
memory address of the stack registers (beginning with `A`),
the storage registers and the program storage.

This information is only useful if you have a monitor program
loaded and can access the data directly.

```
S

s0777700FFFFFFF                                                               
20001000000000                                                                  
07777000000003                                                                  
07777000000003                                                                  
01010000000003                                                                  
01111000000003                                                                  
20000000005202                                                                  
07777000000003                                                                  
$
```

The `S` command sends the stack, starting with register A.
A and B together control the display which is showing "7777.00"
in this example.

