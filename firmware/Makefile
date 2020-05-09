#
# build for real hardware, origin 0x9000
#

all: main-9000.hex

DEFINES = -DONLY_REG_T -DZ80PACK -DZ80 -DUPCO
CFLAGS = +z80 --list $(DEFINES) -clib=sdcc_iy

diskey.o: diskey.asm
	z80asm diskey.asm

diskey_sw.o: diskey_sw.asm
	z80asm diskey_sw.asm

diskey_test.o: diskey_test.c diskey.h
	zcc $(CFLAGS) -c diskey_test.c -pragma-define:CRT_ORG_CODE=0x9000

main.o: main.c np25_hack_standalone.h keyboard_upco.h
	zcc $(CFLAGS) -c main.c -pragma-define:CRT_ORG_CODE=0x9000

keyboard_upco.o: keyboard_upco.c keyboard_upco.h
	zcc $(CFLAGS) -c keyboard_upco.c -pragma-define:CRT_ORG_CODE=0x9000

keyboard.o: keyboard.c keyboard.h
	zcc $(CFLAGS) -c keyboard.c -pragma-define:CRT_ORG_CODE=0x9000

diskey.bin: diskey_sw.o diskey_test.o
	zcc +z80 -m -O3 -startup=1 -clib=sdcc_iy diskey_sw.o diskey_test.o \
        -o diskey -lm -create-app -startup=0 -pragma-define:CRT_ORG_CODE=0x9000

main.bin: main.o keyboard.o keyboard_upco.o diskey_sw.o
	zcc +z80 -m -O3 -startup=1 -clib=sdcc_iy main.o keyboard_upco.o diskey_sw.o \
        -o main -lm -create-app -startup=0 -pragma-define:CRT_ORG_CODE=0x9000

diskey-9000.hex: diskey.bin
	srec_cat diskey.bin -binary -offset 0x9000 -o diskey-9000.hex -intel

main-9000.hex: main.bin
	srec_cat main.bin -binary -offset 0x9000 -o main-9000.hex -intel

clean:
	rm -f *~ *.o main *.lst *.sym *.ihx *.lk *.map *.rel *.bin *.def *.lis
