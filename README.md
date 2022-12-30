# dylan-playground

Implementation of play.opendylan.org which lets users try out Dylan code in a
web browser.

## Installation

* Install [dylan-tool](http://github.com/dylan-lang/dylan-tool) if it's not
  already part of your Open Dylan installation.
* `git clone https://github.com/dylan-lang/dylan-playground`
* `cd dylan-playground`
* `dylan update`
* `dylan build --all`

## Deployment

By default the playground is deployed to `/opt/dylan-playground/{dev,live}` and
it expects `/opt/opendylan/bin/dylan-compiler` to exist. To change either of
those you must edit the Makefile.

1.  Stop the current dylan-playground process so the executable file can be
    replaced.  Usually just `systemctl stop dylan-playground`.

1.  `make install` to install the "dev" instance. To install the "live"
    instance, use `environment=live make install`.

2.  The first time you deploy you'll need to configure systemd. As root, run
    these commands:

    ```shell
    cp dylan-playground.service /etc/systemd/system/
    systemctl start dylan-playground
    # ...check /var/log/syslog to see that it started correctly...
    systemctl enable dylan-playground
    ```

3.  **NOTE that if you change the deployment directory you must move the
    "shares" subdirectory to the new location or shared playground links will
    be broken.**

## HTTPS

Dylan's `ssl-network` has bit rotted so in the interest of speed I just put the
playground behind an nginx proxy. Here are some reminders about how I set it
up.

* Start nginx with default settings. It must listen on port 80 for the cert
  challenge.

* Use certbot to install a Let's Encrypt cert and key:
  ```shell
  $ sudo snap install certbot
  $ sudo certbot certonly --nginx
  ```

  The cert should be renewed automatically due to a systemctl timer. See
  `systemctl list-timers`.  To renew the certificate manually, stop the
  playground web server and run `certbot renew --standalone` and restart
  nginx with `systemctl restart nginx`.

* Create new nginx config and restart nginx:
  ```
  listen 443 ssl;
  listen [::]:443 ssl;
  server_name play.opendylan.org;
  ssl_certificate     /etc/letsencrypt/live/play.opendylan.org/cert.pem;
  ssl_certificate_key /etc/letsencrypt/live/play.opendylan.org/privkey.pem;
  limit_req_zone $binary_remote_addr zone=playground:1m rate=30r/m;
  location / {
    limit_req zone=playground burst=10;
    proxy_pass http://localhost:80;  # dylan-playground server
  }
  ```

* Replace `default` with the `play.opendylan.org` config in `sites-enabled` and
  restart with `nginx -s reload`.
