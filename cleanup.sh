#!/bin/bash -x

# Remove playground directories and server logs older than 30 days.

if [[ $# != 1 ]]; then
    echo "Usage: $(dirname $0) DIRECTORY"
    exit 2
fi

days="30"
dir="$1"

# Note this finds directories in 'live' and 'live/_build/build'.
find "$dir" -name 'play-*' -type d -mtime +"$days" -exec rm -r {} \;


find "$dir" -name 'server.log*' -mtime +"$days" -exec rm {} \;
find "$dir" -name 'request.log*' -mtime +"$days" -exec rm {} \;
