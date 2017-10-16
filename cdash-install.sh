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
apt-get install -y apache2 libapache2-mod-php mysql-server  && \
apt-get install -y php php-mysql php-xsl php-curl php-gd php-dev php-xmlrpc php-bcmath php-mbstring php-xdebug

echo "-- Installing additional packages ... done"

# -----------------------------------------------------------------------------

echo "-- Install CDash ..."

cd /var/www
echo "--> Cloning repository into local working copy ..."
git clone https://github.com/Kitware/CDash.git CDash
cd ${cdash_basedir}
echo "--> Checking out Git branch ..."
git checkout v2.4.0-prebuilt
echo "--> Running CMake to configure project"
mkdir build && cd build && cmake ..

echo "--> Creating copy of configuration file for editing ..."
cd ${cdash_basedir}/config
cp config.php config.local.php
nano config.local.php

cd ${cdash_basedir}
echo "--> Creating symbolic link to web application root directory ..."
ln -s ${cdash_basedir}/public /var/www/html/CDash
echo "--> Changing permissions to application folder ..."
chown www-data backup log public/rss public/upload
chmod a+rwx backup log public/rss public/upload

echo "-- Install CDash ... done"

# -----------------------------------------------------------------------------
#
# Note: Typically the database entry needs to be done by hand; however using
#       the '-e <command>' command line option this should be scriptable as
#       well.
#

echo "-- Create MySQL database for CDash ..."
echo ""
echo "-------------------------------------------------"
echo " create database cdash;"
echo " create user 'cdash'@'localhost' identified by '<password>';"
echo " grant all privileges on cdash.* to 'cdash'@'localhost' with grant option;"
echo "-------------------------------------------------"
echo ""

mysql -u root -p

# mysql> create database cdash;
# mysql> create user 'cdash'@'localhost' identified by '${mysql_pass}';
# mysql> grant all privileges on cdash.* to 'cdash'@'localhost' with grant option;

# -----------------------------------------------------------------------------
#  Configuration of apache

echo "-- Restarting Apache server ..."

service apache2 restart

echo ""
echo "-------------------------------------------------"
echo " To complete install: go to http://localhost/CDash/install.php "
echo "-------------------------------------------------"
echo ""
