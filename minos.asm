	cpu=EZ80F91
	.assume	ADL = 0			;Z80-Mode

	xdef	tasktable
	xdef	initschedule
	xdef	createtask

	xref	multiply
	xref	divide

	include	"minos.inc"

	segment	data

taskcount:				; the count reflecting the total number of tasks
	ds	1
tasktable:				; the task table
	ds	tasksize * tasks
stack:
	ds	200			; the kernel stack
topstack:				; top of stack

	segment	code

initschedule:				; init the mini ROS
	xor	a
	ld	(taskcount),a
	ld	hl,tasktable
	ld	(hl),a
	ld	d,h
	ld	l,e
	inc	de
	ld	bc,tasksize * tasks-1
	ldir
	ret

schedule:				; the main scheduler
	ld	sp,topstack
	ld	hl, taskcount
	ld	b,(hl)
	inc	hl
	ld	c,(hl)
	ld	ix,tasktable
	ld	de,tasksize
loop:
	ld	a,(ix+stasktable.state)
	cp 	ready
	jr	z,found
	add	ix,de
	djnz	loop
	dec c
	jr	nz,loop
	ei
idle:
	jp	idle

found:					; ix points to next runnable task

; creates a new task using the given parameter and sets the task state to ready
;
; parameter (16 bit on stack)
;   1. the task priority (1..254)
;   2. the task period (0 means non-periodic task)
;   3. the initial program counter
;   4. the initial task stack pointer
;   5. the pointer to the task name
;
; returns
;   carry flag and a='error number' in case of error
;   no carry flag and a='task number' otherwise
;
; register used
;   af, bc, de, hl, ix, iy
createtask:
	; get pointer to caller parameter, return address plus parameter (iy)
	ld	iy,2 + 2 * 5
	add	iy,sp
	; check 0 < prio < 255
	ld	a,(iy-2)
	or	a
	jr	z,cterror1
	cp	255
	jr	nc,cterror1
	; save prio for later use
	ld	c,a
	; check for too many tasks
	ld	a,(taskcount)
	cp	tasks
	jr	nc,cterror2
	; iterate over tasks in task table
	ld	ix,tasktable
	ld	de,tasksize
	ld	b,a
	; append directly if task table is empty
	or	a
	jr	z,ctinit
	; restore prio
	ld	a,c
ctloop:
	; check if prio is less than prio of current task
	ld	c,(ix+stasktable.prio)
	cp	c
	jr	nc,ctnext
	; create slot for new task by moving all remaining tasks
	; ... bc = length
	ld	c,b
	ld	b,0
	ld	hl,tasksize
	call	multiply
	ld	b,h
	ld	c,l
	; ... hl = source
	push	ix
	pop	hl
	dec	hl
	add	hl,bc
	; ... de = destination
	ex	de,hl
	ld	hl,tasksize
	add	hl,de
	ex	de,hl
	; ... move remaining tasks
	lddr
	jr	ctinit
ctnext:
	; go to next task until end of task table reached
	add	ix,de
	djnz	ctloop
ctinit:
	; insert task into task table slot
	; ... state
	ld	c,ready
	ld	(ix+stasktable.state),c
	; ... prio
	ld	b,(iy-2)
	ld	(ix+stasktable.prio),b
	; ... period
	ld	c,(iy-4)
	ld	(ix+stasktable.initperiod),c
	; ... pc
	ld	c,(iy-6)
	ld	b,(iy-5)
	ld	(ix+stasktable.initpc),c
	ld	(ix+stasktable.initpc+1),b
	; ... sp
	ld	c,(iy-8)
	ld	b,(iy-7)
	ld	(ix+stasktable.initstack),c
	ld	(ix+stasktable.initstack+1),b
	; ... name
	ld	e,(iy-10)
	ld	d,(iy-9)
	ld	(ix+stasktable.name),e
	ld	(ix+stasktable.name+1),d
	; increment task count
	ld	hl,taskcount
	ld	a,(hl)
	inc	(hl)
	; signal no error and return with new task number
	or	a
	ret

cterror1:
	; error: illegal priority
	ld	a,1
	scf
	ret

cterror2:
	; error: too many tasks
	ld	a,2
	scf
	ret

	end
