	cpu=EZ80F91
	.assume	ADL = 0			;Z80-Mode

	segment	code

	xdef	multiply
	xdef	divide

; hl = bc * hl
multiply:
	ld	de,0
	ex	de,hl
	ld	a,16
	or	a
mloop:
	rl	l
	rl	h
	rl	e
	rl	d
	jr	nc,mnoadd
	add	hl,bc
mnoadd:
	dec	a
	jr	nz,mloop
	ret

; hl = hl / bc
divide:
	ld	de,0
	ex	de,hl
	ld	a,16
dloop:
	scf
	rl	e
	rl	d
	rl	l
	rl	h
	jr	nc,dnocarry
	or	a
	sbc	hl,bc
	jr	dnoadd
dnocarry:
	or	a
	sbc	hl,bc
	jr	nc,dnoadd
	add	hl,bc
	dec	e
dnoadd:
	dec	a
	jr	nz,dloop
dreturn:
	ex	de,hl
	ret

	end
