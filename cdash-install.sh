#!/bin/bash

# -----------------------------------------------------------------------------
#  Variables

# Installation location of CDash (as part of the webserver directory)
cdash_basedir=/var/www/CDash
mysql_pass=""

#_________________________________________________________________________________________
#  Determine OS name and version

varOS=""
varRelease=""

if test -f /etc/os-release ; then
    varName=`cat /etc/os-release | grep NAME | grep -v PRETTY | grep -v CODENAME | grep -v CPE_NAME`
    if test `echo ${varName} | grep Ubuntu` ; then
        varOS="ubuntu"
    elif test `echo ${varName} | grep Fedora` ; then
        varOS="fedora"
    fi
elif test -f /etc/debian_version ; then
    varOS="ubuntu"
elif test -f /etc/fedora-release ; then
  varOS="fedora"
elif test -f /etc/SuSE-release ; then
    varOS="opensuse"
fi

case ${varOS} in
    "fedora")
        varRelease=`cat /etc/os-release | grep VERSION_ID | tr '=' '\n' | grep [0-9]`
        ;;
    "ubuntu")
        varRelease=`cat /etc/os-release | grep VERSION_ID | tr '""' '\n' | grep [0-9]`
        ;;
esac

# -----------------------------------------------------------------------------

echo "-- Update the base system before any new installs ..."

case ${varOS} in
    "fedora")
        dnf -y update
        ;;
    "ubuntu")
        apt-get update --fix-missing && \
        apt-get dist-upgrade -y
        ;;
esac

echo "-- Update the base system before any new installs ... done"

# -----------------------------------------------------------------------------

echo "-- Installing additional packages ..."

case ${varOS} in
    "fedora")
        echo "not yet implemented!"
        ;;
    "ubuntu")
        apt-get install -y cmake git gcc g++ nano net-tools  && \
        apt-get install -y apache2 libapache2-mod-php  && \
        apt-get install -y php-dev php-xmlrpc php-bcmath php-mbstring php-xdebug
        case ${varRelease} in
            "12.04")
                # mysql-client-5.5
                apt-get install -y php5 php5-xsl php5-curl php5-gd php5-mysql mysql-server-5.5
                ;;
            *)
                apt-get install -y php php-xsl php-curl php-gd php-mysql mysql-server
                ;;
        esac
        ;;
esac

echo "-- Installing additional packages ... done"

# -----------------------------------------------------------------------------

echo "-- Install CDash ..."

mkdir -p /var/www
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
#       mysql -u root -p --execute="create database cdash;"
#       mysql -u root -p --execute="create user 'cdash'@'localhost' identified by '${mysql_pass}';"
#       mysql -u root -p --execute="grant all privileges on cdash.* to 'cdash'@'localhost' with grant option;"
#

echo "-- Create MySQL database for CDash ..."
echo ""
echo "--> using the following commands:"
echo "-------------------------------------------------"
echo "  create database cdash;"
echo "  create user 'cdash'@'localhost' identified by '<password>';"
echo "  grant all privileges on cdash.* to 'cdash'@'localhost' with grant option;"
echo "-------------------------------------------------"
echo ""

mysql -u root -p --execute="create database cdash;"
mysql -u root -p --execute="create user 'cdash'@'localhost' identified by '${mysql_pass}';"
mysql -u root -p --execute="grant all privileges on cdash.* to 'cdash'@'localhost' with grant option;"

# -----------------------------------------------------------------------------
#  Configuration of apache

echo "-- Restarting Apache server ..."

service apache2 restart

echo ""
echo "-------------------------------------------------"
echo " To complete install: go to http://localhost/CDash/install.php "
echo "-------------------------------------------------"
echo ""
