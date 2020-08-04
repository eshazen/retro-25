;;; ------------------------------------------------------------
;;; display with VFD support
;;; ------------------------------------------------------------


	GLOBAL _umon_display
	GLOBAL _umon_kbscan
	GLOBAL _umon_kbuff
	GLOBAL _umon_hex
	GLOBAL _umon_switches
	GLOBAL _umon_blank
	GLOBAL _umon_serial
	GLOBAL _umon_putc
	GLOBAL _umon_getc
	GLOBAL _umon_jump
	GLOBAL _vfd_init
	GLOBAL _vfd_display

;;; ------------------------------------------------------------
;;; display / keyboard support
;;; ------------------------------------------------------------

;;; control ports
inpt:	equ	80H

	SECTION	code_compiler

;;;
;;; jump using pointer to struct:
;;;   destination address
;;;   return address (we should fill this in)
;;;     ... any other useful info for the user
;;; 
_umon_jump:
	;; HL points to struct
	push	hl
	ld	e,(hl)		;jump address to de
	inc	hl
	ld	d,(hl)
	inc	hl
	ld	bc,jump_back
	ld	(hl),c		;return address to struct
	inc	hl
	ld	(hl),b
	pop	hl
	ex	de,hl		;DE points to struct, HL is address
	call	ucall		;indirect call trick
	ret
jump_back:
	ret

ucall:	jp	(hl)

;;; buffer for keyboard scan data
kbuff:	db	0,0,0,0,0,0,0,0

_umon_kbuff:
	ld	hl,kbuff
	ld	c,0xfe
	ld	b,7

kkrow:	ld	a,c
	out	(0),a
	in	a,(inpt)
	xor	0ffh
	ld	(hl),a
	inc	hl
	rlc	c
	djnz	kkrow
	
	ld	hl,kbuff
	ret

;;; scan the keyboard
;;; return row/column in A, L or 0 if no key pressed
;;;   Row = bits 3:5
;;;   Col = bits 0:2
;;; scan up through CLK then stop to avoid switches
;;; handle switches separately
_umon_kbscan:	
	push	iy
	ld	hl,0
	ld	de,0ffffh	;row/col = ff/ff 
	
	ld	c,0xfe		;one row set to 0
	ld	b,4		;first 4 columns only

kcol:	ld	a,c
	out	(0),a
	inc	d		;increment column, start at 0
	in	a,(inpt)
	xor	0ffh
	and	7fh		;ignore high bit (serial data)
	jr	z,nohit
	;; find bit number in E

krow:	inc	e		;
	rrc	a
	jr	nc,krow		;loop until 1 found
	ld	a,e		;row
	sla	a		;shift left 3
	sla	a
	sla	a
	or	d		;merge column to low 3 bits
	ld	l,a
	set	0,h
	
nohit:	rlc	c
	djnz	kcol
	ld	a,l		;return scan result in A, HL

	;; now scan first three bits of last column
	;; 
	ld	a,c
	out	(0),a
	inc	d
	in	a,(inpt)
	xor	0ffh
	and	7		;only pay attention to low 3 bits
	jr	z,nohit2
	;; now we have 3 bits to analyze in A
krow2:	inc	e
	rrc	a
	jr	nc,krow2
	;; merge output
	ld	a,e		;row
	sla	a		;shift left 3
	sla	a
	sla	a
	or	d		;merge column to low 3 bits
	ld	l,a
	set	0,h

nohit2:	pop	iy
	ret

;;;
;;; check switches.  Return HL = bit 0: R/S switch bit 1: on/off switch
;;; 
_umon_switches:
	ld	hl,3
	ld	a,0xef		;mask for column 5
	out	(0),a
	in	a,(inpt)
	bit	3,a		;test for P/R switch
	jr	z,skprsw
	res	0,l
skprsw:	bit	4,a		;test for on/off switch
	ret	z
	res	1,l
	ret
	
;;;
;;; check serial input bit status
;;; return 1 if low (space) or 0 if high (mark)
;;; 
_umon_serial:
	ld	hl,0
	in	a,(inpt)
	and	80h
	ret	nz
	set	0,l
	ret

;;;
;;; update the display
;;; use HP-style encoding, so:
;;;   zero = blank
;;;   1-10 = 0 to 9
;;;   11   = "r"
;;;   12   = "F"
;;;   13   = "o"
;;;   14   = "p"
;;;   15   = "E"
;;; bit 6 -> replace digit with "-"
;;; bit 7 -> turn on decimal after
;;;
;;; HL points to 12-byte array for the digits
;;; 
;;; this requires bare unencoded mode on the 7218

s7tbl:	db	80h,0fbh,0b0h,0edh,0f5h,0b6h,0d7h,0dfh
	db	0f0h,0ffh,0f7h,08ch,0ceh,09dh,0eeh,0cfh

minus:	equ	84h		;code for "-" with no decimal

left_m: equ	41h		;left 8 digits mode port
left_d:	equ	40h		;left 8 digits data port
right_m: equ	0c1h		;right 4 digits mode port
right_d: equ	0c0h		;right 4 digits data port

dpyblk:	equ	000h		;blank the display
dpymod:	equ	0b0h		;no decode, data coming, not blanked
dpyhex:	equ	0d0h		;hex decode, data coming, not blanked



_umon_display:
	push	ix
	push	hl
	pop	ix
	ld	c,left_m
	ld	b,8
	call	do7218
	
	ld	c,right_m
	ld	b,8
	call	do7218
	pop	ix
	ret

;;; output data at IX to 7218 decoded using s7tbl
;;; (data is 16-bit words, skip high byte)
;;; c is mode port (data port + 1)
;;; b is word count
;;;
;;; uses A, IX, BC
do7218:	ld	a,dpymod
	out	(c),a
	dec	c		;point to data port
do71:	ld	a,(ix)
	and	0fh
	bit	6,(ix)
	jr	z,nminus	;not "-"
	ld	a,minus		;else replace with minus code
	jr	do72
	
	;; translate using table
nminus:	ld	hl,s7tbl
	ld	e,a
	ld	d,0
	add	hl,de
	ld	a,(hl)
	;; check for decimal and set if so
do72:	bit	7,(ix)
	jr	z,do73
	res	7,a		;clear high bit

do73:	out	(c),a
	inc	ix
	inc	ix
	djnz	do71

	ret

;;;------------------------------------------------------------
;;; display in hex
;;; 12 digits from (hl)
;;; no blanking supported so all digits lit
;;;------------------------------------------------------------

_umon_hex:
	push	ix
	push	hl
	pop	ix

	ld	b,8
	ld	c,left_m
	call	dohex

	ld	c,right_m
	ld	b,8
	call	dohex
	
	pop	ix
	ret

dohex:	ld	a,dpyhex
	out	(c),a
	dec	c
dohx1:	ld	a,(ix)
	inc	ix
	out	(c),a
	djnz	dohx1
	
	ret
	
;;;
;;; blank the display
;;;
_umon_blank:
	ld	a,dpyblk
	out	(left_m),a
	out	(right_m),a
	ret

;;; ------------------------------------------------------------------------
;;; VFD display
;;; ------------------------------------------------------------------------
	

;;;
;;; update the display
;;; use HP-style encoding, so:
;;;   zero = blank
;;;   1-10 = 0 to 9
;;;   11   = "r"
;;;   12   = "F"
;;;   13   = "o"
;;;   14   = "p"
;;;   15   = "e"
;;; bit 6 -> replace digit with "-"
;;; bit 7 -> turn on decimal after
;;;
;;; HL points to 12-byte array for the digits
;;; 
;;; this requires bare unencoded mode on the 7218

	;;         0     1     2     3     4     5     6
vs7tbl:	db	0, 0deh, 082h, 0ech, 0e6h, 0b2h, 076h, 07eh
	;;      7     8     9     r     F     o     p     E
	db	0c2h, 0feh, 0f6h, 028h, 078h, 02eh, 0f8h, 07eh

vminus:	equ	020h		;code for "-" with no decimal
	;; or maybe 08h?

vfd_prt: equ	40h		;display controller port

vfd_d:	 equ	1		;VFD data bit
vfd_stb: equ	2		;VFD strobe bit
vfd_clk: equ	4		;VFD shift clock
vfd_bl:	equ	8		;VFD blanking
vfd_led2: equ	10h		;VFD LED2 (power supply control?)
vfd_led1: equ	20h		;VFD LED1 (power supply control?)

vfd_digits: equ	12		;number of digits
vfd_extra: equ	4		;extra clocks
	
;;; initialize the display hardware
_vfd_init:	
	ld	a,vfd_bl	;blank display by default
	out	(vfd_prt),a
	ret

_vfd_display:	
	push	ix
	push	bc
	push	de

	ld	c,vfd_digits	;digit count

	push	hl		;display data pointer to IX
	pop	ix

	;; extra clocks
	ld	b,vfd_extra
	call	vfd_shifty

dpyb:	ld	a,(ix)		;get display byte

;;; comment out below for raw data
	and	0fh		;only want low  bits
	ld	d,0
	ld	e,a
	ld	hl,vs7tbl	;look up in table
	add	hl,de
	ld	a,(hl)
	bit	7,(ix)		;decimal?
	jr	z,nodp
	or	a,1		;set decimal bit if so
nodp:	bit	6,(ix)		;check minus flag
	jr	z,nomi
	ld	a,vminus	;yes, replace with "-" code

	;; shift out bits 
nomi:	ld	b,8
	call	vfd_shifty

	inc	ix
	inc	ix
	
	dec	c
	jr	nz,dpyb

;;; cycle the strobe to update the display, and un-blank
	ld	a,vfd_stb
	out	(vfd_prt),a
	nop
	nop
	xor	a
	out	(vfd_prt),a
	nop
	nop
	
	pop	de
	pop	bc
	pop	ix
	ret

;;; shift B bits to display from A, LSB first
;;; uses HL
vfd_shifty:
	ld	l,a
	ld	h,0
	
vfd_sh:	xor	a		;clear a
	rrc	l		;data bit to CY
	adc	a,h		;data bit to A bit 0
	out	(vfd_prt),a
	nop
	nop
	or	a,vfd_clk	;assert CLK
	out	(vfd_prt),a
	nop
	nop
	and	a,1		;deassert CLK
	out	(vfd_prt),a
	nop
	nop
	djnz	vfd_sh

	ret
	
	
;;; ------------------------------------------------------------------------
;;; serial port
;;; umon_putc:  send a character
;;; umon_getc:  receive a character
;;;
;;; 


serial_port:	equ	80H	;input port
led_port:	equ	0	;port 0 for LED/keyboard output
	
data_bit:	equ	80H	;input data mask
	
;;; serial port timing macros
;;; 23/10 seem to be OK for 4800 baud (4MHz CPU) or 19200 (16MHz CPU)

;;; UGH - z80asm doesn't support macros

full:	equ	22
half:	equ	9

;;;;; delay macro:  uses B
;;delay	macro	p1
;;	local	dilly
;;	ld	b,p1		;7T
;;
;;;;; 33T per loop / 28T for last
;;dilly:	nop			;4T
;;	nop			;4T
;;	nop			;4T
;;	nop			;4T
;;	nop			;4T
;;	djnz	dilly		;13T / 8T
;;	endm

;;bitdly	macro			;766T
;;	delay	full
;;	endm

;;; there are an additional 70T in the rest of the code,
;;; 833T is ideal 19200 baud, so 833-70 = 763 target
;;; 763 - 27 (call/ret) - 7 (ld) = 729
;;; 23* loop = 721T so add 2 NOPs and we're good

;;; delay exactly 763T (hopefully)?
;;; full=22: 27T+7T+28T+21*33T = 755 + 8 = 763
                                ;27T (call+ret)
bitdly:	ld	b,full          ;7T
dilly:	nop			;4T
	nop			;4T
	nop			;4T
	nop			;4T
	nop			;4T
	djnz	dilly		;13T / 8T
	nop			;4T
	nop			;4T
	ret

;;; old version was 332T
;;; this one is 330T
                                ;27T (call+ret)
halfdly: ld	b,half		;7T
dally:	nop			;4T
	nop			;4T
	nop			;4T
	nop			;4T
	nop			;4T
	djnz	dally		;13T / 8T
	nop			;4T
	ret

;mark	macro
;	ld	a,data_bit
;	out	(led_port),a
;	endm

;spc	macro
;	ld	a,0
;	out	(led_port),a
;	endm



;;; 
;;; receive a character to HL
;;; 
_umon_getc:	
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
	call 	halfdly		;delay to middle of first (start) bit

ci3:
	call	bitdly	       ;delay to middle of LSB data bit    766
	in	a,(serial_port) ; read serial character              12
	and	data_bit	; isolate serial data                 7
	jr	z,ci6		; j if data is 0                  7 / 12
	inc	a		; now register A=serial data          4
ci6:	rra			; rotate it into carry                4
	dec	e		; dec bit count                       4
	jr	z,ci5		; j if last bit                   7 / 12
	
	ld	a,c		; this is where we assemble char      4
	rra			; rotate it into the character from c 4
	ld	c,a		;                                     4

	jr	ci3		; do next bit                        12
	
	;; total loop ~ 836T = 52.3 uS or 19139 Hz (0.3% error, not bad!)

ci5:	ld	l,c
	ld	h,0
	pop	de
	pop	bc

	ret

;;;
;;; send character in HL
;;; saves all
;;; 
_umon_putc:
	push	bc
	push	de
	push	af
	ld	c,l

	ld	e,8		;bit counter
	
;	mark			;ensure a stop bit
	ld	a,data_bit
	out	(led_port),a
	call	bitdly
	
;	spc			;start bit
	ld	a,0
	out	(led_port),a
	call	bitdly
	
	;; loop here for bits
rrot:	rr	c		;shift out LSB
	jr	c,one
	
;	spc
	ld	a,0
	out	(led_port),a
	jr	bite
one:
;	mark
	ld	a,data_bit
	out	(led_port),a
bite:
	call	bitdly
	
	dec	e
	jr	nz,rrot
;	mark
	ld	a,data_bit
	out	(led_port),a
	call	bitdly		; stop bit
	
	pop	af
	pop	de
	pop	bc
	ret
	
	


	SECTION IGNORE
	
