#-------------------------------------------------------------------------------
# (c) Lars Baehren <lbaehren@gmail.com> (2017). All Rights Reserved.
# This software is distributed under the BSD 2-clause license.
#-------------------------------------------------------------------------------

varUser=`whoami`
varSource=/home/${varUser}
varTarget=/media/${varUser}/Backup\\\ Linux/Backup\\\ Ubuntu
varTimestamp=`date +%Y%m%d-%H%M%S`
varSnapshot=${varUser}-${varTimestamp}.tar.bzip2

echo "--> Configuration for backup ..."
echo " - User name     : ${varUser}"
echo " - Source        : ${varSource}"
echo " - Target        : ${varTarget}"
echo " - Timestamp     : ${varTimestamp}"
echo " - Snapshot file : ${varSnapshot}"

# ==============================================================================
#  Step 1 : Mirror the current state of the user home directory onto the backup
#           medium

echo "--> Mirror contents of home directory ..."

rsync -axuzP --delete ${varSource} /media/${varUser}/Backup\ Linux/Backup\ Ubuntu

echo "--> Mirror contents of home directory ... done"

# ==============================================================================
#  Step 2 : Create a compressed, time-stamped archive of the user home directory
#
#  Date/Time         real         user         sys         Size   Comment
#  ---------------   ----------   ----------   ---------   ----   ---------------------
#  20170207-085649   65m15.746s   62m15.640s   0m53.176s     ??   run from source directory
#  20170207-100604   62m00.851s   59m52.056s   0m50.484s    16G   run from source directory
#  20170207-111319   77m32.869s   63m12.600s   0m52.248s    17G   run from backup disk
#  20170207-132156   82m07.583s   64m49.276s   0m56.456s    17G   run from backup disk
#  ---------------   ----------   ----------   ---------   ----   ---------------------
#

echo "--> Creating archive '${varSnapshot}' from current snapshot ..."

# ---------------------------------------------------------
# Variant 1 : Run archive creation directly off the source directory (varSource)
# ---------------------------------------------------------

# cd /home
# time tar -cjf /media/${varUser}/Backup\ Linux/Backup\ Ubuntu/${varSnapshot} ${varUser}

# ---------------------------------------------------------
# Variant 2 : Create compressed archive from previously created snapshot.
# ---------------------------------------------------------

cd /media/${varUser}/Backup\ Linux/Backup\ Ubuntu
time tar -cjf ${varSnapshot} ${varUser}

echo "--> Creating archive '${varSnapshot}' from current snapshot ... done"
