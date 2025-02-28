#!/usr/bin/env bash

DB_DATABASE="bookstack"
DB_USERNAME="book"
DB_PASSWORD=""
DB_HOST="db.lambda.int.cronolabs.net"

function install_packages() {
	dnf install nginx php php-common php-fpm php-mysqlnd php-gd php-zip
}

function install_composer() {
	curl -sS https://getcomposer.org/installer | php
	mv composer.phar /usr/local/bin/composer
	chmod +x /usr/local/bin/composer
}

function install_configs() {
	cp $CLT_RESOURCE/bookstack/nginx.conf /etc/nginx
	cp $CLT_RESOURCE/bookstack/php.conf /etc/nginx/default.d
	cp $CLT_RESOURCE/bookstack/php-fpm.conf /etc/nginx/conf.d
	cp $CLT_RESOURCE/bookstack/.env /usr/share/nginx/html

	echo "Database: "
	read DB_DATABASE

	echo "Username: "
	read DB_USERNAME

	echo "Password: "
	read DB_PASSWORD

	echo "Host: "
	read DB_HOST

	[ -z "$DB_DATABASE" ] && echo "Missing database" && exit 1
	[ -z "$DB_USERNAME" ] && echo "Missing user" && exit 1
	[ -z "$DB_PASSWORD" ] && echo "Missing password" && exit 1
	[ -z "$DB_HOST" ] && echo "Missing host" && exit 1

	sed -i "s/{DATABASE}/$DB_DATABASE/g" /usr/share/nginx/html/.env
	sed -i "s/{USERNAME}/$DB_USERNAME/g" /usr/share/nginx/html/.env
	sed -i "s/{PASSWORD}/$DB_PASSWORD/g" /usr/share/nginx/html/.env
	sed -i "s/{HOST}/$DB_HOST/g" /usr/share/nginx/html/.env
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
