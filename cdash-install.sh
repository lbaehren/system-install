#!/bin/bash

# -----------------------------------------------------------------------------
#  Variables

# Installation location of CDash (as part of the webserver directory)
cdash_basedir=/var/www/CDash

# -----------------------------------------------------------------------------

echo "-- Update the base system before any new installs ..."

apt-get update --fix-missing && \
apt-get dist-upgrade -y

echo "-- Update the base system before any new installs ... done"

# -----------------------------------------------------------------------------

echo "-- Installing additional packages ..."

apt-get install -y nedit cmake git gcc g++ net-tools  && \
apt-get install -y apache2 mysql-server  && \
apt-get install -y php php-mysql php-xsl php-curl php-gd php-dev php-xmlrpc php-bcmath php-mbstring php-xdebug

echo "-- Installing additional packages ... done"

# -----------------------------------------------------------------------------

echo "-- Pull CDash sources from Git repository ..."

cd /var/www
git clone https://github.com/Kitware/CDash.git CDash
cd ${cdash_basedir}
git checkout prebuilt
mkdir build && cd build && cmake ..

cd ${cdash_basedir}/config
cp config.php config.local.php
nano config.local.php

cd ${cdash_basedir}
ln -s ${cdash_basedir}/public /var/www/html/CDash
chmod a+rwx backup log public/rss public/upload

# -----------------------------------------------------------------------------
#
# Note: Typically the database entry needs to be done by hand; however using
#       the '-e <command>' command line option this should be scriptable as
#       well.
#

echo "-- Create MySQL database for CDash ..."
echo ""
echo "mysql> create database cdash;"
echo "mysql> create user 'cdash'@'localhost' identified by '<password>';"
echo "mysql> grant all privileges on cdash.* to 'cdash'@'localhost' with grant option;"
echo ""

mysql -u root -p

# mysql> create database cdash;
# mysql> create user 'cdash'@'localhost' identified by '${mysql_pass}';
# mysql> grant all privileges on cdash.* to 'cdash'@'localhost' with grant option;

# -----------------------------------------------------------------------------
#  Configuration of apache

echo "-- Configuration of CDash module for Apache ..."

mkdir -p /etc/apache2/conf.d

cat << 'EOF' >> /etc/apache2/conf.d/cdash.conf
<Directory /var/www/CDash>
   Order allow,deny
   Allow from all
</Directory>
EOF

echo "-- Restarting Apache server ..."

service apache2 restart
