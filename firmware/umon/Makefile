all: umon.hex

Z80ASM = /home/hazen/bin/zmac
base=xxx

umon.hex: umon_nobase.asm console.asm hex.asm s19200.asm diskey.asm c-link.asm vfd.asm
ifeq ($(base),xxx)
	echo "Missing base=value"
	exit 1
endif
	sed s/UMON_ORIGIN/$(base)/ <umon_nobase.asm >umon_$(base).asm
	$(Z80ASM) umon_$(base).asm

# umon.hex: umon.bin
#	srec_cat umon.bin -binary -o umon.hex -intel

#umon.bin: umon.asm console.asm hex.asm
#	$(Z80ASM) -l -b umon.asm

clean:
	rm -f *~ *.bin *.hex *.lis *.o
	rm -r zout


