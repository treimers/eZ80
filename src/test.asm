	cpu=EZ80F91
	.assume	adl=0			;Z80-Mode

	xdef	test

	xref	multiply
	xref	divide
	xref	minosinit
	xref	minos
	xref	createtask
	xref	inttab
	xref	timerinit
	xref	kernelstack

	segment	code

test:
	; init
	ld	hl,0
	ld	(count1),hl
	ld	(count2),hl
	ld	(count3),hl
	; load stack pointer
	ld	sp,kernelstack
	; test arithmetic
	ld	bc,123
	ld	hl,22
	call	multiply
	jr	c,$			; stop on error
	call	divide
	jr	c,$			; stop on error
	; init minos
	call	minosinit
	; create some test tasks
	ld	de,taskdef1
	call	createtask
	jr	c,$			; stop on error
	ld	de,taskdef2
	call	createtask
	jr	c,$			; stop on error
	ld	de,taskdef3
	call	createtask
	jr	c,$			; stop on error
	; setup interrupts
	im	2
	ld	a,inttab >> 8 & 0ffh
	ld	i,a
	; init timer
	call	timerinit
	; start minos
	jp	minos

taskdef1:
	db	2			;prio
	db	1			;period
	dw	task1			;pc
	dw	stack1			;stack
	dw	name1

taskdef2:
	db	1			;prio
	db	20			;period
	dw	task2			;pc
	dw	stack2			;stack
	dw	name2

taskdef3:
	db	3			;prio
	db	0			;period
	dw	task3			;pc
	dw	stack3			;stack
	dw	name2

name1:
	db	'task1',0

name2:
	db	'task2',0

name3:
	db	'task3',0

task1:
	ld	hl,(count1)
	inc	hl
	ld	(count1),hl
	ret

task2:
	ld	hl,(count2)
	inc	hl
	ld	(count2),hl
	ret

task3:
	ld	hl,(count3)
	inc	hl
	ld	(count3),hl
	jr	task3

	segment	data

	ds	32
stack1:
	ds	32
stack2:
	ds	32
stack3:

count1:
	ds	2
count2:
	ds	2
count3:
	ds	2

	end
