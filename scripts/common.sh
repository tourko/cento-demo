#!/bin/env bash

# Get the name of the script
SCRIPT="${SCRIPT:=$(basename ${BASH_SOURCE[0]})}"
VERSION="${VERSION:='1.1.0'}"

# Print a colored message to stdout or stderr
function print {
    # Fonts decorators
    local NORM=$(tput sgr0)
    local RED=$(tput setaf 1)
    local YELLOW=$(tput setaf 11)
    local GREEN=$(tput setaf 10)
    local GREY=$(tput setaf 8)

    case "$1" in
        "ERR") echo "${RED}Error: $2${NORM}" >&2 ;;
	    "NTC") echo "${YELLOW}$2${NORM}" ;;
	    "INF") echo "${GREEN}$2${NORM}" ;;
        "DBG") echo "${GREY}$2${NORM}" ;;
        *) echo "$1" >&1
    esac
}

# Print version
function version {
    print "${SCRIPT} (version ${VERSION})"
}

# Usage description
if ! declare -f usage >/dev/null 2>&1; then
    function usage {
        # Fonts decorators
    	local NORM=$(tput sgr0)
    	local BOLD=$(tput bold)

    	print
    	print "${BOLD}${SCRIPT} [-h | --help] [-v | --version]${NORM}"
    	print
    	print "Command line option:"
    	print "${BOLD}-h, --help${NORM}                    Display this help and exit."
    	print "${BOLD}-v, --version${NORM}                 Output version information and exit."
    	print
    }
fi

# Checks if a command tool is installed
function check_prerequisite {
    if ! type "$1" > /dev/null 2>&1; then
        return 1
    fi
}

# Check prerequisites
for tool in tput; do
    if ! check_prerequisite ${tool}; then
	print ERR "A required '${tool}' tool is not installed on the system."
	exit 1
    fi
done

SHORT_OPTIONS="hv${SHORT_OPTIONS}"
LONG_OPTIONS="help,version,${LONG_OPTIONS}"
options="${options:=$(getopt -o ${SHORT_OPTIONS} --long ${LONG_OPTIONS} -n "${SCRIPT}" -- "$@")}"

if [ $? -ne 0 ]; then
    usage >&2
    exit 1
fi

eval set -- "${options}"

# Process common options
while true; do
    case "$1" in
        -h|--help)
        usage
        exit 0
        shift
        ;;
        -v|--version)
        version;
        exit 0;
        shift
        ;;
        --)
        shift
        break
        ;;
        *)
        # Unrecognised; pass through unchanged
        break
        ;;
    esac
done
