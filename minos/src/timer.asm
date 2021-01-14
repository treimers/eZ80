	cpu=EZ80F91
	.assume	adl=0			;Z80-Mode

	xdef	timerinit
	xdef	timerisr

	xref	savecontext
	xref	systemtick

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

; timer interval in ms
INTERVAL	equ	50

;Reload value = 31250
;16 * 31250/10 MHz= 50 ms Interrupt
TMR_VALUE	equ	10000000/1000/16*INTERVAL/16

;Timer 0 Reload Register - Low Byte
TMR0_RR_L_IP    EQU	TMR_VALUE & 0ffh
;Timer 0 Reload Register - High Byte
TMR0_RR_H_IP    EQU	TMR_VALUE >> 8

segment	code

timerinit:
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
	ret

timerisr:
	; save all register
	call	savecontext
	; invoke system tick
	call	systemtick
	; acknowledge interrupt and return from interrupt
	in0	a,(TMR0_IIR)
	reti

	end
