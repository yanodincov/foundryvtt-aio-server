ln -fs "/usr/share/zoneinfo/${BACKUP_TIMEZONE}" /etc/localtime
dpkg-reconfigure -f noninteractive tzdata

rclone_ini_config=$(echo -e "[backupstorage]\n$(echo "$json_str" | jq -r 'to_entries[] | "\(.key) = \(.value | tostring)"'))
echo "Created rclon config from json:\n$rclone_ini_config";
echo "$rclone_ini_config" > /root/.config/rclone/rclone.conf

envsubst < /userdata/crontask.template > /etc/cron.d/backup
crontab /etc/cron.d/backup 
chmod 0644 /etc/cron.d/backup
cron

tail -f /var/log/cron.log