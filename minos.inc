maxtasks	equ	20		; maximal number of tasks
blocked		equ	'B'		; task state blocked
ready		equ	'R'		; task state ready
stopped		equ	'S'		; task state stopped

stask		.struct			; the task structure
state		ds	1		; the current task state
prio		ds	1		; the task priority
initperiod	ds	1		; the initial task period
initpc		ds	2		; the initial program counter (start of task code)
initstack	ds	2		; the initial task stack pointer
name		ds	2		; the pointer to the task name
pc		ds	2		; the current task program counter
stack		ds	2		; the current task stack pointer
period		ds	1		; the current task period
filler		ds	2		; fill up to 16 bytes to ease debugging and testing
tasksize	.endstruct stask

staskdef	.struct			; the task definition structure for task creation
prio		ds	1		; the task priority
period		ds	1		; the initial task period
pc		ds	2		; the initial program counter (start of task code)
stack		ds	2		; the initial task stack pointer
name		ds	2		; the pointer to the task name
staskdefsize	.endstruct staskdef
