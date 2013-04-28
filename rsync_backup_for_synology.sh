#!/opt/bin/bash

#######################################################
# Generational backup-script for Synology NAS
# Incremental Backups with minimum dependencies:
#
# Dependencies: bash rsync
#
# Usage: ./rsync_backup.sh <BACKUP-TYPE>
#
# All you need to change you find here:
##################################################
# OPTION
##################################################
# Target Directory for the Backup
BACKUP_DIR=/volume1/backup
RSYNC_OPTS=""

# Don't change this:
BACKUP_TYPE=$1

# define BACKUP_TYPE with a name
# define KEEP with a number of backups to keep before rotating (0-9) 
# define SOURCE_DIR_FILE with a txt-file with a list of directorys to backup 
case $BACKUP_TYPE in 
    	"daily") KEEP=7 ; SOURCE_DIR_FILE=/volume1/backup_daily.txt ;; 
	"weekly") KEEP=4 ; SOURCE_DIR_FILE=/volume1/backup_weekly.txt ;;
	"monthly") KEEP=2 ; SOURCE_DIR_FILE=/volume1/backup_monthly.txt ;;
	*) echo "ERROR: Couldn't find backup-type \"${BACKUP_TYPE}\"" ; exit 1 ;;
esac

##################################################
# END OF OPTION
##################################################

# Check if SOURCE_DIR_FILE exists
if [ ! -f ${SOURCE_DIR_FILE} ] ; then
	echo "ERROR: Couldn't find SOURCE_DIR_FILE \"${SOURCE_DIR_FILE}\"" && exit 1
fi

# Check if BACKUP_DIR exists
if [ ! -d ${BACKUP_DIR} ] ; then
	echo "ERROR: Couldn't find BACKUP_DIR \"${BACKUP_DIR}\"" && exit 1
fi

# Rotate if KEEP is reached
BACKUP_NR=0
if [ -d ${BACKUP_DIR}/${BACKUP_TYPE}.${KEEP} ] ; then
	logger "BACKUP-"${BACKUP_TYPE}": ROTATEING"
	rm -rf "${BACKUP_DIR}/${BACKUP_TYPE}.0"
	while [ -d "${BACKUP_DIR}/${BACKUP_TYPE}.`expr $BACKUP_NR + 1`" ] ; do
		mv "${BACKUP_DIR}/${BACKUP_TYPE}.`expr $BACKUP_NR + 1`" "${BACKUP_DIR}/${BACKUP_TYPE}.$BACKUP_NR" 
		BACKUP_NR=`expr $BACKUP_NR + 1`
	done
fi

# Count number of existing Backups
if [ ! -f ${BACKUP_DIR}/${BACKUP_TYPE}.0 ] ; then
	BACKUP_NR=0
else
	BACKUP_NR=`ls -1d ${BACKUP_DIR}/${BACKUP_TYPE}.[0-9] | wc -l`
fi

# Backing up everything
for sourcedir in `cat ${SOURCE_DIR_FILE}` ; do
	if [ $BACKUP_NR -gt 0 ] ; then
		rsync -aR $RSYNC_OPTS --link-dest="${BACKUP_DIR}/${BACKUP_TYPE}.`expr $BACKUP_NR - 1`" "$sourcedir" "${BACKUP_DIR}/${BACKUP_TYPE}.$BACKUP_NR"
		( [ $? -eq 0 ] && logger "BACKUP-"${BACKUP_TYPE}": SUCCESSFULL" ) || logger "BACKUP-"${BACKUP_TYPE}": ERROR = FAILED"
	else
		rsync -aR $RSYNC_OPTS "$sourcedir" "${BACKUP_DIR}/${BACKUP_TYPE}.$BACKUP_NR"
		( [ $? -eq 0 ] && logger "BACKUP-"${BACKUP_TYPE}": SUCCESSFULL" ) || logger "BACKUP-"${BACKUP_TYPE}": ERROR = FAILED"
	fi
done
