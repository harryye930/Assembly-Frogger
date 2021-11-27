
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
	woodArray: .space 20
	

	

	
.text
#########	  variables  	        ##########
#s0: position of frog
#s1: array of position of cars
#s2: array of position of woods

#########	Start of program	##########
gameStart:
	lw $t0, displayAddress # $t0 stores the base address for display
	jal graphGameBoard # call grpah game board function
	
	la $s0, 3636($t0) # load the initial offset of frog in s0
	lw $t8, frogGreen # store frogGreen to t8
	jal graphFrog  # use function to graph frog
	
	### add initial cars in s1 ###
	la $s1, carArray  # load location of carArray to s1
	la $t3, 2304($t0) 
	sw $t3, ($s1)  # s1[0] = first small rectangle start offset
	
	addi $s1, $s1, 4
	la $t3, 2400($t0)
	sw $t3, ($s1)  #s1[1] = second small rectangle start offset
	
	addi $s1, $s1, 4
	la $t3, 2864($t0)  
	sw $t3, ($s1)  #s1[2] = second small rectangle start offset
	
	addi $s1, $s1, -8  # reset counter for s1
	### finish add cars in s1 ###
	
	add $t4, $zero, $zero  # loop initial value
	addi $t5, $zero, 3  # loop size
	lw $t9, carRed  # car color to t9
	la $t6, ($s1)
	jal graphCarsAndWoods
	
	### add initial woods in s2 ###
	la $s2, woodArray  # load location of carArray to s1
	la $t3, 768($t0) 
	sw $t3, ($s2)  # s2[0] = first small rectangle start offset
	
	addi $s2, $s2, 4
	la $t3, 816($t0)
	sw $t3, ($s2)  #s2[1] = second small rectangle start offset
	
	addi $s2, $s2, 4
	la $t3, 864($t0)  
	sw $t3, ($s2)  #s2[2] = second small rectangle start offset
	
	addi $s2, $s2, 4
	la $t3, 1304($t0)  
	sw $t3, ($s2)  #s2[3] = second small rectangle start offset
	
	addi $s2, $s2, 4
	la $t3, 1352($t0)  
	sw $t3, ($s2)  #s2[4] = second small rectangle start offset
	
	
	
	addi $s2, $s2, -16  # reset counter
	### finish add cars in s2 ###
	
	add $t4, $zero, $zero  # loop initial value
	addi $t5, $zero, 5  # loop size
	lw $t9, woodBrown  # wood color to t9
	la $t6, ($s2)
	jal graphCarsAndWoods
	
	
	
	
	
graphSmallRectanglesLoop:
	bge $t1, $t2, endGraphSmallTranglesLoop
	sll $t2, $t1, 2
	add $t3, $s1, $t2
	sw $t9, ($t3)
	addi $t1, $t1, 1
	
	
endGraphSmallTranglesLoop:
		
	li $v0, 32
 	li $a0, 1000
 	syscall
 	
 	
whileInRange:  # WHile looping if frog don't hit the finish line
	la $t6, 128($t0) # load end condition to stop while loop
	blt $s0, $t6, exitWhileInRange  # exit while loop if s0 (offset of frog) < 128 --> frog have reach other side
	lw $t3, 0xffff0000
	beq $t3, 1, checkW
	j whileInRange
checkW:
	lw $t4, 0xffff0004
	beq $t4, 0x77, respondToW
	j checkA

respondToW:
 	jal graphGameBoard
	addi $s0, $s0, -128  # up 1 unit
	lw $t8, frogGreen # store frogGreen to t8
	jal graphFrog  # use function to graph frog
	j whileInRange

checkA:
	lw $t4, 0xffff0004
	beq $t4, 0x61, respondToA
	j checkS

respondToA:
 	jal graphGameBoard
	addi $s0, $s0, -4  # left 1 unit
	lw $t8, frogGreen # store frogGreen to t8
	jal graphFrog  # use function to graph frog
	j whileInRange
	
	
checkS:
	lw $t4, 0xffff0004
	beq $t4, 0x73, respondToS
	j checkD

respondToS:
 	jal graphGameBoard
	
	
	addi $s0, $s0, 128  # down 1 unit
	lw $t8, frogGreen # store frogGreen to t8
	jal graphFrog  # use function to graph frog
	j whileInRange
	
checkD:
	lw $t4, 0xffff0004
	beq $t4, 0x64, respondToD

respondToD:
 	jal graphGameBoard

	
	addi $s0, $s0, +4  # right 1 unit
	lw $t8, frogGreen # store frogGreen to t8
	jal graphFrog  # use function to graph frog
	j whileInRange
	
	
exitWhileInRange:
	jal graphDeadRespawnAnima  # show dead halo
	li $v0, 32
 	li $a0, 2000
 	syscall
 	
 	j gameStart # restart the game
	
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
# Graph a frog given s0 = initial offset top left corner
	sw $t8, 0($s0) 
	addi $s0, $s0, 8
	sw $t8, 0($s0)
	addi $s0, $s0, 120
	sw $t8, 0($s0)
	addi $s0, $s0, 4
	sw $t8, 0($s0)
	addi $s0, $s0, 4
	sw $t8, 0($s0)
	addi $s0, $s0, 124
	sw $t8, 0($s0)
	addi $s0, $s0, 124
	sw $t8, 0($s0)
	addi $s0, $s0, 4
	sw $t8, 0($s0)
	addi $s0, $s0, 4
	sw $t8, 0($s0)
	addi $s0, $s0, -392 # conpensate iteration of s0
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
# graph the dead animation, given s0 = offset of frog
	lw $t9, white
	sw $t9, -8($s0)
	sw $t9, 116($s0)
	sw $t9, 244($s0)
	sw $t9, 376($s0)
	sw $t9, 16($s0)
	sw $t9, 148($s0)
	sw $t9, 276($s0)
	sw $t9, 400($s0)
	jr $ra
	
graphSmallRectangle:
# graph smaller rectanges for woods and car, t1 = start offset,  t9 = color
	addi $sp, $sp, -4
	sw $ra, 0($sp)  # decrement and backup current program counter
	addi, $t2, $t1, 512  # t8 = t1 + 4rows is end offset
graphSmallRectangleLoop:
	beq $t1, $t2, endGraphSmallRectangleLoop  # exit loop if t1 == t8
	addi $t8, $t1, 24  # t8 = end offset
	jal graphRectangle # graph single row
	addi $t1, $t1, 104  # move t1 to the beginning of next line
	j graphSmallRectangleLoop

endGraphSmallRectangleLoop:	
	lw $ra, 0($sp) 
	addi $sp, $sp, 4  # restore and increment program counter
	jr $ra
	
	
graphCarsAndWoods:
# graph multiple occation of small rectangles, t6 = s1(car)/s2(wood) = array of start address, t9 = color

	addi $sp, $sp, -4
	sw $ra, 0($sp)  # decrement and backup current program counter
graphCarsAndWoodsLoop:
	beq $t4, $t5, endCarsAndWoodsLoop  # check for array end
	lw $t1, ($t6)  # t3 is the start address for car
	#sw $t9, ($t3)
	jal graphSmallRectangle
	addi    $t4, $t4, 1  # advance loop counter
	addi    $t6, $t6, 4  # advance array pointer
	j       graphCarsAndWoodsLoop  # repeat the loop
	
endCarsAndWoodsLoop:
	lw $ra, 0($sp) 
	addi $sp, $sp, 4  # restore and increment program counter
	jr $ra	
	
	
