#!/bin/bash

checkcronjob()
{
CRONTASK="${WORKING}/${PROG} -h ${PGHOST} -p ${PGPORT} -d ${CRMACCT} -m null -c ${CRMACCT} ${CRMACCT}"

TASKCHECK=`crontab -l | grep "${CRONTASK}" | wc -l`
echo "TASKCHECK = $TASKCHECK"
if [ ${TASKCHECK} > 0 ]; then
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

checkcronjob
