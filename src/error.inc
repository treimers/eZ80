err_ctl_int	equ	1			; control flow: unexpected interrupt
err_ctl_restart	equ	2			; control flow: unexpected restart operation
err_ctl_nmi	equ	3			; control flow: unexpected nmi
err_tsk_illprio	equ	4			; task: illegal priority
err_tsk_dupprio	equ	5			; task: duplicate priority
err_tsk_toomany	equ	6			; task: too many tasks
err_tsk_busy	equ	7			; task: periodic task still busy
