	cpu=EZ80F91
	.assume	adl=0			;Z80-Mode

	segment	code

	xdef	multiply
	xdef	divide

; dehl = bc * hl
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
; carry flag on divsion by zero
divide:
ld	de,0
	ld	a,b
	or	c
	scf
	ret	z
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
	or	a
	ret

	end
