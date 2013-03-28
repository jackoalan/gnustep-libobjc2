#!/bin/bash

# Our very own LLVM build
LLVM_DIR=../../llvm/build/bin

# devkitPPC and libogc
DKPPC_DIR=../../build/devkitPPC
OGC_DIR=../../build/libogc

# Bitcode Compile
$LLVM_DIR/clang -target powerpc-generic-eabi -emit-llvm -c -include ../../wii-prefix.pch -o objc_msgSend.bc -fno-builtin -fobjc-exceptions -fobjc-runtime=gnustep-1.7 -I. -I.. -I../objc -I../../build/devkitPPC/powerpc-eabi/include/ -D __PPC__=1 -D _BIG_ENDIAN=1 -D WIISTEP=1 -D NO_PTHREADS -D __TOY_DISPATCH__ -D NO_LEGACY -I ../../build/libogc/include/ objc_msgSend.m

# Bitcode Link
$LLVM_DIR/llvm-link -o objc_msgSend_link.bc ../../build/libobjc-wii.a objc_msgSend.bc

# Optimisation
$LLVM_DIR/opt -o objc_msgSend_link_opt.bc -load=$LLVM_DIR/../lib/libGNUObjCRuntime.dylib -gnu-class-lookup-cache objc_msgSend_link.bc

# Static Compile
$LLVM_DIR/llc -filetype=asm -asm-verbose -mtriple=powerpc-generic-eabi -mcpu=750 -float-abi=hard -relocation-model=static -o objc_msgSend_link_opt.S objc_msgSend_link_opt.bc

# Link
$DKPPC_DIR/bin/powerpc-eabi-gcc -o objc_msgSend_link_opt.elf objc_msgSend_link_opt.S -I$DKPPC_DIR/powerpc-eabi/include/ -meabi -mhard-float -mcpu=750 -mrvl -L ../../build/ -lobjc-wii-asm -L $OGC_DIR/lib/wii/ -logc ../../wii-support.c

# Prepare for Nintendo Bootloader
$DKPPC_DIR/bin/elf2dol -v -v objc_msgSend_link_opt.elf objc_msgSend_link_opt.dol
