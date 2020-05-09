	GLOBAL _umon_display
	GLOBAL _umon_kbscan
	GLOBAL _umon_kbuff
	GLOBAL _umon_hex
	GLOBAL _umon_switches
	GLOBAL _umon_blank

;;; ------------------------------------------------------------
;;; display / keyboard support
;;; ------------------------------------------------------------

;;; control ports
inpt:	equ	80H

	SECTION	code_compiler

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

;;;
;;; blank the display
;;;
_umon_blank:
	ld	a,dpyblk
	out	(left_m),a
	out	(right_m),a
	ret
	

	SECTION IGNORE
	
