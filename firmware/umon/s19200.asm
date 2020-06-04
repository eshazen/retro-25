;;; ------------------------------------------------------------------------
;;; serial port
;;; putc:  send a character from A
;;; getc:  receive a character to A
;;; ------------------------------------------------------------------------


serial_port:	equ	80H	;input port
led_port:	equ	0	;port 0 for LED/keyboard output
	
data_bit:	equ	80H	;input data mask
	
;;; serial port timing macros
;;; 23/10 seem to be OK for 4800 baud (4MHz CPU) or 19200 (16MHz CPU)

;;; UGH - z80asm doesn't support macros

full:	equ	22
half:	equ	9

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

ci5:	ld	a,c

	pop	de
	pop	bc

	ret

;;;
;;; send character in A
;;; saves all
;;; 
putc:
	push	bc
	push	de
	push	af

	ld	c,a

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
	jr	biter
one:
;	mark
	ld	a,data_bit
	out	(led_port),a
biter:
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

;;; function to update port zero, keep serial line marking
;;; (use to output port 0 when serial line is idle)
updpzero:
	ld	a,data_bit
	out	(led_port),a
;	mark
	ret
	
