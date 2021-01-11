	cpu=EZ80F91
	.assume	ADL = 0			;Z80-Mode

	xref	multiply
	xref	divide
	xref	initschedule
	xref	createtask

	segment	data
botstack:				; bottom of stack
	ds	20
topstack:				; top of stack

segment	code

	.org	0

	jp	test

test:
	ld	sp,topstack

	; test arithmetic
	ld	bc,123
	ld	hl,22
	call	multiply
	call	divide

	; init minos
	call	initschedule

	; test some create tasks
	;   1. the task priority (1..254)
	;   2. the task period (0 means non periodic task)
	;   3. the initial program counter
	;   4. the initial task stack pointer
	;   5. the pointer to the task name
	ld	hl,2			; prio
	push	hl
	ld	hl,0			; period
	push	hl
	ld	hl,4343h		; pc
	push	hl
	ld	hl,6363h		; sp
	push	hl
	ld	hl,name1		; name
	push	hl
	call	createtask
	ld	hl,1			; prio
	push	hl
	ld	hl,0			; period
	push	hl
	ld	hl,4141h		; pc
	push	hl
	ld	hl,6161h		; sp
	push	hl
	ld	hl,name2		; name
	push	hl
	call	createtask
	ld	hl,2			; prio
	push	hl
	ld	hl,0			; period
	push	hl
	ld	hl,4444h		; pc
	push	hl
	ld	hl,6464h		; sp
	push	hl
	ld	hl,name3		; name
	push	hl
	call	createtask
	ld	hl,1			; prio
	push	hl
	ld	hl,0			; period
	push	hl
	ld	hl,4242h		; pc
	push	hl
	ld	hl,6262h		; sp
	push	hl
	ld	hl,name4		; name
	push	hl
	call	createtask

endoftest:
	jp	$			;idle

name1:
	db	'task1',0

name2:
	db	'task2',0

name3:
	db	'task3',0

name4:
	db	'task4',0

	end
