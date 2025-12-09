#!/usr/bin/bash
# A script to backup using rclone
# LINUX FILES - DROPBOX TO ONEDRIVE
#
# Set variables
DROPBOXPATH="dropbox:/Simon/Linux"
ONEDRIVEPATH="onedrive:/Documents/Linux backup"
LOGFILEPATH="$(dirname '${BASH_SOURCE}')/logs/"
LOGFILE="Linux.log"
EMAIL="sitagg@gmail.com"

rclone copy -v --log-file "$LOGFILEPATH$LOGFILE" --log-file-max-size 1M --log-file-max-backups 5 "$DROPBOXPATH" "$ONEDRIVEPATH" 
mail -s "Linux Backup" $EMAIL < "$LOGFILEPATH$LOGFILE"
