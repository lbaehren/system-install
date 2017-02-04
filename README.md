# system-install

Collection of notes and scripts for the installation of a new system

## Packages to install

 - Git
 - CMake
 - Clang / LLVM
 - Atom Editor
 - Calibre
 - pwsafe
 - Darktable
 - VLC
 - HFS/HFS+ tools
 - Jekyll static website generator
 - TeXLive
 - Inkscape
 - Imagemagick
 
## Installation of packages

### ... on Ubuntu Linux

~~~~ bash
sudo add-apt-repository ppa:webupd8team/atom
sudo apt-get update --fix-missing
sudo apt-get install atom cmake git clang calibre darktable vlc hfsprogs texlive-full rubygem-jekyll inkscape imagemagick
~~~~

## Configuration

Configure Git:

~~~~ bash
git config --global user.name "Lars Baehren
git config --global user.email lbaehren@gmail.com
~~~~

Create SSH key:

~~~~ bash
cd
mkdir .ssh
cd .ssh
ssh-keygen -t rsa -b 4096 -C lbaehren@gmail.com
~~~~
