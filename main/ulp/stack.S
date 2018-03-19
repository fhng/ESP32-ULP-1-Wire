/*
 * ULP stack and subroutine macros
 */

// R3, you shouldn't touch it in your code
// R1, Don't use it before call a subsoutine, it will get overridden
// R0 and R2 is left for usage.
// Or just PUSH R0-R2 and POP them out.


.macro push rx
	st \rx,r3,0
	sub r3,r3,1
.endm

.macro pop rx
	add r3,r3,1
	ld \rx,r3,0
.endm

// Prepare subroutine jump, uses scratch register sr
// .(DOT) points to your current position of your code, NOT a program counter(register)

.macro psr sr=r1 pos=.
	.set _next2,(\pos+16)
	move \sr,_next2
	push \sr
.endm

// Return from subroutine
.macro ret sr=r1
	pop \sr
	jump \sr
.endm

