#!/bin/bash

TODAY=`/bin/date +%d`
TOMORROW=`/bin/date +%d -d "1 day"`

ARCHIVEDIR=/home/xtnbackups/end-of-month

CRMACCT=xtuple

PGBIN=/usr/lib/postgresql/11/bin

DBNAME=production
PGPORT=5432
PGHOST=localhost
PGUSER=admin
PGCONN="-U ${PGUSER} -h ${PGHOST} -p ${PGPORT} "

BACKUPFILENAME=`date +${DBNAME}-%F-%A-%b-%d-%Y-%H-%M-%S.backup`
RESTORESTAMP=`date +%b_%Y`

RESTORENAME=${DBNAME,,}_${RESTORESTAMP,,}
BACKUPFILE=${ARCHIVEDIR}/${BACKUPFILENAME}


# Check if tomorrow is less than today
# If it is, then create the backup...
if [ $TOMORROW -lt $TODAY ]; then


echo "Running End of Month backup"
echo "Creating ${ARCHIVEDIR}${BACKUPFILENAME}"
${PGBIN}/pg_dump ${PGCONN} -Fc ${DBNAME} -f ${BACKUPFILE}

echo "Creating Database ${RESTORENAME,,}"
echo "createdb ${PGCONN}  ${RESTORENAME,,}"

echo "Restoring ${BACKUPNAME}"
echo "pg_restore ${PGCONN} -d ${RESTORENAME,,} ${BACKUPFILE}"

echo "Transferring ${BACKUPNAME} to Offsite Storage"
s3cmd put ${BACKUPFILE} s3://xtnbackups/bak_${CRMACCT}/EOM/${BACKUPFILENAME}

fi



