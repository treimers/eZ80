	cpu=EZ80F91
	.assume	adl=0			;Z80-Mode

	xdef	minosInit
	xdef	minosMain
	xdef	minosCreateTask
	xdef	minosSystemTick
	xdef	minosSaveContext
	xdef	minosKernelStack

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
minosInit:
	; clear variables
	ld	hl,varbegin
	ld	(hl),0
	ld	de,varbegin + 1
	ld	bc,varend - varbegin - 1
	ldir
	ret

; saves the context of interrupted processing.
;
; parameters:
;   -
; returns:
;   -
minosSaveContext:
	; get return address and save hl to stack
	ex	(sp),hl
	; save af, bc, de to stack
	push	af
	push	bc
	push	de
	; save ix, iy to stack
	push	ix
	push	iy
	; save af', bc', de', hl' to stack
	ex	af,af'
	exx
	push	af
	push	bc
	push	de
	push	hl
	exx
	; manipulate return address
	ld	de,mschedule
	push	de
	; return to caller
	jp	(hl)

; restores the context of interrupted processing,
; enables interrupts again and returns to point of interruption.
;
; parameters:
;   -
; returns:
;   -
minosRestoreContext:
	; restore hl', de', bc', af' from stack
	pop	hl
	pop	de
	pop	bc
	pop	af
	ex	af,af'
	exx
	; restore iy, ix from stack
	pop	iy
	pop	ix
	; restore de, bc, af, hl from stack
	pop	de
	pop	bc
	pop	af
	pop	hl
	; enable interrupts and return
	ei
	ret

; invokes the scheduling at end of an interrupt routine.
;
; restores context of interrupted processing if no new scheduling is required.
; searches for runnable tasks with highest priority otherwise.
; idles if no runnable task available.
mschedule:
	; if all task states unchanged, continue with interrupted flow
	ld	a,(requiresched)
	or	a
	jr	z,minosRestoreContext
	; save current task if available
	ld	bc,(currenttask)
	ld	a,b
	or	c
	jr	z,minosMain
	ld	ix,0
	add	ix,bc
	ld	hl,0
	add	hl,sp
	ld	(ix+stask.stack),l
	ld	(ix+stask.stack+1),h

; starts the scheduling process
;
; searches for runnable tasks with highest priority.
; idles if no runnable task available.
minosMain:
	ld	sp,minosKernelStack
	xor	a
	ld	(requiresched),a
	ld	hl, taskcount
	ld	a,(hl)
	ld	ix,tasktable
	ld	de,tasksize
	or	a
	jr	z,mschedexit
	ld	b,a
mschedloop:
	ld	a,(ix+stask.state)
	cp 	stateReady
	jr	z,mschedfound
	add	ix,de
	djnz	mschedloop
	ld	bc,0
	ld	(currenttask),bc
	; nothing found, enable interrupts and wait for wake by interrupt
mschedexit:
	ei
	halt

; ix points to next runnable task
mschedfound:
	ld	(currenttask),ix
	ld	l,(ix+stask.stack)
	ld	h,(ix+stask.stack+1)
	ld	sp,hl
	jr	minosRestoreContext

; invoked by return from task when tasks ends.
; sets task state to stopped and starts rescheduling.
mschedendtask:
	ld	ix,(currenttask)
	ld	(ix+stask.state),stateStopped
	ld	bc,0
	ld	(currenttask),bc
	jr	minosMain

; handles the system tick when invoked by timer isr.
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
minosSystemTick:
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
	cp	stateReady
	jr	z,sterror
	; decrement period, continue if not zero
	dec	(ix+stask.period)
	jr	nz,stcontinue
	; set new state
	ld	(ix+stask.state),stateReady
	; reload period
	ld	a,(ix+stask.initperiod)
	ld	(ix+stask.period),a
	; init pc
	; ... pc & stack
	ld	l,(ix+stask.initstack)
	ld	h,(ix+stask.initstack+1)
	ld	de,mschedendtask
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

; creates a new task using the given parameter and sets the task state to stopped
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
minosCreateTask:
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
	ld	(ix+stask.state),stateStopped
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
varbegin:				; begin of variable section
taskcount:				; the count reflecting the total number of tasks
	ds	1
requiresched:
	ds	1
currenttask:
	ds	2			; pointer to current running task
tasktable:				; the task table
	ds	tasksize * maxtasks
varend:					; end of variable section

	ds	32			; the kernel stack
minosKernelStack:			; top of kernel stack

	end
