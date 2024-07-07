#!/bin/bash
ln -fs "/usr/share/zoneinfo/${BACKUP_TIMEZONE}" /etc/localtime
dpkg-reconfigure -f noninteractive tzdata

rclone_ini_config=$(echo "${RCLONE_JSON_CONFIG}" | jq -r 'to_entries[] | "\(.key) = \(.value | tostring)"')
echo -e "[backupstorage]\n$rclone_ini_config" > /root/.config/rclone/rclone.conf
echo "Rclone config:"
cat /root/.config/rclone/rclone.conf

envsubst < /userdata/crontask.template > /etc/cron.d/backup
chmod 0644 /etc/cron.d/backup
crontab /etc/cron.d/backup
service cron start

tail -f /var/log/cron.log