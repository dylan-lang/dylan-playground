#!/bin/bash -x

# Stage new code in a target directory.
# Assumes a layout like this:
#   ./_build/bin/dylan-playground   # binary
#   ./dylan-playground              # dylan-playground checkout
#   ./live                          # live deployment dir created by this script

if [[ $# != 1 ]]; then
    echo "Usage: `basename $0` <directory>"
    exit 2
fi

d=`dirname $0`

target_dir="$1"

echo "Deploying to ${target_dir}"

mkdir -p "${target_dir}"

# Copy static assets
cp $d/playground.dsp "${target_dir}/"
cp -r $d/static "${target_dir}/"

# Copy current binaries so we're not subject to dev rebuilds.
cp -r $d/../_build/bin "${target_dir}/"
cp -r $d/../_build/lib "${target_dir}/"

# Copy configs for the same reason.
cp $d/config.live.xml "${target_dir}/"
