#!/bin/bash

# Function to print messages with formatting and timestamp
log_msg() {
    echo -e "$(date +"%Y-%m-%d %H:%M:%S") - $1"
}

# Function to format bytes into human-readable size
human_readable_size() {
    echo $(numfmt --to=iec-i --suffix=B --padding=7 "$1")
}

# Function to convert size with suffix (e.g., 10G) to bytes
size_to_bytes() {
    echo $(numfmt --from=iec-i --suffix=B "$1")
}

# Function to get the total size of backups in a folder
get_total_backup_size() {
    echo $(rclone size "$diskName:$diskBackupPath" --json | jq -r .bytes)
}

# Function to get the current free space on the disk
get_free_disk_space() {
    echo $(rclone about "$diskName:" --json | jq -r .free)
}

# Function to get the total size of the disk
get_total_disk_size() {
    echo $(rclone about "$diskName:" --json | jq -r .total)
}

# Load environment variables
backupEnabled=${BACKUP_ENABLED:-false}
compLvl=${BACKUP_COMPRESSION_LEVEL:-10}
foundryPath="/foundry-aio-server"
backupName="backup.tar.zst"
backupPath="/root/$backupName"
diskName="backupstorage"
diskBackupPath=${BACKUP_STORAGE_FOLDER:-"/foundry/backup"}
bufferSize=${BACKUP_BUFFER_SIZE:-"512M"}
backupsDiskLimit=${BACKUP_DISK_LIMIT:-"1P"} # Default to a large value

# Convert size limit to bytes
backupsDiskLimitBytes=$(size_to_bytes "$backupsDiskLimit")

# Get the total disk size
totalDiskSize=$(get_total_disk_size)
log_msg "Total disk size: $(human_readable_size "$totalDiskSize")"

# Adjust backupsDiskLimitBytes if it exceeds the total disk size
if [ "$backupsDiskLimitBytes" -gt "$totalDiskSize" ]; then
    log_msg "Provided backup size limit ($backupsDiskLimit) exceeds total disk size. Adjusting limit to disk size."
    backupsDiskLimitBytes=$totalDiskSize
    log_msg "New backup size limit: $(human_readable_size "$backupsDiskLimitBytes")"
    backupsDiskLimit=$(human_readable_size "$backupsDiskLimitBytes")
fi

log_msg "{
    \"script_params\": {
        \"backupEnabled\": \"$backupEnabled\",
        \"compLvl\": \"$compLvl\",
        \"foundryPath\": \"$foundryPath\",
        \"backupName\": \"$backupName\",
        \"backupPath\": \"$backupPath\",
        \"diskName\": \"$diskName\",
        \"diskBackupPath\": \"$diskBackupPath\",
        \"bufferSize\": \"$bufferSize\",
        \"backupsDiskLimit\": \"$backupsDiskLimit\"
    }
}"

if [[ "${backupEnabled:-false}" != "true" ]]; then
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

# Calculate MD5 hash of the created backup
log_msg "Calculating MD5 hash of the created backup..."
backupMD5=$(md5sum "$backupPath" | awk '{print $1}')
log_msg "MD5 hash of the created backup: $backupMD5"

# Get size of the backup file
fileSize=$(stat --format=%s "$backupPath")
log_msg "Backup file size: $(human_readable_size "$fileSize")"

# Check total size of backups on remote
totalBackupSize=$(get_total_backup_size)
log_msg "Current total size of backups: $(human_readable_size "$totalBackupSize")"

# Check if adding the new backup exceeds the size limit
if [ $(($totalBackupSize + $fileSize)) -gt $backupsDiskLimitBytes ]; then
    log_msg "Total backup size exceeds limit of $(human_readable_size "$backupsDiskLimitBytes"). Initiating cleanup..."

    # Get a list of files sorted by date in ascending order (oldest first)
    filesToDelete=$(rclone lsjson "$diskName:$diskBackupPath" | jq -r 'sort_by(.ModTime) | .[].Path')
    log_msg "Files will be deleted in the following order until enough space is freed up: $filesToDelete"

    # Delete files starting from the oldest until the total size is within limit
    for fileToDelete in $filesToDelete; do
        rclone deletefile "$diskName:$diskBackupPath/$fileToDelete"
        log_msg "Deleted file: $fileToDelete"

        # Update total backup size
        totalBackupSize=$(get_total_backup_size)
        log_msg "Updated total size of backups: $(human_readable_size "$totalBackupSize")"

        if [ $(($totalBackupSize + $fileSize)) -le $backupsDiskLimitBytes ]; then
            log_msg "Sufficient space cleared for the new backup."
            break
        fi
    done

    # Check if we still exceed the limit
    if [ $(($totalBackupSize + $fileSize)) -gt $backupsDiskLimitBytes ]; then
        log_msg "Unable to free enough space for the new backup. Backup failed."
        exit 1
    fi
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