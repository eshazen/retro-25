;;; ------------------------------------------------------------
;;; VFD display control (output only)
;;; ------------------------------------------------------------



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

vfd_prt:	equ	40h		;display controller port

vfd_d:	 equ	1		;VFD data bit
vfd_stb: equ	2		;VFD strobe bit
vfd_clk: equ	4		;VFD shift clock
vfd_bl:	equ	8		;VFD blanking
vfd_led2: equ	10h		;VFD LED2 (power supply control?)
vfd_led1: equ	20h		;VFD LED1 (power supply control?)

vfd_digits: equ	12		;number of digits
vfd_extra: equ	4		;extra clocks
	
;;; initialize the display hardware
vfd_init:	
	ld	a,vfd_bl	;blank display by default
	out	(vfd_prt),a
	ret

vfd_display:	
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
	
	
