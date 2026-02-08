#!/bin/env bash

ldconfig

# Determine the absolute directory of the script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# Get the name of the script
SCRIPT="${SCRIPT:=$(basename ${BASH_SOURCE[0]})}"

TERM=xterm-256color source ${SCRIPT_DIR}/run_cento_bridge.sh "$@"
