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

install_pwsafe ()
{
    cd
    mkdir -p CodeDevelopment/Projects/Private && cd CodeDevelopment/Projects/Private
    git clone git@github.com:lbaehren/pwsafe.git && cd pwsafe
    git checkout cmake
    mkdir build && cd build
    cmake .. && make
}

#_______________________________________________________________________________
#  Install packages via system's package manager

sudo add-apt-repository ppa:webupd8team/atom
sudo apt-get update --fix-missing
sudo apt-get install -y \
  atom \
  cmake \
  clang \
  calibre\
  darktable \
  git \
  hfsprogs \
  inkscape \
  imagemagick \
  jekyll \
  libreadline-dev \
  okular \
  taskwarrior \
  texlive-full \
  vlc
