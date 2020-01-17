# web-playground

Implementation of play.opendylan.org which lets users try out Dylan code in a
web browser.

## Installation

* Install `dylan-tool`
* Create a workspace containing this repository with `dylan new playground web-playground`.
* Pull down all dependencies with `dylan update`.
* Build with `dylan-compiler -build web-playground`
* Create a chroot with `build-chroot.sh`.  (NOT WORKING YET)
* Run the command it spits out.  (NOT WORKING YET)
* I use authbind to allow non-privileged access to ports 80 and 443:

    sudo touch /etc/authbind/byport/80
    sudo touch /etc/authbind/byport/443
    sudo chmod 777 /etc/authbind/byport/80
    sudo chmod 777 /etc/authbind/byport/443

* Modify web-playground/config.xml to have an absolute pathname for the
  server's working directory:

    <server working-directory="/path/to/web-playground"
            debug="no"
            use-default-virtual-host="yes"
            />

* Start the server with authbind and absolute pathnames everywhere:

    authbind /path/to/_build/bin/web-playground --config /path/to/web-playground/config.xml

