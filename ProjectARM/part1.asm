// Fall 2020 CPSC 355
// Project Part 2 by Desmond Lau
	.text
inputcheck: .string "username is %s and dimensions are %d x %d \n" //junk
error: .string "Error: Invalid board size/number of arguments. Exiting program. \n"
countNeg: .string "negative numbers %d/%d = %-.2f% \n"
countPos: .string "positive numbers %d/%d = %-.2f% \n"
countSpec: .string "special tiles %d/%d = %-.2f% \n"
uncovered: .string "%-10s "
uFloat: .string "%-10.2f "
newline: .string "\n"
star: .string "* "
powerupR: .string "$ "
powerupL: .string "^ "
powerupSc: .string "& "
plus: .string "+ "
minus: .string "- "
xtile: .string "X "
numLives: .string "Lives: %d \n"
numBombs: .string "Bombs: %.0f \n"
numScore: .string "Score: %.2f \n"
enterXCoord: .string "Enter the bomb x-coordinate: \n"
enterYCoord: .string "Enter the bomb y-coordinate: \n"
format: .string "%d"
gameOverMsg: .string "GAME OVER. \n"
winGameMsg: .string "YOU WIN. \n"
preGamePrompt: .string "Press 1 to start the game, 2 to view leaderboard, 3 to quit.\n"
bombMsg: .string "Bomb range increased by %dx for the next bomb.\n"
uncoveredMsg: .string "Total uncovered score: %.2f\n"
quitMidGame: .string "To quit type 999 as both coordinates.\n"
howmany: .string "How many scores do you want to view?\n"

	// define macros
	define(m_r, x19)
	define(n_r, x20)
	define(username_r, x21)
	define(alloc_r, x22)
	define(offset_r, x23)
	define(counter_r, x24)
	define(gameTime_r, x25)
	define(stackPT_r, x28)

	define(allocSpace_r,
		`sub	alloc_r,	xzr,	m_r
		mul	alloc_r,	alloc_r,	n_r	// alloc = -m x n
		mov	x3,	8				// set x3 as 8
		mul	alloc_r,	alloc_r,	x3	// alloc = -m x n x 8 (2d array space
		mul	x3,	m_r,	n_r
		mov	x4,	4
		mul	x4,	x4,	x3			// m x n x 4 (flag board)
		sub	alloc_r,	alloc_r,	x4	// 2d array + flag board
		sub	alloc_r,	alloc_r,	32	// 2d + flag + gameData struct	
		mov	x3,	-16				// set x3 as 16
		and	alloc_r, 	alloc_r,	x3	// and to make sure multiple of 16 bytes
		add	sp,		sp,		alloc_r') // allocate the space	

	// open subroutine to calculate size to store x19-x28 registers before a function
	define(storeOffsets_r,
		`alloc = -(16 + 72 + 64) & -16 // 72 = 8*9 x19-x28   64 = 8*8 d8-d15
		dealloc = -alloc
		x19_OS = 16
		x20_OS = x19_OS + 8
		x21_OS = x20_OS + 8
		x22_OS = x21_OS + 8
		x23_OS = x22_OS + 8
		x24_OS = x23_OS + 8
		x25_OS = x24_OS + 8
		x26_OS = x25_OS + 8
		x27_OS = x26_OS + 8
		x28_OS = x27_OS + 8
		d8_OS = x28_OS + 8
		d9_OS = d8_OS + 8
		d10_OS = d9_OS + 8
		d11_OS = d10_OS + 8
		d12_OS = d11_OS + 8
		d13_OS = d12_OS + 8
		d14_OS = d13_OS + 8
		d15_OS = d14_OS + 8')

	// open subroutine to store the x19-x28 and d8-d15 registers
	define(store_r,
		`str	x19,	[x29, x19_OS]
		str	x20,	[x29, x20_OS]
		str	x21,	[x29, x21_OS]
		str	x22,	[x29, x22_OS]
		str	x23,	[x29, x23_OS]
		str	x24,	[x29, x24_OS]
		str	x25,	[x29, x25_OS]
		str	x26,	[x29, x26_OS]
		str	x27,	[x29, x27_OS]
		str	x28,	[x29, x28_OS]
		str	d8,	[x29, d8_OS]
		str	d9,	[x29, d9_OS]
		str	d10,	[x29, d10_OS]
		str	d11,	[x29, d11_OS]
		str	d12,	[x29, d12_OS]
		str	d13,	[x29, d13_OS]
		str	d14,	[x29, d14_OS]
		str	d15,	[x29, d15_OS]')

	// open subroutine to restore the x19-x28 and d8-d15 registers
	define(restore_r,
		`ldr	x19,	[x29, x19_OS]
		ldr	x20,	[x29, x20_OS]
		ldr	x21,	[x29, x21_OS]
		ldr	x22,	[x29, x22_OS]
		ldr	x23,	[x29, x23_OS]
		ldr	x24,	[x29, x24_OS]
		ldr	x25,	[x29, x25_OS]
		ldr	x26,	[x29, x26_OS]
		ldr	x27,	[x29, x27_OS]
		ldr	x28,	[x29, x28_OS]
		ldr	d8,	[x29, d8_OS]
		ldr	d9,	[x29, d9_OS]
		ldr	d10,	[x29, d10_OS]
		ldr	d11,	[x29, d11_OS]
		ldr	d12,	[x29, d12_OS]
		ldr	d13,	[x29, d13_OS]
		ldr	d14,	[x29, d14_OS]
		ldr	d15,	[x29, d15_OS]')

	// open subroutine to do error checking in command line
	define(cmdLineCheck_r,
		`cmp	m_r,	10	// compares m with 10
		b.lt	errorMsg	// m < 10 go to errorMsg
		cmp	n_r,	10	// compares n with 10
		b.lt	errorMsg')	// n < 10 go to errorMsg

	.balign 4	// code starts at multiple of 4 addresses
	.global	main	// enables main

/* main takes in command line arguments and determines game board size and the player name, and calls other functions
//   parameters: argc (x0) - the number of command line arguments
//               argv (x1) - an array containing the arguments provided */
main:
	stp	x29,	x30,	[sp, -16]!	// store fp and link registers
	mov	x29, 	sp			// update fp

if:	cmp	x0,	4			// compares argc with 4
	b.lt	errorMsg			// argc < 4 go to exit

else:	cmp	x0,	4			// compares argc with 4
	b.gt	errorMsg			// argc > 4 go to exit
	bl	readArgs			// read args
	cmdLineCheck_r()			// error checking board size
	allocSpace_r()				// allocate space in the stack		
	
	mov	x0,	x29 			// pass in 2d array as first arg
	mov	x1,	m_r			// pass in m as 2nd arg
	mov	x2,	n_r			// pass in n as 3rd arg
	bl	initGame

	ldr	x0,	=preGamePrompt	// prompt user to play, leaderboard or quit
	bl	printf
	ldr	x0,	=format
	ldr	x1,	=scan
	bl	scanf
	ldr	x1,	=scan
	ldr	x9,	[x1]
	cmp	x9,	1 // 1 = play game
	b.eq	gotoPlay
	cmp	x9,	2 // 2 = view leaderboard
	b.eq	gotoView
	b	deallocSpace // quit
gotoPlay:
	mov	x0,	xzr
	bl	time
	mov	gameTime_r,	x0
	mov	x0,	x29			// 2d array is 1st arg
	mov	x1,	m_r
	mov	x2,	n_r
	mov	x3,	username_r
	bl	playGame

	mov	x0,	xzr
	bl	time
	mov	x9,	x0
	sub	gameTime_r,	x9,	gameTime_r

	mov	x0,	x29
	mov	x1,	alloc_r
	mov	x2,	username_r
	mov	x3,	gameTime_r
	bl	exitGame
	b	deallocSpace	
gotoView:
	ldr	x0,	=howmany
	bl	printf
	ldr	x0,	=format
	ldr	x1,	=scan	
	bl	scanf	
	ldr	x1,	=scan
	ldr	x9,	[x1]	
	mov	x0,	x9
	bl	displayTopScores

	mov	x0,	xzr
	bl	time
	mov	gameTime_r, x0
	mov	x0,	x29
	mov	x1,	m_r
	mov	x2,	n_r
	mov	x3,	username_r
	bl	playGame

	mov	x0,	xzr
	bl	time
	mov	x9,	x0
	sub	gameTime_r,	x9,	gameTime_r

	mov	x0,	x29
	mov	x1,	alloc_r
	mov	x2,	username_r
	mov	x3,	gameTime_r
	bl	exitGame

deallocSpace:
	sub	alloc_r,	xzr,	alloc_r	// make alloc positive
	add	sp,	sp,	alloc_r		// add alloc to restore space
exit:	ldp	x29,	x30,	[sp],	16	// restore fp and link registers
	ret					// end main

define(negCount_r, x21)
define(counter2_r, x26)
define(pwrCount_r, x25)
define(exitFlag_r, x26)
define(size_r, x27)
define(fsize_r, d8)
define(negNum_r, d9)
define(numPwr_r, d10)

/* initialize the game by populating the game board with positive or negative integers, powerups and exit tiles. It also prints out the uncovered board
//   parameters: stack pointer - the pointer to the stack containing the empty 2d array
//               m - the number of rows in the game board
//              n - the number of columns in the game board 
//   returns: nothing */
storeOffsets_r() // set the offsets
initGame:
	stp	x29,	x30,	[sp, alloc]!	// store fp and link registers
	mov	x29,	sp			// update fp
	store_r()				// save x19-x28 registers

	mov	stackPT_r,	x0		// store 1st arg in stackPT
	mov	m_r,		x1		// store 2nd arg in m
	mov	n_r,		x2		// store 3rd arg in n
	mul	size_r,	m_r,	n_r		// x9 = board size m x n		
	scvtf	fsize_r,	size_r		// convert board size to float
	fmov	d16,	4.0			// set d16 as 4.0
	fmov	d17,	10.0			// set d17 as 10.0
	fdiv	d16,	d16,	d17		// d16 = 4.0/10.0 = 0.4		
	fmul	negNum_r,	fsize_r, d16	// num of negatives = boardsize * 0.4 (40% of board)
	fmov	d16,	2.0			// set d16 as 2.0	
	fmov	d17,	10.0			// set d17 as 10.0
	fdiv	d16,	d16,	d17		// d16 = 2.0/10.0 = 0.2
	fmul	numPwr_r,	fsize_r, d16	// num of powerups = boardszie * 0.2 (20% of board)
	mov	negCount_r,	0 		// negative counter
	mov	pwrCount_r,	0 		// powerup counter
	mov	exitFlag_r,	0 		// flag for exit tile (0 - not there, 1 - already has one)
	mov	offset_r,	alloc_r		// set offset to bottom of stack
	mov	counter_r,	0		// set counter as 0
	mov	x0,	xzr			// set x0 to 0
	bl	time				// call function time
	bl	srand				// call function srand

initLoop:
	bl	rand				// call function rand
	mov	x10,	x0			// store random num in x10
	and	x10,	x10,	0xF		// and with 15

initExitTile: // spawn exit tile if 0
	cmp	x10,	0			// compare randomnum with 0
	b.ne	initNegNum			// if randomnum != 0 go to initNegNum
	cmp	exitFlag_r,	0		// compare exit tile flag with 0
	b.ne	initNegNum			// if flag != 0 (already has exit tile) go to initNegNum
	add	pwrCount_r,	pwrCount_r, 1	// powerup counter + 1 (considered special tile)
	mov	exitFlag_r,	1		// set exit flag with 1
	fmov	d16,	20.00			// exit tile has value of 20
	str	d16,	[stackPT_r, offset_r]	// store exit tile value in stack
	b	initLoopCont

initNegNum: // spawn neg tile if 1 to 6
	cmp	x10,	6			// compare randomnum with 6
	b.gt	initPowerup			// if randomnum > 6 go to initPowerup
	fcvtns	x7,	negNum_r		// convert num of negatives (float) to int	
	cmp	x7,	negCount_r		// compare num of neg with negative counter
	b.lt	initPowerup			// if num of neg < counter go to initPowerup
	add	negCount_r,	negCount_r, 1	// add 1 to negative counter
	mov	x13,	0			// set neg to 0
	mov	x0,	0			// 1st arg min is 0
	mov	x1,	15			// 2nd arg max is 15
	mov	x2,	x13			// 3rd arg neg is 0 (true)
	bl	randomNum // call randomnum function
	fmov	d11,	d0			// retrieve return value randomnum
	str	d11,	[stackPT_r, offset_r]
	b 	initLoopCont

initPowerup:
	cmp	x10,	9			// compare randomnum with 9
	b.gt	initPosNum			// if randomnum > 9 go to initPosNum
	fcvtns	x7,	numPwr_r		// convert num of positives (float) to int
	cmp	x7,	pwrCount_r		// compare num of powerups with powerup counter
	b.lt	initPosNum			// if num of powerups < counter go to initPosNum
	add	pwrCount_r,	pwrCount_r, 1	// add powerup counter by 1
	cmp	x10,	7
	b.eq	powerupRange
	cmp	x10,	8
	b.eq	powerupScore
	cmp	x10,	9
	b.eq	powerupLives
powerupRange:
	fmov	d16,	21.00			// powerup tile has value of 21
	str	d16,	[stackPT_r, offset_r]	// store powerup tile value in stack
	b	initLoopCont
powerupScore:
	fmov	d16,	22.00
	str	d16,	[stackPT_r, offset_r]
	b	initLoopCont
powerupLives:
	fmov	d16,	23.00
	str	d16,	[stackPT_r, offset_r]
	b	initLoopCont

initPosNum:
	mov	x13,	1			// set negative flag to 1 (positive)
	mov	x0,	0			// 1st arg min is 0
	mov	x1,	15			// 2nd arg max is 15
	mov	x2,	x13			// 3rd arg neg is 1 (false)
	bl	randomNum
	fmov	d11,	d0			// retrieve return value randomnum
	str	d11,	[stackPT_r, offset_r]

initLoopCont:	
	add	offset_r,	offset_r, 8 	// add 8 to offset	
	add	counter_r,	counter_r, 1	// add 1 to counter
	cmp	counter_r,	size_r		// compare counter to board size
	b.lt	initLoop			// counter < board size loop back
	
	mov	offset_r,	alloc_r
	mov	counter_r,	0
	mov	counter2_r,	0	
uncoveredBoard:
	ldr	d11,	[stackPT_r, offset_r]	// print uncovered board
ucPrintExit:
	mov	x7,	20
	scvtf	d16,	x7
	fcmp	d16,	d11 			// compare with 20 (exit tile)
	b.ne	ucPrintPowerupRange
	ldr	x0,	=uncovered
	ldr	x1,	=star
	bl	printf
	b 	contUncovered
ucPrintPowerupRange:
	mov	x7,	21
	scvtf	d16,	x7
	fcmp	d16,	d11			// compare with 21 (powerup)
	b.ne	ucPrintPowerupScore
	ldr	x0,	=uncovered
	ldr	x1,	=powerupR
	bl	printf
	b	contUncovered
ucPrintPowerupScore:
	mov	x7,	22
	scvtf	d16,	x7
	fcmp	d16,	d11
	b.ne	ucPrintPowerupLives
	ldr	x0,	=uncovered
	ldr	x1,	=powerupSc
	bl	printf
	b	contUncovered
ucPrintPowerupLives:
	mov	x7,	23
	scvtf	d16,	x7
	fcmp	d16,	d11
	b.ne	ucPrintNum
	ldr	x0,	=uncovered
	ldr	x1,	=powerupL
	bl	printf
	b	contUncovered
ucPrintNum:
	ldr	x0,	=uFloat
	fmov	d0,	d11
	bl	printf
contUncovered:
	add	offset_r,	offset_r, 8
	add	counter_r,	counter_r, 1
	cmp	counter_r,	n_r
	b.lt	uncoveredBoard	
	
	ldr	x0,	=newline
	bl	printf
	mov	counter_r,	0
	add	counter2_r,	counter2_r, 1
	cmp	counter2_r,	m_r
	b.lt	uncoveredBoard

	scvtf	d16,	negCount_r		// print neg number percentage
	fdiv	d16,	d16,	fsize_r
	mov	x7,	100
	scvtf	d17,	x7
	fmul	d16,	d16,	d17
	ldr	x0,	=countNeg		// load x0 with countNeg
	mov	x1,	negCount_r		// load x1 with neg counter
	mov	x2,	size_r
	fmov	d0,	d16
	bl	printf				// print it

	sub	x9,	size_r,	x21		// total - neg - powerups = pos
	sub	x9,	x9,	x25		// print pos number percentage
	scvtf	d16,	x9
	fdiv	d16,	d16,	fsize_r
	mov	x7,	100
	scvtf	d17,	x7
	fmul	d16,	d16,	d17
	ldr	x0,	=countPos
	mov	x1,	x9
	mov	x2,	size_r
	fmov	d0,	d16
	bl	printf

	scvtf	d16,	pwrCount_r		// print powerups percentage
	fdiv	d16,	d16,	fsize_r
	mov	x7,	100
	scvtf	d17,	x7
	fmul	d16,	d16,	d17
	ldr	x0,	=countSpec		// load x0 with countSpec
	mov	x1,	pwrCount_r		// load x1 with powerup counter
	mov	x2,	size_r
	fmov	d0,	d16
	bl	printf				// print it
		
	restore_r()				// restore x19-x28 registers
	ldp	x29,	x30,	[sp],	dealloc	// restore fp and link registers
	ret					// end function

/* randomNum generates a random float within a range
//   parameters: min - the minimum value of the randomly generated float
//               max - the maximum value of the randomly generated float
//               neg - a boolean to check whether to generate a positive or negative float
//   returns: the randomly generated float */
randomNum:
	stp	x29,	x30,	[sp, -16]!	// store fp and link registers
	mov	x29,	sp			// update fp

	mov	x9,	x0			// store 1st arg min in x9
	mov	x10,	x1			// store 2nd arg max in x10
	mov	x11,	x2			// store 3rd arg neg in x11

generateLoop:
	bl	rand				// call rand --> ((rand()+min)&max) whole number
	mov	x12,	x0			// save rand in x12
	add	x12,	x12,	x9		// add with min (0)
	and	x12,	x12,	x10		// and with max	(15)
	scvtf	d12,	x12			// convert to float

	bl	rand				// call rand --> (+(rand()/RAND_MAX)) fraction	
	mov	x13,	x0			// save next rand in x13
	scvtf	d13,	x13			// convert rand to float
	mov	x7,	2147483647		// RAND_MAX value	
	scvtf	d16,	x7			// convert RAND_MAX to float
	fdiv	d13,	d13,	d16		// rand / rand_max to get random decimal point
	fadd	d12,	d12,	d13		// whole number + fraction
	scvtf	d16,	x9			// convert min to float
	fcmp	d16,	d12			// compare min to randomnum
	b.gt	generateLoop			// min > randomnum re-generate
	scvtf	d16,	x10			// convert max to float
	fcmp	d16,	d12			// compares max to randomnum
	b.lt	generateLoop			// max < randomnum re-generate

checkNeg:
	cmp	x11,	0			// if neg flag is 0 (negative)
	b.ne	endGenerate			// neg != 0 (positive) go to endGenerate
	mov	x7,	-1			// x7 = -1
	scvtf	d16,	x7			// convert -1 to float
	fmul	d12,	d12,	d16		// randomnum * -1 to make negative

endGenerate:
	fmov	d0,	d12			// set randomnum as return value
	ldp	x29,	x30,	[sp],	16	// restore fp and link registers
	ret					// end function 

define(lives_r, x24)
define(bombRadius_r, x25)
define(xCoord_r, x26)
define(yCoord_r, x27)
define(score_r, d8)
define(roundScore_r, d9)
define(bombs_r,	d11)

/* function that runs the game and calls other functions in order to do so. It also measures the run time of the game
//   parameters: stack pointer - stack pointer to the 2d array, flag board and game data struct
//               m - the number of rows in the game board
//               n - the number of columns in the game board
//               username - the player's name 
//   returns: nothing */
storeOffsets_r()
playGame:
	stp	x29,	x30,	[sp, alloc]!
	mov	x29,	sp
	store_r()

	mov	stackPT_r,	x0 //x28
	mov	m_r,	x1 // x19
	mov	n_r,	x2 // x20
	mov	username_r,	x3 // x21
	mov	xCoord_r,	-1 // x26
	mov	yCoord_r,	-1 //x27
	mov	bombRadius_r,	1 //x25
	mov	lives_r,	3 // x24
	mov	x10,	0
getBombs:
	fmov	d16,	1.0
	fadd	bombs_r,	bombs_r,	d16
	add	x10,	x10,	3
	cmp	x10,	m_r
	b.lt	getBombs

	mov	x7,	0
	scvtf	score_r,	x7	

	mov	x0,	stackPT_r	
	mov	x1,	m_r
	mov	x2,	n_r
	bl	popFlagBoard // populate the flag board with 0s

playLoop:
	mov	x0,	stackPT_r
	mov	x1,	m_r
	mov	x2,	n_r
	bl	displayGame

	ldr	x0,	=numLives
	mov	x1,	lives_r
	bl	printf
	ldr	x0,	=numScore	
	fmov	d0,	score_r
	bl	printf
	ldr	x0,	=numBombs
	fmov	d0,	bombs_r
	bl	printf

	ldr	x0,	=quitMidGame
	bl	printf
	ldr	x0,	=enterXCoord
	bl	printf
	ldr	x0,	=format
	ldr	x1,	=scan
	bl	scanf
	ldr	x1,	=scan
	ldr	xCoord_r,	[x1]	// get x coord

	ldr	x0,	=enterYCoord
	bl	printf
	ldr	x0,	=format
	ldr	x1,	=scan
	bl	scanf
	ldr	x1,	=scan
	ldr	yCoord_r,	[x1] // get y coord

	mov	x9,	999
	cmp	xCoord_r,	x9
	b.eq	gameOver
	cmp	yCoord_r,	x9
	b.eq	gameOver

	mov	x9,	0
	cmp	xCoord_r,	x9
	b.lt	playLoop
	cmp	yCoord_r,	x9
	b.lt	playLoop
	sub	x7,	m_r,	1
	cmp	xCoord_r,	x7
	b.gt	playLoop
	sub	x7,	n_r,	1
	cmp	yCoord_r,	x7
	b.gt	playLoop

	mov	x0,	stackPT_r	
	mov	x1,	m_r
	mov	x2,	n_r
	mov	x3,	xCoord_r
	mov	x4,	yCoord_r
	mov	x5,	bombRadius_r
	bl	updateBoard		// update the board
	mov	bombRadius_r,	1	// reset bomb radius

	mov	x0,	stackPT_r
	mov	x1,	alloc_r
	mov	x2,	m_r
	mov	x3,	n_r
	mov	x4,	bombRadius_r
	mov	x5,	lives_r
	fmov	d0,	score_r
	fmov	d1,	roundScore_r
	bl	calculateScore
	fmov	d15,	d0 // save win condition returned

	fmov	d16,	1.0
	fcmp	d15,	d16 // 1 = win  0 = still playing
	b.eq	youWin

	mov	offset_r,	alloc_r
	mul	x9,	m_r,	n_r
	mov	x7,	8
	mul	x7,	x9,	x7
	add	offset_r,	offset_r,	x7 // skip over 2d array
	mov	x7,	4
	mul	x7,	x9,	x7
	add	offset_r,	offset_r,	x7 // skip over flag board	

	ldr	lives_r,	[stackPT_r, offset_r]
	add	offset_r,	offset_r,	8
	ldr	bombRadius_r,	[stackPT_r, offset_r]
	add	offset_r,	offset_r,	8
	ldr	score_r,	[stackPT_r, offset_r]
	add	offset_r,	offset_r,	8
	ldr	roundScore_r,	[stackPT_r, offset_r]

	cmp	bombRadius_r,	1
	b.gt	bombRangeMsg
	b	uncoveredScore
bombRangeMsg:
	ldr	x0,	=bombMsg
	mov	x1,	bombRadius_r
	bl	printf
uncoveredScore:
	ldr	x0,	=uncoveredMsg
	fmov	d0,	roundScore_r
	bl	printf
	
	cmp	lives_r,	0
	b.eq	gameOver

	fmov	d16,	1.0 
	fsub	bombs_r,	bombs_r,	d16 // bombs - 1
	mov	x7,	0
	scvtf	d16,	x7
	fcmp	bombs_r,	d16
	b.gt	playLoop		

gameOver:
	ldr	x0,	=gameOverMsg
	bl	printf
	b	stopGame
youWin:
	ldr	x0,	=winGameMsg
	bl	printf
	mov	x0,	stackPT_r
	mov	x1,	m_r
	mov	x2,	n_r
	bl	displayGame
	ldr	x0,	=numLives
	mov	x1,	lives_r
	bl	printf
	ldr	x0,	=numScore	
	fmov	d0,	score_r
	bl	printf
	ldr	x0,	=numBombs
	fmov	d0,	bombs_r
	bl	printf	
stopGame:
	restore_r()
	ldp	x29,	x30,	[sp],	dealloc
	ret

// open subroutine to store the starting and ending x/y coordinates
define(storeStartAndEnd_r,
	`add	sp,	sp,	-32
	sub	x9,	xCoord_r,	bombRadius_r
	str	x9,	[x29, -32]
	sub	x9,	yCoord_r,	bombRadius_r
	str	x9,	[x29, -24]
	add	x9,	xCoord_r,	bombRadius_r
	str	x9,	[x29, -16]
	add	x9,	yCoord_r,	bombRadius_r
	str	x9,	[x29, -8]')

/* updates the flag board after a bomb has uncovered a portion of the board and also does corner and out of bound checking
//   parameters: stack pointer - stack pointer to the flag board and 2d array
//               m - the number of rows in the game board
//               n - the number of columns in the game board
//               x coord - the user inputted x-coordinate of the bomb
//               y coord - the user inputted y-coordinate of the bomb
//               bomb radius - the radius of the bomb
//   returns: nothing */
storeOffsets_r()
updateBoard:
	stp	x29,	x30,	[sp, alloc]!
	mov	x29,	sp
	store_r()

	mov	stackPT_r,	x0
	mov	m_r,	x1
	mov	n_r,	x2
	mov	xCoord_r,	x3
	mov	yCoord_r,	x4
	mov	bombRadius_r,	x5
	storeStartAndEnd_r()
checkXStart:
	ldr	x9,	[x29, -32]
	cmp	x9,	0
	b.ge	checkYStart // radius > 0
	mov	x10,	0
	str	x10,	[x29, -32] // if radius < 0, replace with 0
checkYStart:
	ldr	x9,	[x29, -24]
	cmp	x9,	0
	b.ge	checkXEnd // radius > 0
	mov	x10,	0
	str	x10,	[x29, -24] // if radius < 0, replace with 0
checkXEnd:
	ldr	x9,	[x29, -16]
	sub	x10,	m_r,	1 // rows - 1
	cmp	x9,	x10
	b.le	checkYEnd // radius < max-1
	str	x10,	[x29, -16] // if radius > max-1 , replace with max-1
checkYEnd:
	ldr	x9,	[x29, -8]
	sub	x10,	n_r,	1 // cols - 1
	cmp	x9,	x10
	b.le	finishCheck
	str	x10,	[x29, -8] // if radius > max-1, replace with max-1
finishCheck:
	mov	offset_r,	alloc_r
	mul	x3,	m_r,	n_r
	mov	x4,	8
	mul	x3,	x3,	x4 // m x n x 8
	add	offset_r,	offset_r,	x3 // skip over 2d array	
	mov	counter_r,	0
	mov	counter2_r,	0
updateFlags:
	ldr	x9,	[x29, -32]	// x-start
	cmp	counter2_r,	x9	// compare counter2 (i) with x-start
	b.lt	nextFlag		// i < xstartcoord - skip	
	ldr	x9,	[x29, -16] 	// x-end
	cmp	counter2_r,	x9	// compare counter2 (i) with x-end
	b.gt	nextFlag		// i > xend - skip
	ldr	x9,	[x29, -24]	// y-start
	cmp	counter_r,	x9	// compare counter (j) with y-start
	b.lt	nextFlag		// j < ystart - skip
	ldr	x9,	[x29, -8]	// y-end
	cmp	counter_r,	x9	// compare counter (j) with y-end
	b.gt	nextFlag		// j > yend - skip
	ldr	w7,	[stackPT_r, offset_r] // flagboard value
	cmp	w7,	2 // compare with 2 (if 2, already uncovered and calculated)
	b.eq	nextFlag // if flag == 2 skip
	mov	w7,	1
	str	w7,	[stackPT_r, offset_r] // store flag 1 (uncovered and not calculated)
nextFlag:
	add	counter_r,	counter_r,	1
	add	offset_r,	offset_r,	4
	cmp	counter_r,	n_r
	b.lt	updateFlags
	
	mov	counter_r,	0
	add	counter2_r,	counter2_r,	1
	cmp	counter2_r,	m_r
	b.lt	updateFlags

	add	sp,	sp,	32	
	restore_r()
	ldp	x29,	x30,	[sp],	dealloc
	ret

/* loops throughthe flagging board, compares it with the game board and prints out the respective symbol
//   parameters: stack pointer - stack pointer containing flagging board and 2d array
//               m - number of rows in the game board
//               n - number of columns in the game board
//   returns: nothing */
storeOffsets_r()
displayGame:
	stp	x29,	x30,	[sp, alloc]!
	mov	x29,	sp
	store_r()

	mov	stackPT_r,	x0
	mov	m_r,	x1
	mov	n_r,	x2

	mov	offset_r,	alloc_r
	mul	x25,	m_r,	n_r
	mov	x4,	8
	mul	x25,	x25,	x4	//m x n x 8	
	add	x25,	offset_r,	x25 // x25 = flagboard offset
	mov	counter_r,	0
	mov	counter2_r,	0

checkUncovered:
	ldr	w9,	[stackPT_r, x25]
	cmp	w9,	0
	b.ne	printBoard
	ldr	x0,	=xtile
	bl	printf
	b	contDisplay	
printBoard:
	ldr	d8,	[stackPT_r, offset_r]
printStar:
	mov	x7,	20
	scvtf	d16,	x7
	fcmp	d8,	d16 // compare float with 20
	b.ne	printPowerupRange		
	ldr	x0,	=star
	bl	printf
	b	contDisplay
printPowerupRange:
	mov	x7,	21
	scvtf	d16,	x7
	fcmp	d8,	d16 // compare float with 21
	b.ne	printPowerupScore
	ldr	x0,	=powerupR
	bl	printf
	b	contDisplay
printPowerupScore:
	mov	x7,	22
	scvtf	d16,	x7
	fcmp	d8,	d16
	b.ne	printPowerupLives
	ldr	x0,	=powerupSc
	bl	printf
	b	contDisplay
printPowerupLives:
	mov	x7,	23
	scvtf	d16,	x7
	fcmp	d8,	d16
	b.ne	printPlus
	ldr	x0,	=powerupL
	bl	printf
	b	contDisplay
printPlus:
	mov	x7,	0
	scvtf	d16,	x7
	fcmp	d8,	d16 // compare float with 0
	b.lt	printMinus // float < 0 go to minus
	ldr	x0,	=plus
	bl	printf
	b	contDisplay
printMinus:
	ldr	x0,	=minus
	bl	printf
contDisplay:
	add	offset_r,	offset_r,	8
	add	x25,	x25,	4
	add	counter_r,	counter_r,	1
	cmp	counter_r,	n_r
	b.lt	checkUncovered

	ldr	x0,	=newline
	bl	printf
	mov	counter_r,	0
	add	counter2_r,	counter2_r,	1
	cmp	counter2_r,	m_r
	b.lt	checkUncovered

	restore_r()
	ldp	x29,	x30,	[sp],	dealloc
	ret

/* initially populates the flag board with zeroes
//   parameters: stack pointer - stack pointer to the flagging board
//              m - number of rows in the game board
//             n - number of columns in the game board
//  returns: nothing */
storeOffsets_r()
popFlagBoard:
	stp	x29,	x30,	[sp, alloc]!
	mov	x29,	sp
	store_r()

	mov	stackPT_r,	x0
	mov	m_r,	x1
	mov	n_r, 	x2	

	mov	offset_r,	alloc_r
	mul	x9,	m_r,	n_r
	mov	x4,	8
	mul	x4,	x9,	x4 // m x n x 8
	add	offset_r,	offset_r, x4 // start offset at beginning of flag board
	mov	counter_r,	0
flagBoardLoop:
	mov	x4,	0
	str	x4,	[stackPT_r, offset_r]
	add	offset_r,	offset_r,	4
	add	counter_r,	counter_r,	1
	cmp	counter_r,	x9
	b.lt	flagBoardLoop

	restore_r()
	ldp	x29,	x30,	[sp], dealloc
	ret

/* function to read arguments from the command line*/
readArgs:
	stp	x29,	x30,	[sp, -16]!	// store fp and link registers
	mov 	x29,	sp			// update fp

	mov	x28,	x1			// load x28 with x1 (argv)
	ldr	x0,	[x28, 8]		// player name is first arg - offset is 8
	mov	username_r,	x0		// set username as x0
	ldr	x0,	[x28, 16]		// board size M is 2nd arg - offset is 16
	bl	atoi				// convert to int
	mov	m_r,	x0			// set m as x0
	ldr	x0,	[x28, 24]		// board size N is 3rd arg - offset is 24
	bl	atoi				// convert to int
	mov	n_r,	x0			// set n as x0

	ldp	x29,	x30,	[sp],	16	// retore fp and link registers
	ret					// end main

// display an error message
errorMsg:
	ldr	x0,	=error			// load x0 with error
	bl	printf				// print error message
	b	exit				// go to exit

	.data
buffer: .string " "
scan: .dword 0
