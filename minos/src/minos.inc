maxtasks	equ	20		; maximal number of tasks

stateBlocked	equ	'B'		; task state blocked
stateReady	equ	'R'		; task state ready
stateStopped	equ	'S'		; task state stopped

stask		.struct			; the task structure
state		ds	1		; the current task state
prio		ds	1		; the task priority
period		ds	1		; the current task period
name		ds	2		; the pointer to the task name
stack		ds	2		; the current task stack pointer
initperiod	ds	1		; the initial task period
initpc		ds	2		; the initial program counter (start of task code)
initstack	ds	2		; the initial task stack pointer
filler		ds	4		; fill to 16 bytes
tasksize	.endstruct stask

staskdef	.struct			; the task definition structure used when creating a new task
prio		ds	1		; the task priority
period		ds	1		; the initial task period
pc		ds	2		; the initial program counter (start of task code)
stack		ds	2		; the initial task stack pointer
name		ds	2		; the pointer to the task name
staskdefsize	.endstruct staskdef
