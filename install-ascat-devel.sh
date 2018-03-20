#-----------------------------------------------------------------------------------------
# MetTools - A Collection of Software for Meteorology and Remote Sensing
# Copyright (C) 2017  EUMETSAT
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#-----------------------------------------------------------------------------------------

## =======================================================================================
##
##  Global variables and definitions
##
## =======================================================================================

cmd_curl="curl -k -L"
cmd_tar="tar -xzf"

INSTALL_PREFIX=/opt/local
METTOOLS_PREFIX=/opt/mettools

## =======================================================================================
##
##  System inspection
##
## =======================================================================================

osName=""
osCPE_NAME=""
osVersion=""

if [[ -f /etc/os-release ]] ; then
    osName=`grep NAME /etc/os-release | grep -v _NAME | tr "=" "\n" | grep [a-z]`
    osCPE_NAME=`grep CPE_NAME /etc/os-release | tr '"' '\n' | grep cpe`
    osVersion=`echo ${osCPE_NAME} | tr ":" "\n" | grep [0-9]`
else
    if [[ -f /etc/system-release-cpe ]] ; then
        osCPE_NAME=`cat /etc/system-release-cpe`
    fi
    if [[ -f /etc/system-release ]] ; then
        osName=`cat /etc/system-release | tr " " "\n" | head -n 1`
        osVersion=`cat /etc/system-release | tr " " "\n" | grep [0-9]`
    fi
fi

echo "------------------------------------------------------------"
echo " Configuration summary"
echo ""
echo " - OS name      : ${osName}"
echo " - OS CPE_NAME  : ${osCPE_NAME}"
echo " - OS version   : ${osVersion}"
echo " - Curl command : '${cmd_curl}'"
echo " - Tar command  : '${cmd_tar}'"
echo "------------------------------------------------------------"

## =======================================================================================
##
##  Package installation using package manager
##
## =======================================================================================

#-----------------------------------------------------------------------------------------
#  CentOS
#-----------------------------------------------------------------------------------------

install_packages_centos ()
{
    yum install -y deltarpm nano net-tools yum-skip-broken
    yum groupinstall -y --skip-broken "Development tools"
    # --- specific development packages ---
    yum install -y bzip2
    yum install -y compat-libf2c-34.i686
    yum install -y curl
    yum install -y doxygen
    yum install -y expat-devel expat-devel.i686
    yum install -y fftw-devel fftw-devel.i686
    yum install -y gcc gcc-c++ gcc-fortran
    yum install -y git
    yum install -y glibc-devel glibc-devel.i686
    yum install -y graphviz
    yum install -y grep
    yum install -y kexec-tools
    yum install -y ksh
    yum install -y libaio
    yum install -y libdb-4_8-devel
    yum install -y libgfortran
    yum install -y libstdc++.i686
    yum install -y libX11-devel
    yum install -y libxml2 libxml2-devel
    yum install -y ncurses-devel
    yum install -y openssh openssl
    yum install -y patch
    yum install -y sed
    yum install -y sqlite-devel
    yum install -y tar
    yum install -y texinfo
    yum install -y valgrind valgrind.i686
    yum install -y which
    yum install -y xerces-c.i686 xerces-c-devel.i686
    yum install -y zlib zlib.i686

    case ${osVersion} in
        "7")
            yum install -y hostname
            yum install -y libstdc++-static.i686
            ;;
    esac

    echo "-- Create missing symbolic links ..."
    ln -sf /usr/lib/libg2c.so.0 /usr/lib/libg2c.so
    echo "-- Create missing symbolic links ... done"
}

#-----------------------------------------------------------------------------------------
#  Fedora
#-----------------------------------------------------------------------------------------

install_packages_fedora ()
{
    echo "Nothing to do yet!"
}

#-----------------------------------------------------------------------------------------
#  openSUSE
#-----------------------------------------------------------------------------------------

install_packages_opensuse ()
{
    zypper -n update
    zypper install deltarpm nano net-tools
    zypper install -t pattern devel_C_C++
    # --- specific development packages ---
    for NAME in  \
        bzip2  \
        compat-32bit  \
        curl  \
        doxygen  \
        libexpat-devel  \
        libexpat-devel-32bit  \
        fftw3-devel  \
        libfftw3-3-32bit \
        f2c-32bit  \
        gcc  \
        gcc-c++  \
        gcc-fortran  \
        git  \
        glibc-devel  \
        glibc-devel-32bit \
        graphviz  \
        grep  \
        kexec-tools  \
        ksh  \
        libaio  \
        libdb-4_8-devel  \
        libgfortran3  \
        libgfortran3-32bit  \
        libstdc++-devel  \
        libstdc++-devel-32bit  \
        libX11-devel  \
        libxml2  \
        libxml2-devel  \
        ncurses-devel  \
        openssh  \
        openssl  \
        patch  \
        sed  \
        sqlite-devel  \
        tar  \
        texinfo  \
        valgrind  \
        which  \
        libxerces-c-devel  \
        libxerces-c-3_1-32bit  \
        zlib-devel  \
        zlib-devel-32bit
    {
        zypper install ${NAME}
    }
}

## =======================================================================================
##
##  Package installation functions
##
## =======================================================================================

#-----------------------------------------------------------------------------------------
#  CMake
#-----------------------------------------------------------------------------------------

install_cmake ()
{
    cmakeVersion=3.9.2

    echo "[install.sh] Installing CMake v${cmakeVersion} ..."

    cd /tmp && \
    ${cmd_curl} https://cmake.org/files/v3.9/cmake-${cmakeVersion}.tar.gz> cmake-${cmakeVersion}.tar.gz && \
    ${cmd_tar} cmake-${cmakeVersion}.tar.gz && \
    cd cmake-${cmakeVersion} && \
    ./bootstrap --prefix=${INSTALL_PREFIX} && \
    cat CMakeCache.txt | sed s/"libncurses.a"/"libcurses.a"/ > CMakeCache.tmp && mv CMakeCache.tmp CMakeCache.txt &&\
    make -j2 && \
    make install

    #  post-installation clean-up
    cd /tmp
    rm -rf cmake-${cmakeVersion}*

    # Add PATH
    export PATH=${INSTALL_PREFIX}/bin:$PATH

    echo "[install.sh] Installing CMake v${cmakeVersion} ... done"
}

#-----------------------------------------------------------------------------------------
#  Boost C++ libraries
#-----------------------------------------------------------------------------------------

install_boost ()
{
    boostMinorVersion=58
    boostVersion=1.${boostMinorVersion}.0
    boostArchive=boost_1_${boostMinorVersion}_0.tar.gz
    boostLibraries="regex,system,thread,test"

    cd /tmp

    if [[ -f ${boostArchive} ]] ; then
        # we might have a local copy because sourceforge at times can be rather slow
        echo "[install.sh] Found Boost source archive ${boostArchive}"
    else
        echo "[install.sh] Downloading Boost source archive ..."
        ${cmd_curl} https://sourceforge.net/projects/boost/files/boost/${boostVersion}/${boostArchive} > ${boostArchive}
    fi
    echo "[install.sh] Unpacking Boost source archive ..." && \
    ${cmd_tar} ${boostArchive} && \
    cd boost_1_${boostMinorVersion}_0 && \
    echo "[install.sh] Bootstrapping Boost sources for build ..." && \
    ./bootstrap.sh --with-libraries=${boostLibraries} --prefix=${INSTALL_PREFIX} && \
    echo "[install.sh] Building Boost libraries ..." && \
    ./b2 threading=multi --prefix=${INSTALL_PREFIX} address-model=32 architecture=x86 install && \
    echo "[install.sh] Installation of Boost complete."

    #  post-installation clean-up
    cd /tmp
    rm -rf boost_1_${boostMinorVersion}_0*
}

#-----------------------------------------------------------------------------------------
#  GNU Scientific Library (GSL)
#-----------------------------------------------------------------------------------------

install_gsl ()
{
    gslVersion=1.16

    cd /tmp

    echo "[install.sh] Downloading GSL source archive ..." && \
    ${cmd_curl} "ftp://208.118.235.20/gnu/gsl/gsl-${gslVersion}.tar.gz" > gsl-${gslVersion}.tar.gz && \
    echo "[install.sh] Unpacking GSL archive ..." && \
    ${cmd_tar} gsl-${gslVersion}.tar.gz && \
    cd gsl-${gslVersion}

    export CFLAGS="-m32 -g -O2 -lstdc++"
    ./configure --prefix=${INSTALL_PREFIX} && \
    make -j2 MAKEINFO=true && \
    make install

    echo "[install.sh] Installation of GSL complete."

    #  post-installation clean-up
    cd /tmp
    rm -rf gsl-${gslVersion}*
}

## =======================================================================================
##
##  Script main
##
## =======================================================================================

#-----------------------------------------------------------------------------------------
#  Installation of system packages
#-----------------------------------------------------------------------------------------

echo "[install.sh] Installing system packages ..."

case ${osName} in
    "CentOS Linux"|"CentOS")
        install_packages_centos
        ;;
    "Fedora")
        install_packages_fedora
        ;;
    "openSUSE")
        install_packages_opensuse
        ;;
esac

echo "[install.sh] Installing system packages ... done"

#-----------------------------------------------------------------------------------------
#  Custom installation of additional packages
#-----------------------------------------------------------------------------------------

install_cmake
install_boost
install_gsl
