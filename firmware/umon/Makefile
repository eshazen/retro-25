all: umon.hex

# Z80ASM = /home/hazen/work/z88dk/bin/z80asm
Z80ASM = /home/hazen/bin/zmac

umon.hex: umon.asm console.asm hex.asm s19200.asm diskey.asm c-link.asm
	$(Z80ASM) umon.asm

# umon.hex: umon.bin
#	srec_cat umon.bin -binary -o umon.hex -intel

#umon.bin: umon.asm console.asm hex.asm
#	$(Z80ASM) -l -b umon.asm

clean:
	rm -f *~ *.bin *.hex *.lis *.o
	rm -r zout


