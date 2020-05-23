;;; Retro-25 Boostrap loader
;;; Tries for serial port load for 10s, then
;;; loads flash code (see flashtable below)
;;;
;;; ----- Serial loader ----------------------------
;;; operate at 19200 baud for 16MHz CPU clock
;;; (4800 baud for 4MHz CPU clock)
;;; 
;;; output '*'
;;; expect binary words (LSB first):
;;;    0x5791, <addr>, <count>
;;; then <count> data bytes
;;; jumps to <addr> after load
;;; if header not seen after a few bytes, start over
;;; by sending '*' again
;;;
;;; echo back all received bytes
;;; ------------------------------------------------

;;; expects to be stored at 0000 in flash, then
;;; relocates to 'ram' below

;;; can be non-zero for testing
rom:	equ	0
	
ram:	equ	0f800h
	
off	equ	ram-rom

	org	rom

start:	jp	mover
	jp	flashtable	;dummy jump to locate flash table	

	org	rom+40h		;skip past restart vectors

mover:	ld	sp,ram

	;; copy code to RAM
	ld	hl,rom
	ld	de,ram
	ld	bc,last-rom+1	;size of code to move
	ldir

	jp	main+off

	org	rom+100h

;;;
;;; table of flash images
;;; 
flashtable:	
	dw	0xcafe		;magic number marks start of table
;;; first flash image
	dw	0x1000		;start address in ROM
	dw	0x9000		;RAM target address
	dw	0x4000		;size in bytes
	dw	0x9000		;entry point

	dw	0,0,0,0		;table ends with zeroes

	org	rom+200h
	
	
;;;----------------------------------------------------
;;; all code from here on must be position-corrected
;;; (all absolute addresses must add "+off")
;;;----------------------------------------------------

;;;
;;; 1200-baud bit-bang serial routines
;;;
;;; getc - read character, return in A
;;; putc - write character from A
;;;
	
;;; hardware ports
led_port:	equ	0	;port 0 for LED/keyboard output
led_bit:	equ	40H	;bit 6 for LED control
	
serial_port:	equ	80H	;input port
	
data_bit:	equ	80H	;input data mask

;;; -------------------- macros --------------------
;;; 23/10 seem to be OK for 4800 baud (4MHz CPU) or 19200 (16MHz CPU)

full:	equ	23
half:	equ	10

;;; delay macro:  uses B
;;; 40 T-states/loop	
delay	macro	p1
	local	dilly
	ld	b,p1

dilly:	nop
	nop
	nop
	nop
	nop
	djnz	dilly
	endm

bitdly	macro
	delay	full
	endm

halfdly macro
	delay	half
	endm

mark	macro
	ld	a,data_bit
	out	(led_port),a
	endm

spc	macro
	ld	a,0
	out	(led_port),a
	endm

;;; ----------------------------------------

;;; 
;;; receive a character to A
;;; 
getc:	
	push	bc
	push	de
	
	ld	e,9		; bit count (start + 8 data)
	
	;; wait for high
ci0:	in	a,(serial_port)
	and	data_bit
	jr	z,ci0		;loop if/while low
	
ci1:	in	a,(serial_port) ; read serial line
	and	data_bit	; isolate serial bit
	jr	nz,ci1		; loop while high
	halfdly			;delay to middle of first (start) bit

ci3:
	bitdly			;delay to middle of LSB data bit
	in	a,(serial_port) ; read serial character
	and	data_bit	; isolate serial data
	jr	z,ci6		; j if data is 0
	inc	a		; now register A=serial data
ci6:	rra			; rotate it into carry
	dec	e		; dec bit count
	jr	z,ci5		; j if last bit
	
	ld	a,c		; this is where we assemble char
	rra			; rotate it into the character from carry
	ld	c,a

	jr	ci3		; do next bit
	
ci5:	ld	a,c
	pop	de
	pop	bc

	ret

;;;
;;; send character in A
;;; saves all
;;; 
	
putc:	push	bc
	push	de
	push	af
	
	ld	c,a

	ld	e,8		;bit counter
	
	mark			;ensure a stop bit
	bitdly
	
	spc			;start bit
	bitdly
	
	;; loop here for bits
rrot:	rr	c		;shift out LSB
	jr	c,one
	
	spc
	jr	bite
one:
	mark
bite:
	bitdly
	
	dec	e
	jr	nz,rrot
	mark
	bitdly			; stop bit
	
	pop	af
	pop	de
	pop	bc
	ret
	
;;; ----------------------------------------
;;; main program starts here
;;; ----------------------------------------
main:	ld	a,'*'		;output '*'
	call	putc+off

;;; delay here for 10s waiting for serial data, then jump to EEPROM loader
	ld	hl,0
	ld	b,50
	
	;; wait here for either a low on serial line or timeout
schk:	in	a,(serial_port) ; read serial line
	and	data_bit	; isolate serial bit
	jr	z,bload		; loop while high

	dec	hl
	ld	a,h
	or	l
	jr	nz, schk

	djnz	schk

;;; EEPROM loader
	ld	hl,(flashtable)
	ld	a,h		;check for 0xcafe
	cp	0xca
	jr	nz,main
	ld	a,l
	cp	0xfe
	jr	nz,main

	ld	ix,flashtable+2	;first image
	ld	l,(ix)		;start address
	ld	h,(ix+1)
	ld	e,(ix+2)	;target address
	ld	d,(ix+3)
	ld	c,(ix+4)	;count
	ld	b,(ix+5)
	ldir			;move it

	ld	l,(ix+6)	;start address
	ld	h,(ix+7)

	jp	(hl)

;;; got a serial character, start loader
bload:	ld	b,5		;max bad bytes
	;; read chars until 5 received or 0x91 seen
bin1:	call	getc+off
	call	putc+off
	cp	0x91		;first magic byte?
	jr	z,bin1a
	djnz	bin1
	jr	main		;bail out on error after 5 bad bytes
	
	;; read chars, skipping repeat 0x91, wait for 0x57
bin1a:	call	getc+off
	call	putc+off
	cp	0x91
	jr	z,bin1a
	cp	0x57
	jr	nz,main
	
	;; get address to hl
	call	getc+off
	call	putc+off
	ld	l,a
	call	getc+off
	call	putc+off
	ld	h,a
	push	hl
	pop	ix
	;; get count to bc
	call	getc+off
	call	putc+off
	ld	c,a
	call	getc+off
	call	putc+off
	ld	b,a
	;; read and store data
bin2:	call	getc+off
	call	putc+off
	ld	(hl),a
	inc	hl
	dec	bc
	ld	a,b
	or	c
	jr	nz,bin2

	jp	(ix)

last	equ	$

	end
	
