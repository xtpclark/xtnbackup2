#!/bin/bash

updatextnbu()
{
if [[ -z $(which ec2metadata) ]]; then
MACHID=`hostname -f`
else
MACHID=`ec2metadata --instance-id`
fi

curl -X POST \
-d '{"CRMACCT":"'"${CRMACCT}"'", "STORAGEID":2, "CRMACCT_ID":"'"${CRMID}"'", "PGHOST":"'"${PGHOST}"'", "PGPORT":"'"${PGPORT}"'", "PGDB":"'"${PGDB}"'", "BACKUPFILE":"'"${BACKUPFILE}"'","GLOBALFILE":"'"${GLOBALFILE}"'", "PGVER":"'"${PGDUMPVER}"'", "STARTJOB":"'"${STARTDBJOB}"'", "STOPJOB":"'"${STOPDBJOB}"'", "STARTRS":"'"${STARTRSJOB}"'", "STOPRS":"'"${STOPRSJOB}"'","DBSIZE":"'"${DBSIZE}"'", "STOREURL":"'${BACKUPACCT}/${BACKUPFILE}'", "WASSPLIT":"'"${WASSPLIT}"'", "MACHID":"'"${MACHID}"'"}' \
http://xtntrack.xtuple.com/ \
--header "Content-Type:application/json"

}
