#!/bin/bash

#_______________________________________________________________________________
#  Configure Git

configure_git ()
{
  git config --global user.name "Lars Baehren"
  git config --global user.email lbaehren@gmail.com
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

install_fwbackups ()
{
    # install required packages
    sudo apt-get install -y gettext autotools-dev intltool python-crypto python-paramiko python-gtk2 python-glade2 python-notify cron
    
    # get packages sources
    cd
    mkdir -p CodeDevelopment/Projects/OpenSource && cd CodeDevelopment/Projects/OpenSource
    git clone git://github.com/firewing1/fwbackups.git
    cd fwbackups
    ./configure --prefix=/usr/local && make && sudo make install
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

#_______________________________________________________________________________
#  Install packages via system's package manager

sudo add-apt-repository ppa:webupd8team/atom
sudo apt-get update --fix-missing
sudo apt-get dist-upgrade -y
sudo apt-get install -y \
  atom \
  bacula \
  cmake \
  clang \
  calibre\
  darktable \
  git \
  hfsprogs \
  htop \
  inkscape \
  imagemagick \
  jekyll \
  libreadline-dev \
  libssl-dev \
  okular \
  taskwarrior \
  texlive-full \
  vlc
