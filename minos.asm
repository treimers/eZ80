	cpu=EZ80F91
	.assume	adl=0			;Z80-Mode

	xdef	tasktable
	xdef	initschedule
	xdef	createtask

	xref	multiply

	include	"minos.inc"
	include	"error.inc"

	segment	code

; init the minOS
;
; parameter
;   -
; returns
;   -
initschedule:
	; clear vars
	xor	a
	ld	(taskcount),a
	ld	hl,tasktable
	ld	(hl),a
	ld	d,h
	ld	e,l
	inc	de
	ld	bc,tasksize * maxtasks-1
	ldir
	; create idle task
	ld	de,idletaskdef
	call	ctinternal
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
	ld	a,(ix+stask.state)
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


; creates a new task without priority check (internally used)
;
; parameter
;   de = pointer to task definition
; returns
;   carry flag and a='error number' in case of error
;   no carry flag and a='task number' otherwise
ctinternal:
	; flag: create without prio check
	ld	b,0
	jr	ctdocreate

; creates a new task using the given parameter and sets the task state to ready
;
; parameter
;   de = pointer to task definition
; returns
;   carry flag and a='error number' in case of error
;   no carry flag and a='task number' otherwise
createtask:
	; flag: create with prio check
	ld	b,1
ctdocreate:
	; get pointer to caller parameter (iy)
	ld	iy,0
	add	iy,de
	ld	a,(iy+staskdef.prio)
	djnz	ctnocheck
	; check 0 < prio < 255
	or	a
	jr	z,cterror1
	cp	255
	jr	nc,cterror1
ctnocheck:
	; save prio for later use
	ld	c,a
	; check for too many tasks
	ld	a,(taskcount)
	cp	maxtasks
	jr	nc,cterror2
	; iterate over tasks in task table
	ld	ix,tasktable
	ld	de,tasksize
	ld	b,a
	; append directly if task table is empty
	or	a
	jr	z,ctinittask
	; restore prio
	ld	a,c
ctloop:
	; check if prio is less than prio of current task
	ld	c,(ix+stask.prio)
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
	jr	ctinittask
ctnext:
	; go to next task until end of task table reached
	add	ix,de
	djnz	ctloop
ctinittask:
	; insert task into task table slot
	; ... state
	ld	c,ready
	ld	(ix+stask.state),c
	; ... prio
	ld	b,(iy+staskdef.prio)
	ld	(ix+stask.prio),b
	; ... period
	ld	c,(iy+staskdef.period)
	ld	(ix+stask.initperiod),c
	; ... pc
	ld	c,(iy+staskdef.pc)
	ld	b,(iy+staskdef.pc+1)
	ld	(ix+stask.initpc),c
	ld	(ix+stask.initpc+1),b
	; ... sp
	ld	c,(iy+staskdef.stack)
	ld	b,(iy+staskdef.stack+1)
	ld	(ix+stask.initstack),c
	ld	(ix+stask.initstack+1),b
	; ... name
	ld	e,(iy+staskdef.name)
	ld	d,(iy+staskdef.name+1)
	ld	(ix+stask.name),e
	ld	(ix+stask.name+1),d
	; increment task count
	ld	hl,taskcount
	ld	a,(hl)
	inc	(hl)
	; signal no error and return with new task number
	or	a
	ret

cterror1:
	; error: illegal priority
	ld	a,err_ill_prio
	scf
	ret

cterror2:
	; error: too many tasks
	ld	a,err_too_mntsk
	scf
	ret

idletaskdef:
	db	255			;prio
	db	0			;period
	dw	idle			;pc
	dw	topidlestack		;stack
	dw	idlename

idlename:
	db	'idle-task',0

	segment	data

taskcount:				; the count reflecting the total number of tasks
	ds	1
tasktable:				; the task table
	ds	tasksize * maxtasks
stack:
	ds	32			; the kernel stack
topstack:				; top of kernel stack

idlestack:
	ds	32			; the kernel stack
topidlestack:				; top of kernel stack

	end
