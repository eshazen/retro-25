;;; 
;;; hex input/output
;;;
;;; phex1    - print hex digit from A
;;; phex2    - print hex byte from A
;;; phex4    - print hex word from HL
;;; ihex1    - hex to binary in A, NC if valid


;;; print hex nibble from a
phex1:	push 	af
	and 	a, 0fh
	add	a,'0'
	cp	'9'+1
	jr	c,phex1a
	add	a,'A'-'0'-10
phex1a:	call	putc
	pop	af
	ret

;;; print hex byte from a
phex2:	push	af
	push	bc
	ld	b,a		;save value
	rrca
	rrca
	rrca
	rrca			;get high nibble
	call	phex1
	ld	a,b		;get low nibble
	call	phex1
	pop	bc
	pop	af
	ret

;;; print hex word from HL
phex4:	push	hl
	push	af
	ld	a,h
	call	phex2
	ld	a,l
	call	phex2
	pop	af
	pop	hl
	ret

;;; convert ASCII hex in A to binary
;;; NC if valid hex
;;; if invalid, A is modified but not valid
ihex1:	sub	'0'		;A-'0'
	ret	c		;A < '0', not valid
	cp	10
	ccf
	ret	nc		;all done if result < 10
	sub	'A'-'9'-1	;should give value 10..15
	cp	10
	ret	c
	cp	16
	ccf
	ret

;;;;;; dump argc/argv
;;;adump:	ld	a,(argc)
;;;	ld	b,a
;;;	call	phex2
;;;	call	crlf
;;;	ld	hl,iargv
;;;	ld	a,b
;;;	or	a
;;;	ret	z
;;;	
;;;adump1:	ld	e,(hl)
;;;	inc	hl
;;;	ld	d,(hl)
;;;	inc	hl
;;;	ex	de,hl		;swap hl/de
;;;	call	phex4
;;;	ex	de,hl
;;;	call	space
;;;	djnz	adump1
;;;	call	crlf
;;;	ret

;;; get hex from (hl) and return in A (NC if valid)
;;; increment HL past char
ghex1:	ld	a,(hl)
	inc	hl
	jp	ihex1

;;; get 2-digit hex from HL
;;; return in A, other regs preserved
ghex2:	push	bc
	call	ghex1
	jr	c,ghex2a
	rlca
	rlca
	rlca
	rlca
	and	0f0h
	ld	b,a
	call	ghex1
	jr	c,ghex2a
	or	b
ghex2a:	pop	bc
	ret

;;; get 4-digit hex value from HL and return in DE
ghex4:	call	ghex2
	ret	c
	ld	d,a
	call	ghex2
	ld	e,a
	ret

;;; parse hex value up to 4 digits at (hl)
;;; convert to binary in de
;;; return c on error, nc on valid hex
;;; advance HL to char after last hex digit
vhex:	ld	de,0
vhex1:	call	ghex1
	ret	c		;not valid hex, just return with cy
	
	ex	de,hl		;shift DE left 4 bits
	add	hl,hl
	add	hl,hl
	add	hl,hl
	add	hl,hl
	ex	de,hl
	
	or	e		;merge in digit just converted
	ld	e,a
	jr	vhex1

;;; convert numeric tokens from pointer list at HL
;;; to integers in list at DE
;;; token count in B
;;; overwrites HL, DE
cvint:	
	inc	b		;return now if zero count
	dec	b
	ret	z

	push	ix		;save index regs
	push	iy
	
	;; move HL, DE to ix, iy - lazy
	push	hl
	pop	ix
	push	de
	pop	iy

plop:	ld	l,(ix+0)	;get pointer
	ld	h,(ix+1)
	inc	ix
	inc	ix

	call	vhex		;convert value at (HL) to DE
	ld	(iy+0),e
	ld	(iy+1),d
	inc	iy
	inc	iy

	djnz	plop

pardon:	pop	iy
	pop	ix
	ret

