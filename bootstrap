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

# drobo-utils.noarch     : Utilities for managing Drobo storage systems
# drobo-utils-gui.noarch : GUI utilities for managing Drobo storage systems

install_packages ()
{
    install_packages_devel
    install_packages_multimedia

    make install_pwsafe
    make install_timew
    install_texlive
}

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
                gitk \
                intltool \
                nano \
                readline-devel \
                ruby-devel \
                vagrant
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
                gitk \
                intltool \
                libreadline-dev \
                nano \
                ruby-dev \
                vagrant
            ;;
    esac

    # Configure Git
    git config --global user.name "Lars Baehren"
    git config --global user.email lbaehren@gmail.com
    git config --global core.editor "nano"

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
                gimp \
                inkscape \
                luminance-hdr \
                rawtherapee
            ;;
        "ubuntu")
            sudo apt-get install -y \
                calibre \
                darktable \
                gimp \
                inkscape \
                luminance-hdr \
                rawtherapee
            ;;
    esac

    echo "-- Installing multimedia packages ... done"
}

#_________________________________________________________________________________________
#  Create SSH key (e.g. for remote login)

configure_ssh ()
{
  cd
  mkdir .ssh
  cd .ssh
  ssh-keygen -t rsa -b 4096 -C lbaehren@gmail.com
}

#_________________________________________________________________________________________
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

#_________________________________________________________________________________________
#  Install TexLive

install_texlive ()
{
    varYear=`date =%Y`

    wget -c http://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz
    tar -xvzf install-tl-unx.tar.gz
    cd install-tl-${varYear}* && ./install-tl

}

#_________________________________________________________________________________________
#  Install packages for Fedora

install_fedora ()
{
    dnf config-manager --add-repo=http://negativo17.org/repos/fedora-multimedia.repo

    echo "-- Installing system packages for Fedora ..."

    dnf update -y
    ${cmd_dnf} \
        autogen \
        davfs2 \
        drobo-utils \
        drobo-utils-gui \
        graphviz \
        hfsplusutils \
        htop \
        libtool \
        okular \
        openssl-devel \
        simple-mtpfs \
        task \
        texlive

    echo "-- Installing system packages for Fedora ... done"
}

#_________________________________________________________________________________________
#  Install packages for Ubuntu

install_ubuntu ()
{
    echo "-- Installing system packages for Ubuntu ..."

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
      openssl-dev \
      qtpfsgui \
      taskwarrior \
      texlive-full \
      vlc
    sudo apt autoremove

    echo "-- Installing system packages for Ubuntu ... done"
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
