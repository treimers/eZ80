	cpu=EZ80F91
	.assume	adl=0			;Z80-Mode

	include	"error.inc"

	xdef	inttab

	xref	tm0isr
	xref	error

	define	inttable,space=rom,align=256
	segment	inttable

; the complete interrupt table with 128 interrupt vectors
; all unsed slots are filled with unexpected handler routine
inttab:
	;32 vectors
	dw	unexp, unexp, unexp, unexp, unexp, unexp, unexp, unexp
	dw	unexp, unexp, unexp, unexp, unexp, unexp, unexp, unexp
	dw	unexp, unexp, unexp, unexp, unexp, unexp, unexp, unexp
	dw	unexp, unexp, unexp, unexp, unexp, unexp, unexp, unexp

	;32 vectors
	dw	unexp, unexp, unexp, unexp, unexp, unexp, unexp, unexp
	dw	unexp, unexp, tm0isr, unexp, unexp, unexp, unexp, unexp
	dw	unexp, unexp, unexp, unexp, unexp, unexp, unexp, unexp
	dw	unexp, unexp, unexp, unexp, unexp, unexp, unexp, unexp

	;32 vectors
	dw	unexp, unexp, unexp, unexp, unexp, unexp, unexp, unexp
	dw	unexp, unexp, unexp, unexp, unexp, unexp, unexp, unexp
	dw	unexp, unexp, unexp, unexp, unexp, unexp, unexp, unexp
	dw	unexp, unexp, unexp, unexp, unexp, unexp, unexp, unexp

	;32 vectors
	dw	unexp, unexp, unexp, unexp, unexp, unexp, unexp, unexp
	dw	unexp, unexp, unexp, unexp, unexp, unexp, unexp, unexp
	dw	unexp, unexp, unexp, unexp, unexp, unexp, unexp, unexp
	dw	unexp, unexp, unexp, unexp, unexp, unexp, unexp, unexp

	segment	code

unexp:
	ld	a,err_interrupt
	jp	error

	end
