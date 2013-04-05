Sin
===

My own programming language. This is a project I had to to for a class during my engineering studies. So it's completely in spanish.
It's basically a proof of concept showing my own language which was designed to avoid all kind of special language keywords

#The entire language is made out of symbols, except for variable declarations.

It has an internal and custom designed state machine as a parser because we were not allowed to use flex.
To compile it you have to run bison on the .y file, then g++ on the output, and then use the compiler to compile "prueba.txt"
The output from running the final compiler is an asm file with GNU Assembled compatible code.
You can run "crear_compilador.sh" that does it all for you.

So let's get to the interesting part. The language:

##Valid Comments
`````
/*
comment 1
*/
/*
comment 2
/*
comment 3
*/
*/
`````

##Variable definitions (the only place where english keywords are allowed)
`````
real 3.14@pi
int var1
int var2
int 0@var3
int var4
string 'hello '@string1
string 'world'@string2
string string1+string2@string3
`````

##Variable assignation
`````
0@var4
`````

##Print to console
`````
print('0@var4:')
print(var4)
print('~(var4)')
print(~(var4))
`````

##Special operations
`````
2+@var1
2-@var1
2*@var1
2/@var1
`````

##IF condition
`````
pi>3.13?
print('pi is greater than 3.13')
:
print('pi is not greater than 3.13')
;
/*
of course you will never reach the "else" code. it's just an example. stop complaining
*/
`````

##WHILE loop
`````
/*
while var3<8 keep increasing var3 by one
*/
{var3<8}
1+@var3
;
`````

##FOR loop
`````
/*
there is no difference between while and for. you just add new code before the condition like this:
{code1:code2:code3:condition}
code
;
Here is a working example:
*/
{2+@var4:var4<8}
1+@var3
print(var3)
print(var4)
;
`````


Warnings:
Assembly code was writen on a single day, and it had to work on first try, so from an academic and professional point of view, one could say that it's very crappy-
The BNF is not considering some cases for the IF conditions.
This is just a "working" compiler used as proof of concept. It was not meant to be complete, full featured, or bug free.
The entire program AND the language itself are LGPL licensed.

Copyright 2013 Emilio Moretti <emilio.morettiATgmailDOTcom>
This program is distributed under the terms of the GNU Lesser General Public License.
