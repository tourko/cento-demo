#!/bin/env bash

# Determine the absolute directory of the script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# Get the name of the script
SCRIPT="${SCRIPT:=$(basename ${BASH_SOURCE[0]})}"
VERSION='1.1.0'

CENTO_CONFIG_DIR="/opt/cento/config"

# Default options
THREADS=1
declare -i FLOW_OFFLOAD=0
declare -i TERMINATE_FLOWS=0

# Usage description
function usage {
    # Fonts decorators
    local NORM=$(tput sgr0)
    local BOLD=$(tput bold)

    print
    print "${BOLD}${SCRIPT} [--flow-offload] [-t | --threads N] [-h | --help] [-v | --version]${NORM}"
    print
    print "Command line option:"
    print "${BOLD}--flow-offload${NORM}                	Run cento-bridge with the HW flow offload."
    print "${BOLD}--terminate-flows${NORM}              Remove or keep flow records, when flows terminate."
    print "${BOLD}-t, --threads N${NORM}               	Distribute packet processing over N threads."
    print "${BOLD}-h, --help${NORM}                    	Display this help and exit."
    print "${BOLD}-v, --version${NORM}                 	Output version information and exit."
    print
}

SHORT_OPTIONS="t:"
LONG_OPTIONS="flow-offload,terminate-flows,threads:"

source ${SCRIPT_DIR}/common.sh

# Check prerequisites
for tool in nproc cento-bridge; do
    check_prerequisite ${tool}
done

# Process options
while true; do
  case "$1" in
      -t|--threads)
	  THREADS="$2"
	  shift 2
	  ;;
      --flow-offload)
      FLOW_OFFLOAD=1
      shift
      ;;
      --terminate-flows)
	  TERMINATE_FLOWS=1
	  shift
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

# Check that the number of threads is a positive integer value
if ! [[ "${THREADS}" =~ ^[1-9][0-9]*$ ]]; then
    print ERR "The number of threads must be a positive integer value."
    exit 1
fi

# Check that the number of threads is not larger than the number of CPU threads
num_cpus=$(nproc)
if (( ${THREADS} > ${num_cpus} )); then
    print ERR "The number of threads must not be greater than the number of CPU threads (${num_cpus})."
    exit 1
fi

# Calculate the max stream number
num_streams=${THREADS}
max_stream=$((num_streams-1))

# Choose NTPL file depending on whether flow offload is enabled
if (( FLOW_OFFLOAD )); then
    ntpl_file=/opt/cento/ntpl/with_flm.ntpl
else
    ntpl_file=/opt/cento/ntpl/without_flm.ntpl
fi

# Apply the NTPL
sh ${SCRIPT_DIR}/apply_ntpl.sh --vars MAX_STREAM=${max_stream} ${ntpl_file}

if [ $? -ne 0 ]; then
    print ERR "Failed to apply the NTPL."
    exit 1
fi

# Run cento-bridge
CENTO_CMD=(cento-bridge
--interface nt:stream[0-${max_stream}],nt:0
--dpi-level 2
--bridge-conf ${CENTO_CONFIG_DIR}/rules.conf
--blacklist ${CENTO_CONFIG_DIR}/blacklist.txt
--tx-offload
--hw-timestamp)

if (( FLOW_OFFLOAD )); then
    CENTO_CMD=(PF_RING_FLOW_OFFLOAD_AUTO_UNLEARN=${TERMINATE_FLOWS} ${CENTO_CMD[@]} --flow-offload)
fi

print
print INF "# ${CENTO_CMD[*]}"
print

eval "${CENTO_CMD[@]}"
