#!/bin/bash

# Stage new code in a target directory.

if [[ $# != 1 ]]; then
    echo "Usage: `basename $0` <directory>"
    exit 2
fi

if [[ ! -f web-playground.dylan ]]; then
    echo "`basename $0` must be run from the top-level directory in the web-playground repo."
    exit 2
fi

target_dir="$1"

echo "Deploying to ${target_dir}"

mkdir -p "${target_dir}"

# Copy static assets
cp playground.dsp "${target_dir}/"

# Copy current binaries so we're not subject to dev rebuilds.
cp -r ../_build/bin "${target_dir}/"
cp -r ../_build/lib "${target_dir}/"

# Copy configs for the same reason.
cp config*xml "${target_dir}/"

# Copy Open Dylan binaries in place so we don't have to assume it's on $PATH.
od="$(dirname $(dirname $(which dylan-compiler)))"
cp -r --link "${od}" "${target_dir}/"
