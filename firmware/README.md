# Firmware for Retro-25 calculator

`calc/`

calculator firmware - build with "make" - produces `main-9000.hex`

`bootloader/`

boot loader - build with `zmac ser_19200_boot.asm`

Create EEPROM image with:

```
$ srec_cat ser_19200_boot.hex -Intel main-9000.hex -Intel \
  -Offset -32768 -Output eeprom.hex -Intel
```

This will merge the main calculator code (built to execute
at 0x9000) and move it to 0x1000 in the flash, where the bootloader
expects to see it.

Then use your favorite EEPROM programmer to program the file
eeprom.hex starting at offset 0 and you should be good to go.

