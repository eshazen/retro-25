all: flash_vfd.hex flash_led.hex

zout/ser_19200_boot.hex: ser_19200_boot.asm
	zmac ser_19200_boot.asm

flash_vfd.hex: zout/ser_19200_boot.hex ../umon/zout/umon_8100H.hex ../calc/main-vfd.hex
	srec_cat zout/ser_19200_boot.hex -Intel \
	../calc/main-vfd.hex -Intel -Offset -32768 \
	../umon/zout/umon_8100H.hex -Intel -Offset -12544 \
	-Output eeprom-vfd.hex -Intel

flash_led.hex: zout/ser_19200_boot.hex ../umon/zout/umon_8100H.hex ../calc/main-led.hex
	srec_cat zout/ser_19200_boot.hex -Intel \
	../calc/main-led.hex -Intel -Offset -32768 \
	../umon/zout/umon_8100H.hex -Intel -Offset -12544 \
	-Output eeprom-led.hex -Intel
