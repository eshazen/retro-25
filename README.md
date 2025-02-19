# retro-25
Retro-tech HP-25 calculator clones using Z80

<img src=https://github.com/eshazen/retro-25/blob/master/talks/HCC2020/figs/all3_800.jpg width=600>

<table>
  <tr><td><img src=https://github.com/eshazen/retro-25/blob/master/photos/quarter.jpg width=200>
      <td><img src=https://github.com/eshazen/retro-25/blob/master/photos/real_vs_retro.jpg width=200>
      <td><img src=https://github.com/eshazen/retro-25/blob/master/photos/boards.jpg width=200>
</table>

## News!

**2023-01-02**

This is **branch "ScopeClock"**.  Building up another CPU board for used as a general purpose computer for the scope clock, along with the DAC/Interface board from that project, which (whew!) has an actual UART for the serial port.

**2021-01-01**

Time for something new!  The VFD HP-25 is cool and all, but I've lusted after an HP-97 most of my life, plus I love nixie tubes!  Starting to think about a nixie-display HP-97 emulator.  Probably no card reader, but a small printer is certainly doable.  Inspiration from Oliver De Smet (archived elswhere in this repository just in case):

* https://www.hpmuseum.org/cgi-sys/cgiwrap/hpmuseum/archv020.cgi?read=204526
* https://sites.google.com/site/olivier2smet2/hp_projects/hp97

**2020-10-10**

I gave a talk at the HPCC 2020 conference on these calculators.  You can see my slides here:
http://www.hpcc.org/conferences/HPCC2020/HPCC2020_04_Retro_25_revC.pdf

Built a new version with VFD display tubes!

<img src="https://github.com/eshazen/retro-25/blob/master/photos/display_11.jpg" width=300>
See <a href="https://github.com/eshazen/retro-25/tree/master/notes/VFD-Display">notes</a>.

## What's here

`hardware` has the design files for the CPU and keyboard/display boards

* `firmware/bootloader` has a small serial/flash bootloader which should be programmed at $0000
* `firmware/calc` has the main calculator operating firmware
* `firmware/umon` has a simple Z80 monitor I wrote for debugging
* `firmware/basic` has a hacked version of MS BASIC (4K integer version from 1978)
* `util` has some utility software, including: firmware loader, program loader, stack/register clip utility, simple assembler for HP-25 programs, and some template and example programs

## Hardware
The hardware consists of two boards, a CPU board and an LED+display board.


### CPU board ECOs (mistakes!)

* D2 in the reset circuit - silkscreen is backwards
* U1 pin 11 must be wired to J17 pin 11
* BUSRQ should be tied high or pulled up.  Solder a 1k resistor (or just a wire) from the Z80 (U3) pin 25 to +5V

Also, recommend to cut the trace to nWE on the EEPROM (U4, pin 27) and wire from pin 27 to pin 28.  This disables writing to the EEPROM.  Not essential, but I recommend programming the EEPROM separately in a programmer.  Rogue code can easily wear out the EEPROM (as I found the hard way!) if writing is enabled.  You have been warned.

### Memory and I/O map

The memory map is very simple:

```
EEPROM | 0000-7FFF
RAM    | 8000-FFFF
```
There are six decoded I/O ports:

port | name          | bits  | description
--- | -------------  | ----- | ---------
00 | KB (write only) | bit 0 | KB column 1
"   | "                | bit 1 | KB column 2
"   | "                | bit 2 | KB column 3
"   | "                | bit 3 | KB column 4
"   | "                | bit 4 | KB column 5 and switches
"   | "                | bit 5 | -not used-
"   | "                | bit 6 | LED on CPU board
"   | "                | bit 7 | Serial output
40 | Digits 0-7      | bits 0-7 | ICM7218 display data
41 | Digits 0-7      | bits 0-7 | ICM7218 control data
80 | KB (read only)  | bit 0 | KB row 1
"   | "                | bit 1 | KB row 2
"   | "                | bit 2 | KB row 3
"   | "                | bit 3 | KB row 4
"   | "                | bit 4 | KB row 5
"   | "                | bit 5 | KB row 6
"   | "                | bit 6 | KB row 7
"   | "                | bit 7 | Serial input
c0 | Digits 8-11     | bits 0-7 | ICM7218 display data
c1 | Digits 8-11     | bits 0-7 | ICM7218 control data

All ports except `80` are write-only; port `80` is read-only.

A bit-banged serial port using an FTDI USB adapter is provided
as bit 7 of ports `00` and `80`.  Note that these ports share
keyboard scanning functions, so the code must be carefully written
if both functions are used simultaneously.

There are no interrupts.


## Firmware

See `firmware/calc` for calculator operating program

See `util` for assembler and loader utilities

