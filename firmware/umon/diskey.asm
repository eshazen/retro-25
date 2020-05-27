;;; ------------------------------------------------------------
;;; display / keyboard support
;;; ------------------------------------------------------------

;;; control ports
inpt:	equ	80H

;;; scan the keyboard
;;; return row/column in A, L or 0 if no key pressed
;;;  Row = bits 3:5
;;;  Col = bits 0:2
kbscan:
	ld	hl,0
	ld	de,0ffffh	;row/col = ff/ff 
	ld	c,0xfe		;one row set to 0
	ld	b,7		;row down count

row:	ld	a,c
	out	(0),a
	inc	d		;increment row, start at 1
	in	a,(inpt)
	xor	0ffh
	jr	z,nohit
	;; find bit number in E

col:	inc	e
	rrc	a
	jr	nc,col		;definitely a 1
	;; we found a hit, copy to hl
	ld	a,e		;row
	sla	a		;shift left 3
	sla	a
	sla	a
	or	d
	ld	l,a
	inc	h		;H counts hits
	
nohit:	rlc	c
	djnz	row
	ld	a,l		;return scan result in A, HL
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

dpymod:	equ	0b0h		;no decode, data coming, not blanked

display:
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

