# web-playground

Implementation of play.opendylan.org which lets users try out Dylan code in a
web browser.

## Installation

* Install `dylan-tool`
* Create a workspace containing this repository by running `dylan-tool new playground web-playground`.
* cd playground
* Pull down all dependencies with `dylan-tool update`.
* Build with `dylan-compiler -build web-playground`
* I use authbind to allow non-privileged access to ports 80 and 443:

  ```shell
  sudo touch /etc/authbind/byport/80
  sudo touch /etc/authbind/byport/443
  sudo chmod 777 /etc/authbind/byport/80
  sudo chmod 777 /etc/authbind/byport/443
  ```

## Deployment

I run the dev instance out of my "playground" workspace directory with
`_build/bin/web-playground --config web-playground/config.dev.xml`.

To deploy "live":

* Run `web-playground/deploy.sh live` to deploy the code, assets, and Open
  Dylan to the "live" directory.

* Modify `live/config.live.xml` to have an absolute pathname for the
  server-root directory::

  ```xml
  <server server-root="/path/to/live"
          debug="no"
          use-default-virtual-host="yes"
          />
  ```

* Start the server with authbind if running it on port 80:

  ```shell
  cd live
  authbind bin/web-playground --config config.live.xml
  ```

## HTTPS

Dylan's `ssl-network` has bit rotted so in the interest of speed I just put the
playground behind an nginx proxy. Here are some reminders about how I set it
up.

* Start nginx with default settings, listening on port 80.

* Use certbot to install a Let's Encrypt cert and key:
  ```shell
  $ apt-get install certbot python-certbot-nginx
  $ certbot certonly --nginx
  ```

* Create new nginx config and restart nginx:
  ```
  listen 443 ssl;
  listen [::]:443 ssl;
  server_name play.opendylan.org;
  ssl_certificate     /etc/letsencrypt/live/play.opendylan.org/cert.pem;
  ssl_certificate_key /etc/letsencrypt/live/play.opendylan.org/privkey.pem;
  location / {
    proxy_pass http://localhost:80;  # Dylan web-playground server
  }
  ```

* Replace `default` with the `play.opendylan.org` config in `sites-enabled` and
  restart with `nginx -s reload`.
