#!/usr/bin/env bash

# TODO: check for existing bookstack and if it exists upgrade it instead of installing it

function install_packages() {
	dnf install -y nginx php php-common php-fpm php-mysqlnd php-gd php-zip
}

function install_composer() {
	curl -sS https://getcomposer.org/installer | php
	mv composer.phar /usr/local/bin/composer
	chmod +x /usr/local/bin/composer
}

function install_configs() {
	cp $CLT_TEMPLATE/config/bookstack/nginx.conf /etc/nginx
	cp $CLT_TEMPLATE/config/bookstack/php.conf /etc/nginx/default.d
	cp $CLT_TEMPLATE/config/bookstack/php-fpm.conf /etc/nginx/conf.d
	cp $CLT_TEMPLATE/config/bookstack/.env /usr/share/nginx/html

	[ -z "$DB_WIKI_DATABASE" ] && echo "Missing environment variable DB_DATABASE" && exit 1
	[ -z "$DB_WIKI_USERNAME" ] && echo "Missing environment variable DB_USERNAME" && exit 1
	[ -z "$DB_WIKI_PASSWORD" ] && echo "Missing environment variable DB_PASSWORD" && exit 1
	[ -z "$DB_HOST" ] && echo "Missing environment variable DB_HOST" && exit 1

	sed -i "s/{{CLUSTER_HOSTNAME}}/$CLUSTER_HOSTNAME/g" /usr/share/nginx/html/.env
	sed -i "s/{{DATABASE}}/$DB_WIKI_DATABASE/g" /usr/share/nginx/html/.env
	sed -i "s/{{USERNAME}}/$DB_WIKI_USERNAME/g" /usr/share/nginx/html/.env
	sed -i "s/{{PASSWORD}/$DB_WIKI_PASSWORD/g" /usr/share/nginx/html/.env
	sed -i "s/{{HOST}}/$DB_HOST/g" /usr/share/nginx/html/.env
}

function start_services() {
	systemctl enable nginx
	systemctl start nginx
	systemctl enable php-fpm
	systemctl start php-fpm
}

function restart_services() {
	systemctl restart php-fpm
	systemctl restart nginx
}

function fix_nginx_permissions() {
	chown -R nginx:nginx /usr/share/nginx
	chown -R 0755 /usr/share/nginx
}

function pull_bookstack() {
	cd /usr/share/nginx
	git clone https://github.com/BookStackApp/BookStack.git --branch release --single-branch bookstack
	mv html html-backup
	mv bookstack html
	cd html
	composer install --no-dev
}

function build_bookstack() {
	cd /usr/share/nginx/html
	php artisan key:generate
	php artisan migrate
}

install_packages
install_composer
start_services
pull_bookstack
install_configs
fix_nginx_permissions
build_bookstack
restart_services
