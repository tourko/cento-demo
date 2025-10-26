#!/bin/env bash

# Determine the absolute directory of the script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# Get the name of the script
SCRIPT=$(basename ${BASH_SOURCE[0]})
VERSION='1.1.0'

NT_BIN='/opt/napatech3/bin'
NTPL_CMD="$NT_BIN/ntpl"

# Default options
VARS=""

# Usage description
function usage {
  # Fonts decorators
  local NORM=$(tput sgr0)
  local BOLD=$(tput bold)

  print
  print "${BOLD}${SCRIPT} [-V | --vars var1=value1[,...]] [-h | --help] [-v | --version] <file>${NORM}"
  print
  print "Arguments:"
  print "${BOLD}<file>${NORM}                        A path to the NTPL file."
  print
  print "Command line option:"
  print "${BOLD}-V, --vars var1=value1[,...]${NORM}  A list of variables and their values."
  print "${BOLD}-h, --help${NORM}                    Display this help and exit."
  print "${BOLD}-v, --version${NORM}                 Output version information and exit."
  print
}

# Function to parse a comma-separated key-value string into an associative array
# Usage: parse_kv_string "input_string" array_name
# Example: parse_kv_string "var1=value1,var2=value2" my_array
function parse_kv_string() {
    local input="$1"
    local -n array="$2"  # Nameref to the caller's associative array

    # Clear existing contents by unsetting elements only (preserves -A declaration)
    for existing_key in "${!array[@]}"; do
        unset "array[$existing_key]"
    done

    # Split the input by commas into an array of pairs
    IFS=',' read -ra pairs <<< "$input"

    # Iterate over each pair and split by equals sign
    for pair in "${pairs[@]}"; do
        # Trim leading/trailing whitespace from the pair
        pair=$(echo "$pair" | xargs)
        
        # Skip empty pairs
        if [[ -z "$pair" ]]; then
            continue
        fi
        
        # Split the pair into key and value
        IFS='=' read -r key value <<< "$pair"
        
        # Trim whitespace from key
        key=$(echo "$key" | xargs)
        

        # Skip if no key
        if [[ -n "$key" ]]; then
            array["$key"]="${value:-}"  # Preserve empty values
        fi
    done

    return 0
}

SHORT_OPTIONS="V:"
LONG_OPTIONS="vars:"

source ${SCRIPT_DIR}/common.sh

# Check prerequisites
for tool in ${NTPL_CMD}; do
    check_prerequisite ${tool}
done

# Process options
while true; do
  case "$1" in
      -V|--vars)
          VARS="$2"
	  shift 2
	  ;;
      --)
	  shift
	  break
	  ;;
      *)
	  break
	  ;;
  esac
done

FILE="$1"

### Validate file arguments ###
if [ -z ${FILE} ] ; then
    print ERR "File is required."
    usage >&2
    exit 1
fi

if [[ ! -f "$FILE" ]]; then
    print ERR  "File '$FILE' does not exist or is not a regular file."
    exit 1
fi

if ! file "$FILE" | grep -q "ASCII text"; then
    print ERR "File '$FILE' is not a text file."
    exit 1
fi

# Parse the VARS string into an array
declare -A vars_array

parse_kv_string "${VARS}" vars_array
if [ $? -ne 0 ]; then
    print ERR "Parsing vars failed."
    exit 1
fi

# Read NTPL file line by line
print "--- Beginning of NTPL ---"

while IFS= read -r line; do
    # Skip empty lines
    if [[ -z "$line" ]]; then
        continue
    fi

    # Skip lines starting with "//"
    if [[ "$line" =~ ^[[:space:]]*// ]]; then
        continue
    fi

    # Skip lines starting with "#"
    if [[ "$line" =~ ^[[:space:]]*# ]]; then
        continue
    fi

    # Apply the NTPL line
    if [[ -n "$line" ]]; then
	modified_line="$line"
	# Check if the line contains any of the keys from var_array and replace it with the associated value
        for key in "${!vars_array[@]}"; do
            modified_line=$(echo "$modified_line" | sed "s/\$$key/${vars_array[$key]}/g")
        done

	ntpl_output=$("$NTPL_CMD" -e "$modified_line")
	if [ $? -ne 0 ]; then
	   print ERR "Something is wrong in the NTPL '$modified_line'"
	   print
	   print "NTPL error details:"
	   while IFS= read -r ntpl_output_line; do
	      if [[ "$ntpl_output_line" =~ ^\>\>\> ]]; then
	         print DBG "$ntpl_output_line"
              fi
           done <<< "$ntpl_output"
	   print
	   exit 1
	fi
	
	if [ "$line" != "$modified_line" ]; then
	    print NTC "$modified_line"
	else
	    print "$line"
	fi
    fi
done < "$FILE"

print "------ End of NTPL ------"

