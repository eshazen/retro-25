# UMON monitor

This is a very simple Z80 command line debugger/monitor used during
the bring-up of the calculator.  It might be useful for other purposes.
It is certainly full of bugs!

command (arguments)  |   description
-------------------  |   -----------
`d <addr> <count>      ` |   dump memory
`e <addr> <dd> <dd>... ` |   edit up to 16 bytes in memory
`o <addr> <val>        ` |   output <val> to port <addr>
`z <val>               ` |   set port zero value bits 0-6
`i <addr>              ` |   input from <addr> and display
`g <addr>              ` |   goto addr
`a <val1> <val2>       ` |   hex Arithmetic
`m <adr1> <adr2> <num> ` |   memory compare
`p <adr1> <adr2> <num> ` |   memory copy
`c                     ` |   return to calculator if possible
`b                     ` |   binary load
`r                     ` |   repeat last command
`k                     ` |   scan keyboard
`7 <addr>              ` |   update display from <addr>

By default the monitor is built with origin `8100H` with stack growing down
from the origin.  The monitor is small (1k or so) and comfortably fits below
the calculator code which is at `9000H`.  Both can be resident simultaneously.

Note that the calculator for historical reasons runs the serial port
at 4800 baud while the EEPROM serial boot loader and the calculator serial
interface are at 19200 baud.  This should be sorted out at some point, but
tuning the serial port speed usually requires getting out the oscilloscope.

Most commands are more or less self-explanatory.  A few may require
some further explanation:

`h` displays a set of calculator-style registers (if you know the address,
which you can find using the `I` protocol command

`k`

Scans the keyboard and displays a raw hex code.

`7`

Updates the display from 24 memory locations at the specified address.
The first byte is the character to display.  0 is blank, 1-a are digits 0-9
and values a-f are various special characters used to spell `Error` and `OF`.

Bit 6 causes a `-` to be displayed, while bit 7 causes a decimal point
after the digit.

