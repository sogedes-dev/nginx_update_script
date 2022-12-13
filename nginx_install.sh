#!/bin/sh

# CD TO TMP

mkdir -p /tmp/nginx-build
cd /tmp/nginx-build

# UPDATE SYSTEM

apt update
apt upgrade -y
apt autoremove

# INSTALL BUILD DEPENDENCIES

apt install -y build-essential git

# INSTALL OPTIONAL DEPENDENCIES

## http_image_filter_module     ->      libgd-dev (libgd3 depended)
## http_geoip_module            ->      libgeoip-dev (geoip-bin and libgeoip1 depended)
## http_xslt_module             ->      libxslt1-dev (libxml2-dev, libxml2 and libxslt1.1 depended)

apt install -y libgd-dev libgeoip-dev libxslt1-dev 

# INSTALL NGINX DEPENDENCIES

# PCRE2 10.40
wget --no-check-certificate https://github.com/PCRE2Project/pcre2/releases/download/pcre2-10.40/pcre2-10.40.tar.gz -O pcre2.tar.gz
tar -zxf pcre2.tar.gz
mv pcre2*/ pcre2/

# ZLIB 1.2.13
wget --no-check-certificate https://zlib.net/zlib-1.2.13.tar.gz -O zlib.tar.gz
tar -zxf zlib.tar.gz
mv zlib*/ zlib/

# OPENSSL 1.1.1s (THIS WILL TAKE A WHILE)
# NOTE: WE COULD BOULD THIS WITH OPENSSL-3.x.x W/O PROBLEM, BUT THE BUILD TAKES 45-60 MINUTES
wget --no-check-certificate http://www.openssl.org/source/openssl-1.1.1s.tar.gz -O openssl.tar.gz
tar -zxf openssl.tar.gz
mv openssl*/ openssl/

# THIRD PARTY MODULES

mkdir -p ./modules

# DOWNLOAD STICKY MODULE
(cd ./modules && git clone https://github.com/sogedes-dev/nginx-sticky-module-ng)

# DOWNLOAD NGINX CODE
wget --no-check-certificate https://nginx.org/download/nginx-1.22.1.tar.gz -O nginx.tar.gz
tar -zxf nginx.tar.gz
mv nginx*/ nginx/

# CONFIGURE NGINX AND ITS MODULES (SEE https://nginx.org/en/docs/configure.html FOR MORE DETAILS)
(cd ./nginx && ./configure \
--prefix=/etc/nginx \
--conf-path=nginx.conf \
--pid-path=pid/nginx.pid \
--http-client-body-temp-path=temp/body \
--http-proxy-temp-path=temp/proxy \
--with-pcre=../pcre2 \
--with-pcre-jit \
--with-zlib=../zlib \
--with-openssl=../openssl \
--with-debug \
--with-compat \
--with-threads \
--with-http_ssl_module \
--with-http_stub_status_module \
--with-http_realip_module \
--with-http_v2_module \
--with-stream \
--with-stream_realip_module \
--with-stream_ssl_module \
--with-stream_ssl_preread_module \
--with-stream_geoip_module=dynamic \
--with-mail=dynamic \
--with-mail_ssl_module \
--with-http_geoip_module=dynamic \
--with-http_image_filter_module=dynamic \
--with-http_xslt_module=dynamic \
--without-http_charset_module \
--without-http_ssi_module \
--without-http_userid_module \
--without-http_auth_basic_module \
--without-http_mirror_module \
--without-http_autoindex_module \
--without-http_geo_module \
--without-http_split_clients_module \
--without-http_referer_module \
--without-http_fastcgi_module \
--without-http_uwsgi_module \
--without-http_scgi_module \
--without-http_memcached_module \
--without-http_empty_gif_module \
--without-http_browser_module \
--without-stream_geo_module \
--without-stream_split_clients_module \
--add-module=../modules/nginx-sticky-module-ng \
)
(cd ./nginx && make)
(cd ./nginx && make install)

# CREATE NGINX TEMP AND PID DIR

mkdir -p /etc/nginx/{temp,pid}

# CLEANUP

rm -f /etc/nginx/fastcgi* /etc/nginx/koi-* /etc/nginx/win-utf /etc/nginx/scgi_params* /etc/nginx/uwsgi_params* /etc/nginx/*.default /tmp/nginx-build

# CREATE /USR/SBIN SYMLINK (PATH)

ln --force -s /etc/nginx/sbin/nginx /usr/sbin/nginx

# ADD NGINX TO SYSTEMCTL

cat > /lib/systemd/system/nginx.service << EOL
[Unit]
Description=The NGINX HTTP and reverse proxy server
After=syslog.target network-online.target remote-fs.target nss-lookup.target
Wants=network-online.target

[Service]
Type=forking
PIDFile=/etc/nginx/pid/nginx.pid
ExecStartPre=/usr/sbin/nginx -t
ExecStart=/usr/sbin/nginx
ExecReload=/usr/sbin/nginx -s reload
ExecStop=/sbin/start-stop-daemon --quiet --stop --retry QUIT/5 --pidfile /etc/nginx/pid/nginx.pid
PrivateTmp=true

[Install]
WantedBy=multi-user.target

EOL

# ENABLE NGINX

systemctl enable nginx
systemctl start nginx
