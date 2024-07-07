#!/bin/bash

# Prompt for the path to the rclone config file, with a note about the default value
read -p "Enter the path to the rclone config file (default: ~/.config/rclone/rclone.conf): " config_path

# Use default value if no path is provided
if [ -z "$config_path" ]; then
  config_path="$HOME/.config/rclone/rclone.conf"
fi

# Check if the config file exists
if [ ! -f "$config_path" ]; then
  echo "Config file not found!"
  exit 1
fi

# Get the list of disks
disk_names=$(awk -F'[][]' '/\[.*\]/{print $2}' "$config_path")

# Check if there are any disks in the config file
if [ -z "$disk_names" ]; then
  echo "No disks found in the config file!"
  exit 1
fi

# Display the list of available disks
echo "Available disks:"
echo "$disk_names"

# Prompt for the name of the disk
read -p "Enter the name of the disk: " disk_name

# Check if the entered disk name exists in the list of disks
if ! echo "$disk_names" | grep -qw "$disk_name"; then
  echo "Disk name not found in the config file!"
  exit 1
fi

# Read the config file and find the specified disk
disk_info=$(sed -n "/\[$disk_name\]/,/^$/p" "$config_path")

# Initialize the JSON string
json_str="{"

# Process each line of the disk section
while IFS= read -r line; do
  if [[ $line == *"="* ]]; then
    key=$(echo "$line" | cut -d'=' -f1 | xargs)
    value=$(echo "$line" | cut -d'=' -f2- | xargs)
    json_str+="\"$key\":\"$value\","
  fi
done <<< "$disk_info"

# Remove the last comma and close the JSON object
json_str="${json_str%,}}"

# Output the JSON string
echo "$json_str"