#!/usr/bin/env bash
set -e

if [[ "$EUID" -ne 0 ]]; then
    echo "This script must be run as root. Please use 'sudo'."
    exit 1
fi

today=$(date +"%d-%m-%Y")
target_directory_name="storage"
target_directory="/$target_directory_name"
backuper_directory="$HOME/Backuper"
result_archive="$backuper_directory/$today".tar
destination_directory="/home/user/Mnt"

mkdir $backuper_directory
cp -rv $target_directory $backuper_directory
tar -cvf $result_archive "$backuper_directory/$target_directory_name"

if [ -e $result_archive ]; then
    echo "backup created: $result_archive"
else
    echo "something went wrong: $result_archive"
fi

mv -v $result_archive "$destination_directory"
rm -rf $backuper_directory && echo "$backuper_directory is deleted" \
        || echo "something went wrong with $backuper_directory"
