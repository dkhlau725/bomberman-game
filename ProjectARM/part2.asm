// Fall 2020 CPSC 355
// Project Part 2 by Desmond Lau
	.text
postGamePrompt: .string "Press 1 to view leaderboard and 2 to quit.\n"
format: .string "%d"
scorefile: .string "leaderboard.log"
space: .string " "
newline: .string "\n"
linebreak: .string ","
howmany: .string "How many top scores do you want to view?\n"
displayScores: .string "Name: %s Score: %.2f Time: %ds\n"
extraLife: .string "Extra lives found. \n"
extraScore: .string "You found bonus points. \n"
sorting: .string "... sorting scores ...\n... retrieving data ...\n... error: sorting failed. \n"
linetest: .string "there are %d lines \n"
stringtest: .string "string length is %d \n"

define(m_r, x19)
define(n_r, x20)
define(username_r, x21)
define(alloc_r, x22)
define(offset_r, x23)
define(counter_r, x24)
define(bombRadius_r, x25)
define(gameTime_r, x25)
define(lives_r,	x26)
define(fd_r, w27)
define(numOfScores_r, x22)
define(stackPT_r, x28)
define(score_r, d8)
define(roundScore_r, d9)
define(bombs_r, d11)

	// open subroutine to calculate size to store x19-x28 registers before a function
	define(cstoreOffsets_r,
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

	// open subroutine to store the x19-x28 registers
	define(cstore_r,
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

	// open subroutine to restore the x19-x28 registers
	define(crestore_r,
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

	.balign 4
	.global calculateScore
/* calculates the score uncovered by the bomb
//   parameters: stack pointer - stack pointer to the game board, flag board and game data struct
//               alloc - the bottom of the stack
//               m - number of rows in the game board
//               n - number of columns in the game board
//               bomb radius - the radius of the bomb
//               lives - the number of lives the player has
//               score - the total score of the game
//               round score - the score uncovered by the bomb
//   returns: the win condition (true or false) */
cstoreOffsets_r()
calculateScore:
	stp	x29,	x30,	[sp, alloc]!
	mov	x29,	sp
	cstore_r()

	mov	stackPT_r,	x0
	mov	alloc_r,	x1
	mov	m_r,	x2
	mov	n_r,	x3
	mov	bombRadius_r,	x4
	mov	lives_r,	x5
	fmov	score_r,	d0
	fmov	roundScore_r,	d1	

	fsub	roundScore_r,	roundScore_r,	roundScore_r // set roundscore back to 0
	mov	counter_r,	0
	mov	offset_r,	alloc_r
	mul	x9,	m_r,	n_r // size
	mov	x10,	0 // powerup counter
	mov	x7,	8
	mul	x27,	x9,	x7
	add	x27,	offset_r,	x27 // flagboard offset (skip over 2d)
	mov	x4,	4
	mul	x3,	x9,	x4	// x9 (m x n) x 4
	add	x21,	x27,	x3	// gamedata struct offset (skip over 2d and flag)		
calculateLoop:
	ldr	w7,	[stackPT_r, x27]
	cmp	w7,	1
	b.ne	gotoNext
	mov	w7,	2
	str	w7,	[stackPT_r, x27] // change flag to 2 so won't calc again
	ldr	d12,	[stackPT_r, offset_r] // retrieve number
calcExit:
	mov	x7,	20
	scvtf	d16,	x7
	fcmp	d12,	d16
	b.ne	calcPowerupRange
	fmov	d15,	1.0 // set as 1 - win condition = true
	b	gotoNext
calcPowerupRange:
//	mov	x7,	21
//	scvtf	d16,	x7
	fmov	d16,	21.00
	fcmp	d12,	d16
	b.ne	calcPowerupScore
	mov	x7,	2
	mul	bombRadius_r,	bombRadius_r,	x7
	b	gotoNext
calcPowerupScore:
//	mov	x7,	22
//	scvtf	d16,	x7
	fmov	d16,	22.00
	fcmp	d12,	d16
	b.ne	calcPowerupLives
	mov	x7,	50
	scvtf	d16,	x7
	fadd	score_r,	score_r,	d16 // +50 score :)
	fadd	roundScore_r,	roundScore_r,	d16
	ldr	x0,	=extraScore
	bl	printf
	b	gotoNext
calcPowerupLives:
//	mov	x7,	23
//	scvtf	d16,	x7
	fmov	d16,	23.00
	fcmp	d12,	d16
	b.ne	calcNum
	add	lives_r,	lives_r,	1 // +1 life :)
	ldr	x0,	=extraLife
	bl	printf
	b	gotoNext
calcNum:
	fadd	score_r,	score_r,	d12
	fadd	roundScore_r,	roundScore_r,	d12	
gotoNext:
	add	counter_r,	counter_r,	1
	add	offset_r,	offset_r,	8
	add	x27,	x27,	4
	mul	x9,	m_r,	n_r
	cmp	counter_r,	x9
	b.lt	calculateLoop

calcLives:
	mov	x7,	0
	scvtf	d16,	x7
	fcmp	d16,	score_r // compare score w 0
	b.lt	exitCalc	// 0 < score, good and exit
	sub	lives_r,	lives_r,	1	// lives -1
	cmp	lives_r,	1
	b.lt	exitCalc // lives < 1 exit 
	cmp	x10,	1 // win condition compared w 1
	b.eq	exitCalc // if wincondition = 1 (won) exit
	fsub	score_r,	score_r,	score_r // reset score to 0

exitCalc:
	str	lives_r,	[stackPT_r, x21]
	add	x21,	x21,	8
	str	bombRadius_r,	[stackPT_r, x21]
	add	x21,	x21,	8
	str	score_r,	[stackPT_r, x21]
	add	x21,	x21,	8
	str	roundScore_r,	[stackPT_r, x21]

	fmov	d0,	d15 // get return value
	crestore_r()
	ldp	x29,	x30,	[sp],	dealloc
	ret

	.global exitGame
/* exits the game but logs player score before exiting
//  paramters: stack pointer - stack pointer to game data struct
//              alloc - bottom of the stack
//              username - the player's name
//              game time - the player's game time
//   returns: nothing */
cstoreOffsets_r()
exitGame:
	stp	x29,	x30,	[sp, alloc]!
	mov	x29,	sp
	cstore_r()

	mov	stackPT_r,	x0
	mov	alloc_r,	x1
	mov	username_r,	x2
	mov	gameTime_r,	x3

	mov	x0,	username_r
	mov	x1,	stackPT_r
	mov	x2,	alloc_r
	mov	x3,	gameTime_r
	bl	logScore

	ldr	x0,	=postGamePrompt
	bl	printf
	ldr	x0,	=format
	ldr	x1,	=scan
	bl	scanf
	ldr	x1,	=scan
	ldr	x9,	[x1]

	cmp	x9,	1
	b.eq	postGameScores
	b	exitExit
postGameScores:
	ldr	x0,	=howmany
	bl	printf
	ldr	x0,	=format
	ldr	x1,	=scan
	bl	scanf
	ldr	x1,	=scan
	ldr	x9,	[x1]	
	mov	x0,	x9
	bl	displayTopScores
exitExit:
	crestore_r()
	ldp	x29,	x30,	[sp],	dealloc
	ret

define(writeToFile_r,
	`mov	w0,	$1
	ldr	x1,	=$2
	mov	x2,	$3
	mov	x8,	64
	svc	0')

define(convertString_r,
	`scvtf	d0,	$1
	mov	x0,	$2
	ldr	x1,	=$3
	bl	gcvt')

/* logs the player's stats from their game into a log file
//   parameters: username - the player's name
//               stack pointer - the stack pointer to the game data struct
//               alloc - bottom of the stack
//               game time - the player's game time 
//   returns: nothing */
cstoreOffsets_r()
logScore:
	stp	x29,	x30,	[sp, alloc]!
	mov	x29,	sp
	cstore_r()

	mov	username_r,	x0
	mov	stackPT_r,	x1
	mov	alloc_r,	x2
	mov	gameTime_r,	x3

	mov	w0,	-100	// open file
	ldr	x1,	=scorefile
	mov	w2,	02001 // append/write
	mov	w3,	0700
	mov	x8,	56
	svc	0
	mov	fd_r,	w0
	cmp	fd_r,	0
	b.lt	createNewFile // if doesnt exit create and write 
	b	logLeaderboard
createNewFile:
	mov	w0,	-100
	ldr	x1,	=scorefile
	mov	w2,	0101 //create/write
	mov	w3,	0700
	mov	x8,	56
	svc	0
	mov	fd_r,	w0
logLeaderboard:
	ldr	d9,	[stackPT_r, -16] // get score
	fmov	d0,	d9
	mov	x0,	15
	ldr	x1,	=buffer
	bl	gcvt
	writeToFile_r(fd_r, buffer, 6) // write 6 byte score (max is 999.99) 
	writeToFile_r(fd_r, space, 1)
	convertString_r(gameTime_r, 3, buffer)
	writeToFile_r(fd_r, buffer, 3) // write 3 byte score (max is 999s)
	writeToFile_r(fd_r, space, 1)

	mov	x0,	username_r
	bl	strlen // get length of string
	mov	x19,	x0
	convertString_r(x19, 1, buffer) // convert length to string
	writeToFile_r(fd_r, buffer, 1) // store length (convenience to know how many bytes to read in the string)
	mov	w0,	fd_r
	mov	x1,	username_r
	mov	x2,	x19 
	mov	x8,	64
	svc	0 // write username
	writeToFile_r(fd_r, linebreak, 1) // later will use commas to count number of scores in the log file
	writeToFile_r(fd_r, newline, 1)

	mov	w0,	fd_r
	mov	x8,	57
	svc	0

	crestore_r()
	ldp	x29,	x30,	[sp],	dealloc
	ret

	.global displayTopScores
/* displays a select number of high scores to the user 
//   parameters: num of scores - number of scores the user wants to see
//   returns: nothing */
cstoreOffsets_r()
displayTopScores:
	stp	x29,	x30,	[sp, alloc]!
	mov	x29,	sp
	cstore_r()

	mov	numOfScores_r,	x0

	mov	w0,	-100
	ldr	x1,	=scorefile
	mov	w2,	wzr	// open file read only
	mov	x8,	56
	svc	0
	mov	fd_r,	w0
	cmp	fd_r,	0
	b.lt	stopDisplay

	mov	counter_r,	0
	mov	x28,	0
	mov	x26,		500
countLinesLoop:
	mov	w0,	fd_r
	ldr	x1,	=buffer
	mov	x2,	1 // read 1 byte
	mov	x8,	63
	svc	0
	ldr	x9,	=buffer
	ldrb	w10,	[x9, 0]
	cmp	w10,	',' // compare byte with line break
	b.ne	skipThis
	add	x28,	x28,	1
skipThis:
	add	counter_r,	counter_r,	1
	cmp	counter_r,	x26
	b.lt	countLinesLoop
	mov	w0,	fd_r
	mov	x8,	57
	svc	0
	
exitCountLines:
//	ldr	x0,	=linetest
//	mov	x1,	x28
//	bl	printf

	mov	x7,	32 // 8 for score, 8 for time, 8 for length, 8 for string
	mul	x20,	x7,	x28 // 32 x number of lines for structs
	sub	x20,	xzr,	x20
	and	x20,	x20,	-16
	add	sp,	sp,	x20	
	mov	offset_r,	x20	

	mov	w0,	-100
	ldr	x1,	=scorefile
	mov	w2,	wzr
	mov	x8,	56
	svc	0
	mov	fd_r,	w0

	mov	counter_r,	0
getData:
	mov	x19,	0
	mov	w0,	fd_r // get score
	ldr	x1,	=buffer
	mov	x2,	6
	mov	x8,	63
	svc	0
	ldr	x0,	=buffer
	bl	atof
	str	d0,	[x29, offset_r]
	add	offset_r,	offset_r,	8
	
	mov	w0,	fd_r // get space
	ldr	x1,	=buffer
	mov	x2,	1
	mov	x8,	63
	svc	0
	
	mov	w0,	fd_r // get time
	ldr	x1,	=buffer
	mov	x2,	3
	mov	x8,	63
	svc	0
	ldr	x0,	=buffer
	bl	atoi
	str	x0,	[x29, offset_r]
	add	offset_r,	 offset_r,	8

	mov	w0,	fd_r // get space
	ldr	x1,	=buffer
	mov	x2,	1
	mov	x8,	63
	svc	0

	mov	w0,	fd_r // get size of string
	ldr	x1,	=buffer
	mov	x2,	1
	mov	x8,	63
	svc	0
	ldr	x0,	=buffer
	bl	atoi
	mov	x19,	x0

//	ldr	x0,	=stringtest
//	mov	x1,	x19
//	bl	printf

	mov	w0,	fd_r // get username
	ldr	x1,	=buffer
	mov	x2,	x19
	mov	x8,	63
	svc	0
	ldr	x9,	=buffer
	str	x9,	[x29, offset_r]	
//	add	offset_r,	offset_r,	8

	mov	offset_r,	x20
	ldr	score_r,	[x29, offset_r]
	add	offset_r,	offset_r,	8
	ldr	gameTime_r,	[x29, offset_r]
	add	offset_r,	offset_r,	8
	ldr	username_r,	[x29, offset_r]

	bl	sortScores
	mov	counter_r,	0
printDataLoop:
	ldr	x0,	=displayScores
	mov	x1,	username_r
	fmov	d0,	score_r
	mov	x2,	gameTime_r
	bl	printf
	add	counter_r,	counter_r,	1
	cmp	counter_r,	numOfScores_r
	b.lt	printDataLoop

stopDisplay:
	sub	x20,	xzr,	x20
	add	sp,	sp,	x20
	crestore_r()
	ldp	x29,	x30,	[sp],	dealloc
	ret

// function: sortScores //
cstoreOffsets_r()
sortScores:
	stp	x29,	x30,	[sp, alloc]!
	mov	x29,	sp
	cstore_r()

	ldr	x0,	=sorting
	bl	printf	

	crestore_r()
	ldp	x29,	x30,	[sp],	dealloc
	ret
	
	.data
scan: .dword 0
buffer: .string " "
junk: .string " "
