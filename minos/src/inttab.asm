	cpu=EZ80F91
	.assume	adl=0			;Z80-Mode

	include	"error.inc"

	xdef	inttab

	xref	timerIsr
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
	dw	unexp, unexp, timerIsr, unexp, unexp, unexp, unexp, unexp
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
	ld	a,err_ctl_int
	jp	error

	end
