#!/usr/bin/env bash

DB_HOST="db.lambda.int.cronolabs.net"

function setup_postgres() {
	PG_DATA="/var/lib/pgsql/data"

	dnf install postgresql-server postgresql-contrib

	systemctl enable postgresql

	postgresql-setup --initdb --unit postgresql

	systemctl start postgresql

	cd /var/lib/pgsql/data

	echo "Enter hostname:"
	read DB_HOST
	[ -z "$DB_HOST" ] && echo "Missing hostname" && exit 1
	openssl req -new -x509 -days 365 -nodes -text -out server.crt -keyout server.key -subj "/CN=$DB_HOST"

	cp $CLT_TEMPLATE/config/pg_hba.conf "$PG_DATA/pg_hba.conf"
	cp $CLT_TEMPLATE/config/postgresql.conf "$PG_DATA/postgresql.conf"

	chown postgres:postgres /var/lib/pgsql/data/server.{key,crt}
	chmod 0400 /var/lib/pgsql/data/server.key

	systemctl restart postgresql
}

function setup_mariadb() {
	dnf install mariadb-server
	systemctl enable mariadb
	systemctl start mariadb

	mysql_secure_installation
}

function setup_admin_user() {
	echo "Enter admin username: "
	read admin_username

	echo "Enter admin password: "
	read admin_password

	[ -z "$admin_username" ] && echo "Missing admin username" && exit 1
	[ -z "$admin_password" ] && echo "Missing admin password" && exit 1

	su - postgres -c "psql -U postgres -c 'create role $admin_username with login password '$admin_password'"
	su - postgres -c "psql -U postgres -c 'alter role $admin_user with superuser"

	mysql -u root -p -e "create user '$admin_username'@'%' identified by '$admin_password'"
	mysql -u root -p -e "grant all privileges on *.* to '$admin_username'@'%'"
	mysql -u root -p -e "flush privileges"
}

setup_postgres
setup_mariadb
setup_admin_user
