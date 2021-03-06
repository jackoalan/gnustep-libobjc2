#define _LANGUAGE_ASSEMBLY 1
#include <ogc/machine/asm.h>

#define DTABLE_OFFSET  32
#define SMALLOBJ_MASK  1
#define SHIFT_OFFSET   4
#define DATA_OFFSET    12
#define SLOT_OFFSET    16


// Little time-delay-after string logging routine using
// backup registers for params and lr (OBVIOUSLY VIOLATES PPC-EABI!!!)
.macro LOGStr string, arg, time, lrBupReg, r3BupReg, r4BupReg, r0BupReg, r11BupReg, r12BupReg
	mflr   \lrBupReg
	mr     \r3BupReg, r3
	mr     \r4BupReg, r4
	mr     \r0BupReg, r0
	mr     \r11BupReg, r11
	mr     \r12BupReg, r12
	mr     r4, \arg
	lis    r3, \string@ha
	la     r3, \string@l(r3)
	bl     printf
	li     r3, \time
	bl     sleep
	mr     r3, \r3BupReg
	mr     r4, \r4BupReg
	mr     r0, \r0BupReg
	mr     r11, \r11BupReg
	mr     r12, \r12BupReg
	mtlr   \lrBupReg
.endm

// Simplified string logger
.macro LOGst string, arg, time
	LOGStr \string, \arg, \time, r16, r17, r18, r19, r20, r21
.endm

.macro MSGSEND receiver, sel
	.cfi_startproc

	cmplwi \receiver, 0
	beq    4f                              // Skip everything if the receiver is nil
	
	andi.  r0, \receiver, SMALLOBJ_MASK    // Sets CR0[EQ] if this is not a small int

	beq    1f

	// Decided to use small int class
	lis    r11, LSmallIntClass@ha
	lwz    r11, LSmallIntClass@l(r11)      // Small Int class -> r4 if this is a small int
	b      2f
1:
	// Decided to use `isa` pointer class of receiver
	mr     r11, \receiver                  // Load class to r4 if not a small int
2:
	lwz    r11, DTABLE_OFFSET(r11)         // Dtable -> r4




	lwz    r0, 0(\sel)                     // selector->index -> r5

	lwz    r12, SHIFT_OFFSET(r11)          // dtable->shift -> r6
	lwz    r11, DATA_OFFSET(r11)           // dtable->data -> r4
	
	cmplwi r12, 8                          // If this is a small dtable, jump to the small dtable handlers
	beq    1f
	cmplwi r12, 0
	beq    2f

	lis    r12, 0xff
	and    r12, r12, r0
	srwi   r12, r12, 14
	lwzx   r11, r11, r12
	lwz    r11, DTABLE_OFFSET(r11)
1:                                             // dtable16
	li     r12, 0xff
	slwi   r12, r12, 8
	and    r12, r12, r0
	srwi   r12, r12, 6
	lwzx   r11, r11, r12
	lwz    r11, DTABLE_OFFSET(r11)
2:                                             // dtable8
	andi.  r12, r0, 0xff
	slwi   r12, r12, 2
	lwzx   r11, r11, r12

	cmplwi r11, 0                          // If the slot is nil
	beq    5f                              // Go to the slow path and do the forwarding stuff

	lwz    r11, SLOT_OFFSET(r11)           // Load the method from the slot

3: 
	mtctr  r11                             // Utilise the count register to branch to resolved IMP
	bctr                                   // (without clobbering link register)

4:                                             // Nil receiver
	li    r3, 0
	li    r4, 0
	blr                                    // Return to caller
5:                                             // Slow lookup
	mflr   r0			       // Get Link register
	stw    r0,  4(r1)                      // Save Link register
	stwu   r1,  -40(r1)                    // Save Back chain and push stack frame
	.cfi_def_cfa_offset 40
	.cfi_offset lr, 4
	stw    r3,  4(r1)                      // Save first four parameters (r3,r4,r5,r6)
	stw    r4,  8(r1)
	stw    r5,  12(r1)
	stw    r6,  16(r1)
	stw    r7,  20(r1)
	stw    r8,  24(r1)
	stw    r9,  28(r1)
	stw    r10,  32(r1)
	stw    \receiver, 36(r1)               // Additionally store macro-resolved receiver register


	mr     r4, \sel

	bl     slowMsgLookup                   // This is the only place where the CFI directives have to be accurate...


	mr     r11, r3                         // IMP -> ip
	lwz    r3,  4(r1)                      // Save first four parameters (r3,r4,r5,r6)
	lwz    r4,  8(r1)
	lwz    r5,  12(r1)
	lwz    r6,  16(r1)
	lwz    r7,  20(r1)
	lwz    r8,  24(r1)
	lwz    r9,  28(r1)
	lwz    r10,  32(r1)
	lwz    \receiver, 36(r1)               // Additionally load macro-resolved receiver register
	addi   r1, r1, 40                      // Pop frame from stack
	lwz    r0,  4(r1)                      // Get saved Link register
	mtlr   r0                              // Restore Link register
	b      3b
	.cfi_endproc
.endm

.globl objc_msgSend_fpret
	.type	objc_msgSend_fpret, %function
.globl objc_msgSend
	.type	objc_msgSend, %function
objc_msgSend:
objc_msgSend_fpret:
	MSGSEND r3, r4
.globl objc_msgSend_stret
	.type	objc_msgSend_stret, %function
objc_msgSend_stret:
	MSGSEND r4, r5

LSmallIntClass:
	.long   SmallObjectClasses
	.align  2

