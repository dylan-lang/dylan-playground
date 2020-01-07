#!/bin/bash

#set -e  # exit on error

# Run this as root.

# This tries not to do steps it has already done, if the files exist, so to
# force something to run again remove the relevant files.

# Prerequisites:
# *  Install Open Dylan
# *  Make a directory with the web-playground repository and its associated _build file
#    at the same level. I use `dylan-tool` to create a workspace:
#      * dylan new playground web-playground
#      * dylan update
#      * cd playground
#      * dylan-compiler -build web-playground

if [[ "$USER" != "root" ]]; then
    echo "You need to be root."
    exit 2
fi

if [[ -z "$(which dylan-compiler)" ]]; then
    echo "dylan-compiler must be on \$PATH."
    exit 2
fi

if [[ ! -d _build || ! -d web-playground ]]; then
    echo "./_build/ and ./web-playground/ must exist."
    exit 2
fi

CH=${PWD}/web-playground-chroot
if [[ -d ${CH} ]]; then
    echo "${CH} already exists."
else
    echo "Making ${CH}"
    mkdir ${CH}
fi

if [[ -d ${CH}/boot ]]; then
    echo "debootstrap already ran; skipping."
else
    echo "Running debootstrap buster ${CH}..."
    /usr/sbin/debootstrap buster ${CH}
fi

echo "Installing required packages..."
/usr/sbin/chroot ${CH} /usr/bin/apt-get --yes install libgc-dev libunwind-dev

# Make libgc happy
if [[ -d ${CH}/proc/1 ]]; then
    echo "/proc already mounted; skipping."
else
    echo "Creating /proc ..."
    mkdir ${CH}/proc
    mount --bind /proc ${CH}/proc
fi

# Copy Dylan code we need to /dylan/ in the chroot.
OPEN_DYLAN_DIR="$(dirname $(dirname $(which dylan-compiler)))"
OD_BASE=`basename $OPEN_DYLAN_DIR`
if [[ -d ${CH}/dylan ]]; then
    echo "${CH}/dylan already exists; not copying Dylan files."
else
    echo "Copying Dylan files to ${CH}/dylan ..."
    mkdir -p ${CH}/dylan/opendylan
    cp -r -p ./_build ${CH}/dylan/
    cp -r -p ./web-playground ${CH}/dylan/
    cp -r -p ${OPEN_DYLAN_DIR}/* ${CH}/dylan/opendylan/
fi

startup=dylan-web-playground.sh

echo "Creating ${CH}/dylan/${startup}..."
cat << EOF > ${CH}/dylan/${startup}
#!/bin/bash -x

export DYLAN=/dylan
export LD_LIBRARY_PATH=/dylan/_build/lib
export PATH=/dylan/opendylan/bin:\$PATH
cd /dylan
_build/bin/web-playground --config /dylan/web-playground/config.xml
EOF
chmod +x ${CH}/dylan/${startup}

echo "To start the Dylan web playground run '/usr/sbin/chroot ${CH} /dylan/${startup}'."
