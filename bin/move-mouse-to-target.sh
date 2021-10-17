#!/bin/bash

# -------------------------------------------------------------------------------------- #
# This script searches for a given image on the screen and moves the mouse to the        #
# position of the upper left corner if it's found. If the image is not found, an exit    #
# code of 1 is returned. For the image search, this script uses of the find-target.sh    #
# script. The given parameters are direcly passed to this script.                        #
#                                                                                        #
# -s scale_factor: In order to optimize the performance, both, the target image and the  #
#                  screen capture is scaled down by 1 / scale_factor. Lower numbers can  #
#                  help finding difficult targets but will also increase the calculation #
#                  time. Reasonable values are [1...10], default is 4.                   #
# -f fuzziness:    A mean-squared-error threshold under which a location is considered   #
#                  to be a match. Default is 0.01. Increase this to make finding a       #
#                  target more likely but also increase the possibility of false         #
#                  positives.                                                            #
# -------------------------------------------------------------------------------------- #

usage() {
  echo "Usage: $0 -s scale_factor -f fuzziness target.png" >&2
}

SCALE_FACTOR=4
FUZZINESS=0.01

while getopts "s:f:h" opt; do
  case $opt in
    s) SCALE_FACTOR="${OPTARG}";;
    f) FUZZINESS="${OPTARG}";;
    h) usage; exit 0;;
    *) usage; exit 1;;
  esac
done

shift $((OPTIND-1))
TARGET=$1

# Make sure the target image is given.
if [[ -z "${TARGET}" ]]; then
    usage
    exit 1
fi

# Search for the target image on the screen.
POS=$(find-target.sh -s $SCALE_FACTOR -f $FUZZINESS "${TARGET}")
if [[ -z "${POS}" ]]; then
  echo "Failed to find ${TARGET} on the screen!" >&2
  exit 1
fi

echo "Performing mouse move to [${POS}]" >&2
xdotool mousemove ${POS}
