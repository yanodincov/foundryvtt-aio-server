ln -fs "/usr/share/zoneinfo/${BACKUP_TIMEZONE}" /etc/localtime
dpkg-reconfigure -f noninteractive tzdata

envsubst < /userdata/rclone.template.conf > /root/.config/rclone/rclone.conf

envsubst < /userdata/crontask.template > /etc/cron.d/backup
crontab /etc/cron.d/backup 
chmod 0644 /etc/cron.d/backup
cron

tail -f /var/log/cron.log