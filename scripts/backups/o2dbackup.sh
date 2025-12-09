#!/usr/bin/bash
# A script to backup using rclone
# ONEDRIVE TO DROPBOX 
#
# Set variables
DROPBOXPATH="dropbox:/Onedrive Docs Backup"
ONEDRIVEPATH="onedrive:/Shared Documents"
LOGFILEPATH="$(dirname '${BASH_SOURCE}')/logs/"
LOGFILE="O2D.log"
EMAIL="sitagg@gmail.com"

rclone copy -v --log-file "$LOGFILEPATH$LOGFILE" --log-file-max-size 1M --log-file-max-backups 5 "$ONEDRIVEPATH" "$DROPBOXPATH"
mail -s "O2D BAckup" $EMAIL < "$LOGFILEPATH$LOGFILE"
