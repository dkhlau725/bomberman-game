#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <string.h>
#include <stdbool.h>
#include <ctype.h>

// define preset colors to use in the game (Linux only) - Note the colors were removed to make the .script file easier to read
#define RED "\x1B[31m"
#define GRN "\x1B[32m"
#define YEL "\x1B[33m"
#define BLU "\x1B[34m"
#define MAG "\x1B[35m"
#define CYN "\x1B[36m"
#define WHT "\x1B[37m"
#define RESET "\x1B[0m"

// https://stackoverflow.com/questions/13408990/how-to-generate-random-float-number-in-c
/* randomNum generates a random float within a range
   parameters: min - the minimum value of the randomly generated float
               max - the maximum value of the randomly generated float
               neg - a boolean to check whether to generate a positive or negative float
   returns: the randomly generated float */
float randomNum(int min, int max, bool neg) {
    float random = 0.0;
    while (random == 0.0 || random < min || random > max) { // make sure it generates non-zero values
            random = ((float)rand()) / ((float)(RAND_MAX / max)); 
    }
    if (neg == true) { // changes value to negative if neg is true
        random *= -1;
    }
    return random;
}

/* initialize the game by populating the game board with positive or negative integers, powerups and exit tiles. It also prints out the uncovered board
   parameters: *board - the 2D array where the values of the game board are stored
               boardX - the number of rows in the game board
               boardY - the number of columns in the game board
               boardSize - the area of the board calculated by boardX * boardY
   returns: nothing */
void initializeGame(float *board, int boardX, int boardY, int boardSize) {
    int i, j;
    int negOrPos = 0;
    int negCounter = 0; 
    int numOfNeg = 0.4 * boardSize; // only 40% max of board should be negative values
    int powerupCounter = 0;
    int numOfPowerups = 0.2 * boardSize; // only max 20% of board can be bomb range doublers
    bool neg = false;
    bool exitTile = false;
    srand(time(0)); // seeding to ensure the board is different every game
    
    for (i = 0; i < boardX; i++) {
        for (j = 0; j < boardY; j++) {
            negOrPos = rand() & 0xF; // rand() % 16

            if (negOrPos == 0 && exitTile == false) {  // spawn the exit tile if 0
                exitTile = true;
                *(board + i * boardY + j) = 100.00;
                printf(MAG "%-10s" RESET, "  *");
            }
            else if (negOrPos >= 1 && negOrPos <= 6 && negCounter < numOfNeg) {  // spawn a negative number if between 1-6
                negCounter++;
                neg = true;
                *(board + i * boardY + j) = randomNum(0, 15, neg);
                printf(RED "%-10.2f" RESET, *(board + i * boardY + j));
            }
            else if (negOrPos >= 7 && negOrPos <= 9 && powerupCounter < numOfPowerups) {  // spawn powerups if 7, 8 or 9
                powerupCounter++;
                if (negOrPos == 7) {
                    *(board + i * boardY + j) = 200.00; // bomb range doubler
                    printf(YEL "%-10s" RESET, "  $");
                }
                else if (negOrPos == 8) {
                    *(board + i * boardY + j) = 300.00; // extra bomb
                    printf(YEL "%-10s" RESET, "  !");
                }
                else {
                    *(board + i * boardY + j) = 400.00; // extra life
                    printf(YEL "%-10s" RESET, "  ?");
                }
            }
            else {  // spawn an positive number if between 10-16
                neg = false;
                *(board + i * boardY + j) = randomNum(0, 15, neg);
                printf(GRN "%-10.2f" RESET, *(board + i * boardY + j));
            }
        }   
        printf("\n");
    }
    printf("Total amount of negative numbers: %d/%d (%.2f%% of the board, <= 40%%)\n", negCounter, boardSize, ((float)negCounter/(float)boardSize)*100);
}

/* loops through the flagging board, compares it with the game board and prints out the respective symbol
   parameters: *board - the 2D array where the values of the game board are stored
               *flagBoard - a 2D array consisting of flags to mark whether a portion of the game board is uncovered or not 
               boardX - the number of rows in the game board
               boardY - the number of columns in the game board
               xCoord - the user inputted x-coordinate of the bomb
               yCoord - the user inputted y-coordinate of the bomb
   returns: nothing */
void displayGame(float *board, int *flagBoard, int boardX, int boardY, int xCoord, int yCoord) {
    int i ,j;
    int bob;

    for (i = 0; i < boardX; i++) {
        for (j = 0; j < boardY; j++) {
            if (*(flagBoard + i * boardY + j) == 0) { // if the flagging board is 0 (uncovered)
                printf(CYN "%s" RESET, "X ");
            }
            else { // if the flagging board is 1 (uncovered and not included in score) or 2 (uncovered and included in score)
                if (*(board + i * boardY + j) == 100.00) {  // if tile is the exit tile
                    printf(MAG "%s" RESET, "* ");
                }
                else if (*(board + i * boardY + j) == 200.00) { // if tile is a bomb range doubler
                    printf(YEL "%s" RESET, "$ ");
                }
                else if (*(board + i * boardY + j) == 300.00) { // if tile is an extra bomb
                    printf(YEL "%s" RESET, "! ");
                }
                else if (*(board + i * boardY + j) == 400.00) { // if tile is an extra lfe
                    printf(YEL "%s" RESET, "? ");
                }
                else if (*(board + i * boardY + j) > 0) { // if tile is a positive float
                    printf(GRN "%s" RESET, "+ ");
                }               
                else { // if tile is a negative float
                    printf(RED "%s" RESET, "- ");
                }
            }
        }
        printf("\n");
    }
}

/* initially populuates the flagging board with zeroes
   parameters: *flagBoard - a 2D array consisting of flags to mark whether a portion of the game board is uncovered or not 
               boardX - the number of rows in the game board
               boardY - the number of columns in the game board
   returns: nothing */
void populateFlagBoard(int *flagBoard, int boardX, int boardY) {  // 0 means covered, 1 means uncovered
    int i, j;  
    
    for (i = 0; i < boardX; i++) {
        for (j = 0; j < boardY; j++) {
            *(flagBoard + i * boardY + j) = 0;
        }
    }
}

/* checks if the bomb radius surpasses the left side of the game board
   parameters: boardY - the number of columns in the game board
               yCoord - the user inputted y-coordinate of the bomb
               bombRadius - the radius of the bomb
   returns: 0 if false, 1 if true */
int leftBorder(int boardY, int yCoord, int bombRadius) {
    if (yCoord - bombRadius <= 0) {
        return 1;
    }
    return 0;
}

/* checks if the bomb radius surpasses the right side of the game board
   parameters: boardY - the number of columns in the game board
               yCoord - the user inputted y-coordinate of the bomb
               bombRadius - the radius of the bomb
   returns: 0 if false, 1 if true */
int rightBorder(int boardY, int yCoord, int bombRadius) {
    if (yCoord + bombRadius >= boardY-1) {
        return 1;
    }
    return 0;
}

/* checks if the bomb radius surpasses the top side of the game board
   parameters: boardX - the number of rows in the game board
               xCoord - the user inputted x-coordinate of the bomb
               bombRadius - the radius of the bomb
   returns: 0 if false, 1 if true */
int topBorder(int boardX, int xCoord, int bombRadius) {
    if (xCoord - bombRadius <= 0) {
        return 1;
    }
    return 0;
}

/* checks if the bomb radius surpasses the bottom side of the game board
   parameters: boardX - the number of rows in the game board
               xCoord - the user inputted x-coordinate of the bomb
               bombRadius - the radius of the bomb
   returns: 0 if false, 1 if true */
int bottomBorder(int boardX, int xCoord, int bombRadius) {
    if (xCoord + bombRadius >= boardX-1) {
        return 1;
    }
    return 0;
}

/* updates the flagging board after a bomb has uncovered a portion of the board and also does various corner and out of bounds checking
   parameters: *flagBoard - a 2D array consisting of flags to mark whether a portion of the game board is uncovered or not   
               boardX - the number of rows in the game board
               boardY - the number of columns in the game board
               xCoord - the user inputted x-coordinate of the bomb
               yCoord - the user inputted y-coordinate of the bomb
               bombRadius - the radius of the bomb
   returns: nothing */
void updateBoard(int *flagBoard, int boardX, int boardY, int xCoord, int yCoord, int bombRadius) {
    int i, j;
    int xStartCoord = 0; // the x-coordinate of where the board starts uncovering
    int yStartCoord = 0; // the y-coordinate of where the board starts uncovering
    int xEndCoord = 0; // the x-coordinate of where the board stops uncovering
    int yEndCoord = 0; // the y-coordinate of where the board stops uncovering
    int leftSide = leftBorder(boardY, yCoord, bombRadius); 
    int rightSide = rightBorder(boardY, yCoord, bombRadius);
    int topSide = topBorder(boardX, xCoord, bombRadius);
    int bottomSide = bottomBorder(boardX, xCoord, bombRadius);

    if (leftSide == 1 && topSide == 1) { // if bomb radius touches both left and top borders 
        xStartCoord = 0;
        yStartCoord = 0;
        xEndCoord = xCoord + bombRadius;
        yEndCoord = yCoord + bombRadius;
    }
    else if (rightSide == 1 && topSide == 1) { // if bomb radius touches both right and top borders 
        xStartCoord = 0;
        yStartCoord = yCoord - bombRadius;
        xEndCoord = xCoord + bombRadius;
        yEndCoord = boardY - 1;
    }
    else if (leftSide == 1 && bottomSide == 1) { // if bomb radius touches both left and bottom borders 
        xStartCoord = xCoord - bombRadius;
        yStartCoord = 0;
        xEndCoord = boardX - 1;
        yEndCoord = yCoord + bombRadius;
    }
    else if (rightSide == 1 && bottomSide == 1) { // if bomb radius touches both right and bottom borders 
        xStartCoord = xCoord - bombRadius;
        yStartCoord = yCoord - bombRadius;
        xEndCoord = boardX - 1;
        yEndCoord = boardY - 1;
    }
    else if (leftSide == 1) { // if bomb radius touches only left border
        xStartCoord = xCoord - bombRadius;
        yStartCoord = 0;
        xEndCoord = xCoord + bombRadius;
        yEndCoord = yCoord + bombRadius;
    }
    else if (topSide == 1) { // if bomb radius touches only top border
        xStartCoord = 0;
        yStartCoord = yCoord - bombRadius;
        xEndCoord = xCoord + bombRadius;
        yEndCoord = yCoord + bombRadius;
    }
    else if (rightSide == 1) { // if bomb radius touches only right border
        xStartCoord = xCoord - bombRadius;
        yStartCoord = yCoord - bombRadius;
        xEndCoord = xCoord + bombRadius;
        yEndCoord = boardY - 1;
    }
    else if (bottomSide == 1) { // if bomb radius touches only bottom border
        xStartCoord = xCoord - bombRadius;
        yStartCoord = yCoord - bombRadius;
        xEndCoord = boardX - 1;
        yEndCoord = yCoord + bombRadius;
    }
    else { // if bomb radius touches no borders
        xStartCoord = xCoord - bombRadius;
        yStartCoord = yCoord - bombRadius;
        xEndCoord = xCoord + bombRadius;
        yEndCoord = yCoord + bombRadius;
    }

    // sets the flags of the values between the start point and the end point to 1 (uncovered)
    for (int i = 0; i < boardX; i++) {
        for (int j = 0; j < boardY; j++) {
            if (i >= xStartCoord && i <= xEndCoord && j >= yStartCoord && j <= yEndCoord && *(flagBoard + i * boardY + j) != 2) {
                *(flagBoard + i * boardY + j) = 1;
            }
        }
    }
}

/* calculates the score uncovered by the bomb
   parameters: *flagBoard - a 2D array consisting of flags to mark whether a portion of the game board is uncovered or not   
               *board - the 2D array where the values of the game board are stored
               boardX - the number of rows in the game board
               boardY - the number of columns in the game board
               *score - the total score of the game
               *roundScore - the score uncovered by the bomb
               *lives - the number of lives the player has
               *bombRadius - the radius of the bomb
               *winGame - if the game has been won  
   returns: the update score */
int calculateScore(int *flagBoard, float *board, int boardX, int boardY, float *score, float *roundScore, int *lives, int *bombs, int *bombRadius, bool *winGame) {
    int i, j;
    *roundScore = 0;
    int doublerCounter = 0;

    for (i = 0; i < boardX; i++) {
        for (j = 0; j < boardY; j++) {
            if (*(flagBoard + i * boardY + j) == 1) { // if tile was uncovered
                *(flagBoard + i * boardY + j) = 2; // sets it to 2 so then the next calculation won't include it again
                if (*(board + i * boardY + j) == 100.00) { // if uncovered tile was the exit tile
                    *winGame = true;
                }
                else if (*(board + i * boardY + j) == 200.00) { // if uncovered tile was a bomb range doubler
                    doublerCounter++;
                }
                else if (*(board + i * boardY + j) == 300.00) { // if uncovered tile was an extra bomb
                    (*bombs)++;
                }
                else if (*(board + i * boardY + j) == 400.00) { // if uncovered tile was an extra life
                    (*lives)++;
                }
                else { // if tile is a float
                    *score += *(board + i * boardY + j);
                    *roundScore += *(board + i * boardY + j);
                }               
            }
        }
    }
    for (int k = 0; k < doublerCounter; k++) { // the bomb radius multiplier if multiple powerups uncovered
        *bombRadius *= 2; 
    }

    if (*score < 0) { // if score drops below zero, a life is lost
        (*lives)--;
        if (*lives >= 1 && *winGame == false) {
            *score = 0;
        }
        printf(RED "%s" RESET, "\nYOU DIED!\n");
    }
}

// https://www.programmingsimplified.com/c/source-code/c-program-bubble-sort 
/* the bubble sort algorithm is used to sort the top scores in descending order
   parameters: *playerNames - the 2D array consisting of the player names
               *playerScores - the array consisting of the player scores
               *playerTimes - the array consisting of the player game times
               size - the size of the arrays
   returns: nothing */
void sortScores(char *playerNames, float *playerScores, float *playerTimes, int size) { 
    int i, j, h;
    float k, l;
    char names[300];

    for (i = 0; i < size - 1; i++) {
        for (j = 0; j < size - i - 1; j++) {
            if (playerScores[j] < playerScores[j+1]) {
                k = playerScores[j]; // swaps the scores
                playerScores[j] = playerScores[j+1];
                playerScores[j+1] = k;

                l = playerTimes[j]; // swaps the player times
                playerTimes[j] = playerTimes[j+1];
                playerTimes[j+1] = l;

                for (h = 0; h < 300; h++) { // swaps the names
                    names[h] = *(playerNames + j * 300 + h);
                    *(playerNames + j * 300 + h) = *(playerNames + (j+1) * 300 + h);
                    *(playerNames + (j+1) * 300 + h) = names[h];
                }
            }
        }
        
    }
}

/* displays a select number of high scores to the user
   parameters: numberOfScores - the number of scores the user wants to see (user-inputted)
   returns: nothing */
void displayTopScores(int numberOfScores) {
    int i, j;
    int lines = 0;
    FILE *filePointer;
    char singleLine[300]; 
    filePointer = fopen("leaderboard.log", "r"); // opens the leaderboard

    if (filePointer == NULL) {
        printf(RED "ERROR! No scores in the leaderboard yet!\n" RESET);
        exit(1);
    }
    while(!feof(filePointer)){ // fgets reads line by line and counts number of rows
        fgets(singleLine, 300, filePointer);
        lines++;
    }
    fclose(filePointer);

    if (numberOfScores > lines-1) { // if user want to retrieve more top scores than there actually is, retrieve all top scores
        numberOfScores = lines-1;
    }

    filePointer = fopen("leaderboard.log", "r"); // re-opens leaderboard since it was read through to find number of scores
    char player[300];
    float score;
    float gameTime;
    char playerNames[lines-1][300]; 
    float playerScores[lines-1];
    float playerTimes[lines-1];

    for (i = 0; i < lines-1; i++) { // reads the leaderboard and append values to their proper array
        fscanf(filePointer, "%s", player);
        for (j = 0; j < 300; j++) {           
            playerNames[i][j] = player[j];
        }
        fscanf(filePointer, "%f", &score);
        playerScores[i] = score;
        fscanf(filePointer, "%f", &gameTime);
        playerTimes[i] = gameTime;
    }

    sortScores(*playerNames, playerScores, playerTimes, lines-1);

    //prints the leaderboard
    printf(YEL "------------------------------LEADERBOARD--------------------------------\n" RESET);
    printf(" %s\t%-10s\t\t\t%s\t\t\t%s\n", "POS", "NAME", "SCORE", "TIME(s)");
    for (i = 0; i < numberOfScores; i++) {
        printf(" #%d\t%-10s\t\t\t%.2f\t\t\t%.1f\n", i+1, playerNames[i], playerScores[i], playerTimes[i]);
    }
    printf(YEL "-------------------------------------------------------------------------\n" RESET);
    fclose(filePointer);
}

/* logs the player's stats from their game into a log file
   parameters: **playerName - the player's name
               gameTime - the player's game time
               score - the player's score
   returns: nothing */
void logScore(char ** playerName, float gameTime, float score) {
    FILE *leaderBoard;
    leaderBoard = fopen("leaderboard.log", "a");
    fprintf(leaderBoard, "%-10s %-10.2f %-10.1f \n", *playerName, score, gameTime); // writes to the log file
    fclose(leaderBoard);
}

/* exits the game, but logs the player score before exiting
   parameters: **playerName - the player's name
               gameTime - the player's game time
               score - the player's score
   returns: nothing */
void exitGame(char ** playerName, float gameTime, float score) {
    char option;
    int numOfScores;

    printf("Thanks for playing %s! Press 'l' to display top scores or 'q' to quit.\n", *playerName, gameTime);
    logScore(playerName, gameTime, score);
    scanf(" %c", &option);
    if (option == 'l') {
        printf("How many top scores do you want to view?\n");
        scanf("%d", &numOfScores);
        displayTopScores(numOfScores);
    }
    else {
        printf("Exiting game...\n");
    }
    exit(1);   
}

/* function that runs the game and calls the above functions in order to do so. It also measures the run time of the game
   parameters: *board - the 2D array where the values of the game board are stored
               boardX - the number of rows in the game board
               boardY - the number of columns in the game board
               boardSize - the area of the board calculated by boardX * boardY
               *playerName - the player's name
   returns: nothing */
void playGame(float *board, int boardX, int boardY, int boardSize, char * playerName) {
    bool gameOver = false;
    bool winGame = false;
    bool wrongInput = false;
    float score = 0;
    float roundScore = 0;
    float gameTime = 0;
    int bombRadius = 1;
    int lives = 3;
    int bombs = 0.5 * boardX; // amount of bombs is 50% of boardX
    int xCoord = -1;
    int yCoord = -1;  
    int flagBoard[boardX][boardY];
    char *p;
    time_t start, end;

    populateFlagBoard(*flagBoard, boardX, boardY);
    displayGame(board, *flagBoard, boardX, boardY, xCoord, yCoord);
    time(&start); // marks the time when the game starts

    do {
        int oldNumBombs = bombs;
        int oldNumLives = lives;
        if (wrongInput == false) { // if the user enters wrong input, skip printing these lines
            printf("Lives: %d\n", lives);
            printf("Score: %.2f\n", score);
            printf("Bombs: %d\n", bombs);
        }
        wrongInput = false;

        if (bombs == 0) { // if there are no more bombs, game over
            gameOver = true;
            time(&end); // marks the time when the game stops
            gameTime = difftime(end, start); // calculate the difference between the start and end times (in seconds)
            printf(RED "%s" RESET, "GAME OVER - OUT OF BOMBS!\n");
            exitGame(&playerName, gameTime, score);
        }

	printf("You can exit the game at any time by typing in coordinates (-1,-1).\n");
        printf("Enter bomb coordinates (x, y):\n");
        int scannedInput = scanf("%d %d", &xCoord, &yCoord);

        if (scannedInput != 2) {// checks if a string is entered instead
            printf(RED "Invalid input! Exiting Program.\n" RESET);
            exit(1);
        }
        if (xCoord == -1 && yCoord == -1) {
            gameOver = true;
            time(&end); // marks the time when the game stops
            gameTime = difftime(end, start); // calculate the difference between the start and end times (in seconds)
            exitGame(&playerName, gameTime, score);
        }

        else if (xCoord > boardX-1 || yCoord > boardY-1 || xCoord < 0 || yCoord < 0) { // if input out of bounds, re-prompt user
            wrongInput = true;
            printf(RED "Input is out of bounds! Try again.\n" RESET);
            continue;
        }

        updateBoard(*flagBoard, boardX, boardY, xCoord, yCoord, bombRadius);
        bombRadius = 1; // reset bomb radius to 1 so it applies only to 1 bomb
        calculateScore(*flagBoard, board, boardX, boardY, &score, &roundScore, &lives, &bombs, &bombRadius, &winGame);

        if (winGame == true) { // if game is won 
            gameOver = true;
            time(&end); // marks the time when the game stops
            gameTime = difftime(end, start); // calculate the difference between the start and end times (in seconds)

            printf(GRN "%s" RESET, "\nYOU WON!\n");  
            displayGame(board, *flagBoard, boardX, boardY, xCoord, yCoord);
            printf(GRN "%s" RESET, "Post Game Stats: \n");
            printf("Lives Remaining: %d\n", lives);
            printf("Final Score: %.2f\n", score);
            printf("Bombs Remaining: %d\n", bombs-1);        
            exitGame(&playerName, gameTime, score);
        }
        if (bombRadius > 1) { // if bomb radius is increased (found "$")
            printf(YEL "\nBomb range increased by %dx for the next bomb\n" RESET, bombRadius);
        }
        if (bombs > oldNumBombs+1) { // if extra bombs found (found "!")
            printf(YEL "\nExtra bomb(s) found!\n" RESET);
        }
        if (lives > oldNumLives) { // if extra lives found (found "?")
            printf(YEL "\nExtra live(s) recovered!\n" RESET);
        }

        printf("\nTotal uncovered score: %.2f\n", roundScore);
        displayGame(board, *flagBoard, boardX, boardY, xCoord, yCoord);

        if (lives == 0) { // if no lives left, end game
            gameOver = true;
            printf(RED "%s" RESET, "GAME OVER!\n");
            printf(RED "%s" RESET, "Post Game Stats: \n");
            printf("Lives Remaining: %d\n", lives);
            printf("Final Score: %.2f\n", score);
            printf("Bombs Remaining: %d\n", bombs-1);        
            exitGame(&playerName, gameTime, score);
            exitGame(&playerName, gameTime, score);
        }
        bombs--; 
    }
    while (gameOver == false);
}

/* main takes in command line arguments and determines game board size and the player name, and calls other functions
   parameters: argc - the number of command line arguments
               *argv[] - an array containing the arguments provided
   returns: 0 */
int main(int argc, char *argv[]) {
    int boardX = 0, boardY = 0;
    int boardSize;
    int numOfScores;
    char *playerName;
    char *p;
    char option;

    if (argc < 4) { // checks for valid number of arguments
        printf(RED "ERROR: Invalid number of arguments. Exiting Program.\n" RESET);
        exit(1);
    }
    playerName = argv[1];
    boardX = (int)(strtol(argv[2], &p, 10)); 
    boardY = (int)(strtol(argv[3], &p, 10)); 

    if (boardX >= 10 && boardY >= 10 && boardY <= 23) { // makes sure the user enters the correct dimensions
        boardSize = boardX * boardY;
        float board[boardX][boardY];
        printf(YEL "LAUNCHING BOMBERMAN...\n" RESET);
        printf(CYN "Welcome, %s! Initializing your game board of size %dx%d...\n" RESET, playerName, boardX, boardY);
        initializeGame(*board, boardX, boardY, boardSize);
        printf(CYN "Ready to go! Press 'p' to play, Press 'l' to display leaderboard and 'q' to quit.\n" RESET);
        scanf(" %c", &option);
        if (option == 'p') {
            playGame(*board, boardX, boardY, boardSize, playerName);
        }
        else if (option == 'l') {
            printf("How many top scores do you want to view?\n");
            scanf("%d", &numOfScores);
            displayTopScores(numOfScores);
            playGame(*board, boardX, boardY, boardSize, playerName);
        }
        else {
            exit(1);
        }  
    }
    else {
        printf(RED "ERROR: Invalid board size. Valid number of rows: 10 or greater. Valid number of columns: 10 to 23. Exiting Program.\n" RESET);
        exit(1);
    }
}
