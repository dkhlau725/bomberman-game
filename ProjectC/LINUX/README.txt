--README--

-CPSC 355 Fall 2020-
-Prof. Jalal Kawash-
-Project Part 1 by Desmond Lau-

OVERVIEW: This C game is a modified console version of bomberman. The game consists of a board of hidden rewards (such as bomb range multipliers, 
          extra bombs and extra scores) and scores (both positive and negative floats). The user starts with a 3 lives and certain amount of bombs,
          and types in the coordinates to place a bomb to blow up a portion of the board to uncover the rewards. 
          If the total uncovered score is less than zero, the player loses a life. 
          The game ends in 3 ways: 
          1) If the player uncovers the exit tile, in which they win the game 
          2) If the player runs out of lives, in which they lose the game
          3) If the player runs out of bombs, in which they lose the game

How to launch the game (Linux OS):
1) Open command prompt and enter the folder bomberman.c is located
2) Compile the program (gcc bomberman.c -o bomberman)
3) Launch the game by typing "./bomberman username m n" (where username is your desired username to display on the leaderboard, m is the number of 
   rows and n is the number of columns)
   ex. "./bomberman bob 15 15" generates a 15x15 game board for the player "bob"
   (Try keeping the user name 15 characters or less to ensure the leaderboard displays correctly)

***NOTE: Launching the game in Windows will not work as the game uses Linux coded colors***

GAME LEGEND:
'+' indicates a positive score
'-' indicates a negative score
'$' indicates a bomb range doubler (they can stack)
'!' indicates an extra bomb reward (they can stack) - if you uncover only 1, you regain the bomb you just used
'?' indicates an extra life reward (they can stack) - if you die and uncover 1, you regain the life you lost             

