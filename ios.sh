#!/usr/bin/env bash

set -exo pipefail

if [ "$#" -ne 3 ]; then
  echo "Usage: $0 udid port height width " >&2
fi

#UDID=$(system_profiler SPUSBDataType | sed -n -E -e '/(iPhone|iPad)/,/Serial/s/ *Serial Number: *(.+)/\1/p')
UDID="$1"
PORT="$2"
HEIGHT="$3"
WIDTH="$4"
RESOLUTION="${HEIGHT}x${WIDTH}"

./ios_minicap \
    --udid $UDID \
    --port $PORT \
    --resolution $RESOLUTION
