#
# This file defines some trampolines for calling blocks.  A block function
# looks like this:
# 
# retType blockFn(block*, ...)
#
# An IMP looks like this:
#
# retType imp(id, SEL,...)
#
# The trampoline must find the block pointer and then call the block function
# with the correct first argument, the self pointer moved to the second real
# argument (the first block argument) and the _cmd parameter excised

.file	"block_trampolines.S"
#if __arm__
.syntax unified
.globl __objc_block_trampoline_sret
	.type	__objc_block_trampoline_sret, %function
.globl __objc_block_trampoline_end_sret
.globl __objc_block_trampoline
	.type	__objc_block_trampoline, %function
.globl __objc_block_trampoline_end
#else
.globl __objc_block_trampoline_sret
	.type	__objc_block_trampoline_sret, @function
.globl __objc_block_trampoline_end_sret
.globl __objc_block_trampoline
	.type	__objc_block_trampoline, @function
.globl __objc_block_trampoline_end
#endif
#if __x86_64
__objc_block_trampoline:
	mov   -15(%rip), %rsi      # Load the block pointer into the second argument
	xchg  %rdi, %rsi           # Swap the first and second arguments
	jmp   *-32(%rip)           # Call the block function
__objc_block_trampoline_end:
__objc_block_trampoline_sret:
	mov   -15(%rip), %rdx      # Load the block pointer into the second argument
	xchg  %rdx, %rsi           # Swap the first and second arguments
	jmp   *-32(%rip)           # Call the block function
__objc_block_trampoline_end_sret:
#elif __i386
__objc_block_trampoline:
	call  next_line            # Store the instruction pointer on the stack
next_line:
	pop   %eax                 # Load the old instruction pointer
	mov   4(%esp), %ebx        # Load the self parameter
	mov   %ebx, 8(%esp)        # Store self as the second argument
	mov   -9(%eax), %ebx       # Load the block pointer to %ebx
	mov   %ebx, 4(%esp)        # Store the block pointer in the first argument
	jmp   *-13(%eax)           # Call the block function
__objc_block_trampoline_end:
__objc_block_trampoline_sret:
	call  next_line2           # Store the instruction pointer on the stack
next_line2:
	pop   %eax                 # Load the old instruction pointer
	mov   8(%esp), %ebx        # Load the self parameter
	mov   %ebx, 12(%esp)       # Store self as the second argument
	mov   -9(%eax), %ebx       # Load the block pointer to %ebx
	mov   %ebx, 8(%esp)        # Store the block pointer in the first argument
	jmp   *-13(%eax)           # Call the block function
__objc_block_trampoline_end_sret:
#elif __mips__
#	ifdef _ABI64
__objc_block_trampoline:
	move     $a1, $a0
	ld       $a0, -16($25)
	ld       $25, -8($25)
	jr       $25
__objc_block_trampoline_end:
__objc_block_trampoline_sret:
	move     $a2, $a1
	ld       $a1, -16($25)
	ld       $25, -8($25)
	jr       $25
__objc_block_trampoline_end_sret:
#	else
__objc_block_trampoline:
	move   $a1, $a0
	lw     $a0, -8($25)
	lw     $25, -4($25)
	jr     $25
__objc_block_trampoline_end:
__objc_block_trampoline_sret:
	move   $a2, $a1
	lw     $a1, -8($25)
	lw     $25, -4($25)
	jr     $25
__objc_block_trampoline_end_sret:
#	endif
#elif __arm__
__objc_block_trampoline:
	mov r1, r0                 // Move self over _cmd
	ldr r0, [pc, #-16]         // Load the block pointer over self
	ldr pc, [pc, #-24]         // Jump to the block function
__objc_block_trampoline_end:
__objc_block_trampoline_sret:
	mov r2, r1                 // Move self over _cmd
	ldr r1, [pc, #-16]         // Load the block pointer over self
	ldr pc, [pc, #-24]         // Jump to the block function
__objc_block_trampoline_end_sret:
#elif __ppc__
#define _LANGUAGE_ASSEMBLY 1
#include <ogc/machine/asm.h>
__objc_block_trampoline:
	mr    r4, r3                 // Move self over _cmd
    mflr  r0
    bl    0
    mflr  r3
    mtlr  r0
	addi  r3, r3, -32               // Load the block pointer over self
	b     -40                   // Jump to the block function
__objc_block_trampoline_end:
__objc_block_trampoline_sret:
	mr    r5, r4                 // Move self over _cmd
    mflr  r0
    bl    0
    mflr  r4
    mtlr  r0
	addi  r4, r4, -32               // Load the block pointer over self
	b     -40                   // Jump to the block function
__objc_block_trampoline_end_sret:
#else
#warning imp_implementationWithBlock() not implemented for your architecture
__objc_block_trampoline:
__objc_block_trampoline_end:
__objc_block_trampoline_sret:
__objc_block_trampoline_end_sret:
#endif
.section .note.GNU-stack,"",%progbits
