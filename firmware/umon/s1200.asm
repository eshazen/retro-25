;;;
;;; 1200-baud (4MHz) or 4800 (16MHz) bit-bang serial routines
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
full:	equ	99		;was 100
half:	equ	49		;was 50

;;; delay macro:  uses B
;;; 33 T-states/loop	

;;; need to shorten by ~14 T-states for new macros
	
delay	macro	p1
	local	dilly
	ld	b,p1		;7 TS
	ld	b,p1		;two extra for +14 TS
	ld	b,p1		;two extra for +14 TS

dilly:	nop			; 4 TS
	nop			; 4 TS
	nop			; 4 TS
	nop			; 4 TS
	nop			; 4 TS
	djnz	dilly		;13 TS
	endm			;33 TS total

bitdly	macro
	delay	full
	endm

halfdly macro
	delay	half
	endm

;;; original version
	
;;mark	macro
;;	ld	a,data_bit
;;	out	(led_port),a
;;	endm
;;
;;spc	macro
;;	ld	a,0
;;	out	(led_port),a
;;	endm

;;; new version with stored value

mark	macro
	ld	a,(pzero)		; 13 TS
	set	7,a			; 8 TS  total 14 longer
;	ld	a,data_bit		; 7 TS
	out	(led_port),a
	endm

spc	macro
	ld	a,(pzero)
	res	7,a
	out	(led_port),a
	endm
	

;;; ----------------------------------------

;;; function to update port zero, keep serial line marking
;;; (use to output port 0 when serial line is idle)
updpzero:
	mark
	ret


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
	jr	bitte
one:
	mark
bitte:
	bitdly
	
	dec	e
	jr	nz,rrot
	mark
	bitdly			; stop bit
	
	pop	af
	pop	de
	pop	bc
	ret
	
