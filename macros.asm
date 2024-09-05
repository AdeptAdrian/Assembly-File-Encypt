#Macro that can print any string without having to have a billion labels in the main file		
		.macro printString(%str)
		.data
string:		.asciiz		%str		#Create a label for the string
		.text
		la	$a0, string		#Load the string's address in $a0
		li	$v0, SysPrintString	#Print string command in $v0
		syscall				#Print the string
		.end_macro