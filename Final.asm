/*
@author: Emilio Moretti
Copyright 2013 Emilio Moretti <emilio.morettiATgmailDOTcom>
This program is distributed under the terms of the GNU Lesser General Public License.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public License
along with this program. If not, see <http://www.gnu.org/licenses/>.
*/

// A macro with two parameters
//  implements the write system call
   .macro write str, str_size 
      movl  $4, %eax
      movl  $1, %ebx
      movl  \str, %ecx
      movl  \str_size, %edx
      int   $0x80
   .endm
   
// Implements the read system call
   .macro read buff, buff_size
      movl  $3, %eax
      movl  $0, %ebx
      movl  \buff, %ecx
      movl  \buff_size, %edx
      int   $0x80
   .endm
   
// declare a string
.macro def_str name, value
	\name:
	  .ascii "\value\0"
	  sizeof_\name:
	  .long .-\name -1
	  
.endm

// declare an integer constant
.macro def_int name, value
	\name:
	  .word \value
	  .word 0
.endm


/*

Our code starts here!
*/
.section .data
fbuffer:
    .float 0.0
newline:
	.ascii "\n\0"
def_int string_temp,0
__real_0:
.float 3.14
__pi:
.float 0.0
def_int __var1, 0
def_int __var2, 0
def_int __int_5, 0
def_int __var3, 0
def_int __var4, 0
def_str __constant_str_9, "hola "
def_int __string1, 0
def_str __constant_str_12, "mundo"
def_int __string2, 0
def_int __string3, 0
def_str __constant_str_23, "0@var4:"
def_str __constant_str_27, "~(var4)"
def_str __constant_str_32, "valor de var1"
def_int __int_34, 42
def_str __constant_str_39, "var1+2 usando asignaciones especiales"
def_int __int_41, 2
__real_49:
.float 3.13
def_str __constant_str_51, "pi es mayor que 3.13"
def_int __int_55, 8
def_int __int_57, 1
def_str __constant_str_63, "despues del while var3 vale:"
def_str __constant_str_83, "Valores de las variables var3 y var4 dentro del for"
def_str __constant_str_90, "string1:"
def_str __constant_str_94, "string2:"
def_str __constant_str_98, "Concatenadas:"
#1#
     
.section .bss
    .lcomm str_buff, 2048
#2#


# Text segment begins
.section .text
.global _start

/*
Gets the string to be printed and the lenght
*/
	print_str:
		#Create a stack frame
		pushl %ebp  #stack base address is on the stack.
		movl %esp, %ebp  #now the base pointer is the same as esp
		#dont save all 32 bit registers, leave that to the programmer outside. pushal = pushad
		#pushal   
		
		# string: ebp+4(return addresss)+4(string pointer)
		# string len: ebp+4(return address)+4(string pointer)+4(string len)

		movl  $4, %eax
		movl  $1, %ebx
		movl 8(%ebp),%ecx  #ecx has the string pointer (the memory reference means: ebp + 4)
		movl 12(%ebp),%edx  #edx has the string lenght
		int   $0x80
		
		movl  $4, %eax
		movl  $1, %ebx
		movl $newline,%ecx  #ecx has the string pointer (the memory reference means: ebp + 4)
		movl $1,%edx  #edx has the string lenght
		int   $0x80
		
		#don't pop the registers, we didn't backup them
		#popal #restore all registers
		
		#function return value
		movl $0, %eax
		
		# restore the stack
		movl %ebp, %esp #restore esp
		popl %ebp       #restore stack base pointer
	ret $8 # return and remove parameters (string, lenght): 8 = sizeof(string) + sizeof(lenght)

/*
compare two strings
*/
string_equals:
dec %edi
lab1:
inc %edi ;//ds:di -> next character in string2
lodsb ;//load al with next char from string 1
;//note: lodsb increments si automatically
cmpb  %al,(%edi) ;//compare characters
jne NotEqual ;//jump out of loop if they are not the same
cmpb $0,%al ;//they are the same, but end of string?
jne lab1 ;//no - so go round loop again
;//-----------------------------------------------------------------------------
;//end of string, and the "jne NotEqual" instruction hasn't been executed so they're equal
;//-----------------------------------------------------------------------------
mov $0,%eax
jmp string_cmp_end ;//continue with rest of program
NotEqual:
mov $1,%eax
string_cmp_end:
ret

/*
compare two strings
*/
string_below:
dec %edi
lab1_b:
inc %edi ;//ds:di -> next character in string2
lodsb ;//load al with next char from string 1
;//note: lodsb increments si automatically
cmpb $0,%al ;//they are the same, but end of string?
je next_b ;//no - so go round loop again
cmpb  %al,(%edi) ;//compare characters
jnb NotEqual_b ;//jump out of loop if they are not the same
;//-----------------------------------------------------------------------------
;//end of string, and the "jne NotEqual" instruction hasn't been executed so they're equal
;//-----------------------------------------------------------------------------
next_b:
mov $0,%eax

jmp string_cmp_end_b ;//continue with rest of program
NotEqual_b:
mov $1,%eax
string_cmp_end_b:
ret

/*
compare two strings
*/
string_above:
dec %edi
lab1_a:
inc %edi ;//ds:di -> next character in string2
lodsb ;//load al with next char from string 1
;//note: lodsb increments si automatically
cmpb $0,%al ;//they are the same, but end of string?
je next_a ;//no - so go round loop again
cmpb  %al,(%edi) ;//compare characters
jna NotEqual_a ;//jump out of loop if they are not the same

;//-----------------------------------------------------------------------------
;//end of string, and the "jne NotEqual" instruction hasn't been executed so they're equal
;//-----------------------------------------------------------------------------
next_a:
mov $0,%eax
jmp string_cmp_end_a ;//continue with rest of program
NotEqual_a:
mov $1,%eax
string_cmp_end_a:
ret


/*
print a single char on screen
*/
putc:
;// prints the character in al
	pushl %edx
	pushl %ecx
	pushl %ebx
    pushl %eax ;// doubles as a buffer to print from

	movl  $4, %eax
	movl  $1, %ebx
	movl %esp,%ecx  #ecx has the string pointer (the memory reference means: ebp + 4)
	movl $1,%edx  #edx has the string lenght
	int   $0x80

    popl %eax
    popl %ebx
    popl %ecx
    popl %edx
    ret
/*
;//Prints AX in hex to the screen when CALLed.
*/
Hex2ASCII: 
	pushw %cx
	movw $4,%cx
	H2Aloop:
		rol $4,%ax
		pushw %ax
		and $0x0F,%al
		cmp $0x0A,%al
		sbb $0x69,%al
		das
		call putc
		popw %ax
		dec %cx
		jnz H2Aloop
	popw %cx
ret
/*
Close program. Gets the exit code in the stack
*/
exit:
	# Put the code number for system call
	movl  $1, %eax
	movl 4(%esp),%ebx  /* Return value */
	int   $0x80    /* Bye bye bambino*/
	#function return value
	movl $0, %eax
	ret $4  #should never get here anyway

/*
String Len
*/
strlen:
		#Create a stack frame
		pushl %ebp  #stack base address is on the stack.
		movl %esp, %ebp  #now the base pointer is the same as esp
 
		xor	%ecx, %ecx
		movl 8(%ebp),%edi
		not	%ecx
		xor %eax, %eax
		cld
		repne scasb
		not	%ecx
		lea	-1(%ecx),%eax
 
		# restore the stack
		movl %ebp, %esp #restore esp
		popl %ebp       #restore stack base pointer
	ret $4
	
/*
Return an empty space in str_buff
*/
get_space:
		#Create a stack frame
		pushl %ebp  #stack base address is on the stack.
		movl %esp, %ebp  #now the base pointer is the same as esp
		movl $str_buff,%edi
		alloc_start:
			
			xor	%ecx, %ecx
			not	%ecx
			xor %eax, %eax
			cld
			repne scasb ;//search the first 0
			not %ecx
			mov $2048,%ebx
			sub %ecx,%ebx
			movl %ebx,%ecx ;//ebx has the amount of memory remains
			movl %edi,(string_temp)
			xor %eax, %eax
			cld
			repe	scasb   ;//repeat until something different than 0 is found
			sub %ecx,%ebx
			movl 8(%ebp),%eax ;//expected
			cmp %eax,%ebx  ;//check if we managed to get the required ammount
			jbe alloc_start ;//if we didnt start all over
			mov (string_temp),%eax
		# restore the stack
		movl %ebp, %esp #restore esp
		popl %ebp       #restore stack base pointer
	ret $4
	
# Program entry point
_start:

__at_block_2:
__real_0__decl_0:
movl (__real_0),%eax
pushl %eax
__pi_1:
mov (__pi),%eax
pushl %eax
__at_2:
popl %ebx
popl %eax
movl %eax,(__pi)
__at_block_2_decl:
__var1_3:
mov (__var1),%eax
pushl %eax
__var1_3_decl:
popl %eax
__var2_4:
mov (__var2),%eax
pushl %eax
__var2_4_decl:
popl %eax
__at_block_7:
__int_5__decl_5:
xor %eax,%eax
movw (__int_5),%ax
pushl %eax
__var3_6:
mov (__var3),%eax
pushl %eax
__at_7:
popl %ebx
popl %eax
movl %eax,(__var3)
__at_block_7_decl:
__var4_8:
mov (__var4),%eax
pushl %eax
__var4_8_decl:
popl %eax
__at_block_11:
__constant_str_9__decl_9:
movl $__constant_str_9,%eax
pushl %eax
__string1_10:
mov (__string1),%eax
pushl %eax
__at_11:
popl %ebx
popl %eax
movl %eax,(__string1)
__at_block_11_decl:
__at_block_14:
__constant_str_12__decl_12:
movl $__constant_str_12,%eax
pushl %eax
__string2_13:
mov (__string2),%eax
pushl %eax
__at_14:
popl %ebx
popl %eax
movl %eax,(__string2)
__at_block_14_decl:
__at_block_19:
__add_str_block_17:
__string1_15:
mov (__string1),%eax
pushl %eax
__string2_16:
mov (__string2),%eax
pushl %eax
__add_str_17:
movl 4(%esp),%eax
push %eax
call strlen
push %eax
movl 4(%esp),%eax
push %eax
call strlen
pushl %eax
movl 4(%esp),%ebx
add %ebx,%eax

pushl %eax
 
call get_space

movl 12(%esp),%esi
movl 4(%esp),%ecx
mov %eax,%edi
rep movsb
movl 8(%esp),%esi
movl (%esp),%ecx
rep movsb
xor %eax,%eax
stosb
popl %eax
popl %eax
popl %eax
popl %eax
movl (string_temp),%eax
pushl %eax
__string3_18:
mov (__string3),%eax
pushl %eax
__at_19:
popl %ebx
popl %eax
movl %eax,(__string3)
__at_block_19_decl:
__at_block_22:
__int_5__decl_20:
xor %eax,%eax
movw (__int_5),%ax
pushl %eax
__var4_21:
mov (__var4),%eax
pushl %eax
__at_22:
popl %ebx
popl %eax
movl %eax,(__var4)
__print_string_24:
__constant_str_23__decl_23:
movl $__constant_str_23,%eax
pushl %eax
movl (%esp),%eax
push %eax
 call strlen
push %eax
movl 4(%esp),%eax
push %eax
call print_str
pop %eax
__print_string_26:
__var4_25:
mov (__var4),%eax
pushl %eax
movb $'0',%al
call putc
movb $'x',%al
call putc
pop %eax
rol $16,%eax
call Hex2ASCII
rol $16,%eax
call Hex2ASCII
movb $10,%al
call putc
__print_string_28:
__constant_str_27__decl_27:
movl $__constant_str_27,%eax
pushl %eax
movl (%esp),%eax
push %eax
 call strlen
push %eax
movl 4(%esp),%eax
push %eax
call print_str
pop %eax
__print_string_31:
__not_block_30:
__var4_29:
mov (__var4),%eax
pushl %eax
__not_30:
popl %eax
not %ax
pushl %eax
movb $'0',%al
call putc
movb $'x',%al
call putc
pop %eax
rol $16,%eax
call Hex2ASCII
rol $16,%eax
call Hex2ASCII
movb $10,%al
call putc
__print_string_33:
__constant_str_32__decl_32:
movl $__constant_str_32,%eax
pushl %eax
movl (%esp),%eax
push %eax
 call strlen
push %eax
movl 4(%esp),%eax
push %eax
call print_str
pop %eax
__at_block_36:
__int_34__decl_34:
xor %eax,%eax
movw (__int_34),%ax
pushl %eax
__var1_35:
mov (__var1),%eax
pushl %eax
__at_36:
popl %ebx
popl %eax
movl %eax,(__var1)
__print_string_38:
__var1_37:
mov (__var1),%eax
pushl %eax
movb $'0',%al
call putc
movb $'x',%al
call putc
pop %eax
rol $16,%eax
call Hex2ASCII
rol $16,%eax
call Hex2ASCII
movb $10,%al
call putc
__print_string_40:
__constant_str_39__decl_39:
movl $__constant_str_39,%eax
pushl %eax
movl (%esp),%eax
push %eax
 call strlen
push %eax
movl 4(%esp),%eax
push %eax
call print_str
pop %eax
__at_block_45:
__add_block_43:
__int_41__decl_41:
xor %eax,%eax
movw (__int_41),%ax
pushl %eax
__var1_42:
mov (__var1),%eax
pushl %eax
__add_43:
popl %ebx
popl %eax
add %ebx,%eax
pushl %eax
__var1_44:
mov (__var1),%eax
pushl %eax
__at_45:
popl %ebx
popl %eax
movl %eax,(__var1)
__print_string_47:
__var1_46:
mov (__var1),%eax
pushl %eax
movb $'0',%al
call putc
movb $'x',%al
call putc
pop %eax
rol $16,%eax
call Hex2ASCII
rol $16,%eax
call Hex2ASCII
movb $10,%al
call putc
__if_block_53:
__more_block_50:
__pi_48:
mov (__pi),%eax
pushl %eax
__real_49__decl_49:
movl (__real_49),%eax
pushl %eax
__more_50:
popl %ebx
popl %eax
mov %ebx,(fbuffer)
flds fbuffer
mov %eax,(fbuffer)
flds fbuffer
fcomip
fstp %st(0) # to clear stack
ja ismore_50
mov $1,%eax
jmp endmore_50
ismore_50:
 xor %eax,%eax
endmore_50:
 pushl %eax
__if_cond_53:
popl %eax
mov $1,%ebx
cmp %eax,%ebx
je __if_end_53
__print_string_52:
__constant_str_51__decl_51:
movl $__constant_str_51,%eax
pushl %eax
movl (%esp),%eax
push %eax
 call strlen
push %eax
movl 4(%esp),%eax
push %eax
call print_str
pop %eax
__if_end_53:
__cycle_block_62:
__less_block_56:
__var3_54:
mov (__var3),%eax
pushl %eax
__int_55__decl_55:
xor %eax,%eax
movw (__int_55),%ax
pushl %eax
__less_56:
popl %ebx
popl %eax
cmp %ebx,%eax
jb isless_56
mov $1,%eax
jmp endless_56
isless_56:
xor %eax,%eax
endless_56:
pushl %eax
__cycle_cond_62:
popl %eax
mov $1,%ebx
cmp %eax,%ebx
je __cycle_end_62
__at_block_61:
__add_block_59:
__int_57__decl_57:
xor %eax,%eax
movw (__int_57),%ax
pushl %eax
__var3_58:
mov (__var3),%eax
pushl %eax
__add_59:
popl %ebx
popl %eax
add %ebx,%eax
pushl %eax
__var3_60:
mov (__var3),%eax
pushl %eax
__at_61:
popl %ebx
popl %eax
movl %eax,(__var3)
jmp __cycle_block_62
__cycle_end_62:
__print_string_64:
__constant_str_63__decl_63:
movl $__constant_str_63,%eax
pushl %eax
movl (%esp),%eax
push %eax
 call strlen
push %eax
movl 4(%esp),%eax
push %eax
call print_str
pop %eax
__print_string_66:
__var3_65:
mov (__var3),%eax
pushl %eax
movb $'0',%al
call putc
movb $'x',%al
call putc
pop %eax
rol $16,%eax
call Hex2ASCII
rol $16,%eax
call Hex2ASCII
movb $10,%al
call putc
__at_block_69:
__int_5__decl_67:
xor %eax,%eax
movw (__int_5),%ax
pushl %eax
__var4_68:
mov (__var4),%eax
pushl %eax
__at_69:
popl %ebx
popl %eax
movl %eax,(__var4)
__cycle_block_89:
__at_block_74:
__add_block_72:
__int_41__decl_70:
xor %eax,%eax
movw (__int_41),%ax
pushl %eax
__var4_71:
mov (__var4),%eax
pushl %eax
__add_72:
popl %ebx
popl %eax
add %ebx,%eax
pushl %eax
__var4_73:
mov (__var4),%eax
pushl %eax
__at_74:
popl %ebx
popl %eax
movl %eax,(__var4)
__less_block_77:
__var4_75:
mov (__var4),%eax
pushl %eax
__int_55__decl_76:
xor %eax,%eax
movw (__int_55),%ax
pushl %eax
__less_77:
popl %ebx
popl %eax
cmp %ebx,%eax
jb isless_77
mov $1,%eax
jmp endless_77
isless_77:
xor %eax,%eax
endless_77:
pushl %eax
__cycle_cond_89:
popl %eax
mov $1,%ebx
cmp %eax,%ebx
je __cycle_end_89
__at_block_82:
__add_block_80:
__int_57__decl_78:
xor %eax,%eax
movw (__int_57),%ax
pushl %eax
__var3_79:
mov (__var3),%eax
pushl %eax
__add_80:
popl %ebx
popl %eax
add %ebx,%eax
pushl %eax
__var3_81:
mov (__var3),%eax
pushl %eax
__at_82:
popl %ebx
popl %eax
movl %eax,(__var3)
__print_string_84:
__constant_str_83__decl_83:
movl $__constant_str_83,%eax
pushl %eax
movl (%esp),%eax
push %eax
 call strlen
push %eax
movl 4(%esp),%eax
push %eax
call print_str
pop %eax
__print_string_86:
__var3_85:
mov (__var3),%eax
pushl %eax
movb $'0',%al
call putc
movb $'x',%al
call putc
pop %eax
rol $16,%eax
call Hex2ASCII
rol $16,%eax
call Hex2ASCII
movb $10,%al
call putc
__print_string_88:
__var4_87:
mov (__var4),%eax
pushl %eax
movb $'0',%al
call putc
movb $'x',%al
call putc
pop %eax
rol $16,%eax
call Hex2ASCII
rol $16,%eax
call Hex2ASCII
movb $10,%al
call putc
jmp __cycle_block_89
__cycle_end_89:
__print_string_91:
__constant_str_90__decl_90:
movl $__constant_str_90,%eax
pushl %eax
movl (%esp),%eax
push %eax
 call strlen
push %eax
movl 4(%esp),%eax
push %eax
call print_str
pop %eax
__print_string_93:
__string1_92:
mov (__string1),%eax
pushl %eax
movl (%esp),%eax
push %eax
 call strlen
push %eax
movl 4(%esp),%eax
push %eax
call print_str
pop %eax
__print_string_95:
__constant_str_94__decl_94:
movl $__constant_str_94,%eax
pushl %eax
movl (%esp),%eax
push %eax
 call strlen
push %eax
movl 4(%esp),%eax
push %eax
call print_str
pop %eax
__print_string_97:
__string2_96:
mov (__string2),%eax
pushl %eax
movl (%esp),%eax
push %eax
 call strlen
push %eax
movl 4(%esp),%eax
push %eax
call print_str
pop %eax
__print_string_99:
__constant_str_98__decl_98:
movl $__constant_str_98,%eax
pushl %eax
movl (%esp),%eax
push %eax
 call strlen
push %eax
movl 4(%esp),%eax
push %eax
call print_str
pop %eax
__print_string_101:
__string3_100:
mov (__string3),%eax
pushl %eax
movl (%esp),%eax
push %eax
 call strlen
push %eax
movl 4(%esp),%eax
push %eax
call print_str
pop %eax
#3#
	
	pushl $0 #exit code = 0
	call exit


