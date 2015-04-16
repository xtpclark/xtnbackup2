Clone into where you want to run the backup from. 
i.e. 
<pre>
git clone xtnbackup2.git /mnt/backup
cd /mnt/backup/
./xtnbackup.sh
</pre>

Sets up XTN Backup.

xtnutils directory contains options for XTN customers

Initial setup sets INI options, which are read on subsequent runs.

Sets Crontab

Removes Old backups, based on number of days to store.

Set archive directory - This could be a NFS/SMB mount

Mail report option via mutt mailer.

Currently creates a backup of every database on the port except
postgres, template1, template0.

Backs up as individual backups - not pg_dumpall.

Creates backup of globals.

