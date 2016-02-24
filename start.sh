#!/bin/bash

# PHP & Nginx start
service nginx start
service php7.0-fpm start

if [ ! -d /var/lib/mysql/mysql ]; then
    chown mysql:mysql /var/lib/mysql
    mysql_install_db
fi

# Provide terminating MySQL to TERM
trap "mysqladmin shutdown" TERM

# Start MySQL in background
mysqld_safe --bind-address=0.0.0.0 &

# Wait to end of all processes
wait


