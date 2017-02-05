# system-install

Collection of notes and scripts for the installation of a new system

## Packages to install

| Name        | Description                        |
|-------------|------------------------------------|
| Atom        | Hackable editor                    |
| CMake       | Cross-platform configuration tool  |
| Calibre     | eBook management tool              |
| Darktable   | Raw images processor               |
| Git         | Distributed version control system |
| Clang       | C/C++ frontend to LLVM framework   |
| pwsafe      | Pasword store                  |
| VLC         | Multimedia player              |
| hfsprogs    | HFS/HFS+ tools                 |
| Jekyll      | Static website generator       |
| TeXLive     | Complete package for TeX/LaTeX |
| Inkscape    |  |
| Imagemagick |  |
| Okular      | Universal document viewer |
| RawTherapee | Raw image converter and digital photo processor |
| Luminance HDR |
| Taskwarrior |  |

## Installation of packages

### ... on Ubuntu Linux

~~~~ bash
sudo add-apt-repository ppa:webupd8team/atom
sudo apt-get update --fix-missing
sudo apt-get install -y atom
sudo apt-get install -y cmake clang calibre
sudo apt-get install -y darktable
sudo apt-get install -y git
sudo apt-get install -y hfsprogs
sudo apt-get install -y inkscape imagemagick
sudo apt-get install -y jekyll
sudo apt-get install -y luminance-hdr rawtherapee qtpfsgui
sudo apt-get install -y okular
sudo apt-get install -y taskwarrior texlive-full
sudo apt-get install -y vlc
~~~~

## Configuration

Configure Git:

~~~~ bash
git config --global user.name "Lars Baehren"
git config --global user.email lbaehren@gmail.com
~~~~

Create SSH key:

~~~~ bash
cd
mkdir .ssh
cd .ssh
ssh-keygen -t rsa -b 4096 -C lbaehren@gmail.com
~~~~
