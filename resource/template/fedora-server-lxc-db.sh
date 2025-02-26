#!/usr/bin/env bash

PG_DATA="/var/lib/pgsql/data"

dnf install postgresql-server postgresql-contrib

systemctl enable postgresql

postgresql-setup --initdb --unit postgresql

systemctl start postgresql

cd /var/lib/pgsql/data

openssl req -new -x509 -days 365 -nodes -text -out server.crt -keyout server.key -subj "/CN=db.lambda.int.cronolabs.net"

cp $CLT_TEMPLATE/config/pg_hba.conf "$PG_DATA/pg_hba.conf"
cp $CLT_TEMPLATE/config/postgresql.conf "$PG_DATA/postgresql.conf"

chown postgres:postgres /var/lib/pgsql/data/server.{key,crt}
chmod 0400 /var/lib/pgsql/data/server.key

systemctl restart postgresql
