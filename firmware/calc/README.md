# Main calculator firmware

Compile using sdcc in z88dk per makefile.  Produces
`main-9000.hex` which must be loaded by some sort of bootloader
to `0x9000` in RAM.  (See bootloader elsewhere in the repository).

Some notes about the code:

Pure C with a bit of assembly for keyboard / display control.

Works great at 16MHz CPU clock with no wait states... within 20%
or so of original hardware speed.  Runs original HP-25 microcode
in an emulated version of the HP CPU.

Originally the code would also run under unix as a pure C application,
or under a Z80 emulator.  There are some lingering `#ifdef UNIX_TERM`
and such, but most of this code has been removed and it now works
only as a pure Z80 application on the target hardware.

## Serial Port Support

There is a very simple-minded serial port server included in the
calculator code.  It polls for a "break" condition on the serial port
and then expects to communicate at 19200 baud.  The purpose is to support
such things a saving/loading programs from a remote machine, and to
allow for cut/paste from the stack to the X11 clipboard.

Commands are as follows:

Command   | Description
-------   | -----------  
 `I    `  | Display location of stack, registers, program
 `S    `  | Display stack registers A,B,X,Y,Z,T,M1,M2
 `R    `  | Display storage registers R0-R7
 `P    `  | Display program storage
 `Mdddd`  | Write to storage registers
 `Qdddd`  | write to program storage
 `J    `  | Jump to monitor
 `0x91`   | Reboot (jump to 0)

After sending break, the calculator responds with `'>'`.
For the display commands (the first four above) 8 registers
with 14 hex digits each are displayed.  These correspond to
4 bits each digit from a 56-bit internal register, with
the most significant digit displayed first.

The display is terminated with a `'$'` character.

`I`

Displays 3 4-digit hex values, which correspond to the starting
memory address of the stack registers (beginning with `A`),
the storage registers and the program storage.

This information is only useful if you have a monitor program
loaded and can access the data directly.

`S`

The `S` command sends the stack, starting with register A.
A and B together control the display which is showing "7777.00"
in this example.

```
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

`R`

The `R` command sends the 8 storage registers.

In this example the registers contain various interesting constants
(e, pi...).

```
>R03141592654000                                                               
02718281828000                                                                  
01602176634981                                                                  
02997924580008                                                                  
06674300000989                                                                  
06626070150966                                                                  
01986445857975                                                                  
09192631770009                                                                  
$
```

`P`

The `P` command displays the program memory, which is organized
as 7 registers with 7 program steps (2 digits) each.

```
F6C1F1D5010000
00000000000000
00000000000000
00000000000000
00000000000000
00000000000000
00000000000000
```

The example above represents a simple counting program:

```
"31"       f6   1  : ENTR
"01"       c1   2  : 1
"51"       f1   3  : +
"14 74"    d5   4  : PSE
"13 01"    01   5  : GTO 01
"13 00"    00   6  : GTO 00
```

`M`

This command is used to overwrite the contents of the storage registers,
starting with `R0`.  The format of the data is a continuous stream of
hex digits exactly as displayed by the `R` command (but no line breaks).
Terminate the load either by sending exactly 14*8 characters, or sending
any control character to end.

`Q`

This command is used to overwrite the contents of the program memory.
It works the same way as the `M` command.  Typically one would use
the `load_prog` utility instead of doing this directly.

`J`

The `J` command allows transfer of control to a resident
monitor.  A simple monitor called `umon` is supplied in this repository.
One argument is passed in `HL` with the address of a data structure:

```
struct {
  uint16_t jump_to;		/* UMON jump address 0x8121 */
  uint16_t jump_back;		/* return address filled in by assembly */
  uint16_t regs;		/* address of registers */
  uint16_t ram;			/* address of RAM */
} reg_info;
```

`jump_to` is set to a constant 0x8121 which is the monitor entry point.

`jump_back` is the return address to restart the calculator.

`regs` is the address of the registers (first value from `I` command).

`ram` is the address of the `LastX` register which precedes the program
memory.

`0x91`

This is the first byte sent by the `load_firmware` utility and this
causes a jump to 0 to restart the EEPROM boot loader.  This will allow
new firmware to be loaded directly while the calculator is running
without needing to press the hardware reset button.
