#-----------------------------------------------------------------------------------------
# (c) Lars Baehren <lbaehren@gmail.com> (2017). All Rights Reserved.
# This software is distributed under the BSD 2-clause license.
#-----------------------------------------------------------------------------------------

## === Variables =========================================================================

varUserID=`id -u`
varUserName=`whoami`
varPlatform=`uname | tr "[A-Z]" "[a-z]"`
varBasedir=`pwd`
varOS=`cat /etc/os-release | grep NAME | grep -v PRETTY | grep -v CODENAME | grep -v CPE_NAME | tr "=" "\n" | grep -v NAME | tr "[A-Z]" "[a-z]"`
varKernelRelease=`uname -r`
varKernelVersion=`uname -v`

## Backup configuration
varSourceDir=/home/${varUserName}
varTimestamp=`date +%Y%m%d-%H%M%S`
varSnapshot=${varUserName}-${varTimestamp}.tar.bzip2

cmdRsync=rsync -axuzP --delete --exclude Videos --exclude .DS_Store

.SILENT: get_os backup_drobo1 backup_usb1 backup_usb2 install_timew

##________________________________________________________________________________________
##  Determine OS

get_os:
	if test -f /etc/os-release ; then \
		echo "--> Parsing /etc/os-release ..." ; \
	    varName=`cat /etc/os-release | grep NAME | grep -v PRETTY | grep -v CODENAME | grep -v CPE_NAME` ; \
	    if test `echo $$varName | grep Ubuntu` ; then \
	        varOS="ubuntu" ; \
	    elif test `echo $$varName | grep Fedora` ; then \
	        varOS="fedora" ; \
	    fi ; \
	elif test -f /etc/debian_version ; then \
	    varOS="ubuntu" ; \
	elif test -f /etc/fedora-release ; then \
	    varOS="fedora" ; \
	elif test -f /etc/SuSE-release ; then \
	    varOS="opensuse" ; \
	fi

##________________________________________________________________________________________
##  Show list of available targets

help:
	@echo "The following are valid targets for this Makefile:"
	@echo " backup          --  Backup of home directory onto external media"
	@echo " backup_drobo1   --  Backup of home directory onto 'Drobo 1'"
	@echo " backup_usb1     --  Backup of home directory onto 'Toshiba 1TB' external drive"
	@echo " backup_usb2     --  Backup of home directory onto 'Maxtor 2TB' external drive"
	@echo " install_pwsafe  --  Install 'pwsafe' password store from source"
	@echo " install_timew   --  Install 'timew' time-tracking tool from source"

## =======================================================================================
##
##  Backup
##
## =======================================================================================

##________________________________________________________________________________________
##  Backup home directory

backup: backup_drobo1 backup_usb1 backup_usb2

##________________________________________________________________________________________
##  Backup to 'Drobo Gen 1'

backup_drobo1:
	varTarget="/run/media/${varUserName}/Drobo Gen 1/Backups/${varOS}" ; \
	if [ -d "$$varTarget" ] ; then \
		echo "--> Found 'Drobo Gen 1' - starting backup of ${varSourceDir} ..." ; \
		cd "$$varTarget" ; \
		${cmdRsync} ${varSourceDir} . ; \
		echo "--> Creating archive '${varSnapshot}' from current snapshot ..." ; \
		time tar --exclude=Videos --exclude=Music -cjf ${varSnapshot} ${varSourceDir} ; \
		echo "--> Creating archive '${varSnapshot}' from current snapshot ... done" ; \
	fi

##________________________________________________________________________________________
##  Backup to 'Toshiba 1TB' external USB drive

backup_usb1:
	varTarget="/run/media/${varUserName}/Toshiba1TB/Backups/${varOS}" ; \
	if [ -d "$$varTarget" ] ; then \
		echo "--> Found 'Toshiba1TB' - starting backup of ${varSourceDir} ..." ; \
		cd "$$varTarget" ; \
		${cmdRsync} ${varSourceDir} . ; \
		echo "--> Creating archive '${varSnapshot}' from current snapshot ..." ; \
		time tar --exclude=Videos --exclude=Music -cjf ${varSnapshot} ${varSourceDir} ; \
		echo "--> Creating archive '${varSnapshot}' from current snapshot ... done" ; \
	fi

##________________________________________________________________________________________
##  Backup to 'Matrox 2TB' external USB drive

backup_usb2:
	varTarget="/run/media/${varUserName}/Maxtor2TB/Backups/${varOS}" ; \
	if [ -d "$$varTarget" ] ; then \
		echo "--> Found 'Maxtor2TB' - starting backup of ${varSourceDir} ..." ; \
		cd "$$varTarget" ; \
		${cmdRsync} ${varSourceDir} . ; \
		echo "--> Creating archive '${varSnapshot}' from current snapshot ..." ; \
		time tar --exclude=Videos --exclude=Music --exclude=*.vdi -cjf ${varSnapshot} ${varSourceDir} ; \
		echo "--> Creating archive '${varSnapshot}' from current snapshot ... done" ; \
	fi

## =======================================================================================
##
##  Installation instructions
##
## =======================================================================================

install: install_timew install_pwsafe

#_________________________________________________________________________________________
#  Install 'pwsafe' password store

install_pwsafe:
	cd ${varBasedir} && \
    git clone git@github.com:lbaehren/pwsafe.git && \
    cd pwsafe && \
	git checkout cmake && \
    mkdir build && \
	cd build && \
    cmake -DCMAKE_INSTALL_PREFIX=/usr/local .. && \
	make && \
	make install && \
	cd ${varBasedir} && \
    rm -rf pwsafe

#_________________________________________________________________________________________
#  Install TimeWarrior time tracking tool

install_timew:
	cd ${varBasedir} && \
    wget -c https://taskwarrior.org/download/timew-1.0.0.tar.gz ; \
    tar -xvzf timew-1.0.0.tar.gz && \
    cd timew-1.0.0 && \
    mkdir build && \
	cd build && \
    cmake -DCMAKE_INSTALL_PREFIX=/usr/local .. && \
	make -j2 && \
	make install && \
	cd ${varBasedir} && \
    rm -rf timew-1.0.*
