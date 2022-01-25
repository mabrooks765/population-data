#!/bin/bash

# Quick bash script that does the following:
# 1) curls https://en.wikipedia.org/wiki/List_of_U.S._states_and_territories_by_population using the MediaWiki API
# 2) Writes the output to a file
# 3) Parses the file for several pieces of info: 
#    - gets the 50 state abbreviations mentioned for a specific year (2010 and 2020 only options based on table data)
#    - based on the state abbrevations, grabs the population for that year
#    - NOTE: due to the way territories are handled in the table (they are not referenced by their two-letter abbreviation,
#      the territory list is hard-coded. I didn't see a way around this in a feasible amount of time.
# 4) Check if the script was run with any options
# 4a) If not, take input from user for options: 
#    - help (or no input): print input options for the script 
#    - summary: calculate and output median, mean, and standard deviation for all states and territories
#    - state X, where X is a two-letter input matching a state/territory abbreviation (case-insensitive): outputs that location's population
# Note: there is census data for 2010, as well as 2020. Due to the nature of the assignment, 2020 is hardcoded in several places, but could be swapped to a variable if desired
# to allow for parsing 2010 data

### Variables ###
wiki_url=https://en.wikipedia.org/w/api.php?action=parse\&page=List_of_U.S._states_and_territories_by_population\&contentmodel=wikitext\&prop=wikitext\&section=5\&formatversion=2
wiki_data_file="/tmp/states.txt"

# always start total_population at 0 before we start summing values later
total_population=0

### Functions ###
# Define our median function
# We know we have an even number of states plus territories, so it will only deal with even numbers for now
median() {
  arr=($(printf '%d\n' "${@}" | sort -n))
  nel=${#arr[@]}
  (( j=nel/2 ))
  (( k=j-1 ))
  (( val=(${arr[j]} + ${arr[k]})/2 ))
  echo $val
}

# Define our mean function
# We will hardcode the number of states and territories for the time being
mean() {
  (( val="$@"/56 ))
  echo $val
}

# Define our standard deviation function
# We will assume we're calculating population standard deviation here (no pun intended)
sd() {
  # First get the mean
  mean_val=($(mean $1))
  shift
  
  # Next, take each state/territory population and calculate deviation to the mean, square it, and place it back in the array
  count=0
  arr=($(printf '%d\n' "${@}"))
  for el in "${arr[@]}"; do 
    x=$(( el - $mean_val ))
    y=$(( x*x ))
    arr[$count]=$y
    ((count+=1))
  done
  
  # Get the total of the squared deviations, and calculate the mean (variance)
  running_total=0
  for entry in "${arr[@]}"; do running_total=$((running_total+$entry)); done
  variance=($(mean $running_total))

  # Finally, get the square root of the variance
  std_dev=($(awk -v x=$variance 'BEGIN{print sqrt(x)}'))
  echo $std_dev
}

# curl wiki_url for data and store in a file locally
curl -s ${wiki_url} -o $wiki_data_file 

# cast an array of the 50 state abbreviations
# regex grabs all of the state abbreviations used for the year of 2020
states=($(cat $wiki_data_file | grep -oe begin=[A-Z][A-Z]\_2020 | grep -oe [A-Z][A-Z]))

# cast an array of territory values
# due to the way the variable sub works, the array consists only of the first word of the territory name
declare -A terrs=( [PR]="Puerto" [CM]="Northern" [DC]="District" [GU]="Guam" [VI]="U.S." [AS]="American")
terr_abbr=("PR" "DC" "CM" "GU" "AS" "VI")

# check if the script was run with any options
# if not, get input from the user
if [ -z "$1" ]; then
  # Get input from the user on what they want to do: get help, get a summary of the data, get info about a specific state or territory, or maybe they don't have a clue what they want to do
  read -p "Enter an option (-h,--help; -s,--summary; --state): " option
else
  # script was run with command-line argument
  # if the argument is invalid, it will be caught
  option="$1"
fi

# execute a case statement to determine what actions should be executed based on input
case "$option" in
  -s|--summary)
    echo "Gathering summary data (median, mean, and standard deviation)"
    # will need to get total population of states + territories in two different steps due to how they're referenced in the table
    # first, get our array set so we don't have to keep opening the data file
    state_terr_data=($(for state in "${states[@]}"; do cat $wiki_data_file | grep -oP '(?<=section begin='${state}'_2020).*?(?=section end='${state}'_2020)' | grep -oE '([0-9]+,){1,2}[0-9]+' | sed 's/,//g'; done))
    state_terr_data+=($(for terr in "${terrs[@]}"; do cat $wiki_data_file | grep -oP '(?<=Flag\|'${terr}').*?(?=data-sort-value)'| grep -oE '([0-9]+,){1,2}[0-9]+' | head -n1 | sed 's/,//g'; done))

    # loop over array to get total population stored in $value
    for entry in "${state_terr_data[@]}"; do total_population=$((total_population+$entry)); done
    
    # now do some math
    # call our median function 
    # we know we have an even number of states plus territories (50 + 6 = 56), so not going to account for an odd number here
    pop_med=($(median "${state_terr_data[@]}"))
    echo "The median population value of all states and territories in the United States is: $pop_med"

    # call our mean function
    pop_mean=($(mean "$total_population"))
    echo "The mean population of all states and territories in the United States is: $pop_mean"

    # finally, get the standard deviation
    pop_std_dev=($(sd "$total_population" "${state_terr_data[@]}"))
    echo "The standard deviation of the population of each state and territory in the United States is: $pop_std_dev"
    ;;
  --state)
    # convert the input to upper-case
    state=${2^^}

    # check if a state/territory abbreviation was entered. If not, ask for one/
    # if it was entered, check to make sure it's valid, and if so grab the population of the requested state. Otherwise, exit
    if [ -z $state ]; then
      read -p "Please enter the abbreviated state name (two-letter abbreviation) for its population: " state
    fi
    if printf '%s\n' "${states[@]}" | grep -Fixq "$state"; then
      state_pop=($(cat $wiki_data_file | grep -oP '(?<=section begin='${state}'_2020).*?(?=section end='${state}'_2020)' | grep -oE '([0-9]+,){1,2}[0-9]+'))
    elif printf '%s\n' "${terr_abbr[@]}" | grep -Fixq "$state"; then
      terr_name="${terrs[$state]}"
      state_pop=($(cat $wiki_data_file | grep -oP '(?<=Flag\|'${terr_name}').*?(?=data-sort-value)'| grep -oE '([0-9]+,){1,2}[0-9]+' | head -n1))
    else
      echo "You seemed to have entered the state/territory abbreviation incorrectly. Please try again."
      exit
    fi
    echo "The population of $state is: $state_pop"
    ;;
  *)
    echo "=========="
    echo "This script can be run with the following command-line arguments: "
    echo "-h: this option will return this help menu"
    echo "-s,--summary: this will return the mean, median, and standard deviation for all U.S. states and territories based on 2020 U.S. Census data"
    echo "--state XY, where XY is a two-letter abbreviation of a state/territory: will return the specific population of the desired state or territory. This is not case sensitive."
    echo "=========="
    ;;
esac

# clean up the tmp file we created from the curl earlier
rm $wiki_data_file
