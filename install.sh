#!/bin/bash
# ----------------------------------------------------------------------------------------
# (c) Lars Baehren <lbaehren@gmail.com> (2017).
# All Rights Reserved.
# This software is distributed under the BSD 2-clause license.
# ----------------------------------------------------------------------------------------

cmd_dnf="dnf install --allowerasing -y"

## === Determine OS ======================================================================

varOS=""

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

## =======================================================================================
##
##  Functions
##
## =======================================================================================

#_________________________________________________________________________________________
#  Install development packages

install_packages_devel ()
{
    echo "-- Installing development packages ..."
    case ${varOS} in
        "fedora")
            ${cmd_dnf} \
                cppcheck \
                clang \
                cmake \
                curl \
                docker \
                gcc-gfortran \
                git \
                intltool \
                readline-devel \
                ruby-devel
            ;;
        "ubuntu")
            sudo apt-get install -y \
                cppcheck \
                clang \
                cmake \
                curl \
                docker \
                gfortran \
                git \
                intltool \
                libreadline-dev \
                ruby-dev
            ;;
    esac

    # Configure Git
    git config --global user.name "Lars Baehren"
    git config --global user.email lbaehren@gmail.com

    echo "-- Installing development packages ... done"
}

#_________________________________________________________________________________________
#  Install multimedia packages (audio, video, imaging)

install_packages_multimedia ()
{
    echo "-- Installing multimedia packages ..."

    case ${varOS} in
        "fedora")
            ${cmd_dnf} \
                calibre \
                darktable \
                inkscape \
                luminance-hdr \
                rawtherapee
            ;;
        "ubuntu")
            sudo apt-get install -y \
                calibre \
                darktable \
                inkscape \
                luminance-hdr \
                rawtherapee
            ;;
    esac

    echo "-- Installing multimedia packages ... done"
}

install_packages ()
{
    install_packages_devel
    install_packages_multimedia

    install_timew
}

#_______________________________________________________________________________
#  Create SSH key (e.g. for remote login)

configure_ssh ()
{
  cd
  mkdir .ssh
  cd .ssh
  ssh-keygen -t rsa -b 4096 -C lbaehren@gmail.com
}

#_______________________________________________________________________________
#  Install 'fwbackups' backup utility

install_fwbackups ()
{
    # install required packages
    case ${varOS} in
        "fedora")
            ${cmd_dnf} autogen automake gettext intltool cron
            ;;
        "ubuntu")
            sudo apt-get install -y gettext autotools-dev python-crypto python-paramiko python-gtk2 python-glade2 python-notify cron
            ;;
    esac

    # get packages sources
    cd
    mkdir -p CodeDevelopment/Projects/OpenSource && cd CodeDevelopment/Projects/OpenSource

    # check out new copy or update existing copy
    if test -d fwbackups ; then
      cd fwbackups
      git pull
    else
      git clone git://github.com/firewing1/fwbackups.git
      cd fwbackups
    fi

    # configure, build and install the software
    ./autogen.sh && ./configure --prefix=/usr/local && make && sudo make install
}

install_timew ()
{
    basedir=`pwd`
    wget -c https://taskwarrior.org/download/timew-1.0.0.tar.gz
    tar -xvzf timew-1.0.0.tar.gz
    cd timew-1.0.0
    mkdir build && cd build
    cmake -DCMAKE_INSTALL_PREFIX=/usr/local .. && make -j2 && make install

    cd ${basedir} && rm -rf timew-1.0.*
}

#_______________________________________________________________________________
#  Install 'pwsafe' password store

install_pwsafe ()
{
    cd
    mkdir -p CodeDevelopment/Projects/Private && cd CodeDevelopment/Projects/Private
    git clone git@github.com:lbaehren/pwsafe.git && cd pwsafe
    git checkout cmake
    mkdir build && cd build
    cmake -DCMAKE_INSTALL_PREFIX=/usr/local .. && make && sudo make install
}

install_fedora ()
{
    echo "-- Installing system packages for Fedora Linux ..."
    dnf update -y
    ${cmd_dnf} \
        autogen \
        davfs2 \
        graphviz \
        hfsplusutils \
        htop \
        libtool \
        okular \
        pwsafe \
        task \
        texlive
    echo "-- Installing system packages for Fedora Linux ... done"
}

## Install packages for Ubuntu
install_ubuntu ()
{
    sudo add-apt-repository ppa:webupd8team/atom
    sudo apt-get update --fix-missing
    sudo apt-get dist-upgrade -y
    sudo apt-get install -y \
      atom \
      hfsprogs \
      htop \
      imagemagick \
      jekyll \
      libssl-dev \
      okular \
      qtpfsgui \
      taskwarrior \
      texlive-full \
      vlc
    sudo apt autoremove
}

## =======================================================================================
##
##  Script main
##
## =======================================================================================

case ${varOS} in
    "fedora")
        install_fedora
        ;;
    "ubuntu")
        install_ubuntu
        ;;
    *)
        echo "Unsupported OS."
        ;;
esac

install_packages
# install_fwbackups
