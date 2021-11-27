
# https://minnie.tuhs.org/CompArch/Resources/mips_quick_tutorial.html#RegisterDescription
# https://courses.cs.washington.edu/courses/cse378/00au/ctomips2.pdf
.data
	displayAddress: .word 0x10008000
	grassGreen: .word 0x34a853
	woodBrown: .word 0xb45f06
	riveBlue: .word 0x4a86e8
	middleRestPurple: .word 0x674ea7
	carRed: .word 0xea4336
	roadBlack: .word 0x464848
	frogGreen: .word 0x02ff00
	white: .word 0xffffff
	carArray: .space 12
	

	

	
.text
#########	Start of program	##########
gameStart:
	lw $t0, displayAddress # $t0 stores the base address for display
	jal graphGameBoard # call grpah game board function
	
	la $t7, 3636($t0) # load the initial offset of frog in t7
	lw $t8, frogGreen # store frogGreen to t8
	jal graphFrog  # use function to graph frog
	
	li $v0, 32
 	li $a0, 1000
 	syscall
 	
 	
whileInRange:  # WHile looping if frog don't hit the finish line
	la $t6, 128($t0) # load end condition to stop while loop
	blt $t7, $t6, exitWhileInRange  # exit while loop if t7 (offset of frog) < 128 --> frog have reach other side
	#bge $t7, $t6, checkUserInput # check user input if not reached other side

	lw $t3, 0xffff0000
	beq $t3, 1, checkW
	j whileInRange
checkW:
	lw $t4, 0xffff0004
	beq $t4, 0x77, respondToW
	j checkA

respondToW:
 	jal graphGameBoard
	la $t1, 2304($t0)
	jal graphSmallRectangle
	addi $t7, $t7, -128  # up 1 unit
	lw $t8, frogGreen # store frogGreen to t8
	jal graphFrog  # use function to graph frog
	j whileInRange

checkA:
	lw $t4, 0xffff0004
	beq $t4, 0x61, respondToA
	j checkS

respondToA:
 	jal graphGameBoard
	
	addi $t7, $t7, -4  # left 1 unit
	lw $t8, frogGreen # store frogGreen to t8
	jal graphFrog  # use function to graph frog
	j whileInRange
	
	
checkS:
	lw $t4, 0xffff0004
	beq $t4, 0x73, respondToS
	j checkD

respondToS:
 	jal graphGameBoard
	
	
	addi $t7, $t7, 128  # down 1 unit
	lw $t8, frogGreen # store frogGreen to t8
	jal graphFrog  # use function to graph frog
	j whileInRange
	
checkD:
	lw $t4, 0xffff0004
	beq $t4, 0x64, respondToD

respondToD:
 	jal graphGameBoard

	
	addi $t7, $t7, +4  # right 1 unit
	lw $t8, frogGreen # store frogGreen to t8
	jal graphFrog  # use function to graph frog
	j whileInRange
	
	
exitWhileInRange:
	jal graphDeadRespawnAnima
	li $v0, 32
 	li $a0, 2000
 	syscall
 	
 	j gameStart
	
	li $v0, 10 # terminate the program gracefully
 	syscall




	

#########	Functions 	###########


graphRectangle: 
# graph a triangle given t1 = start offset, t8 = end offset, t9 = colour
graphLoop:   
	beq $t1, $t8, endGraphLoop # if t1 == t8 end loop
	sw $t9, 0($t1) # graph with colour t9
	addi $t1, $t1, 4 # t1 = t1+1
	j graphLoop
endGraphLoop:
	jr $ra

graphFrog:
# Graph a frog given t7 = initial offset top left corner
	sw $t8, 0($t7) 
	addi $t7, $t7, 8
	sw $t8, 0($t7)
	addi $t7, $t7, 120
	sw $t8, 0($t7)
	addi $t7, $t7, 4
	sw $t8, 0($t7)
	addi $t7, $t7, 4
	sw $t8, 0($t7)
	addi $t7, $t7, 124
	sw $t8, 0($t7)
	addi $t7, $t7, 124
	sw $t8, 0($t7)
	addi $t7, $t7, 4
	sw $t8, 0($t7)
	addi $t7, $t7, 4
	sw $t8, 0($t7)
	addi $t7, $t7, -392 # conpensate iteration of t7
	jr $ra
	
graphGameBoard:
	addi $sp, $sp, -4
	sw $ra, 0($sp)  # decrement and backup current program counter
	la $t1, 0($t0)
	la $t8, 768($t0) # finish line green before 768 offset
	lw $t9, grassGreen # load grassGreen
	jal graphRectangle
	la $t8, 1792($t0) # river blue before 1792 offset
	lw $t9, riveBlue # load riveBlue
	jal graphRectangle
	la $t8, 2304($t0) # middle purple before 2304 offset
	lw $t9, middleRestPurple # load middleRestPurple
	jal graphRectangle
	la $t8, 3328($t0) # road black before 3328 offset
	lw $t9, roadBlack # load roadBlack
	jal graphRectangle
	la $t8, 4096($t0) # start line green before 4096 offset
	lw $t9, grassGreen # load grassGreen
	jal graphRectangle
	lw $ra, 0($sp) 
	addi $sp, $sp, 4  # restore and increment program counter
	jr $ra
	
graphDeadRespawnAnima:
	lw $t9, white
	sw $t9, -8($t7)
	sw $t9, 116($t7)
	sw $t9, 244($t7)
	sw $t9, 376($t7)
	sw $t9, 16($t7)
	sw $t9, 148($t7)
	sw $t9, 276($t7)
	sw $t9, 400($t7)
	jr $ra
	
graphSmallRectangle:
# graph smaller rectanges for woods and car, t1 = start offset,  t9 = color
	addi $sp, $sp, -4
	sw $ra, 0($sp)  # decrement and backup current program counter
	addi, $t2, $t1, 512  # t8 = t1 + 4rows is end offset
graphSmallRectangleLoop:
	beq $t1, $t2, endGraphSmallRectangleLoop  # exit loop if t1 == t8
	addi $t8, $t1, 24  # t8 = end offset
	lw $t9, carRed 
	jal graphRectangle # graph single row
	addi $t1, $t1, 104  # move t1 to the beginning of next line
	j graphSmallRectangleLoop

endGraphSmallRectangleLoop:	
	lw $ra, 0($sp) 
	addi $sp, $sp, 4  # restore and increment program counter
	jr $ra

	
	
	
