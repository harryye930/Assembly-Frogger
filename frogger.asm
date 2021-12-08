#####################################################################
#
# CSC258H5S Fall 2021 Assembly Final Project
# University of Toronto, St. George
#
# Student: Name, Student Number 
#  - Runlong Ye, 1005715264
#
# Bitmap Display Configuration:
# - Unit width in pixels: 8
# - Unit height in pixels: 8
# - Display width in pixels: 256
# - Display height in pixels: 256
# - Base Address for Display: 0x10008000 ($gp)
#
# Which milestone is reached in this submission?
# (See the assignment handout for descriptions of the milestones)
# - Milestone 5 
#
# Which approved additional features have been implemented?
# (See the assignment handout for the list of additional features)
# 1. Display the number of lives remaining.
# 2. Dynamic increase in difficulty as game progresses
# 3. Have objects in different rows move at different speeds
# 4. Make a second level that starts after the player completes first level
# 5. Have some of the floating objects sink and reappear
#
# Any additional information that the TA needs to know:
# - You need to press p (Play) to start playing game, and hit p again once you have losed all lives :)
# - Other resources used extensively:
# https://minnie.tuhs.org/CompArch/Resources/mips_quick_tutorial.html#RegisterDescription
# https://courses.cs.washington.edu/courses/cse378/00au/ctomips2.pdf
# https://courses.cs.vt.edu/~cs2505/summer2011/Notes/pdf/T23.MIPSArrays.pdf
#####################################################################


.data 
	displayAddress: .word 0x10008000
	
	# store game initialization
	level: .word 0
	time: .word 0
	score: .word 0
	
	# colors
	carRed: .word 0xea4336
	woodBrown: .word 0xb45f06
	lifeColor: .word 0xff0000
	grassGreen: .word 0x34a853
	middleRestPurple: .word 0x674ea7
	white: .word 0xffffff
	riveBlue: .word 0x4a86e8
	roadBlack: .word 0x464848
	frogGreen: .word 0x02ff00
	
	# store variable about frog
	lifeRemain: .word 3
	safeZoneStatus: .word 1
	beenHit: .word 0
	winStatus: .word 0
	gameStatus: .word 0
	
	frogLocations: .word 0, 12, 128, 132, 136, 140, 260, 264, 384, 388, 392, 396
	frogCoor: .word 15, 28  # store frog corrdinate in (x, y) format
	frogSize: .word 4, 4	# store frog size as 4*4
	frogSpeed: .word 0
	
	# store variable about car
	carSize: .word 6, 4	# 6*3 size for car
	upperRowCarLocation: .word 0, 20, 15, 20
	upperRowCarSpeed: .word 1
	lowerRowCarLocation: .word 5, 24, 20, 24
	lowerRowCarSpeed: .word -2
	
	# store variables about wood
	
	woodSize: .word 8, 4	# 8*4 size for wood
	upperRowWoodSpeed: .word -1
	upperRowWoodLocation: .word 4, 8, 20, 8 
	lowerRowWoodSpeed: .word -2
	lowerRowWoodLocation: .word 8, 12, 28, 12 
	sinkTime: .word 3
	sinkCount: .word 0
	isSink: .word 0
	
	ObjInitialPosition: .word 0
	nextLineSignal: .word 15
	canvas: .space 1536

.text 
	
main:
	
	# Reset the game including data
	jal resetData
	
resetFrogCoor: 			# Reset the coordinate of frog
	la $t1, frogCoor
	li $t2, 15
	sw $t2, 0($t1) 
	li $t2, 28
	sw $t2, 4($t1) 
	# End of the resetting
	
	# Init
	Init:
	jal drawBg
	jal drawObjs
	jal drawFrog
	jal drawCanvas
	jal graphDeadRespawnAnima
	li $v0, 32
 	li $a0, 1000
 	syscall
	
	
	# End of Init
	
	
gameStart:
	
	bgt $zero, $zero, Exit
	jal reactKey # Check the key events
	
	# check collision and wining status
	jal collisionDetect
	
	# Check win status
	lw $t1, winStatus
	beq $t1, $zero, skip
	jal increaseSpeed
	jal nextLevelCheck
	la $t1, winStatus
	sw $zero, 0($t1)
	lw $t1, score # add 1 to score
	addi $t1, $t1, 1
	la $t2, score
	sw $t1, ($t2) 
	
	
	
	# Pain the zone as fullfilled
	la $t1, endCheckingWin 
	add $s3, $t1, $zero # s3 for return address
	la $t1, canvas
	add $s1, $t1, $zero # s1 for canvas
	la $t4, frogCoor
	lw $t0, 0($t4) # t0 ->  x address
	lw $t1, 4($t4) # t1 ->  y address
	addi $t2, $zero, 4 # t2 for width
	addi $t3, $zero, 4 # t3 for height
	li $t9, 0x009900 # t9 for color

	j drawRectangle

	# End painting
	
	endCheckingWin:
	j resetFrogCoor
	skip:
	# End of checking sin status
	
	# reset the frog position if it is hit or drown
	lw $t1 beenHit
	beq $t1, $zero, noHitting
	la $t3, beenHit
	sw $zero, 0($t3) # Reset the hitting status
	# Action when frog hit something
	lw $t1, lifeRemain
	addi $t1, $t1, -1 # Subtract 1 from the total life count
	la $t2 lifeRemain
	sw $t1, ($t2)
	beq $t1, $zero, main
	j resetFrogCoor
	
noHitting: # Frog does not hit anything
	
	# Check if the frog is on wood and react accordingly
	jal frogOnWood
	
	lw $t1, gameStatus # is the game status is 0, freeze the canvas
	beq $t1, $zero, sleep
	
	lw $t1, ObjInitialPosition # Decide how fast shoud the objects be moved
	lw $t2, nextLineSignal
	bge $t1, $t2, moveBranch
	addi $t1, $t1, 1
	la $t2, ObjInitialPosition
	sw $t1, 0($t2)
	j current4
	
	moveBranch:
	la $t1, ObjInitialPosition
	sw $zero, 0($t1)
	jal sinkWood
	jal moveObjsCoor
	current4: # End of the moveing process
	
	jal drawBg
	jal drawObjs
	jal drawFrog
	jal drawCanvas
	
	sleep:
	li $v0, 32
	li $a0, 17
	syscall
	
	j gameStart
	
Exit:
	
	li $v0, 10 # terminate the program gracefully

	syscall
	
	
frogOnWood:
	# Check is the frog is on wood, if it is, then make the frog move with the wood
	la $t0, frogCoor # to store the address of frog coordinate
	lw $t0, 4($t0) # t1 to store the y coordinate of frog
	li $t1, 8 
	blt $t0, $t1, noFrogOnWood1 #
	li $t1, 12
	bge $t0, $t1, noFrogOnWood1 #
	
	# Action when on positive woods
	lw $t1, upperRowWoodSpeed
	la $t2, frogSpeed
	sw $t1, 0($t2) # Assign frog a speed
	j frogOnWoodEnd
	
	noFrogOnWood1:
	
	li $t1, 12
	blt $t0, $t1, noFrogOnWood2 #
	li $t1, 16
	bge $t0, $t1, noFrogOnWood2 #
	
	# Action when on negative woods
	lw $t1, lowerRowWoodSpeed
	la $t2, frogSpeed
	sw $t1, 0($t2)
	j frogOnWoodEnd
	
	noFrogOnWood2: # Reset the frog speed to 0 if it is not on wood
	la $t1, frogSpeed
	sw $zero, 0($t1)
	
	frogOnWoodEnd:
	
	jr $ra
	
	
	
	
	
	

#########	Functions 	###########	
	
	
	
	
	
	
	
collisionDetect: 
# detect if the collision is happening
		# t0 -> x coord
		# t1 -> y coord
		# t9 -> color
		# input stack: coor1, coor2, size1, size2
		# return flag, 1 for collision in car zone and drown in water zone
		
		
		la $t0, frogCoor # to store the address of frog coordinate
		lw $t1, 4($t0) # t1 to store the y coordinate of frog
		lw $t0, 0($t0) # t0 to store the x coordinate, override the previous value
	 	
	 	# First if the frog is in Car Zone
	 	li $t9, 20 # The beginning row of Car Zone
	 	blt $t1, $t9, aboveCarZone # frog is above the car Zone
	 	li $t9, 28  # the endingt row of car zone
	 	bge $t1, $t9, belowCarZone # frog is below the car Zone
	 	
	 	# At this point, frog is in the car Zone
	 	li $t9, 24
	 	bge $t1, $t9, lowerRowCarDetect 
	 	
	 	# Action if in lower row car Zone, checked
	 	la $t9, upperRowCarDetectEnd # push the parameters into the stack
	 	addi $sp, $sp, -4
	 	sw $t9, 0($sp)
	 	
	 	la $t9, upperRowCarLocation
	 	addi $sp, $sp, -4
	 	sw $t9, 0($sp)
	 	
	 	la $t9, carSize
	 	addi $sp, $sp, -4
	 	sw $t9, 0($sp)
	 	
	 	j objCollisionWithFrog
upperRowCarDetectEnd:
	 	lw $t9, 0($sp) # Store the hitting status into the t9 regiter
	 	addi $sp, $sp, 4
	 	la $t5, beenHit # Store the address of hitting Status into t5
	 	sw $t9, 0($t5)
	 	
	 	j finishDetect
	 	
	 	# Action in quick car Zone
lowerRowCarDetect:
	 	
	 	# Checked
	 	la $t9, lowerRowCarDetectEnd # push the parameters into the stack
	 	addi $sp, $sp, -4
	 	sw $t9, 0($sp)
	 	
	 	la $t9, lowerRowCarLocation
	 	addi $sp, $sp, -4
	 	sw $t9, 0($sp)
	 	
	 	la $t9, carSize
	 	addi $sp, $sp, -4
	 	sw $t9, 0($sp)
	 	
	 	j objCollisionWithFrog
	 	lowerRowCarDetectEnd:
	 	lw $t9, 0($sp) # Store the hitting status into the t9 regiter
	 	addi $sp, $sp, 4
	 	la $t5, beenHit # Store the address of hitting Status into t5
	 	sw $t9, 0($t5)
	 	j finishDetect
	 	
	 	aboveCarZone:
	 	li $t9, 8 # t9 store the starting y coordinate of waterZone
	 	blt $t1, $t9, safeZoneAction
	 	
	 	# Action when in mid Zone
	 	li $t9, 16
	 	beq $t1, $t9, finishDetect
	 	li $t9, 12
	 	beq $t1, $t9, negativeWaterDetect
	 	
	 	# Action in positiveWater Zone
		# Checked
	 	la $t9, positiveWaterDetectEnd # push the parameters into the stack
	 	addi $sp, $sp, -4
	 	sw $t9, 0($sp)
	 	
	 	addi $sp, $sp, -4
	 	la $t8, upperRowWoodLocation
	 	sw $t8, 0($sp) # store the address of x, y coordinate into stack
	 	
	 	
	 	la $t9, woodSize
	 	
		# Store the address of wood width into stack
		addi $sp, $sp, -4
	 	sw $t9, 0($sp)
	 	
	 	j objCollisionWithFrog
	 	positiveWaterDetectEnd:

	 	lw $t9, 0($sp) # Store the hitting status into the t9 regiter
	 	addi $sp, $sp, 4
	 	li $t8, 1
		sub $t9, $t8, $t9 # Store the opposite vaoue into the game status
	 	la $t5, beenHit # Store the address of hitting Status into t5
	 	sw $t9, 0($t5) 
	 	j finishDetect
	 	
	 	# Action in negative water Zone
	 	negativeWaterDetect:
	 	la $t9, negativeWaterDetectEnd # push the parameters into the stack
	 	addi $sp, $sp, -4
	 	sw $t9, 0($sp)
	 	
	 	addi $sp, $sp, -4
	 	la $t8, lowerRowWoodLocation
	 	sw $t8, 0($sp) # store the address of x, y coordinate into stack
	 	
	 	
	 	la $t9, woodSize	 # Wood width
		# Store the address of wood width into stack
		addi $sp, $sp, -4
	 	sw $t9, 0($sp)
	 	
	 	j objCollisionWithFrog
	 	
	 	negativeWaterDetectEnd:
	 	lw $t9, 0($sp) # Store the hitting status into the t9 regiter
	 	addi $sp, $sp, 4
	 	li $t8, 1
		sub $t9, $t8, $t9 # Store the opposite vaoue into the game status
	 	la $t5, beenHit # Store the address of hitting Status into t5
	 	sw $t9, 0($t5)
	 	j finishDetect
	 	
	 	
	 	
	 	safeZoneAction: # The zone that win the game, can add more features
		# checked
	 	li $t9, 1
	 	la $t8, winStatus
	 	sw $t9, 0($t8)
	 	j finishDetect
	 	
	 	belowCarZone: 
	 	
	 	finishDetect:
	 	jr $ra
	 	
	 	
objCollisionWithFrog: # stack: return address, objCoordinate, objSize (Address)
# register used, t2-8
	lw $t2, 0($sp) # use t2 to store the address of object size
	addi $sp, $sp, 4
	# lw $t3, 4($t2) # t3 store the height of the object
	lw $t2, 0($t2) # t2 to store the width of the object
		     
	lw $t4, 0($sp) # 
	addi $sp, $sp, 4
	add $s4, $t4, $zero # Copy the value in t4 to s4, the address of 
	# lw $t5, 4($t4) # t5 to store the y coordinate of the object
	lw $t4, 0($t4) # t4 to store the x coordiante of the object
		     
     
	la $t6, frogCoor
	# lw $t7, 4($t6) # t7 to store the y coordinate of the frog
	lw $t6, 0($t6) # t6 to store the x coordinate of the frog
		     
	add $t8, $t4, $t2 # the x coordinate of the right coner of the object
	bge $t6, $t8, offCollision1
	# Checked
	addi $t8, $t6, 4 # t8 to store the right cooner of the frog
	ble $t8, $t4, offCollision1
		     
	li $t7, 1
	lw $t8, 0($sp) # strote the return address to the t8
	sw $t7, 0($sp) # store the return value into the stack
		     
	jr $t8
		     
	offCollision1:
		     
	lw $t4, 8($s4) # t4 to store x coor of the object
	# lw $t5, 4($t4) # t5 to store the y coordinate of the object
		     
     
	la $t6, frogCoor
	# lw $t7, 4($t6) # t7 to store the y coordinate of the frog
	lw $t6, 0($t6) # t6 to store the x coordinate of the frog
		     
	add $t8, $t4, $t2 # the x coordinate of the right coner of the object
	bge $t6, $t8, offCollision2
 # Checked
	addi $t8, $t6, 4 # t8 to store the right cooner of the frog
	ble $t8, $t4, offCollision2
		     
	li $t7, 1
	lw $t8, 0($sp) # strote the return address to the t8
	sw $t7, 0($sp) # store the return value into the stack	
	jr $t8
		     
offCollision2:
		     
	lw $t8, 0($sp) # strote the return address to the t2
	sw $zero, 0($sp) # store the return value into the stack
	jr $t8		      
		     
			
	 	
	 	
	
	
reactKey:
	lw $t8, 0xffff0000
	beq $t8, 1, keyboardInput 	# react to key if pressed
	j noKeyEvent
	
keyboardInput:
	
	lw $t2, 0xffff0004 		# load the key value to t2
	
	beq $t2, 0x70, respondToP 	# Trigger p 
	lw $t6, gameStatus
	beq $t6, $zero, noKeyEvent 	# if the game status is 0, no key event will be respond
	j checkW
respondToP:
	li $t5, 1
	lw $t3, gameStatus
	la $t4, gameStatus
	sub $t3, $t5, $t3 		# If R is pressed, change the game status, either from start to end or end to start
	sw $t3, 0($t4)			# 1 represent start and 0 represent end
	
	j noKeyEvent

checkW:
	lw $t2, 0xffff0004
	beq $t2, 0x77, respondToW
	j checkA

respondToW:				# Move the frog up by 4 pixels
	la $t3, frogCoor
	la $t4, frogCoor
	lw $t3, 4($t3)
	addi $t3, $t3, -4
	
	li $t5, 0
	blt $t3, $t5, boundTop 		# Fix the y coordinate to 0 if it is smaller than 28
	
	j noBoundTop
	boundTop:
	add $t3, $zero, $t5
	noBoundTop:
	sw $t3, 4($t4)
	

	j noKeyEvent
	
	
checkA:
	lw $t2, 0xffff0004
	beq $t2, 0x61, respondToA
	j checkS
	
respondToA: 				# Move the frog left by one pixels
	la $t3, frogCoor
	la $t4, frogCoor
	lw $t3, 0($t3)
	addi $t3, $t3, -1
	
	blt $t3, $zero, boundLeft 	# Fix the x coordinate to 0 if it is smaller than 0
	
	j noBoundLeft
	boundLeft:
	add $t3, $zero, $zero
	noBoundLeft:
	sw $t3, 0($t4)
	
	j noKeyEvent
	


checkS:
	lw $t2, 0xffff0004
	beq $t2, 0x73, respondToS
	j checkD
	
respondToS: 				# Move the frog down by 4 pixels
	la $t3, frogCoor
	la $t4, frogCoor
	lw $t3, 4($t3)
	addi $t3, $t3, 4
	
	li $t5, 28	
	bgt $t3, $t5, boundBot 		# Fix the y coordinate to 28 if it is greater than 124
	
	j noBoundBot
	boundBot:
	add $t3, $zero, $t5
	noBoundBot:
	sw $t3, 4($t4)
	
	j noKeyEvent


checkD:
	lw $t2, 0xffff0004
	beq $t2, 0x64, respondToD
	j noKeyEvent

respondToD: 				# Move the frog right by 1 pixels
	la $t3, frogCoor
	la $t4, frogCoor
	lw $t3, 0($t3)
	addi $t3, $t3, 1
	
	li $t5, 28
	bge $t3, $t5, boundRight 	# Fix the x coordinate to 28 if it is greater than 28
	
	j noBoundRight
	boundRight:
	li $t5, 28
	add $t3, $zero, $t5
	noBoundRight:
	sw $t3, 0($t4)
	
	j noKeyEvent
	
	

	
	
noKeyEvent:
	jr $ra

	
drawCanvas:
	la $t0, canvas
	lw $t1, displayAddress
	
	addi $t2, $zero, 0 # Use t2 to loop
	li $t3, 1024
	li $t7, 4
	
	lw $t5, 0($t0)
	sw $t5, 0($t1)
	
	drawLoopBegin:
	bge $t2, $t3, drawStopLoop
	
	add $t0, $t0, $t7
	add $t1, $t1, $t7
	
	lw $t5, 0($t0)
	sw $t5, 0($t1)
	addi $t2, $t2, 1
	j drawLoopBegin
	
	drawStopLoop:
	jr $ra
	

moveObjsCoor:
	# Move frog, the speed of the frog could be 0
	la $t2, frogCoor
	lw $t1, frogSpeed
	la $a1, frogMoveEnd
	j Move
	
	frogMoveEnd:
	# Fix the frog position in case it fall from the screen
	lw $t3, 0($t2) # store the x coordinate into t3
	blt $t3, $zero, setToZero
	li $t4, 28
	bge $t3, $t4, setToRightBound
	j frogFixEnd
	
	setToRightBound:
	li $t3, 27
	sw $t3, 0($t2)
	
	setToZero:
	li $t3, 0
	sw $t3, 0($t2)
	
	frogFixEnd:

	# 
	la $t2, upperRowWoodLocation
	lw $t1, upperRowWoodSpeed
	la $a1, woodMoveEnd
	j Move
	
	woodMoveEnd:
	addi $t2, $t2, 8
	la $a1, woodMoveEnd1
	j Move
	
	woodMoveEnd1:
	la $t2, lowerRowWoodLocation
	lw $t1, lowerRowWoodSpeed
	la $a1, woodMoveEnd2
	j Move
	
	woodMoveEnd2:
	addi $t2, $t2, 8
	la $a1, woodMoveEnd3
	j Move
	
	woodMoveEnd3:
	
	la $t2, upperRowCarLocation
	lw $t1, upperRowCarSpeed
	la $a1, carMoveEnd
	j Move
	
	carMoveEnd:
	addi $t2, $t2, 8
	la $a1, carMoveEnd1
	j Move
	
	carMoveEnd1:
	la $t2, lowerRowCarLocation
	lw $t1, lowerRowCarSpeed
	la $a1, carMoveEnd2
	j Move
	
	carMoveEnd2:
	addi $t2, $t2, 8
	la $a1, carMoveEnd3
	j Move
	
	carMoveEnd3:
	jr $ra
	
	Move:
	lw $t3, 0($t2)
	add $t3, $t3, $t1
	li $t4, 32
	bge $t3, $t4, resetCoor
	blt $t3, $zero, readdCoor
	j doNoReset
	
	resetCoor:
	sub $t3, $t3, $t4
	j doNoReset
	
	readdCoor:
	addi $t3, $t3, 32
	j doNoReset
	
	doNoReset:
	sw $t3, 0($t2)
	jr $a1
	
drawObjs: # draw the objects
	la $s1, canvas
	
	lw $t9, woodBrown # Use t9 to store color
	la $t8, upperRowWoodLocation # t4 for coordinates
	la $a0, woodSize # t5 for obj size
	la $s2 objCurrent0
	j draw
	objCurrent0:
	
	addi $t8, $t8, 8
	la $s2 objCurrent1
	j draw
	objCurrent1:
	
	la $t8, lowerRowWoodLocation
	la $s2 objCurrent2
	j draw
	objCurrent2:
	
	addi $t8, $t8, 8
	la $s2 objCurrent3
	j draw
	objCurrent3:
	
	lw $t9, carRed # Use t9 to store color
	la $t8, upperRowCarLocation # t4 for coordinates
	la $a0, carSize # t5 for obj size
	la $s2 objCurrent4
	j draw
	objCurrent4:
	
	addi $t8, $t8, 8
	la $s2 objCurrent5
	j draw
	objCurrent5:
	
	la $t8, lowerRowCarLocation
	la $s2 objCurrent6
	j draw
	objCurrent6:
	
	addi $t8, $t8, 8
	la $s2 objCurrent7
	j draw
	objCurrent7:
	
	# Start draw life indicator
	
	lw $s5, lifeRemain # Store life count to t4
	li $s4, 0
	
	addi $sp, $sp, -4
	sw $s4, ($sp)
	addi $sp, $sp, -4
	sw $s5, ($sp)
	
	startLifeIndicator:
	lw $s5, ($sp)
	addi $sp, $sp, 4
	lw $s4, ($sp)
	addi $sp, $sp, 4
	
	beq $s5, $s4, endDrawObjs # Indicate the remaining lives
	
	addi $s4, $s4, 1
	addi $sp, $sp, -4 # push s4
	sw $s4, ($sp)
	addi $sp, $sp, -4 # push s5
	sw $s5, ($sp)
	
	
	lw $t9, lifeColor
	
	la $t5, jumpingTo # Pop the address of return to stack
	addi $sp, $sp, -4
	sw $t5, ($sp)
	
	addi $sp, $sp, -4 # Pop the value of color into stack
	sw $t9, ($sp)
	
	la $t5, canvas # pop the address of canvas into stack
	addi $sp, $sp, -4
	sw $t5, ($sp)
	
	li $t5, 3
	addi $s4, $s4, -1
	mul $t5, $t5, $s4 # The x coordinate of the rectangle
	addi $sp, $sp, -4
	sw $t5, ($sp)
	
	addi $sp, $sp, -4
	sw $zero, ($sp) # The y coordinate of the rectangle
	
	li $t5, 2 
	addi $sp, $sp, -4 # Pop the width and height into the stack
	sw $t5, ($sp)
	
	addi $sp, $sp, -4
	sw $t5, ($sp)
	
	j drawRectangleByStack
	
	jumpingTo:
	addi $s4, $s4, 1
	j startLifeIndicator
	
	endDrawObjs:
	jr $ra
	
	
	draw:	
	lw $t0, 0($t8) # Coordinates
	lw $t1, 4($t8)
	
	lw $t2, 0($a0) # Width
	lw $t3, 4($a0) # Height
	
	la $s3, drawObj
	j drawRectangle
	
	drawObj:
	jr $s2
	
	
drawRectangle: # t0 to store the x and t1 to store the y, t2 to store the width and t3 to store the height and t9 for color, s1 for canvas
		# x and y goes from 0 to 32, corresponding to the pixels, use s3 to jump back
		
	li $t4, 128 # Transfer the coordinate of y into relative addres values/diatance from the starting position
	mul $t1, $t1, $t4
	addi $v1, $t1, 0 # index for looping
	
	li $t4, 4 # Transfer the coordinate of x into relative addres values/diatance from the starting position
	mul $t0, $t0, $t4
	addi $v0, $t0, 0 # index for looping
	
	add $t6, $t0, $t1 # Store the value of distance from initial point to current point, already by 4
	
	add $t7, $t0, $t1 # Same as above, used as cursor for looping, change horizontally
	
	
	li $t4, 0 # Will be used as loop variant for outer loop
	li $t5, 0 # Will be used as loop variant for inner loop
	
	recOuter:
	beq $t4, $t3, recOuterEnd # The outer loop for the y 
	li $t5, 0
	
	recInner:
	beq $t5, $t2, recInnerEnd # The inner loop for the x
	
	add $a3, $t7, $s1
	sw $t9, 0($a3) # paint the color
	
	addi $t5, $t5, 1 # Accumulate
	
	
	
	la $s5, recCurrent0
	addi $s7, $t7, 0 # Set s7 to the t7, passing the parameter to the helper function
	j addressToCoordinate # Calculate the coordinate
	
	recCurrent0:
	add $a1, $k1, $zero # Store the y coordinate to a1, later to compare with a2
	
	addi $t7, $t7, 4 # Add t7 by 4, move the cursor right by one pixel
	
	la $s5, recCurrent1
	addi $s7, $t7, 0 # Set s7 to the t7, passing the parameter to the helper function
	j addressToCoordinate # Calculate the coordinate
	
	recCurrent1:
	add $a2, $k1, $zero # Store the later y coordinate as a2
	
	bgt $a2, $a1, verticalMoveBack # If a2 is greater than a1, than move the vertical cursor up by one pixel
	j recNothing
	
	verticalMoveBack:
	li $a1, 128
	sub $t7, $t7, $a1
	
	
	recNothing: 
	
	j recInner
	
	recInnerEnd:
	addi $t4, $t4, 1 # Accumulate
	addi $t6, $t6, 128 # Add 128 to t6 so that the cursor move one pixel down
	addi $t7, $t6, 0 # reset the t7 to t6 so that its horizontal position is back on zero
	j recOuter
	
	recOuterEnd:
	jr $s3
	
addressToCoordinate: # Take s7 as the address and store x to k0, y to k1, use s5 to jump back

	li $k1, 0 # Use k0 as the number the s7 can subtract 128
	li $k0, 0
	
	transStart: # First determine the y/k1
	blt $s7, $zero, transEnd # 
	
	li $s6, 128
	sub $s7, $s7, $s6 # Keep subtracting $s7 by 128
	addi $k1, $k1, 1 # Accumulate by add onr to k1
	j transStart
	
	transEnd: # Then Determine the x/k0
	addi $k1, $k1, -1 # Add -1 to be the actual value, note that y start from 0 rather than 1
	addi $s7, $s7, 128 # Since s7 is smaller than 0 at the end of the loop, we add it back
	
	transStart2:
	blt $s7, $zero, transEnd2 # 
	
	li $s6, 4
	sub $s7, $s7, $s6
	addi $k0, $k0, 1
	j transStart2
	
	transEnd2:
	addi $k0, $k0, -1 # Same as above
	jr $s5
	
	
drawBg:
	# graph top grass section
	la $t0, canvas
	lw $t1, grassGreen # $t1 store color
	li $t2, 128 # 4 rows of color $t1 at the top
	li $t3, 0
	
	lw $t4, safeZoneStatus
	la $t5, safeZoneStatus
	sw $zero, ($t5)
	bgt, $t4, $zero, resetSafeZone
	j startGraphEndGrass
resetSafeZone:
	li $t2, 256
startGraphEndGrass:
		beq $t3, $t2, stopGraphEndGrass
		sw $t1, 0($t0)
		addi $t0, $t0, 4
		addi $t3, $t3, 1
		j startGraphEndGrass 
stopGraphEndGrass:
	
	bgt, $t4, $zero, graphRiver
	addi $t0, $t0, 512
graphRiver:
	# graph river section
	lw $t1, riveBlue
	addi $t3, $t2, 0
	addi $t2, $t2, 256
	
startGraphRiver:
		beq $t3, $t2, stopGraphRiver
		sw $t1, 0($t0)
		addi $t0, $t0, 4
		addi $t3, $t3, 1
		j startGraphRiver 
stopGraphRiver:
	# graph middle resting zone
	lw $t1, middleRestPurple
	addi $t3, $t2, 0
	addi $t2, $t2, 128
startGraphMiddleRest:
		beq $t3, $t2, stopGraphMiddleRest
		sw $t1, 0($t0)
		addi $t0, $t0, 4
		addi $t3, $t3, 1
		j startGraphMiddleRest 
stopGraphMiddleRest:
	
	# graph read section
	lw $t1, roadBlack
	addi $t3, $t2, 0
	addi $t2, $t2, 256
	
startGraphRoad:
		beq $t3, $t2, stopGraphRoad
		sw $t1, 0($t0)
		addi $t0, $t0, 4
		addi $t3, $t3, 1
		j startGraphRoad
stopGraphRoad:
	
	# start drawing bottom grass section
	
	lw $t1, grassGreen
	addi $t3, $t2, 0
	addi $t2, $t2, 128
	
startGraphBeginningGrass:
		beq $t3, $t2, stopGraphBeginningGrass
		sw $t1, 0($t0)
		addi $t0, $t0, 4
		addi $t3, $t3, 1
		j startGraphBeginningGrass
stopGraphBeginningGrass:
	jr $ra
		
		
graphDeadRespawnAnima:
# graph the dead animation, given t1 = offset of frog
	lw $t1, displayAddress
	la $t1, 3644($t1)
	lw $t9, white
	sw $t9, -8($t1)
	sw $t9, 116($t1)
	sw $t9, 244($t1)
	sw $t9, 376($t1)
	sw $t9, 20($t1)
	sw $t9, 152($t1)
	sw $t9, 280($t1)
	sw $t9, 404($t1)
	jr $ra
	
		
drawFrog:
	la $t0, canvas
	lw $t1, frogGreen # $t1 stores the frog colour code
	
	la $t2, frogCoor # $t2 is used to store the address of x and y coordinates 
	la $t3, frogLocations # $t3 is used to store relative the addres of frogLocations
	li $t4, 0
	li $t5, 12
	
	li $s7 4
	lw $s6 0($t2)
	mul $t8, $s6, $s7
	li $s7, 128
	
	lw $s6 4($t2)
	mul $t9, $s6, $s7
	add $t2, $t8, $t9
	
	beginDrawFrog:
		li $t7, 4
		beq $t4, $t5, endDrawFrog
		mul $s1, $t7, $t4
		add $s1, $t3, $s1 # The position index of frogpixel in array
		
		lw $t6, 0($s1) # t6 to store the distance from the initial position, already by 4
		
		# initial posiiton, should be multiplied by 4
		add $t7, $t2, $zero

		add $t7, $t7, $t6 # let t7 to store the absolute position
		add $t7, $t0, $t7
		sw $t1, 0($t7)
		addi $t4, $t4, 1
		j beginDrawFrog
	endDrawFrog:
		jr $ra

		
	
drawRectangleByStack: # Stack: returnAddress, colorValue, Canvas, xCoor, yCoor, Width, Height
		# t0 to store the x and t1 to store the y, t2 to store the width and t3 to store the height and t9 for color, s1 for canvas
		# x and y goes from 0 to 32, corresponding to the pixels, use s3 to jump back
	lw $t3, 0($sp) # t3 for height
	addi $sp, $sp, 4
	lw $t2, ($sp) # t2 for width
	addi $sp, $sp, 4
	lw $t1, ($sp) # t1 for y coordinate
	addi $sp, $sp, 4
	lw $t0, ($sp) # t0 for x coordinate
	addi $sp, $sp, 4
	
	lw $s1, ($sp) # s1 for address of canvas 
	addi $sp, $sp, 4
	
	lw $t9, ($sp) # t9 for color value
	addi $sp, $sp, 4
	
	lw $s3, ($sp) # s3 for jump back address
	addi $sp, $sp, 4
	
		
	li $t4, 128 # Transfer the coordinate of y into relative addres values/diatance from the starting position
	mul $t1, $t1, $t4
	addi $v1, $t1, 0 # index for looping
	
	li $t4, 4 # Transfer the coordinate of x into relative addres values/diatance from the starting position
	mul $t0, $t0, $t4
	addi $v0, $t0, 0 # index for looping
	
	add $t6, $t0, $t1 # Store the value of distance from initial point to current point, already by 4
	
	add $t7, $t0, $t1 # Same as above, used as cursor for looping, change horizontally
	
	
	li $t4, 0 # Will be used as loop variant for outer loop
	li $t5, 0 # Will be used as loop variant for inner loop
	
	recOuter1:
	beq $t4, $t3, recOuterEnd1 # The outer loop for the y 
	li $t5, 0
	
	recInner1:
	beq $t5, $t2, recInnerEnd1 # The inner loop for the x
	
	add $a3, $t7, $s1
	sw $t9, 0($a3) # paint the color
	
	addi $t5, $t5, 1 # Accumulate
	
	
	
	la $s5, recCurrent01
	addi $s7, $t7, 0 # Set s7 to the t7, passing the parameter to the helper function
	j addressToCoordinate # Calculate the coordinate
	
	recCurrent01:
	add $a1, $k1, $zero # Store the y coordinate to a1, later to compare with a2
	
	addi $t7, $t7, 4 # Add t7 by 4, move the cursor right by one pixel
	
	la $s5, recCurrent11
	addi $s7, $t7, 0 # Set s7 to the t7, passing the parameter to the helper function
	j addressToCoordinate # Calculate the coordinate
	
	recCurrent11:
	add $a2, $k1, $zero # Store the later y coordinate as a2
	
	bgt $a2, $a1, verticalMoveBack1 # If a2 is greater than a1, than move the vertical cursor up by one pixel
	j recNothing1
	
	verticalMoveBack1:
	li $a1, 128
	sub $t7, $t7, $a1
	
	
	recNothing1: 
	
	j recInner1
	
	recInnerEnd1:
	addi $t4, $t4, 1 # Accumulate
	addi $t6, $t6, 128 # Add 128 to t6 so that the cursor move one pixel down
	addi $t7, $t6, 0 # reset the t7 to t6 so that its horizontal position is back on zero
	j recOuter1
	
	recOuterEnd1:
	jr $s3
	
increaseSpeed:
	
	li $t3, 3
	lw $t0, nextLineSignal
	li $t1, 5
	ble $t0, $t1, skipSpeedingPWood
	sub $t0, $t0, $t3
	
	la $t1, nextLineSignal
	sw $t0, ($t1)
	skipSpeedingPWood:
	# end of speeding up
	jr $ra
	
resetData:
	# Reset the data
	la $t1, safeZoneStatus
	li $t2, 1
	sw $t2, 0($t1)
	
	la $t1, woodSize # reset the wood size, only the width
	li $t2, 8
	sw $t2, 0($t1)
	
	la $t1, upperRowWoodSpeed # reset the wood speed, only the width
	li $t2, 2
	sw $t2, 0($t1)
	
	la $t1, lowerRowWoodSpeed # reset the wood speed, only the width
	li $t2, -1
	sw $t2, 0($t1)
	
	la $t1, upperRowCarSpeed# reset the car speed, only the width
	li $t2, 1
	sw $t2, 0($t1)
	
	la $t1, lowerRowCarSpeed# reset the car speed, only the width
	li $t2, -2
	sw $t2, 0($t1)
	
	la $t1, woodSize # reset the wood size, only the width
	li $t2, 8
	sw $t2, 0($t1)

	
	la $t1, level
	sw $zero, 0($t1)
	
	la $t1, score
	sw $zero, 0($t1)
	
	la $t1, lifeColor
	li $t2, 0xff0000
	sw $t2, 0($t1)
	
	la $t1, winStatus
	sw $zero, 0($t1)
	
	la $t1, gameStatus
	sw $zero, 0($t1)
	
	la $t1, beenHit
	sw $zero, 0($t1)
	
	la $t1, lifeRemain
	li $t2, 3
	sw $t2, 0($t1)
	
	la $t1, ObjInitialPosition
	sw $zero, 0($t1)
	
	la $t1, nextLineSignal
	li $t2, 15
	sw $t2, 0($t1)
	
	la $t1, frogSpeed
	sw $zero, 0($t1)
	
	jr $ra
	
nextLevelCheck:
	lw $t1, score
	li $t2, 2
	blt $t1, $t2, noNextLevel
	# Go to next level
	la $t1, woodSize
	li $t2, 4
	sw $t2, ($t1)
	
	# 7f00ff as color for health indicator
	la $t1, lifeColor
	li $t2, 0x7f00ff
	sw $t2, ($t1)
	
	noNextLevel:
	jr $ra
	
sinkWood:
# controls the "random" sink of the wood
	lw $t1, sinkCount
	lw $t2, isSink
	lw $t3, sinkTime
	
	# Action when float
	addi $t1, $t1, 1
	la $t4, sinkCount
	sw $t1, ($t4)
	bge $t1, $t3, changeSinkStatus
	j endOfChanging
	# Action when still floating
	
changeSinkStatus:
	la $t1, sinkCount
	sw $zero, ($t1)
	li $t4, 1
	sub $t2, $t4, $t2 # change the sinking status
	la $t1, isSink
	sw $t2, ($t1)
	
	# Case when change to sink
	beq $t2, $zero, toFloat
	# Action to hide the second wood so that two woods overlay
	la $t5, upperRowWoodLocation
	lw $t6, 8($t5) # x coor of second wood
	lw $t7, ($t5) # x coor of the first wood
	sub $t8, $t6, $t7 # x of 2 - x of 1
	sw $t7, 8($t5) # Store the first x into the second x
	addi $sp, $sp, -4
	sw $t8, ($sp) # push the diff into the diference
	# end of hiding the wood
	j endOfChanging
	
toFloat:
	# Action to restore the second wood
	la $t5, upperRowWoodLocation
	lw $t6, ($sp) # t6 for the diff between first and second wood
	addi $sp, $sp, 4
	lw $t7, ($t5)
	add $t7, $t7, $t6 # t7 for the actual wood x coor
	sw $t7, 8($t5) # restore
	# End of action
	
endOfChanging:
	jr $ra
	
		
	
Testing:
	li $v0,1

move $a0,$t2

syscall

li $a0, 'f'
li $v0, 11    # print_character
syscall
