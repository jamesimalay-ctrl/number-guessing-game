#!/bin/bash

SECRET_NUMBER=$(( RANDOM % 1000 + 1 ))
PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"
echo "Enter your username:"
read -r USERNAME
DB_USERNAME=$(printf "%s" "$USERNAME" | sed "s/'/''/g")
USER_DATA=$($PSQL "SELECT games_played || ' ' || best_game FROM users WHERE username = '$DB_USERNAME'")
if [[ -n "$USER_DATA" ]]; then
  GAMES_PLAYED=$(echo "$USER_DATA" | cut -d ' ' -f 1)
  BEST_GAME=$(echo "$USER_DATA" | cut -d ' ' -f 2)
  echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
else
  echo "Welcome, $USERNAME! It looks like this is your first time here."
fi
echo "Guess the secret number between 1 and 1000:"
read -r USER_GUESS
NUMBER_OF_GUESSES=1
while [[ "$USER_GUESS" != "$SECRET_NUMBER" ]]; do
  if [[ ! "$USER_GUESS" =~ ^[0-9]+$ ]]; then
    echo "That is not an integer, guess again:"
  else
    GUESS_VALUE=$USER_GUESS
    while [[ ${#GUESS_VALUE} -gt 1 && ${GUESS_VALUE:0:1} == 0 ]]; do
      GUESS_VALUE=${GUESS_VALUE:1}
    done
    if [[ ${#GUESS_VALUE} -gt 4 ]] || (( 10#$GUESS_VALUE > SECRET_NUMBER )); then
      echo "It's lower than that, guess again:"
    elif (( 10#$GUESS_VALUE < SECRET_NUMBER )); then
      echo "It's higher than that, guess again:"
    else
      break
    fi
  fi
  read -r USER_GUESS
  NUMBER_OF_GUESSES=$((NUMBER_OF_GUESSES + 1))
done
echo "You guessed it in $NUMBER_OF_GUESSES tries. The secret number was $SECRET_NUMBER. Nice job!"
$PSQL "INSERT INTO users (username, games_played, best_game) VALUES ('$DB_USERNAME', 1, $NUMBER_OF_GUESSES) ON CONFLICT (username) DO UPDATE SET games_played = users.games_played + 1, best_game = LEAST(users.best_game, EXCLUDED.best_game)" >/dev/null
