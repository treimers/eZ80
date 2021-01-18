# minOS
minOS is a tiny real time operating system for the Z80 processor with following features

- small kernel written in assembler
- task scheduling based on priorities (pre-emptive task switching)
- simply adoptable to hardware timer
- support for concurrent task execution 
- support for periodic tasks
- utility routines for isr (interupt service routines)

## Getting started

Download the source code, assemble, link and deploy the software.

A small test program **test.asm** is provided demonstrating start und usage of **minOS**.

## Introduction

Embedded applications can benefit from minOS multi tasking support allowing developers to structure and divide their solutions into logical parts that can be run independently and in parallel.

minOS offers a task management based on task priority. Pre-emptive scheduling ensures the appropriate reactions to real time events and and the correct activities such as interrupt handling and task switching.

Periodic tasks are also available in minOS for application use. A periodic task will be restarted after a given interval automatically allowing simple implementation of recurring operations.

Functionality to create, start or stop tasks as well as support for interupt service routines are provided by the minOS real time kernel.

minOS is written in Assembler and is by that small and fast.

## Main routines

minOS comes with two main routines that must be called in order to initialise and start it:

- **minosInit**
- **minosStart**

**minosInit** must be called prior to use any minOS functionality. The initialization will take care for setting up all internal data structure.

After initialisation of a system including preparation of on-chip or external hardware, execution of self checks, initialisation of system data and creation of initial task the start routine **minosStart** of minOS must be called. The routine will run in an endless loop and will take care for minOS schedeling.

## Task Management

minOS provides a task creation routine **minosCreateTask**. This can be called during initial setup as well as during runtime in order to create new tasks that are taken into account by the minOS scheduler.

```
	ld  de,taskdef
	call	minosCreateTask
	jr  c,error
	...
  
taskdef:
	db	2   ;prio
	db	1   ;period
	dw	task  ;pc
	dw	stack ;stack
	dw	name  ;name
  
name:
	db	'task',0
  
task:
	ld	hl,(count)
	inc	hl
	ld	(count),hl
	ret

	ds	32
stack:
```

Feature versions of minOS will support further operations like task deletion **minosDeleteTask**, task wait **minosWait**, wake of tasks **minosWake** and others.

## Interrupts

An API function **minosSaveContext** is available for interrupt services routines that must be invoked prior to any calls to kernel routines from an interrupt handler.

```
uart_isr:
	call	minosSaveContext
  ...
  reti
```

A timer interrupt is required to perform management of periodic tasks and trigger recurring scheduling activities. The time interrupt handler must ensure that minOS system tick handling is invoked by calling **minosSystemTick** on every interrupt by the timer.

```
timer_isr:
	call	minosSaveContext
  call	minosSystemTick
  reti
```

## Scheduler

minOS scheduling is based on task priorities. When a task with priority higher than that of the currently running task is activated the scheduler will perform a task switch on next invocation. This approach is called pre-emptive scheduling.

## Tasks

