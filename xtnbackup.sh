#!/bin/bash
exec 3>&1 4>&2
trap 'exec 2>&4 1>&3' 0 1 2 3

EDITOR=vi
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
WORKING=$DIR
HOMEDIR=$DIR
cd $DIR
echo "Working dir is $DIR"

WORKDATE=`/bin/date "+%m%d%y_%s"`
PLAINDATE=`date`

# Update the clock.
sudo ntpdate -s ntp.ubuntu.com

PROG=`basename $0`
HOSTNAME=`hostname`

usage() {
  echo "$PROG usage:"
  echo
  echo "$PROG -H"
  echo "$PROG [ -h hostname ] [ -p port ] [ -d database ] [ -m user@company.com ] [ -c CRMACCNTNAME ] companyname"
  echo
  echo "-H      print this help and exit"
  echo "-h      hostname of the database server (default $PGHOST)"
  echo "-p      listening port of the database server (default $PGPORT)"
  echo "-d      name of database"
  echo "-m      Notification Email recipient"
  echo "-c      CRMACCOUNT Name"
  echo " Last value is company name, becomes bak_companyname"
exit 0
}

setup()
{
DIRS='archive ini logs'
set -- $DIRS
for i in "$@"
do
 if [ -d $i ];
then
echo "Directory $i exists"
else
echo "$i does not exists, creating."
mkdir -p $i
fi
done
}

enviro()
{
SETS=${WORKING}/ini/settings.ini
}

pre()
{
enviro
echo "Checking environment"
if [ ! -f ${SETS} ]
then

setup #Sets up Directory Structure
setini
checkcronjob
echo "Checking environment again"
pre
else
enviro
setini

 if [ ${ISXTN} -eq "1" ]; then
  source ${WORKING}/xtnutils/sendglobalstos3.sh
  source ${WORKING}/xtnutils/updatextnbu.sh
  source ${WORKING}/xtnutils/checks3bucket.sh
  source ${WORKING}/xtnutils/senddbtos3.sh
  source ${WORKING}/xtnutils/s3chk.sh
  s3chk
 fi

fi
}

setini()
{
SETS=${WORKING}/ini/settings.ini

echo "Checking Settings"
if [ -e $SETS ]
 then
  echo "${SETS} Exists, reading settings"
source $SETS
DUMPVER=`$PGBIN/pg_dump -V | head -1 | cut -d ' ' -f3`
CN=$CRMACCT
BACKUPACCT=xtnbackups/bak_${CN}
WORKDATE=`date "+%m%d%Y"`
LOGFILE="${LOGDIR}/${PGHOST}_BackupStatus_${CN}_${WORKDATE}.log"
GLOBALFILE=${CN}_${PGHOST}_globals_${HOSTNAME}_${WORKDATE}.sql

 else
echo "Creating Backup Config"

PS3="Are you an XTN Subscriber? "
select ISXTN in Yes No
do
if [ $ISXTN = "Yes" ]; then
ISXTN=1
break
else
ISXTN=0
break
fi
done


echo "Set your xTuple Account Number"
echo "Default: xtnbackup. You can also contact xTuple, or accept default"
read CRMACCT

if [ -z $CRMACCT ]; then
CRMACCT=xtnbackup
fi

echo "Set the Postgres DB User"
echo "default: postgres"
read PGUSER

if [ -z $PGUSER ]; then
PGUSER=postgres
fi

 echo "Set the Postgres DB Host"
 echo "default: localhost"
read PGHOST

if [ -z $PGHOST ]; then
PGHOST=localhost
fi

echo "Set the Postgres DB Port"
echo "default: 5432"
read PGPORT

if [ -z $PGPORT ]; then
PGPORT=5432
fi

echo "Set the PG Dump Path"
echo "default: $(pg_config --bindir)"
read PGBIN

if [ -z $PGBIN ]; then
PGBIN=$(pg_config --bindir)
fi

 echo "Set Database Dump Extension"
 echo "default: backup"
read DUMPEXT

if [ -z $DUMPEXT ]; then
DUMPEXT=backup
fi

 echo "Set the path to Archive Backups in"
 echo "default: ${WORKING}/archive"
read ARCHIVEDIR

if [ -z $ARCHIVEDIR ]; then
ARCHIVEDIR=${WORKING}/archive
fi

echo "These are the databases to exclude from backup"
echo "You can change this list in the settings.ini file"
echo "default: \"'postgres','template0','template1'\""
echo "Just hit any-key"
echo " "
read dummy

if [ -z $EXCLUDEFROMBACKUP ]; then
EXCLUDEFROMBACKUP="\"'postgres','template0','template1'\""
fi

 echo "Set how many days of backups to keep locally."
 echo "default: 3"
read DAYSTOKEEP

if [ -z $DAYSTOKEEP ]; then
DAYSTOKEEP=3
fi

 echo "Set the path to store Logs"
 echo "default: ${WORKING}/logs"
read LOGDIR

if [ -z $LOGDIR ]; then
LOGDIR=${WORKING}/logs
fi


if [ $ISXTN == 1 ]; then
  echo "Set a Mailer"
  echo "default: /usr/bin/mutt"
  read MAILPRGM

  if [ -z $MAILPRGM ]; then
  MAILPRGM=/usr/bin/mutt
  fi

 echo "Set an Email address to send the backup report to"
 read MTO

  if [ -z $MTO ]; then
  MTO=cloudops@xtuple.com
  fi
fi 

echo "Wrote: ${SETS}"

cat << EOF > $SETS
ISXTN=${ISXTN}
CRMACCT=${CRMACCT}
PGUSER=${PGUSER}
PGHOST=${PGHOST}
PGPORT=${PGPORT}
PGBIN=${PGBIN}
DUMPEXT=${DUMPEXT}
ARCHIVEDIR=${ARCHIVEDIR}
LOGDIR=${LOGDIR}
EXCLUDEFROMBACKUP=${EXCLUDEFROMBACKUP}
DAYSTOKEEP=${DAYSTOKEEP}
MAILPRGM=${MAILPRGM}
MTO=${MTO}

EOF


fi

}

checkcronjob()
{
CRONTASK="${WORKING}/${PROG} -h ${PGHOST} -p ${PGPORT} -d ${CRMACCT} -m null -c ${CRMACCT} ${CRMACCT}"

TASKCHECK=`crontab -l | grep "${CRONTASK}" | wc -l`

if [ ${TASKCHECK} = 0 ]; then
echo "Let's set what time you'd like the backup to run"
unset CRONHOUR
unset CRONMIN
setcronjob
fi
}

setcronjob()
{

echo "Enter a Hour 0-23 (Zero = Midnight)"
read CRONHOUR

echo "Enter a Minute 0-59 (Zero = Top of Hour)"
read CRONMIN

if [ "$CRONHOUR" -eq "$CRONHOUR" ] 2>/dev/null
		then
			CRONHOUR=${CRONHOUR}
		else
	unset CRONHOUR
fi

if [ "$CRONMIN" -eq  "$CRONMIN" ] 2>/dev/null
		then
			CRONMIN=${CRONMIN}
			else
	unset CRONMIN
fi

if [ -z "$CRONMIN" ] && [ -z "$CRONHOUR" ]; then
setcronjob
else
crontab -l | { cat; echo "${CRONMIN} ${CRONHOUR} * * * /bin/bash ${CRONTASK}" ; } | crontab - 2>/dev/null

if [ $? = 0 ];
 then
 echo "Crontab Set for ${CRONHOUR}:${CRONMIN} /bin/bash ${CRONTASK}"
 else
 echo "Something went wrong, try again."
 setcronjob
fi

fi

}


settings()
{
echo "IN SETTINGS"
if [ -e $SETS ]
then
pre
else
echo "No Settings, Let's create them"
pre
exit 0;
fi
}

removelog()
{
CONVERTDAYS=`expr ${DAYSTOKEEP} \* 1400`

REMOVALLOG="${LOGDIR}/removal.log"

REMOVELIST=`find ${ARCHIVEDIR}/*.backup -type f -mmin +${CONVERTDAYS} -exec ls {} \;`
REMOVELISTSQL=`find ${ARCHIVEDIR}/*.sql -type f -mmin +${CONVERTDAYS} -exec ls {} \;`


cat << EOF >> $REMOVALLOG
========================================
REMOVAL LOG FOR $WORKDATE
========================================
EOF

for REMOVEME in $REMOVELIST ; do
rm -rf $REMOVEME
cat << EOF >> $REMOVALLOG
$REMOVEME Deleted
EOF
done

for REMOVEMESQL in $REMOVELISTSQL ; do
rm -rf $REMOVEMESQL
cat << EOF >> $REMOVALLOG
$REMOVEMESQL Deleted
EOF
done
}



backupdb()
{
#==============
# Loop through database names and back them up.
# Make list of databases to backup individually.
#==============
PGDUMPVER=`pg_dump -V`

STARTJOB=`date +%T`

cat << EOF >> $LOGFILE
======================================
Backup Job Started: $WORKDATE $STARTJOB
PGDump Version: ${PGDUMPVER}
======================================
EOF

# This will backup all databases other than the ones listed i.e. postgres,template0,template1

BACKUPLIST=`echo "SELECT datname as "dbname" FROM pg_catalog.pg_database \
           WHERE datname NOT IN (${EXCLUDEFROMBACKUP}) ORDER BY 1;" | \
           $PGBIN/psql -A -t -h $PGHOST -U $PGUSER -p $PGPORT postgres`

for DB in $BACKUPLIST ; do

BACKUPFILE=${CN}_${DB}_${HOSTNAME}_${WORKDATE}.backup

STARTDBJOB=`date +%T`
$PGBIN/pg_dump --host $PGHOST --port $PGPORT --username $PGUSER $DB --format custom --blobs --file ${ARCHIVEDIR}/${BACKUPFILE}
STOPDBJOB=`date +%T`

cat << EOF >> $LOGFILE
Database: ${DB}
BackupFile:${BACKUPFILE}
s3Start:${STARTDBJOB}
s3Stop:${STOPDBJOB}

EOF

S3BUCKET=s3://$BACKUPACCT

BACKUPOUT=${ARCHIVEDIR}/${BACKUPFILE}
GLOBALOUT=${ARCHIVEDIR}/${GLOBALFILE}

if [ $ISXTN == "1" ]; then
senddbtos3
updatextnbu
fi

done
}

backupglobals()
{
#==============
# Grab the Globals too
#==============

$PGBIN/pg_dumpall -U $PGUSER -h $PGHOST -p $PGPORT -g > ${ARCHIVEDIR}/${GLOBALFILE}

cat << EOF >> $LOGFILE
Globals: $GLOBALFILE
==================================
EOF

if [ $ISXTN == "1" ]; then
sendglobalstos3
fi


}


mailcustreport()
{
MAILPRGM=`which mutt`
if [ -z $MAILPRGM ]; then
true

else

$MAILPRGM -e 'set content_type="text/plain"' $MTO -s "xTuple Nightly Backup Details" < ${LOGFILE}

# $MAILPRGM -s "Nightly backup details for $SERVERNAME" $MTO < $MES
fi


rm ${LOGFILE}


}


OPTIND=1

while getopts ":H:h:p:d:m:c" opt; do
  case "$opt" in
    H)   usage exit 0 ;;
    h)   export PGHOST=$OPTARG ;;
    p)   export PGPORT=$OPTARG ;;
    d)   export PGDB=$OPTARG ;;
    m)   export NOTE=$OPTARG ;;
    c)   export CRMACCT=$OPTARG ;;
    *)    usage ; exit 1 ;;
  esac
  
done

shift "$((OPTIND-1))"

pre
# settings
removelog
backupdb
backupglobals
 #sendglobalstos3
mailcustreport

exit 0;
