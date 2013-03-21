#!/bin/bash

# Bitcode Compile
clang-mp-3.3 -emit-llvm -c -include ../../wii-prefix.pch -o objc_msgSend.bc -fno-builtin -fobjc-exceptions -fobjc-runtime=gnustep-1.7 -I. -I.. -I../objc -I../../build/devkitPPC/powerpc-eabi/include/  -D WIISTEP=1 -D NO_PTHREADS -D __TOY_DISPATCH__ -I ../../build/libogc/include/ objc_msgSend.m

# Static Compile
llc-mp-3.3 -filetype=asm -asm-verbose -mtriple=powerpc-generic-eabi -mcpu=750 -float-abi=hard -relocation-model=static -o objc_msgSend.S objc_msgSend.bc

# Link
powerpc-eabi-gcc -o objc_msgSend.elf objc_msgSend.S -I../../build/devkitPPC/powerpc-eabi/include/ -meabi -mhard-float -mcpu=750 -mrvl -L ../../build/ -L ../../build/libogc/lib/wii/ -lobjc -logc ../../ssp.c

# Prepare for Nintendo Bootloader
elf2dol -v -v objc_msgSend.elf objc_msgSend.dol
