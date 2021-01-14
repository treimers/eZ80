	cpu=EZ80F91
	.assume	adl=0			;Z80-Mode

	xdef	minosinit
	xdef	minos
	xdef	createtask
	xdef	systick
	xdef	saveregs
	xdef	kernelstack

	xref	multiply
	xref	error

	include	"minos.inc"
	include	"error.inc"

	segment	code

; initializes the minOS
;
; parameter
;   -
; returns
;   -
minosinit:
	; clear vars
	xor	a
	ld	(taskcount),a
	ld	(requiresched),a
	ld	hl,tasktable
	ld	(hl),a
	ld	d,h
	ld	e,l
	inc	de
	ld	bc,tasksize * maxtasks-1
	ldir
	ret

; saves the context of interrupted job.
;
; parameters:
;   -
; returns:
;   -
saveregs:
	; save hl, af, bc, de
	ex	(sp),hl
	push	af
	push	bc
	push	de
	; save ix, iy
	push	ix
	push	iy
	; save af', bc', de', hl'
	ex	af,af'
	exx
	push	af
	push	bc
	push	de
	push	hl
	exx
	; manipulate return address
	ld	de,schedule
	push	de
	; return to caller
	jp	(hl)

restoreregs:
	; restore hl', de', bc', af'
	pop	hl
	pop	de
	pop	bc
	pop	af
	ex	af,af'
	exx
	; restore iy, ix
	pop	iy
	pop	ix
	; restore de', bc', af', hl'
	pop	de
	pop	bc
	pop	af
	pop	hl
	; enable interrupts and return
	ei
	ret

schedule:
	; if all task states unchanged, continue with interrupted flow
	ld	a,(requiresched)
	or	a
	jr	z,restoreregs
	; save current task if available
	ld	bc,(currenttask)
	ld	a,b
	or	c
	jr	z,minos
	ld	ix,0
	add	ix,bc
	ld	hl,0
	add	hl,sp
	ld	(ix+stask.stack),l
	ld	(ix+stask.stack+1),h
minos:
	ld	sp,kernelstack
	ld	hl, taskcount
	ld	a,(hl)
	ld	ix,tasktable
	ld	de,tasksize
	or	a
	jr	z,schedexit
	ld	b,a
schedloop:
	ld	a,(ix+stask.state)
	cp 	ready
	jr	z,schedfound
	add	ix,de
	djnz	schedloop
	ld	bc,0
	ld	(currenttask),bc
schedexit:
	ei
schedidle:
	jp	schedidle

; ix points to next runnable task
schedfound:
	ld	(currenttask),ix
	ld	l,(ix+stask.stack)
	ld	h,(ix+stask.stack+1)
	ld	sp,hl
	jr	restoreregs

schedendtask:
	ld	ix,(currenttask)
	ld	(ix+stask.state),stopped
	ld	bc,0
	ld	(currenttask),bc
	jr	minos

; handles the system tick invoked by timer isr.
;
; decrements counter for each priodic tasks and
; starts all tasks where period is expired.
;
; aborts the system in case of attempt to restart
; a periodic task that is still running.
;
; parameters:
;   -
; returns:
;   -
; errors:
;   err_tsk_busy: cannot restart already running task
systick:
	; get task table
	ld	ix,tasktable
	; do nothing if task table empty
	ld	a,(taskcount)
	or	a
	jr	z,stexit
	ld	b,a
	; iterate over all tasks
stloop:
	; ignore non-periodic tasks
	ld	a,(ix+stask.initperiod)
	or	a
	jr	z,stcontinue
	; check busy
	ld	a,(ix+stask.state)
	jr	z,stcontinue
	cp	ready
	jr	z,sterror
	; decrement period, continue if not zero
	dec	(ix+stask.period)
	jr	nz,stcontinue
	; set new state
	ld	(ix+stask.state),ready
	; reload period
	ld	a,(ix+stask.initperiod)
	ld	(ix+stask.period),a
	; init pc
	; ... pc & stack
	ld	l,(ix+stask.initstack)
	ld	h,(ix+stask.initstack+1)
	ld	de,schedendtask
	dec	hl
	ld	(hl),d
	dec	hl
	ld	(hl),e
	ld	e,(ix+stask.initpc)
	ld	d,(ix+stask.initpc+1)
	dec	hl
	ld	(hl),d
	dec	hl
	ld	(hl),e
	ld	de,10*2
	or	a
	sbc	hl,de
	ld	(ix+stask.stack),l
	ld	(ix+stask.stack+1),h
	; mark scheduling required
	ld	a,1
	ld	(requiresched),a
stcontinue:
	ld	de,tasksize
	add	ix,de
	djnz	stloop
stexit:
	ret

sterror:
	ld	a,err_tsk_busy
	jp	error

; creates a new task using the given parameter and sets the task state to ready
;
; parameters:
;   de = pointer to task definition
; returns:
;   no carry flag and a='task number'
;   carry flag and a='error number' in case of error
; errors:
;   err_tsk_illprio: prio = 0 or prio = 255
;   err_tsk_dupprio: prio already in use
;   err_tsk_toomany: too many tasks
createtask:
	; get pointer to caller parameter (iy)
	ld	iy,0
	add	iy,de
	ld	a,(iy+staskdef.prio)
	; check 0 < prio < 255
	or	a
	jr	z,cterror1
	cp	255
	jr	nc,cterror1
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
	jr	c,ctinsert
	; check for duplicate prio
	jr	z,cterror3
	; go to next task until end of task table reached
	add	ix,de
	djnz	ctloop
ctinittask:
	; insert task into task table slot
	; ... state
	ld	(ix+stask.state),stopped
	; ... prio
	ld	b,(iy+staskdef.prio)
	ld	(ix+stask.prio),b
	; ... period
	ld	c,(iy+staskdef.period)
	ld	(ix+stask.initperiod),c
	ld	(ix+stask.period),c
	; ... pc
	ld	c,(iy+staskdef.pc)
	ld	b,(iy+staskdef.pc+1)
	ld	(ix+stask.initpc),c
	ld	(ix+stask.initpc+1),b
	; ... sp
	ld	l,(iy+staskdef.stack)
	ld	h,(iy+staskdef.stack+1)
	ld	(ix+stask.initstack),l
	ld	(ix+stask.initstack+1),h
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

ctinsert:
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

cterror1:
	; error: illegal task priority
	ld	a,err_tsk_illprio
	scf
	ret

cterror2:
	; error: too many tasks
	ld	a,err_tsk_toomany
	scf
	ret

cterror3:
	; error: duplicate task priority
	ld	a,err_tsk_dupprio
	scf
	ret

	segment	data

taskcount:				; the count reflecting the total number of tasks
	ds	1
requiresched:
	ds	1
currenttask:
	ds	2			; pointer to current running task
tasktable:				; the task table
	ds	tasksize * maxtasks

	ds	32			; the kernel stack
kernelstack:				; top of kernel stack

	end
