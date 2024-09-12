#  Written by Adrian, starting November 1, 2023.

#The program can encrypt and decrypt files using user-defined key
		.include 	"SysCalls.asm"
		.include 	"macros.asm"
		.data
		.eqv		nameLimit	256	#Max length + new line char
		.eqv		keyLimit	61	#Max length + new line char
		.eqv		bufferLimit	1024	#Buffer size
fileName:	.space		nameLimit		#Will hold the name of input file
key:		.space		keyLimit		#Will hold the enc/dec key
buffer:		.space		bufferLimit		#Buffer for reading from the file
outFile:	.space		nameLimit		#Will hold the name of input file
		.text
		.globl		main
main:		move	$a0, $s0		#If there's an open file, close it
		li	$v0, SysCloseFile	
		syscall
		move	$a0, $s1		#If there's an open file, close it
		li	$v0, SysCloseFile
		syscall	
		printString("1: Encrypt the file\n")
		printString("2: Decrypt the file\n")
		printString("3: Exit\n")
		li	$v0, SysReadInt		#Read the user's input
		syscall
		beq	$v0, 3, terminate	#Exit the program, if that option was chosen
		move	$a2, $v0		#Save the user's choice for later
		printString("Enter the name of the file: ")
		la	$a0, fileName		#Address of input buffer
		li	$a1, nameLimit		#Max length of the input string
		li	$v0, SysReadString	#Syscall to read the user's input
		syscall	
		jal	removeNL		#Remove the new line char from the input
		printString("Enter the key, por favor: ")
		la	$a0, key		#Address of input buffer
		li	$a1, keyLimit		#Limit of char's for the key string
		li	$v0, SysReadString	#Syscall to read the user's input
		syscall	
		beq	$a0, '\n', keyError	#Key not valid if the first char is '\n'
		beq	$a2, 1, encryption	#Proceed to encrypt
		beq	$a2, 2, decryption	#Proceed to decrypt
		printString("That was not a valid menu option\n")	
		j	main			#If the user didn't select a valid menu option, return back

encryption:	la	$a0, fileName		#Address of the input file name
		li	$a1, 0			#Flagged to read
		li	$a2, 0			#Mode, which is ignored
		li	$v0, SysOpenFile	#Syscall to open the file
		syscall
		blt	$v0, 0, fatal		#Error with the file = terminate
		move	$s0, $v0		#Save the file descriptor in $s0		
		la	$a1, outFile		#Address of output file buffer
		#Copy over the file name char by char, only changing the extension
reExtend:	lbu	$t0, ($a0)		#Load the char into $t0
		sb	$t0, ($a1)		#Copy it into the output file name string
		addi	$a0, $a0, 1		#Go to the next element
		addi	$a1, $a1, 1		#Go to the next element
		bne	$t0, '.', reExtend	#If we haven't reached the extension, keep going 
		li	$t0, 'e'		#Load ascii e into $t0
		sb	$t0, ($a1)		#Store it in the output file name
		li	$t0, 'n'		#Load ascii n into $t0
		sb	$t0, 1($a1)		#Store it in the output file name
		li	$t0, 'c'		#Load ascii c into $t0
		sb	$t0, 2($a1)		#Store it in the output file name
		
		la	$a0, outFile		#Address of output file name
		li	$a1, 1			#Flag for write
		li	$a2, 0			#Mode, which is ignored 
		li	$v0, SysOpenFile	#Syscall to open the file
		syscall
		blt	$v0, 0, fatal		#Error with the file = terminate
		move	$s1, $v0		#Save the file descriptor in $s1
getEncBlock:	move	$a0, $s0		#Copy the file descryptor of input file
		la	$a1, buffer		#Addres of the buffer in $a1
		li	$a2, bufferLimit	#Num of chars to read in $a2
		li	$v0, SysReadFile	#Read the block of bytes from the file
		syscall
		beqz	$v0, main		#If no char's were left, the encryption was successful 
		li	$t0, 0			#Counter of char's changed in the buffer
		la	$a2, key		#Load the address of key into $a2
encBuffer:	lbu	$t1, ($a1)		#Load the char from the buffer
		lbu	$t2, ($a2)		#Load the char from the key
		bne	$t2, '\n', continue	#If we loaded a new line, reset the key
		la	$a2, key		#Load it back
		lbu	$t2, ($a2)		#Load the first char of the key for encryption
continue:	addu	$t1, $t1, $t2		#Add the two char values
		sb	$t1, ($a1)		#Store it into the buffer
		addi	$a1, $a1, 1		#Move to the next char in the buffer
		addi	$a2, $a2, 1		#Move to the next char in the key
		addi 	$t0, $t0, 1		#Increment the counter
		blt	$t0, $v0, encBuffer	#If didn't go through all the read chars, loop back
		move	$a0, $s1		#File descriptor of output file in $s1
		la	$a1, buffer		#Buffer adress in $a1
		move	$a2, $t0		#The num of chars to write = num of chars modified in the buffer
		li	$v0, SysWriteFile	#Write into the output file
		syscall
		j	getEncBlock		#Read the next block from the file
decryption:	la	$a0, fileName		#Address of the input file name
		li	$a1, 0			#Flag to read
		li	$a2, 0			#Mode, which is ignored 
		li	$v0, SysOpenFile	#Syscall for opening the file for reading
		syscall
		move	$s0, $v0		#Save the file descriptor in $s0
		blt	$v0, 0, fatal		#Error with the file = terminate
		la	$a1, outFile		#Address of output file buffer
		#Copy over the file name char by char, only changing the extension
reachPeriod:	lbu	$t0, ($a0)		#Load the char into $t0
		sb	$t0, ($a1)		#Copy it into the output file name string
		addi	$a0, $a0, 1		#Go to the next element
		addi	$a1, $a1, 1		#Go to the next element
		bne	$t0, '.', reachPeriod	#If we haven't reached the extension, keep going 
		li	$t0, 't'		#Load ascii t into $t0
		sb	$t0, ($a1)		#Store it in the output file name
		li	$t0, 'x'		#Load ascii x into $t0
		sb	$t0, 1($a1)		#Store it in the output file name
		li	$t0, 't'		#Load ascii t into $t0
		sb	$t0, 2($a1)		#Store it in the output file name
		la	$a0, outFile		#Adress of the output file name in $a0
		li	$a1, 1			#Flag for writing
		li	$a2, 0			#Mode, which is ignored
		li	$v0, SysOpenFile	#Syscall for opening the file
		syscall
		blt	$v0, 0, fatal		#Error with the file = terminate
		move	$s1, $v0		#Save the file descriptor in $s1
getDecBlock:	move	$a0, $s0		#Load the file descriptor of input file
		la	$a1, buffer		#Adress of the buffer
		li	$a2, bufferLimit	#Limit of chars to read
		li	$v0, SysReadFile	#Syscall to read from the file
		syscall
		beqz	$v0, main		#If no chars were read, we're done
		li	$t0, 0			#Counter of char's changed in the buffer
		la	$a2, key		#Adress of the key in $a2
decBuffer:	lbu	$t1, ($a1)		#Load the char from the buffer
		lbu	$t2, ($a2)		#Load the char from the key
		bne	$t2, '\n', skip		#If not at nw line, don't refresh the key adress
		la	$a2, key		#Load adress of the key again
		lbu	$t2, ($a2)		#The first chat is used for decryption
skip:		subu	$t1, $t1, $t2		#Decrypt the character 
		sb	$t1, ($a1)		#Store it in the buffer
		addi	$a1, $a1, 1		#Move to the next char in the buffer
		addi	$a2, $a2, 1		#Move to the next char in the key
		addi 	$t0, $t0, 1		#Increment the numbver of processed chars within the buffer
		blt	$t0, $v0, decBuffer	#If not at the last char, go back
		move	$a0, $s1		#File descriptor in $a0
		la	$a1, buffer		#Adress of the buffer
		move	$a2, $t0		#The num of chars to write = num of chars modified in the buffer
		li	$v0, SysWriteFile	#Syscall for writing into a file
		syscall
		j	getDecBlock		#Go to the next block to decrypt
		#Removes the new line character. Address of the string is passed in $a0		
removeNL:	lbu	$t0, ($a0)		#Load the char in $t0
		addi	$a0, $a0, 1		#Move to the next adress
		bne	$t0, '\n', removeNL	#If not \n, get the next one
		sb	$zero, -1($a0)		#The adress is one past the \n, so store null-term before it
		jr	$ra			#Jump back
keyError:	printString("The key was not valid. Returning to menu.\n")
		j	main	
fatal:		printString("There was an error with the file\n")
		printString("Terminating the program for my safety\n")			
terminate:	li	$v0, SysExit		#Syscall for exiting the program
		syscall	
