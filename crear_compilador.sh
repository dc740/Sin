#!/bin/bash


GROUP_NAME=GrupoTema2
bison --output=./$GROUP_NAME.c $GROUP_NAME.y


echo Intentando compilar el compilador...

g++ -g ./$GROUP_NAME.c -o ./$GROUP_NAME.exec


echo Intentando compilar el codigo de programa1.sin
./$GROUP_NAME.exec

echo Intentando compilar programa.asm
as -g --32 -o "Final.o" "Final.asm" 
ld -g -melf_i386 -o "Final.exec" "Final.o"
