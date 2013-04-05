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

#3#
	
	pushl $0 #exit code = 0
	call exit


