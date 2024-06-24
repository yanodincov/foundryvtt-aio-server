#!/bin/bash

# Export all environment variables from the docker container's init process
for variable_value in $(cat /proc/1/environ | sed 's/\x00/\n/g'); do
    export $variable_value
done

# Function to print messages with formatting and timestamp
log_msg() {
    echo -e "$(date +"%Y-%m-%d %H:%M:%S") - $1"
}

# Function to format bytes into human-readable size
human_readable_size() {
    echo $(numfmt --to=iec-i --suffix=B --padding=7 "$1")
}

# Function to get number of free bytes on a disk
get_free_disk_space() {
    echo $(rclone about "$diskName:" --json | jq -r .free)
}

# Load environment variables into local variables and log them
BACKUP_ENABLED=${BACKUP_ENABLED:-false}
compLvl=${BACKUP_COMPRESSION_LEVEL:-10}
foundryPath="/foundry-aio-server"
backupName="backup.tar.zst"
backupPath="/root/$backupName"
diskName="kd"
diskBackupPath=${BACKUP_FOLDER:-"/foundry/backup"}
bufferSize=${BACKUP_BUFFER_SIZE:-"512M"}

log_msg "Environment variables:
BACKUP_ENABLED=$BACKUP_ENABLED
BACKUP_COMPRESSION_LEVEL=$compLvl
foundryPath=$foundryPath
backupName=$backupName
backupPath=$backupPath
diskName=$diskName
diskBackupPath=$diskBackupPath
bufferSize=$bufferSize"

if [[ "${BACKUP_ENABLED:-false}" != "true" ]]; then
    log_msg "Backup is disabled. Skipping backup process."
    exit 0
fi

# Main backup process
log_msg "Starting backup process..."

# Remove current backup file if exists to free up space for the new file
[ -e "$backupPath" ] && { log_msg "Removing previous backup file: $backupPath"; rm "$backupPath"; }

# Create archive with backup using zstd compression
log_msg "Creating backup archive $backupPath from $foundryPath"
tar --use-compress-program="zstd -$compLvl" -cf "$backupPath" --absolute-names "$foundryPath"

# Create backup folder on a rclone disk
log_msg "Creating backup folder $diskName:$diskBackupPath"
rclone mkdir "$diskName:$diskBackupPath"

# Calculate MD5 hash of the created backup
log_msg "Calculating MD5 hash of the created backup..."
backupMD5=$(md5sum "$backupPath" | awk '{print $1}')
log_msg "MD5 hash of the created backup: $backupMD5"

# Get MD5 hash of the last backup from kd
log_msg "Getting MD5 hash of the last backup from kd..."
lastBackup=$(rclone ls "$diskName:$diskBackupPath" | grep -Eo '[0-9]{14}-backup.tar.zst' | sort -n | tail -n 1)
lastBackupMD5=$(rclone md5sum "$diskName:$diskBackupPath/$lastBackup" | awk '{print $1}')
log_msg "MD5 hash of the last backup from kd: $lastBackupMD5"

# Compare MD5 hashes
if [ "$backupMD5" == "$lastBackupMD5" ]; then
    log_msg "MD5 hashes match. Backup process completed successfully."
    exit 0
fi

# Get size of the backup file
fileSize=$(stat --format=%s "$backupPath")
log_msg "Backup file size: $(human_readable_size "$fileSize")"

# Get disk information
freeSpace=$(get_free_disk_space)
log_msg "Free space on disk '$diskName': $(human_readable_size "$freeSpace")"

# Check if there is enough space on the disk
if [ "$freeSpace" -lt "$fileSize" ]; then
    log_msg "Insufficient space on disk '$diskName'. Initiating cleanup..."

    # Get a list of files sorted by date in ascending order (oldest first)
    filesToDelete=$(rclone lsjson "$diskName:$diskBackupPath" | jq -r 'sort_by(.Name) | .[].Path')
    log_msg "Files will be deleted in the following order until enough space is freed up: $filesToDelete"

    # Delete files starting from the oldest until enough space is available
    for fileToDelete in $filesToDelete; do
        rclone deletefile "$diskName:$diskBackupPath/$fileToDelete"
        log_msg "Deleted file: $fileToDelete"

        # Update free space information
        freeSpace=$(get_free_disk_space)

        log_msg "Free space on disk '$diskName': $(human_readable_size "$freeSpace")"
        if [ "$freeSpace" -ge "$fileSize" ]; then
            log_msg "Sufficient space freed up. Continuing with the backup process."
            break
        fi
        log_msg "Continuing disk cleanup..."
    done

    # Check if enough space has been freed up; otherwise, exit the script
    if [ "$freeSpace" -lt "$fileSize" ]; then
        log_msg "Insufficient space even after deleting backup files. Backup failed."
        exit 1
    fi
    log_msg "Memory freed up successfully for the new backup."
fi

# Start upload of backup file to the designated folder
log_msg "Starting upload of $backupPath to $diskName:$diskBackupPath"
rclone copy --buffer-size "$bufferSize" "$backupPath" "$diskName:$diskBackupPath"
if [ $? -ne 0 ]; then
    log_msg "Command \"rclone copy --buffer-size $bufferSize $backupPath $diskName:$diskBackupPath\" failed. Exiting."
    exit 1
fi

# Cleanup local backup file
log_msg "Deleting $backupPath"
rm "$backupPath"

# Rename backup file on the remote disk with timestamp
diskbackupFilePath="$diskBackupPath/$(date +"%Y%m%d%H%M%S")-$backupName"
log_msg "Renaming $diskName:$diskBackupPath/$backupName to $diskbackupFilePath"
rclone moveto "$diskName:$diskBackupPath/$backupName" "$diskName:$diskbackupFilePath"
log_msg "Backup $diskName:$diskbackupFilePath saved successfully"
