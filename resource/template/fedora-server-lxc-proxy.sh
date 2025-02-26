#!/usr/bin/env bash

SSL_PRIVATE="/etc/ssl/private"
SSL_CERTS="/etc/ssl/certs"

dnf install nginx

systemctl enable nginx
systemctl start nginx

mkdir -p /etc/ssl/private/
mkdir -p /etc/nginx/snippets
mkdir -p /var/www/cronolabs.net/html

openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout "$SSL_PRIVATE/nginx-selfsigned.key" -out "$SSL_CERTS/nginx-selfsigned.crt"
openssl dhparam -out /etc/nginx/dhparam.pem 4096

cp "$CTL_TEMPLATE/config/index.html" /var/www/cronolabs.net/html
cp "$CTL_TEMPLATE/config/ssl-params.conf" /etc/nginx/snippets
cp "$CTL_TEMPLATE/config/self-signed.conf" /etc/nginx/snippets
cp "$CTL_TEMPLATE/config/backend-mapping.conf" /etc/nginx/snippets
cp "$CTL_TEMPLATE/config/dcronolabs.net.conf" /etc/nginx/conf.d

chown -R nginx:nginx /var/www
chmod -R 0755 /var/www

systemctl reload nginx
