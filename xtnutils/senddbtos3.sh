#!/bin/bash

senddbtos3()
{

STARTRSJOB=`date +%T`
s3cmd put ${BACKUPOUT} ${S3BUCKET}/${BACKUPFILE}
STOPRSJOB=`date +%T`
DBSIZE=`ls -lh ${ARCHIVEDIR}/${BACKUPFILE} | cut -d' ' -f5`

cat << EOF >> ${LOGFILE}
s3Link: ${S3BUCKET}/${BACKUPFILE}
Time: ${STARTRSJOB} / ${STOPRSJOB}
BackupSize: ${DBSIZE}
EOF

}

