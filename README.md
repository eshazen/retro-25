<img src=https://github.com/eshazen/retro-25/blob/master/photos/quarter.jpg width=300>

# retro-25
Retro-tech HP-25 calculator clone using Z80

## Hardware
The hardware consists of two boards, a CPU board and an LED+display board.  There are a few mistakes in the RevA/Rev1 boards:

### CPU board ECOs
* D2 in the reset circuit - silkscreen is backwards
* U1 pin 11 must be wired to J17 pin 11
* BUSRQ should be tied high or pulled up.  Solder a 1k resistor (or just a wire) from the Z80 (U3) pin 25 to +5V

Also, recommend to cut the trace to nWE on the EEPROM (U4, pin 27) and wire from pin 27 to pin 28.  This disables writing to the EEPROM.  Not essential, but I recommend programming the EEPROM separately in a programmer.  Rogue code can easily wear out the EEPROM (as I found the hard way!) if writing is enabled.  You have been warned.

## Firmware

See firmware/calc for calculator operating program

See firmware/bootloader for boot loader supporting serial download and EEPROM load
