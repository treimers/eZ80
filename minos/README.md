# minOS
minOS is a small real time operating system for the Z80 processor with following features
- small kernel written in assembler
- pre-emptive task switching
- simply adoptable to hardware timer
- support for concurrent tasks and task switching
- task scheduling based on priorities
- support for periodic tasks
- utility routines for isr (interupt service routines)

## Getting started

Download the source code, assemble, link and deploy the software.

A small test program **test.asm** is provided demonstrating start und usage of **minOS**.

## Introduction

Embedded application can benefit from minOS multi tasking support allowing developers to structure and divide their solutions into logical parts that can be run independently and parallel.

minOS offers a task management based on task priority. Pre-emptive scheduling ensures the appropriate actions to real time events and and the correct activities such as interrupt handling and task switching.

Periodic tasks are also available for application use. A periodic task will be restarted after a given interval by minOS automatically allowing simple implementation of recurring operations.

Functionality to create, start or stop tasks as well as support for interupt service routines are provided by this minOS real time kernel.

minOS is written in Assembler and is by that small and fast.

## Main routines

minOS comes with two main routines that must be called in order to initialise and start it:

- minosInit
- minosStart

**minosInit** must be called prior to use any minOS functionality. The initialization will take care to set up all internal data structure.

After boot set up of a system including preparation of on-chip or external hardware, execution of self checks, initialisation of system data and creation of initial task the startung routine **minosStart** of minOS must be called.

## Task Management

minOS provides a task creation routine. This can be called during initial setup as well as during runtime in order to create new tasks that are taken into during scheduling.

Feature versions of minOS will support further operations like task deletion, task wait or task wake.

## Interrupts

minOs comes with interrupt support allowing interrupt service routines to make use of kernel functionality like task management.

A timer interrupt is required to perform management of periodic tasks and trigger recurring scheduling activities. minOS provides simple and fast functions in order to ease the process of implementing responsive interrupt service routines.

## Scheduler and Tasks
