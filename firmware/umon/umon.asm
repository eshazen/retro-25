;;;
;;; simple Z80 monitor
;;;
;;; d <addr> <count>           dump memory
;;; e <addr> <dd> <dd>...      edit up to 16 bytes in memory
;;; o <addr> <val>             output <val> to port <addr>
;;; z <val>		       set port zero value bits 0-6
;;; i <addr>                   input from <addr> and display
;;; g <addr>                   goto addr
;;; a <val1> <val2>            hex Arithmetic
;;; h <addr>                   dump HP registers from <addr> (A)
;;; c                          return to calculator if possible
;;; b			       binary load
;;; r			       repeat last command
;;; calculator hardware
;;; k                          scan keyboard
;;; 7 <addr>		       update display from <addr>
;;; 
;;; deprecated commands
;;; p ...		       dump argc / argv for debug
;;; 

	org	08100H

stak:	equ	$		;stack grows down from start

;;; jump table for useful entry points
	jmp	main		;0000  cold start
	jmp	getch		;0003  read serial input to HL [C]
	jmp	putch		;0006  output serial from HL [C]
	jmp	crlf		;0009  output CR/LF
	jmp	puts		;000c  output string from HL
	jmp	phex2		;000f  output hex byte from A
	jmp	phex4		;0012  output hex word from HL
	jmp	setpzero	;0015  set pzero mask from A
	jmp	updpzero	;0018  update port from pzero
	jmp	kbscan		;001b  scan keyboard to HL
	jmp	display		;001e  update display from HL
	jmp	savestate	;0021  save state and cold start

;;; ---- data area ----

;;; save CPU state coming from extrnal prog
savesp:	dw	0		;stack pointer
state:	dw	0		;sentinel value
	dw	0		;IY
	dw	0		;IX
	dw	0		;HL
stater:	dw	0		;DE
	dw	0		;BC
	dw	0		;AF
estate:	equ	$
	

pzero:	db	0		;port 0 value bits 0-6
lastc:	db	0		;last command byte

buff:	rept	60
	db	0
	endm

bend:	equ	$		;mark the end

maxarg:	equ	18		;maximum number of arguments
argc:	db	0
	
argv:	rept	maxarg*2
	dw	0
	endm
	
iargv:	rept	maxarg*2
	dw	0
	endm

	INCLUDE "s1200.asm"
	INCLUDE "console.asm"
	INCLUDE "hex.asm"
	INCLUDE "strings.asm"
	INCLUDE "diskey.asm"
	INCLUDE "c-link.asm"

banner:	db	"UMON v0.5 ORG ",0
error:	db	"ERROR",0

main:	ld	sp,stak
	ld	hl,banner
	call	puts
	ld	hl,stak
	call	phex4
	call	crlf
	
loop:	ld	a,'>'		;prompt
	call	putc

	ld	hl,buff
	ld	bc,bend-buff	; maximum size
	call	gets

	;; check for 'R'
	ld	a,(buff)
	cp	a,'R'
	jr	nz,not_r

	;; restore last command byte
	ld	a,(lastc)
	ld	(buff),a

	;; parse string into tokens at argc / argv
not_r:	ld	hl,buff
	ld	de,argv
	ld	b,maxarg
	call	strtok	
	ld	a,c
	ld	(argc),a

	;; convert tokens to integers
	ld	hl,argv
	ld	de,iargv
	ld	b,a
	call	cvint

	ld	hl,buff		;parse command character
	ld	a,(hl)
	ld	(lastc),a	;save for possible repeat

	cp	a,'D'		;dump memory
	jz	dump

	cp	a,'C'		;return to calc
	jz	calc

	cp	a,'H'
	jz	hpdump
	
	cp	a,'A'
	jz	arith

	cp	a,'E'
	jz	edit

	cp	a,'G'
	jz	goto

	cp	a,'B'
	jz	binary
	
	cp	a,'O'
	jz	output

	cp	a,'I'
	jz	input

	cp	a,'Z'
	jz	zero

	cp	a,'K'
	jz	kbtest

	cp	a,'7'
	jz	dptest
	
errz:	ld	hl,error
	call	puts
	call	crlf
	
	jp	loop

quit:	jp	0

kbtest:	call	kbscan
	call	phex4
	call	crlf
	jp	loop

dptest:	ld	hl,(iargv+2)
	call	display
	jp	loop


;;; set port zero value
zero:	ld	a,(iargv+2)
	ld	(pzero),a
	jp	loop

;;; alternative subr to do this from outside
setpzero: ld (pzero),a
	ret

;;; output to port
output:	ld	a,(iargv+2)
	ld	c,a
	ld	a,(iargv+4)
	out	(c),a
	jp	loop

;;; input from port
input:	ld	a,(iargv+2)
	ld	c,a
	in	a,(c)
	call	phex2
	call	crlf
	jp	loop

;;; start binary loader
;;; expect binary words (LSB first):
;;;    0x5791, <addr>, <count>
;;; then <count> data bytes
;;; does not jump after, just returns to prompt
;;; if header not seen after a few bytes, bail out
;;;
;;; echo back all received
;;; 
binary:	ld	b,5		;max bad bytes
	;; read chars until 5 received or 0x91 seen
bin1:	call	getc
	call	putc
	cp	0x91		;first magic byte?
	jr	z,bin1a
	djnz	bin1
	jr	errz
	
	;; read chars, skipping repeat 0x91, wait for 0x57
bin1a:	call	getc
	call	putc
	cp	0x91
	jr	z,bin1a
	cp	0x57
	jr	nz,errz
	
	;; get address to hl
	call	getc
	call	putc
	ld	l,a
	call	getc
	call	putc
	ld	h,a
	ld	(iargv),hl
	;; get count to bc
	call	getc
	call	putc
	ld	c,a
	call	getc
	call	putc
	ld	b,a
	ld	(iargv+2),bc
	;; read and store data
bin2:	call	getc
	call	putc
	ld	(hl),a
	inc	hl
	dec	bc
	ld	a,b
	or	c
	jr	nz,bin2

	;; leave addr, count in iargv+2, iargv+4
	jp	loop

;;; jump to 1st arg
goto:	cp	2
	jp	c,errz
	ld	hl,(iargv+2)
	jp	(hl)

;;; edit values into memory
edit:	ld	a,(argc)
	cp	a,3		;need at least 3 args
	jp	c,errz

	sub	a,2
	ld	b,a		;count of bytes to store

	ld	hl,(iargv+2)	;get address
	ld	ix,iargv+4	;pointer to first data item

eloop:	ld	a,(ix)
	ld	(hl),a
	inc	hl
	inc	ix
	inc	ix
	djnz	eloop
	jp	loop

;;; dump some memory
dump:	ld	hl,(iargv+2)	;first arg
	ld	a,(iargv+4)	;second arg
	
	ld	b,a		;count
	call	hdump
	jp	loop

;;; hex dump B bytes from HL
	;; see if we need to print the address
hdump:	ld	a,l
	and	0xf
	jr	nz,bite
	push	hl
	call	crlf
	call	phex4
	ld	a,':'
	call	putc
	call	space
	pop	hl
	
bite:	ld	a,(hl)
	inc	hl
	call	phex2
	call	space

noadr:	djnz	hdump
	call	crlf
	ret

;;; do hex arithmetic
arith:	ld	hl,(iargv+2)	;first arg
	ld	de,(iargv+4)	;second arg
	
	add	hl,de
	call	phex4
	call	space
	ld	hl,(iargv+2)	;first arg
	ld	de,(iargv+4)	;second arg
	or	a		;clear CY
	sbc	hl,de
	call	phex4
	call	crlf
	jp	loop

;;; HP calculator word size
wsize:	equ	14
;;; register names
hpregs:	db	"ABXYZT12", 0

;;; dump HP registers
;;; all 14 nibbles:  A, B, X, Y, Z, T, M1, M2
hpdump:	ld	hl,(iargv+2)	;first arg
	ld	de,wsize
	ld	ix,hpregs
	
hpd1:	ld	a,(ix)		;get register name
	inc	ix
	or	a		;Z=done
	jp	z,loop

	call	putc		;display reg name
	call	space		;space
	call	hpreg		;display reg
	jr	hpd1

;;; display HP register from (HL)
;;; de must be WSIZE (14)
;;; save bc, advance HL past reg
hpreg:	push	hl
	push	bc
	ld	b,wsize
	add	hl,de		;point to next reg
hpr1:	dec	hl
	ld	a,(hl)
	call	phex1
	djnz	hpr1
	pop	bc
	pop	hl
	add	hl,de
	call	crlf
	ret

;;;
;;; arriving from e.g. calculator
;;; save all primary regs and return address from (DE)
;;; then cold start the monitor with a message
altban:	db	"UMON RESTART ",0	

savestate:
	ld	(savesp),sp	;save stack pointer
	ld	sp,estate
	push	af
	push	bc
	push	de
	push	hl
	push	ix
	push	iy
	ld	hl,0cafeh
	push	hl

;;; cold start with alternate banner, display struct address
	ld	sp,stak
	ld	hl,altban
	call	puts
	ld	hl,(stater)
	call	phex4
	call	crlf
	
	jp	loop
	
;;;
;;; try to return to calculator
;;; 
calc:	ld	sp,state
	pop	hl		;get sentinel value, last pushed
	or	a
	ld	de,0cafeh
	sbc	hl,de
	jp	nz,main		;cold start on error
	;; restore the state and jump, using (hl) for the jump
	pop	iy
	pop	ix
	pop	hl
	pop	de
	pop	bc
	pop	af
	ex	de,hl		;HL points to struct
	inc	hl
	inc	hl		;HL points to return address
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	ld	sp,(savesp)
	ex	de,hl
	jp	(hl)

	.end
