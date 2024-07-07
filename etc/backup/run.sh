ln -fs "/usr/share/zoneinfo/${BACKUP_TIMEZONE}" /etc/localtime
dpkg-reconfigure -f noninteractive tzdata

rclone_config=$(jq -r 'to_entries | map("[\(.key)]\n\(.value | to_entries | map("\(.key) = \(.value | tostring)") | .[] ) | .[]' ${RCLONE_JSON_CONFIG})
# Вывод на экран (можно закомментировать, если не нужен)
echo "Created rclon config from json:\n$rclone_config";
echo "$rclone_config" > /root/.config/rclone/rclone.conf

envsubst < /userdata/crontask.template > /etc/cron.d/backup
crontab /etc/cron.d/backup 
chmod 0644 /etc/cron.d/backup
chmod 1755 /userdata/backup.sh
cron

tail -f /var/log/cron.log