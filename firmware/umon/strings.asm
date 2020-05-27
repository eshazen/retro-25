;;;
;;; string library
;;;

	;; parse string at (HL) into space-separated tokens
	;; In:	HL points to null-terminated string
	;; 	DE points to buffer for 16-bit pointers to tokens
	;; 	B contains maximum token count
	;; Out: HL overwritten
	;; 	DE overwritten
	;; 	C contains count of tokens found
	;; 	separators in buffer overwritten with \0
	;; 
	;; leading spaces in buffer ignored

	;; initialize
strtok:	xor	a		;clear a
	ld	c,a		;zero count

	;; skip space(s)
dotok:	ld	a,(hl)
	inc	hl
	or	a		;check for terminator
	ret	z		;return if so
	
	cp	a,' '		;check for space
	jr	z,dotok		;keep scanning if so
	
	dec	hl		;back up to non-space char
	;; HL now points to non-space, non-null (start of token)

	;; store pointer HL at DE, increment DE past pointer
	ex	de,hl
	ld	(hl),e
	inc	hl
	ld	(hl),d
	inc	hl
	ex	de,hl

	inc	c		;update the token count

	;; HL points to a non-space, non-term
	;; scan to next space or term
skan:	inc	hl
	ld	a,(hl)
	or	a		;check for null
	ret	z		;we're done
	cp	a,' '
	jr	nz,skan		;scan past non-spaces

	;; HL points to space.  Over-write with NULL
	ld	(hl),0

	inc	hl		;point to next char past null
	djnz	dotok
	
	ret
