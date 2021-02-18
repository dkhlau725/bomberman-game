--README--

-CPSC 355 Fall 2020-
-Prof. Jalal Kawash-
-Project Part 2 by Desmond Lau-

OVERVIEW: This ARM game is a modified console version of bomberman. The game consists of a board of hidden rewards (such as bomb range multipliers, 
          extra scores and extra lives) and scores (both positive and negative floats). The user starts with a 3 lives and certain amount of bombs,
          and types in the coordinates to place a bomb to blow up a portion of the board to uncover the rewards. 
          If the total uncovered score is less than zero, the player loses a life. 
          The game ends in 3 ways: 
          1) If the player uncovers the exit tile, in which they win the game 
          2) If the player runs out of lives, in which they lose the game
          3) If the player runs out of bombs, in which they lose the game

How to launch the game (Linux OS):
1) Open command prompt and enter the folder containing the 2 .asm files
2) Compile the program (using the makefile)
3) Launch the game by typing "./proj username m n" (where username is your desired username to display on the leaderboard, m is the number of 
   rows and n is the number of columns)
   ex. "./proj bob 15 15" generates a 15x15 game board for the player "bob"

GAME LEGEND:
'+' indicates a positive score
'-' indicates a negative score
'$' indicates a bomb range doubler (they can stack)
'&' indicates a +50 score reward (they can stack)
'^' indicates an extra life reward (they can stack) - if you die and uncover 1, you regain the life you lost             
