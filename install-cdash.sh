#!/bin/bash

#  DESCRIPTION
#
#    This script is intended to handle the installation of a CDash test server on a
#    Fedora/Debian/Ubuntu based platform. Package dependencies - CDash is operating
#    on top of a commonly used LAMP stack - are resolved primarily via the system's
#    package manager (apt/dnf/yum), while CDash itself is taken from the project's
#    code repository as hosted on Github [5].
#
#  REFERENCES
#
#  [1] https://cmake.org/Wiki/CDash:Administration
#  [2] https://cmake.org/Wiki/CDash:Upgrade
#  [3] https://nodejs.org/en/download/package-manager/#debian-and-ubuntu-based-linux-distributions
#  [4] https://wiki.debian.org/MySql
#  [5] https://github.com/Kitware/CDash.git

# ========================================================================================
#
#  Variables
#
# ========================================================================================

mysql_pass=""

# Git branch of CDash repo to use for installation
CDASH_VERSION=master

# Installation prefix for CDash (INSTALL_PREFIX/CDash)
INSTALL_PREFIX=/var/www

#
# --- do not edit below this point! ------------------------------------------------------
#

# Installation location of CDash (as part of the webserver directory)
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
#
#  In order to support installation of multiple platforms we need to perform a system
#  introspection first in order to determine operating system name and version. The
#  variables 'OS_NAME'  and 'OS_VERSION' then can be use later on for branching into
#  platform-specific installation/configuration instructions.

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
#
#  In order to be consistent across our target platforms we directly retrieve Node.js
#  from the project itself.

install_nodejs ()
{
    case ${OS_NAME} in
        "debian"|"ubuntu")
            curl -sL https://deb.nodesource.com/setup_9.x | bash -
            apt-get install -y nodejs
            ;;
        "fedora")
            curl --silent --location https://rpm.nodesource.com/setup_9.x | bash -
            dnf -y install nodejs
            ;;
    esac
}

#_________________________________________________________________________________________
#  Installation of system packages
#
#  Basic components of the actual LAMP steck can be installed through the system's
#  package manager (apt, yum, dnf). Major distinction is between RPM- and DEB-based
#  systems. If necessary we distinguish between release versions of a given OS since
#  package names might change.

install_system_packages ()
{
    echo "-- Installing of system packages ..."

    case ${OS_NAME} in
        # --- Debian/GNU Linux ----------------------------
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
        # --- Fedora --------------------------------------
        "fedora")
            echo "--> Updating Fedora base system ..."
            dnf -y update
            ;;
        # --- Ubuntu --------------------------------------
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
                    apt-get install -y php5 php5-xsl php5-curl php5-gd php5-mysql mysql-server-5.5
                    ;;
                *)
                    apt-get install -y php php-xsl php-curl php-gd php-mysql mysql-server
                    ;;
            esac
            ;;
        # -------------------------------------------------
    esac

    echo "-- Installing additional packages ... done"
}

#_________________________________________________________________________________________
#  Installation of CDash server
#
#  This function performs the installation of the actual CDash server from the source code
#  hosted on Github.

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

    cd ${CDASH_PREFIX}
    echo "--> Creating symbolic link to web application root directory ..."
    ln -s ${CDASH_PREFIX}/public ${INSTALL_PREFIX}/html/CDash
    echo "--> Changing permissions to application folder ..."
    mkdir -p node_modules
    chown www-data backup log public/rss public/upload node_modules
    chmod a+rwx backup log public/rss public/upload node_modules
    echo "--> Creating symbolic link to web application root directory ... done"

    echo "--> Install PHP modules ..."
    cd ${CDASH_PREFIX}
    curl -sS https://getcomposer.org/installer | php
    php composer.phar install --no-dev --optimize-autoloader
    echo "--> Install PHP modules ... done"

    echo "--> Install Node modules ..."
    cd ${CDASH_PREFIX}
    npm install
    node_modules/.bin/gulp
    echo "--> Install Node modules ... done"

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

    echo "-- Install CDash ... done"
}

#_________________________________________________________________________________________
#  Configure MySQL database for CDash

configure_mysql ()
{
    echo "-- Create MySQL database for CDash ..."

    # --- Generate batch file with set of commands to run on the MySQL database
    echo ""                                                                           > configure_mysql.sql
    echo "create database cdash;"                                                    >> configure_mysql.sql
    echo "create user 'cdash'@'localhost' identified by '${mysql_pass}';"            >> configure_mysql.sql
    echo "grant all privileges on cdash.* to 'cdash'@'localhost' with grant option;" >> configure_mysql.sql
    echo "exit"                                                                      >> configure_mysql.sql

    # --- Run the previously created set of instructions on the database
    mysql -u root -p${mysql_pass} < configure_mysql.sql

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
