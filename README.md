# web-playground

Implementation of play.opendylan.org which lets users try out Dylan code in a
web browser.

## Installation

* Install `dylan-tool`
* Create a workspace containing this repository by running `dylan-tool new playground web-playground`.
* cd playground
* Pull down all dependencies with `dylan-tool update`.
* Build with `dylan-compiler -build web-playground`
* Create a chroot with `build-chroot.sh`.  (NOT WORKING YET)
* Run the command it spits out.  (NOT WORKING YET)
* I use authbind to allow non-privileged access to ports 80 and 443:

    sudo touch /etc/authbind/byport/80
    sudo touch /etc/authbind/byport/443
    sudo chmod 777 /etc/authbind/byport/80
    sudo chmod 777 /etc/authbind/byport/443

* Run `web-playground/deploy.sh live` to deploy the code and assets to the
  "live" directory.

* Modify web-playground/config.xml to have an absolute pathname for the
  server-root directory::

  ```xml
  <server server-root="/path/to/live"
          debug="no"
          use-default-virtual-host="yes"
          />
  ```

* Start the server with authbind if running it on port 80:

  ```xml
  cd live
  authbind bin/web-playground --config config.xml
  ```
