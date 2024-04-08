#!/bin/bash

# Set global variables
compLvl=${BACKUP_COMPRESSION_LEVEL:-10}
foundryPath="/foundry-aio-server"

backupName="backup.tar.zst"
backupPath="/userdata/$backupName"

rcloneConfigPath="/root/.config/rclone/rclone.conf"
rcloneConfigTemplatePath="/userdata/rclone.template.conf"

diskName="kd"
diskBackupPath=${BACKUP_FOLDER:-"/foundry/backup"}
bufferSize=${BACKUP_BUFFER_SIZE:-500M}

# Function to print messages with formatting
log_msg() {
    echo -e "$(date): $1"
}

# Function to format bytes into human-readable size
human_readable_size() {
    echo $(numfmt --to=iec-i --suffix=B --padding=7 $1)
}

# Function to get number of free bytes on a disk
get_free_disk_space() {
    echo $(rclone about "$diskName:" --json | jq -r .free)
}

# Main backup process
log_msg "Starting backup process..."

# Remove current backup file if exists to free up space for the new file
[ -e "$backupPath" ] && { log_msg "Removing previous backup file: $backupPath"; rm "$backupPath"; }

# Create archive with backup using zstd compression
log_msg "Creating backup archive $backupPath from $foundryPath"
tar --use-compress-program="zstd -$compLvl" -cf $backupPath --absolute-names "$foundryPath"

# Fill envs into rclone.template.conf
log_msg "Creating rclone config from env"
[ -e "$rcloneConfigPath" ] && rm "$rcloneConfigPath"
envsubst < "$rcloneConfigTemplatePath" > "$rcloneConfigPath.updated"
mv "$rcloneConfigPath.updated" "$rcloneConfigPath"

# Create backup folder on a rclone disk
log_msg "Creating backup folder $diskName:$diskBackupPath"
rclone mkdir "$diskName:$diskBackupPath"

# Get size of the backup file
fileSize=$(stat --format=%s "$backupPath")
log_msg "Backup file size: $(human_readable_size $fileSize)"

# Get disk information
freeSpace=$(get_free_disk_space)
log_msg "Free space on disk '$diskName': $(human_readable_size $freeSpace)"

# Check if there is enough space on the disk
if [ $freeSpace -lt $fileSize ]; then
    log_msg "Insufficient space on disk '$diskName'. Initiating cleanup..."

    # Get a list of files sorted by date in ascending order (oldest first)
    filesToDelete=$(rclone lsjson "$diskBackupPath" | jq -r 'sort_by(.Name) | .[].Path')
    log_msg "Files will be deleted in the following order until enough space is freed up: $filesToDelete"

    # Delete files starting from the oldest until enough space is available
    for fileToDelete in $filesToDelete; do
        rclone deletefile "$diskBackupPath/$fileToDelete"
        log_msg "Deleted file: $fileToDelete"

        # Update free space information
        freeSpace=$(get_free_disk_space)

        log_msg "Free space on disk '$diskName': $(human_readable_size $freeSpace)"
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
log_msg "Starting upload of $backupPath to $diskBackupPath"
rclone copy --buffer-size $bufferSize "$backupPath" "$diskBackupPath"

# Cleanup local backup file
log_msg "Deleting $backupPath"
rm "$backupPath"

# Rename backup file on the remote disk with timestamp
diskbackupPath="$diskBackupPath/$(date +"%Y%m%d%H%M%S")-$backupName"
log_msg "Renaming $diskBackupPath/$backupName to $diskbackupPath"
rclone moveto "$diskBackupPath/$backupName" "$diskName:$diskbackupPath"
log_msg "Backup $diskName:$diskbackupPath saved successfully"
