#
# build for real hardware, origin 0x9000
# two targets for VFD and LED display
# currently only differences are in np25_hack_standalone.h, selected
# by preprocessor define "VFD"
#

all:
	@echo "'make vfd' or 'make led'"

vfd: main-vfd.hex

led: main-led.hex

DEFINES = -DONLY_REG_T -DZ80PACK -DZ80 -DUPCO -DUMON_SERVER
CFLAGS = +z80 --list $(DEFINES) -clib=sdcc_iy

SOURCES = main.c np25_hack_standalone.h key_translate.h diskey.h

main_vfd.o: $(SOURCES)
	zcc $(CFLAGS) -DVFD -c main.c -pragma-define:CRT_ORG_CODE=0x9000

main_led.o: $(SOURCES)
	zcc $(CFLAGS) -c main.c -pragma-define:CRT_ORG_CODE=0x9000

vfd_control.o: vfd_control.c vfd_control.h
	zcc $(CFLAGS) -c vfd_control.c -pragma-define:CRT_ORG_CODE=0x9000

diskey_sw_vfd.o: diskey_sw_vfd.asm
	z80asm diskey_sw_vfd.asm

main_vfd.bin: main_vfd.o diskey_sw_vfd.o vfd_control.o
	zcc +z80 -m -O3 -startup=1 -clib=sdcc_iy \
	main.o diskey_sw_vfd.o vfd_control.o \
        -o main_vfd -lm -create-app -startup=0 -pragma-define:CRT_ORG_CODE=0x9000

main_led.bin: main_led.o diskey_sw_vfd.o
	zcc +z80 -m -O3 -startup=1 -clib=sdcc_iy main.o diskey_sw_vfd.o \
        -o main_led -lm -create-app -startup=0 -pragma-define:CRT_ORG_CODE=0x9000

main-vfd.hex: main_vfd.bin
	srec_cat main_vfd.bin -binary -offset 0x9000 -o main-vfd.hex -intel

main-led.hex: main_led.bin
	srec_cat main_led.bin -binary -offset 0x9000 -o main-led.hex -intel

clean:
	rm -f *~ *.o *.lst *.sym *.ihx *.lk *.map *.rel *.bin *.def *.lis
