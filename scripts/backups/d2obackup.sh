#!/usr/bin/bash
# A script to backup using rclone
# DROPBOX TO ONEDRIVE
#
# Set variables
DROPBOXPATH="dropbox:/Business Receipts"
ONEDRIVEPATH="onedrive:/Business Receipts Backup"
LOGFILEPATH="$(dirname '${BASH_SOURCE}')/logs/"
LOGFILE="D2O.log"
EMAIL="sitagg@gmail.com"

rclone copy -v --log-file "$LOGFILEPATH$LOGFILE" --log-file-max-size 1M --log-file-max-backups 5 "$DROPBOXPATH" "$ONEDRIVEPATH" 
mail -s "D2O Backup" $EMAIL < "$LOGFILEPATH$LOGFILE"
