# dylan-playground

Implementation of play.opendylan.org which lets users try out Dylan code in a
web browser.

## Installation

* Install `dylan-tool`
* Create a workspace containing this repository by running `dylan-tool new playground dylan-playground`.
* cd playground
* Pull down all dependencies with `dylan-tool update`.
* Build with `dylan-compiler -build dylan-playground`
* I use authbind to allow non-privileged access to ports 80 and 443:

  ```shell
  sudo touch /etc/authbind/byport/80
  sudo touch /etc/authbind/byport/443
  sudo chmod 777 /etc/authbind/byport/80
  sudo chmod 777 /etc/authbind/byport/443
  ```

## Deployment

I run the dev instance out of my "playground" workspace directory with
`_build/bin/dylan-playground --config dylan-playground/config.dev.xml`.

To deploy "live":

* Modify `live/config.live.xml` to have absolute paths:

  ```xml
  <dylan-playground
      root-directory="/path/to/playground/live"
      template-directory="/path/to/playground/live"
      dylan-compiler="/path/to/opendylan/bin/dylan-compiler"
      />
  ```

* Stop the current dylan-playground process so the executable file can be
  replaced.

* Run `dylan-playground/deploy.sh live` to deploy the code, assets, and Open
  Dylan to the "live" directory.

* Configure systemd. As root, run these commands:

  ```shell
  cp dylan-playground.service /etc/systemd/system/
  systemctl start dylan-playground
  # ...check /var/log/syslog to see that it started correctly...
  systemctl enable dylan-playground
  ```

* Or start it by hand using the command in dylan-playground.service

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

  The cert should be renewed automatically due to a systemctl timer. See
  `systemctl list-timers`.  To renew the certificate manually, stop the
  playground web server and run `certbot renew --standalone`.

* Create new nginx config and restart nginx:
  ```
  listen 443 ssl;
  listen [::]:443 ssl;
  server_name play.opendylan.org;
  ssl_certificate     /etc/letsencrypt/live/play.opendylan.org/cert.pem;
  ssl_certificate_key /etc/letsencrypt/live/play.opendylan.org/privkey.pem;
  location / {
    proxy_pass http://localhost:80;  # dylan-playground server
  }
  ```

* Replace `default` with the `play.opendylan.org` config in `sites-enabled` and
  restart with `nginx -s reload`.
