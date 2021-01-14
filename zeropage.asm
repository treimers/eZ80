	cpu=EZ80F91
	.assume	adl=0			;Z80-Mode

	include	"error.inc"

	xdef	error

	xref	test

	define	boot,space=rom
	segment	boot

	.org	0h
reset:
rst0:
	jp	test
rst8:
	.org	8h
	ld	bc,8h
	jr	rsterror
rst10:
	.org	10h
	ld	bc,10h
	jr	rsterror
rst18:
	.org	18h
	ld	bc,18h
	jr	rsterror
rst20:
	.org	20h
	ld	bc,20h
	jr	rsterror
rst28:
	.org	28h
	ld	bc,28h
	jr	rsterror
rst30:
	.org	30h
	ld	bc,30h
	jr	rsterror
rst38:
	.org	38h
	ld	bc,38h
	jr	rsterror
nmi:
	.org	66h
	ld	a,err_ctl_nmi
	jp	error

rsterror:
	ld	a,err_ctl_restart
	pop	bc
	dec	bc
	jp	error

	segment	code

error:
	jr	$

	end
