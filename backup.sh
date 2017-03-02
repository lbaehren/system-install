#-----------------------------------------------------------------------------------------
# (c) Lars Baehren <lbaehren@gmail.com> (2017). All Rights Reserved.
# This software is distributed under the BSD 2-clause license.
#-----------------------------------------------------------------------------------------

##________________________________________________________________________________________
##  Determine OS

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

##________________________________________________________________________________________
##

varUser=`whoami`
varSource=/home/${varUser}
varTarget=/run/media/${varUser}/BackupToshiba/Fedora-25
varTimestamp=`date +%Y%m%d-%H%M%S`
varSnapshot=${varUser}-${varOS}-${varTimestamp}.tar.bzip2

## Report configuration

echo "--> Configuration for backup ..."
echo " - Operating system : ${varOS}"
echo " - User name        : ${varUser}"
echo " - Source           : ${varSource}"
echo " - Target           : ${varTarget}"
echo " - Timestamp        : ${varTimestamp}"
echo " - Snapshot file    : ${varSnapshot}"

##________________________________________________________________________________________
##  Mirror contents of home directory

mirror_user_home ()
{
    echo "--> Mirror contents of home directory ..."
    rsync -axuzP --delete --exclude Videos --exclude Music ${varSource} ${varTarget}
    echo "--> Mirror contents of home directory ... done"
}

##________________________________________________________________________________________
##  Create archive from current snapshot

archive_snapshot ()
{
    echo "--> Creating archive '${varSnapshot}' from current snapshot ..."

    # ----------------------------------------------------------------
    # Variant 1 : Run archive creation directly off the source directory (varSource)
    # ----------------------------------------------------------------

    # cd /home
    # time tar -cjf /media/${varUser}/Backup\ Linux/Backup\ Ubuntu/${varSnapshot} ${varUser}

    # ----------------------------------------------------------------
    # Variant 2 : Create compressed archive from previously created snapshot.
    # ----------------------------------------------------------------

    cd ${varTarget}
    time tar -cjf ${varSnapshot} ${varUser}

    echo "--> Creating archive '${varSnapshot}' from current snapshot ... done"
}

# ==============================================================================
#  Step 1 : Mirror the current state of the user home directory onto the backup
#           medium

mirror_user_home

# ==============================================================================
#  Step 2 : Create a compressed, time-stamped archive of the user home directory
#
#  Date/Time         real           user          sys         Size   Comment
#  ---------------   ------------   -----------   ---------   ----   ---------------------
#  20170207-085649     65m15.746s    62m15.640s   0m53.176s     ??   run from source directory
#  20170207-100604     62m00.851s    59m52.056s   0m50.484s    16G   run from source directory
#  20170207-111319     77m32.869s    63m12.600s   0m52.248s    17G   run from backup disk
#  20170207-132156     82m07.583s    64m49.276s   0m56.456s    17G   run from backup disk
#  20170208-101154     75m42.138s    60m18.216s   0m57.764s    17G   run from backup disk
#  20170209-160547    105m32.623s    67m22.432s   1m15.600s    17G   run from backup disk
#  20170210-085405     86m51.969s    68m08.332s   1m02.584s    17G   run from backup disk
#  20170211-182814    191m30.588s   149m53.180s   2m23.620s    42G   run from backup disk
#  20170213-074803    246m48.037s   128m31.676s   2m05.272s    36G   run from backup disk
#  20170213-192732    143m19.795s   123m40.620s   1m44.064s    36G   run from backup disk
#  20170215-011802    148m18.714s   125m41.912s   1m56.704s    36G   run from backup disk
#  20170215-123717    217m48.614s   135m28.764s   3m38.892s    36G   run from backup disk
#  20170216-184941    145m35.027s   122m33.324s   1m38.344s
#  20170218-012446    201m32.736s   154m03.540s   2m08.340s    37G   run from backup disk
#  20170301-214008    256m48.850s   223m57.830s   3m33.418s
#  ---------------   ------------   -----------   ---------   ----   ---------------------

archive_snapshot
