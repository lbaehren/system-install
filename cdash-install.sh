#!/bin/bash

#  References
#
#  [1] https://cmake.org/Wiki/CDash:Administration
#  [2] https://cmake.org/Wiki/CDash:Upgrade
#  [3] https://nodejs.org/en/download/package-manager/#debian-and-ubuntu-based-linux-distributions
#  [4] https://wiki.debian.org/MySql

# ========================================================================================
#
#  Variables
#
# ========================================================================================

# TODO: set password for MySQL database
mysql_pass=""
CDASH_VERSION=master

# Installation location of CDash (as part of the webserver directory)
INSTALL_PREFIX=/var/www
CDASH_PREFIX=${INSTALL_PREFIX}/CDash
OS_NAME=""
OS_VERSION=""

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
        varName=`cat /etc/os-release | grep NAME | grep -v PRETTY | sed s/\"//g`
        # check for Ubuntu
        if [[ ${varName} =~ .*Ubuntu.* ]]
        then
            OS_NAME="ubuntu"
        fi
        # check for Debian
        if [[ ${varName} =~ .*Debian.* ]]
        then
            OS_NAME="debian"
        fi
        # check for Fedora
        if [[ ${varName} =~ .*Fedora.* ]]
        then
            OS_NAME="fedora"
        fi
    fi

    if [[ ${OS_NAME} == "" ]] ; then
        # check for Debian
        if test -f /etc/debian_version ; then
            OS_NAME="debian"
            OS_VERSION=`cat /etc/debian_version`
        fi
        # check for Fedora
        if test -f /etc/fedora-release ; then
          OS_NAME="fedora"
        fi
        # check for OpenSuSE
        if test -f /etc/SuSE-release ; then
            OS_NAME="opensuse"
        fi
    fi

    if [[ ${OS_VERSION} == "" ]] ; then
        case ${OS_NAME} in
            "debian")
                OS_VERSION=`cat /etc/os-release | grep VERSION_ID | tr '=' '\n' | sed s/\"//g | grep [0-9]`
                ;;
            "fedora")
                OS_VERSION=`cat /etc/os-release | grep VERSION_ID | tr '=' '\n' | grep [0-9]`
                ;;
            "ubuntu")
                OS_VERSION=`cat /etc/os-release | grep VERSION_ID | tr '""' '\n' | grep [0-9]`
                ;;
        esac
    fi
}

#_________________________________________________________________________________________
#  Installation of MySQL server

install_mysql ()
{
    echo "--> Installing MySQl server system package ..."

    apt-get install -y mysql-server

    echo "--> Stopping MqSQL service ..."

    service mysql stop

    echo "--> create 'init' file to be used as input ..."

    echo "UPDATE mysql.user SET Password=PASSWORD('${mysql_pass}') WHERE User='root';" > mysql-init
    echo "FLUSH PRIVILEGES;" >> mysql-init
    mysqld_safe --init-file=mysql-init --nowatch

    # clean up
    rm mysql-init

    echo "--> Restarting MySQL service ..."
    service mysql start
}

#_________________________________________________________________________________________
#  Installation of Node.js

install_nodejs ()
{
    curl -sL https://deb.nodesource.com/setup_9.x | bash -
    apt-get install -y nodejs
}

#_________________________________________________________________________________________
#   Installation of system packages

install_system_packages ()
{
    echo "-- Installing of system packages ..."

    case ${OS_NAME} in
        "debian")
            echo "--> Updating Debian base system ..."
            apt-get update --fix-missing
            apt-get dist-upgrade -y
            apt-get install -y apt-utils
            echo "--> Installing development tools ..."
            apt-get install -y cmake curl git gcc g++ nano net-tools
            echo "--> Installing Webserver(-modules) ..."
            apt-get install -y apache2 libapache2-mod-php
            echo "--> Installing MySQL database server ..."
            install_mysql
            echo "--> Installing Node.js ..."
            install_nodejs
            echo "--> Installing PHP modules ..."
            apt-get install -y php php-dev
            apt-get install -y php-xmlrpc php-bcmath php-mbstring php-xdebug php-xsl php-curl php-gd php-mysql
            ;;
        "fedora")
            echo "--> Updating Fedora base system ..."
            dnf -y update
            ;;
        "ubuntu")
            echo "--> Updating Ubuntu base system ..."
            apt-get update --fix-missing
            apt-get dist-upgrade -y
            apt-get install -y apt-utils
            echo "--> Installing development tools ..."
            apt-get install -y cmake curl git gcc g++ nano net-tools
            echo "--> Installing Webserver(-modules) ..."
            apt-get install -y apache2 libapache2-mod-php
            echo "--> Installing Node.js ..."
            install_nodejs
            echo "--> Installing PHP modules ..."
            apt-get install -y php-dev php-xmlrpc php-bcmath php-mbstring php-xdebug
            case ${OS_VERSION} in
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
    git checkout ${CDASH_VERSION}

    if [ "${CDASH_VERSION}" != "master" ]; then
        git checkout -b ${CDASH_VERSION}
    fi

    echo "--> Install PHP modules ..."
    cd ${CDASH_PREFIX}
    curl -sS https://getcomposer.org/installer | php
    php composer.phar install --no-dev --optimize-autoloader

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
    mkdir node_modules
    chown www-data backup log public/rss public/upload node_modules
    chmod a+rwx backup log public/rss public/upload node_modules

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

    mysql -u root -p${mysql_pass} --execute="create database cdash; create user 'cdash'@'localhost' identified by '${mysql_pass}'; grant all privileges on cdash.* to 'cdash'@'localhost' with grant option; QUIT;"

    # echo "--> running SQL command: > create database cdash;"
    # mysql -u root -p --execute="create database cdash;"
    #
    # echo "--> running SQL command: > create user 'cdash'@'localhost' identified by '<password>';"
    # mysql -u root -p --execute="create user 'cdash'@'localhost' identified by '${mysql_pass}';"
    #
    # echo "--> running SQL command: > grant all privileges on cdash.* to 'cdash'@'localhost' with grant option;"
    # mysql -u root -p --execute="grant all privileges on cdash.* to 'cdash'@'localhost' with grant option;"

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
