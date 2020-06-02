# Utility software

This folder contains some utility software which runs on a PC connected to the Retro-25.

## Assembler

`asm25.pl` is a simple assembler for HP-25 code.  It reads input files like this:

```
#
# very simple example:  count by 1's
#
count.txt
 1  : ENTR
 2  : 1
 3  : +
 4  : PSE
 5  : GTO 01
 6  : GTO 00     # always end with GTO 00
```

It produces a listing file:

```
count.lst
"31"       f6   1  : ENTR
"01"       c1   2  : 1
"51"       f1   3  : +
"14 74"    d5   4  : PSE
"13 01"    01   5  : GTO 01
"13 00"    00   6  : GTO 00
"13 00"    00   7  : GTO 00
```

And a hex file
```
f6c1f1d5010000
```

## Program Loader

`load_prog.c` is a C program to load HP-25 programs assembled with `asm25.pl` to the calculator.  For example:

```
  $ ./load_prog /dev/ttyUSB0 P `cat count.hex`
```

## Firmware Loader

`load_firmware.c` is a C program to overwrite the operating firmware
in the calculator with a new version.  Note that at the moment there
is no ability to program the flash, so this is temporary until the next power-cycle, at which
point the calculator will revert to the EEPROM version.

```
  # (push reset button, then within ~10 sec:)
  $ ./load_firmware ../firmware/calc/main-9000.hex /dev/ttyUSB0
```

The loader assumes that a bootloader like `ser_19200_boot.asm` is running and has been put in the 
boot state by pressing reset.  It would be sensible to include the serial bootloader in the calculator code itself,
but I haven't gotten around to this yet.
