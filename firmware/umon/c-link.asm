;;; ------------------------------------------------------------
;;; C-compatible entry points for some useful functions
;;; ------------------------------------------------------------

;;; output character from L
putch:	ld	a,l
	jp	getc

;;; get character to HL
getch:	call	getc
	ld	l,a
	ld	h,0
	ret
	
