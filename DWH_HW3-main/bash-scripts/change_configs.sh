#!/bin/bash
set -e
cp /etc/postgresql/init-script/config/pg_hba.conf /var/lib/postgresql/data/pg_hba.conf
cp /etc/postgresql/init-script/config/postgresql.conf /var/lib/postgresql/data/postgresql.conf
cp /etc/postgresql/init-script/config/postgresql.conf /var/lib/postgresql/data-slave/postgresql.conf
cp /etc/postgresql/init-script/slave-config/postgresql.auto.conf /var/lib/postgresql/data-slave/postgresql.auto.conf

