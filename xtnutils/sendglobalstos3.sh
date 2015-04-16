#!/bin/bash

sendglobalstos3()
{

STARTRSJOB=`date +%T`

s3cmd put ${GLOBALOUT} ${S3BUCKET}/${GLOBALFILE}

STOPRSJOB=`date +%T`
DBSIZE=`ls -lh ${ARCHIVEDIR}/${BACKUPFILE} | cut -d' ' -f5`


}

