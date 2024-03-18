#!/usr/bin/env bash
#
#------------------------------- HEADER	---------------------------------------- #
# cloud_backup.sh - Do backups from your files on a cloud provider
#
# Site:    	https://github.com/Thales-Coutinho
# Author:   	Thales Martim Coutinho
# Maintenance:  Thales Martim Coutinho
# License: 	GNU v3.0
#
# ------------------------------------------------------------------------ #
#  Description :
#  This program performs tar compression and gunzip compression of the
#  specified directories, sending the result to a remote directory in the
#  cloud using Rclone, it also allows the automatic removal of Obsolete files..
#
#  Examples :
#  	$ ./backup.sh
#  	With this command the backup is executed
# ------------------------------------------------------------------------ #
# Changelog:
#
#   v1.0 08/12/2022, Thales Martim Coutinho:
#   	- Start of the program.
#
#   v1.1 15/09/2022, Thales Martim Coutinho;
#   	- automatic removal of old backups.
#   	- fixing Rclone connection issues.
#
#   v1.2 04/03/2023, Thales Martim Coutinho;
#   	- Automatic sending to the remote Repository, eliminating the need for
#       local intermediate files and increasing performance.
#   	- There is no need to include the creation date in the file name.
# ------------------------------------------------------------------------ #
#
#  Tested on:   bash 5.2.15
#
# ------------------------------- VARIABLES ------------------------------------------ #

source /home/thales/Dev/Cloud-Backup/config

# ------------------------------- TESTS -------------------------------------------- #

# Rclone is installed?
if ! command -v rclone &> /dev/null; then
	echo "Rclone is not installed, install with your distribution's package manager
	or consult the official documentation URL: https://rclone.org/install/"
	exit 1
fi

# Rclone remote is configured?
if ! test -f ~/.config/rclone/rclone.conf; then
	echo "Rclone is not configured for the user $USER, use the command <rclone config>
	if you don't know how to configure it, see URL: https://rclone.org/docs/"
	exit 1
fi
# ------------------------------- functions ------------------------------------------ #

# function to print and record error messages in the log and close the program
die() { echo "$*" | tee -a $LOG_PATH ; exit 1; }

# ------------------------------- EXECUTION ----------------------------------------- #

# Creating the Backup file and sending it to the remote directory
tar -cpPzf - "${INCLUDED_DIRECTORIES[@]}" | rclone rcat "$RCLONE_REMOTE""$NAME_FILE" || \
die "[$(date +'%d-%m-%Y %T')] ERROR: failed to generate file"

echo "[$(date +'%d-%m-%Y %T')] SUCCESS: backup file "$NAME_FILE" sent"| tee -a $LOG_PATH

# current number of files in the cloud
TOTAL_FILES=$(rclone lsf "$RCLONE_REMOTE" | wc -l)

# removing obsolete files
if [[ $TOTAL_FILES -ge  $NUMBER_BACKUPS ]]; then
   FILES_TO_REMOVE=$(( $TOTAL_FILES - $NUMBER_BACKUPS ))
   for (( n=0;n<$FILES_TO_REMOVE;n++ )); do
  	TO_REMOVE=$(rclone lsjson "$RCLONE_REMOTE" --files-only | jq -r '.[] | "\(.ModTime) \(.Name)"' | sort | head -n 1 | cut -d' ' -f2-)
  	rclone deletefile "$RCLONE_REMOTE""$TO_REMOVE"
  	echo "[$(date +'%d-%m-%Y %T')] SUCCESS: obsolete file $RCLONE_REMOTE$TO_REMOVE removed"| tee -a $LOG_PATH
   done
   echo "[$(date +'%d-%m-%Y %T')] SUCCESS: obsolete files removed"| tee -a $LOG_PATH
fi

echo " **Backup completed successfully!**"

# ---------------------------------------------------------------------------------- #


