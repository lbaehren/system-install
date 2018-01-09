#!/bin/bash

# ========================================================================================
#
#  Variables
#
# ========================================================================================

# TODO: set password for MySQL database
mysql_pass=""

# Installation location of CDash (as part of the webserver directory)
INSTALL_PREFIX=/var/www
CDASH_PREFIX=${INSTALL_PREFIX}/CDash
varOS=""
varRelease=""

case ${mysql_pass} in
    "")
        echo "[ERROR] MySQL password not set!"
        exit 1;
        ;;
esac

# ========================================================================================
#
#  Functions
#
# ========================================================================================

#_________________________________________________________________________________________
#  Determine OS name and version

check_system ()
{
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
}

#_________________________________________________________________________________________
#   Installation of system packages

install_system_packages ()
{
    echo "-- Installing of system packages ..."

    case ${varOS} in
        "fedora")
            echo "--> Update base system ..."
            dnf -y update
            ;;
        "ubuntu")
            echo "--> Update base system ..."
            apt-get update --fix-missing && \
            apt-get dist-upgrade -y
            echo "--> Installing development tools ..."
            apt-get install -y cmake curl git gcc g++ nano net-tools npm
            echo "--> Installing Webserver(-modules) ..."
            apt-get install -y apache2 libapache2-mod-php
            echo "--> Installing PHP modules ..."
            apt-get install -y php-dev php-xmlrpc php-bcmath php-mbstring php-xdebug
            case ${varRelease} in
                "12.04"|"14.04")
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
}

#_________________________________________________________________________________________
#  Installation of CDash server

install_cdash ()
{
    echo "-- Install CDash ..."

    mkdir -p ${INSTALL_PREFIX}
    cd ${INSTALL_PREFIX}

    echo "--> Cloning repository into local working copy ..."
    git clone https://github.com/Kitware/CDash.git CDash

    echo "--> Check out version to use for install ..."
    cd ${CDASH_PREFIX}
    git checkout v2.4.0
    git checkout -b v2.4.0

    echo "--> Install PHP modules ..."
    cd ${CDASH_PREFIX}
    curl -sS https://getcomposer.org/installer | php
    php composer.phar install

    echo "--> Install Node modules ..."
    cd ${CDASH_PREFIX}
    npm install
    node_modules/.bin/gulp

    echo "--> Running CMake to configure project"
    cd ${CDASH_PREFIX}
    mkdir build && \
    cd build && \
    cmake ..

    echo "--> Creating copy of configuration file for editing ..."
    cd ${CDASH_PREFIX}/config
    cp config.php config.local.php
    echo "--> Opening file 'config.local.php' for editing ..."
    nano config.local.php

    cd ${CDASH_PREFIX}
    echo "--> Creating symbolic link to web application root directory ..."
    ln -s ${CDASH_PREFIX}/public ${INSTALL_PREFIX}/html/CDash
    echo "--> Changing permissions to application folder ..."
    chown www-data backup log public/rss public/upload
    chmod a+rwx backup log public/rss public/upload

    echo "-- Install CDash ... done"
}

#_________________________________________________________________________________________
#  Configure MySQL database for CDash
#
#  Note: Typically the database entry needs to be done by hand; however using
#        the '-e <command>' command line option this should be scriptable as
#        well.
#        [https://dev.mysql.com/doc/refman/5.7/en/command-line-options.html]
#
#        mysql -u root -p --execute="create database cdash;"
#        mysql -u root -p --execute="create user 'cdash'@'localhost' identified by '${mysql_pass}';"
#        mysql -u root -p --execute="grant all privileges on cdash.* to 'cdash'@'localhost' with grant option;"

configure_mysql ()
{
    echo "-- Create MySQL database for CDash ..."

    echo "--> running SQL command: > create database cdash;"
    mysql -u root -p --execute="create database cdash;"

    echo "--> running SQL command: > create user 'cdash'@'localhost' identified by '<password>';"
    mysql -u root -p --execute="create user 'cdash'@'localhost' identified by '${mysql_pass}';"

    echo "--> running SQL command: > grant all privileges on cdash.* to 'cdash'@'localhost' with grant option;"
    mysql -u root -p --execute="grant all privileges on cdash.* to 'cdash'@'localhost' with grant option;"

    echo "-- Create MySQL database for CDash ... done"
}

# ========================================================================================
#
#  Script main
#
# ========================================================================================

check_system
install_system_packages
install_cdash
configure_mysql

# -----------------------------------------------------------------------------
#  Configuration of apache

echo "-- Restarting Apache server ..."
service apache2 restart
echo "-- Restarting Apache server ... done"

echo ""
echo "-------------------------------------------------"
echo " To complete install: go to http://localhost/CDash/install.php "
echo "-------------------------------------------------"
echo ""
