Working version as of 3/23/20 or so
Compile using sdcc in z88dk per makefile.

A bit of assembly for keyboard / display control.

Works great at 16MHz CPU clock (run from RAM).

Expects a bootloader of some sort in EEPROM to copy code
to RAM at specified target address (normally 0x9000).
