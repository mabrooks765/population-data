# population-data
Quick and dirty script to pull some census data from Wikipedia and parse through it a bit

The script can take several inputs:
-s, --summary: this option will return the mean, median, and standard deviation for all U.S. states and territories based on 2020 U.S. Census data
--state XY, where XY is a two-letter abbreviation of a state/territory: will return the specific population of the desired state or territory. This is not case sensitive.
-h: returns a simple help menu

If the script is run with no command-line arguments, it will prompt the user for an input.

Ensure you make the script executable after cloning.

Example:
```
$ ./population_data.sh --state IN
The population of IN is: 6,785,528
```

The script is written in bash, and can be downloaded and run locally. It will attempt to pull info from the following Wikipedia article:
https://en.wikipedia.org/wiki/List_of_U.S._states_and_territories_by_population

On run, the script will `curl` this page using the MediaWiki API and grab the parsed WikiText specifically for the "State and territory rankings" table on the page. It will create a file in the "/tmp" directory where this info will be stored while the script runs. This file will be cleaned up upon script exit.
