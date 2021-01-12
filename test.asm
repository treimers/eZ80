	cpu=EZ80F91
	.assume	adl=0			;Z80-Mode

	xdef	test
	xdef	tm0isr

	xref	multiply
	xref	divide
	xref	initschedule
	xref	createtask
	xref	inttab

	include	"ez80F91.inc"

TMR0_CTL_IP     EQU	10001101B	;Timer 0 Control Register
					;Bit0 =1: Timer enabled
					;Bit1 =0: Reload function not forced
					;Bit2 =1:Continous mode
					;Bit3:4 =01: System clock divider = 16
					;Bit5:6 =00: Timer source = system clock
					;Bit7 =1: Timer stop at debug breakpoints
TMR0_IER_IP     EQU	00000001B	;Timer 0 Interrupt Enable Register
					;Bit0 =1: Interrupt on end-of-count enabled

INTERVAL	equ	50
TMR_VALUE	equ	10000000/1000/16*INTERVAL/16

TMR0_RR_L_IP    EQU	TMR_VALUE & 0ffh	;Timer 0 Reload Register - Low Byte
TMR0_RR_H_IP    EQU	TMR_VALUE >> 8		;Timer 0 Reload Register - High Byte
					;Reload value = 31250
					;16 * 31250/10 MHz= 50 ms Interrupt

segment	code

test:
	; load stack pointer
	ld	sp,topstack

	; test arithmetic
	ld	bc,123
	ld	hl,22
	call	multiply
	jr	c,$			; stop on error
	call	divide
	jr	c,$			; stop on error

	; init minos
	call	initschedule

	; test some create tasks
	ld	de,task1
	call	createtask
	jr	c,$			; stop on error
	ld	de,task2
	call	createtask
	jr	c,$			; stop on error
	ld	de,task3
	call	createtask
	jr	c,$			; stop on error

	im	2
	ld	a,inttab >> 8 & 0ffh
	ld	i,a
	;Control Register initialisieren
	ld	a,TMR0_CTL_IP
	out0	(TMR0_CTL),a
	;Interrupt Enable Register initialisieren
	ld	a,TMR0_IER_IP
	out0	(TMR0_IER),A
	;Reload Register Low Byte initialisieren
	ld	a,TMR0_RR_L_IP
	out0	(TMR0_RR_L),A
	;Reload Register High Byte initialisieren
	ld	a,TMR0_RR_H_IP
	out0	(TMR0_RR_H),A

	ld	a,20
	ld	(counter),a
	xor	a
	ld	(seconds),a
	ei

	ld	de,0
	ld	hl,0
	ld	bc,0
tloop:
	scf
	adc	hl,bc
	ex	de,hl
	adc	hl,bc
	ex	de,hl
	jr	tloop

endoftest:
	jp	$			;idle

task1:
	db	3			;prio
	db	0			;period
	db	'CC'			;pc
	db	'cc'			;stack
	dw	name1

task2:
	db	2			;prio
	db	0			;period
	db	'BB'			;pc
	db	'bb'			;stack
	dw	name2

task3:
	db	1			;prio
	db	0			;period
	db	'AA'			;pc
	db	'aa'			;stack
	dw	name2

name1:
	db	'task1',0

name2:
	db	'task2',0

name3:
	db	'task3',0

name4:
	db	'task4',0

tm0isr:
	push	af
	ld	a,(counter)
	dec	a
	jr	nz,icontinue
	ld	a,(seconds)
	inc	a
	ld	(seconds),a
	ld	a,20
icontinue:
	ld	(counter),a
	; acknowledge interrupt
	in0	a,(TMR0_IIR)
	pop	af
	ei
	reti

	segment	data

botstack:				; bottom of stack
	ds	20
topstack:				; top of stack

counter	ds	1
seconds	ds	1

	end
