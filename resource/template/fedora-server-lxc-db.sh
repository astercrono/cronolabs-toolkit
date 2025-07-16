#!/usr/bin/env bash

function setup_postgres() {
	PG_DATA="/var/lib/pgsql/data"

	dnf install -y postgresql-server postgresql-contrib

	systemctl enable postgresql

	postgresql-setup --initdb --unit postgresql

	systemctl start postgresql

	cd /var/lib/pgsql/data

	[ -z "$DB_HOST" ] && echo "Missing environment variable DB_HOST" && exit 1

	openssl req -new -x509 -days 365 -nodes -text -out server.crt -keyout server.key -subj "/CN=$DB_HOST"

	cp $CLT_TEMPLATE/config/db/pg_hba.conf "$PG_DATA/pg_hba.conf"
	cp $CLT_TEMPLATE/config/db/postgresql.conf "$PG_DATA/postgresql.conf"

	chown postgres:postgres /var/lib/pgsql/data/server.{key,crt}
	chmod 0400 /var/lib/pgsql/data/server.key

	systemctl restart postgresql
}

function setup_mariadb() {
	dnf install -y mariadb-server
	systemctl enable mariadb
	systemctl start mariadb
	echo -e "\n\n$DB_ADMIN_PASSWORD\n$DB_ADMIN_PASSWORD\ny\ny\ny\ny" | mysql_secure_installation
}

function setup_admin_user() {
	export PGPASSWORD="$DB_ADMIN_PASSWORD"
	su - postgres -c "psql -U postgres -c \"create role $DB_ADMIN_USERNAME with login password '$DB_ADMIN_PASSWORD'\""
	su - postgres -c "psql -U postgres -c 'alter role $DB_ADMIN_USERNAME with superuser'"

	mysql -u root -p"$DB_ADMIN_PASSWORD" -e "create user '$DB_ADMIN_USERNAME'@'%' identified by '$DB_ADMIN_PASSWORD'"
	mysql -u root -p"$DB_ADMIN_PASSWORD" -e "grant all privileges on *.* to '$DB_ADMIN_USERNAME'@'%'"
	mysql -u root -p"$DB_ADMIN_PASSWORD" -e "flush privileges"
}

function setup_wiki_user() {
	mysql -u root -p"$DB_ADMIN_PASSWORD" -e "create user '$DB_WIKI_USERNAME'@'%' identified by '$DB_WIKI_PASSWORD'"
	mysql -u root -p"$DB_ADMIN_PASSWORD" -e "create database $DB_WIKI_DATABASE"
	mysql -u root -p"$DB_ADMIN_PASSWORD" -e "grant all privileges on $DB_WIKI_DATABASE.* to '$DB_WIKI_USERNAME'@'%'"
	mysql -u root -p"$DB_ADMIN_PASSWORD" -e "flush privileges"
}

setup_postgres
setup_mariadb
setup_admin_user
setup_wiki_user
