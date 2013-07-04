#!/opt/bin/bash
#set -x
#######################################################
# Generational backup-script for Synology NAS
# Incremental Backups with minimum dependencies:
#
# Dependencies: bash rsync
# Optional: nail (For Error-Mails)
#
# Usage: ./rsync_backup.sh <BACKUP-TYPE>
#
# All you need to change you find here:
##################################################
# OPTION
##################################################
# Target Directory for the Backup
BACKUP_DIR=/volume1/backup

#Get Mails using nail if an error accures? 1 = on
MAIL_AT_ERROR=0
MAIL_ADDRESSES=("foo@bar.net" "test@gmail.com")

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
	*) echo "Couldn't find backup-type \"${BACKUP_TYPE}\"" ; exit 1 ;;
esac
##################################################
# END OF OPTION
##################################################

[ ! -d "$BACKUP_DIR" ] && ( mkdir -p "$BACKUP_DIR" || echo "Couldn't create \"$BACKUP_DIR\"" && exit 1)

#rotate if KEEP is reached
BACKUP_NR=0
if [ -d ${BACKUP_DIR}/${BACKUP_TYPE}.${KEEP} ] ; then
	logger -p user.debug "BACKUP-"${BACKUP_TYPE}": ROTATEING"
	rm -rf "${BACKUP_DIR}/${BACKUP_TYPE}.0"
	while [ -d "${BACKUP_DIR}/${BACKUP_TYPE}.`expr $BACKUP_NR + 1`" ] ; do
		mv "${BACKUP_DIR}/${BACKUP_TYPE}.`expr $BACKUP_NR + 1`" "${BACKUP_DIR}/${BACKUP_TYPE}.$BACKUP_NR" 
		BACKUP_NR=`expr $BACKUP_NR + 1`
	done
fi

if [ ! -d ${BACKUP_DIR}/${BACKUP_TYPE}.0 ] ; then
	BACKUP_NR=0
else
	BACKUP_NR=`ls -1d ${BACKUP_DIR}/${BACKUP_TYPE}.[0-9] | wc -l`
fi

FAILED=0
for sourcedir in `cat ${SOURCE_DIR_FILE}` ; do
	if [ $BACKUP_NR -gt 0 ] ; then
		rsync -aR $RSYNC_OPTS --link-dest="${BACKUP_DIR}/${BACKUP_TYPE}.`expr $BACKUP_NR - 1`" "$sourcedir" "${BACKUP_DIR}/${BACKUP_TYPE}.$BACKUP_NR"
		RET=$?
	else
		rsync -aR $RSYNC_OPTS "$sourcedir" "${BACKUP_DIR}/${BACKUP_TYPE}.$BACKUP_NR"
		RET=$?
	fi

	#Send Mail @ Error
	if [ $RET -ne 0 -a $MAIL_AT_ERROR -eq 1 ] ; then
		echo "ERROR when backing up \"${sourcedir}\"" | nail -s"BACKUP: \"${BACKUP_TYPE}\" FAILED" ${MAIL_ADDRESSES[@]}
		FAILED=1
	fi
	
	#Log at error
	if [ $RET -ne 0 ] ; then
		logger -p user.crit "BACKUP-"${BACKUP_TYPE}": FAILED at ${sourcedir}"
	fi
done

#Log success if backup didn't fail
[ $FAILED -eq 0 ] && logger -p user.crit "BACKUP-"${BACKUP_TYPE}": SUCCESSFULL"
exit $FAILED
