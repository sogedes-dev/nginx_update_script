# NGINX Update Script

This script will custom build and install (or update) NGINX on your server.

It is recommended to deinstall NGINX (i.e. `sudo apt remove nginx`) before you install and this version if you have a version managed NGINX already on your system.

If you trust this repository, you can even do this with a one-liner (after the download the script will wait for you to input the sudo password):

```bash
wget -O - https://raw.githubusercontent.com/sogedes-dev/nginx_update_script/main/nginx_install.sh | sudo bash
```

After that run the config check and resolve (usually removing the unused stattement) any errors:

```bash
sudo nginx -t
```

After bigger updates a reboot is recommended, but a `sudo systemctl reload nginx.service` should be sufficent.
If systemctl reports the service as masked ("Failed to start nginx.service: Unit nginx.service is masked."), just unmask it:

```bash
sudo systemctl unmask nginx.service
```
