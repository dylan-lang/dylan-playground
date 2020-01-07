# web-playground

Implementation of play.opendylan.org which lets users try out Dylan code in a
web browser.

## Installation

*  Install `dylan-tool`
*  Create a workspace containing this repository with `dylan new playground web-playground`.
*  Pull down all dependencies with `dylan update`.
*  Build with `dylan-compiler -build web-playground`
*  Create a chroot with `build-chroot.sh`.
*  Run the command it spits out.
