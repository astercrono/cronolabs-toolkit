#!/usr/bin/env bash

dnf install -y nginx

systemctl enable nginx
systemctl start nginx

mkdir -p /etc/ssl/private/
mkdir -p /etc/nginx/snippets
mkdir -p /var/www/$CLUSTER_HOSTNAME/html

openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout "$PROXY_SSL_PRIVATE/nginx-selfsigned.key" -out "$PROXY_SSL_CERTS/nginx-selfsigned.crt" -subj "/C=$PROXY_SSL_COUNTRY/ST=$PROXY_SSL_STATE/L=$PROXY_SSL_LOCATION/O=$PROXY_SSL_ORG/OU=$PROXY_SSL_ORGUNIT/CN=$PROXY_SSL_CN"

if [ $PROXY_SSL_DHPARAM_FAST = 0 ]; then
	openssl dhparam -out /etc/nginx/dhparam.pem 4096
else
	openssl dhparam -dsaparam -out /etc/nginx/dhparam.pem 4096
fi

cp "$CLT_TEMPLATE/config/proxy/index.html" /var/www/$CLUSTER_HOSTNAME/html
cp "$CLT_TEMPLATE/config/proxy/ssl-params.conf" /etc/nginx/snippets
cp "$CLT_TEMPLATE/config/proxy/self-signed.conf" /etc/nginx/snippets
cp "$CLT_TEMPLATE/config/proxy/backend-mapping.conf" /etc/nginx/snippets
cp "$CLT_TEMPLATE/config/proxy/site.conf" /etc/nginx/conf.d/$CLUSTER_HOSTNAME.conf

sed -i "s/{{CLUSTER_HOSTNAME}}/$CLUSTER_HOSTNAME/g" /etc/nginx/conf.d/$CLUSTER_HOSTNAME.conf
sed -i "s/{{CLUSTER_HOSTNAME}}/$CLUSTER_HOSTNAME/g" /etc/nginx/snippets/backend-mapping.conf

chown -R nginx:nginx /var/www
chmod -R 0755 /var/www

systemctl restart nginx
