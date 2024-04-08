FROM ubuntu:latest

# Install dependency
RUN apt update && apt -y install zstd rclone gettext cron jq

# Create directories
RUN mkdir -p /root/.config/rclone /userscripts /foundry-aio-server

# Copy files
COPY ./etc/backup/rclone.template.conf /root/.config/rclone/
COPY ./etc/backup/backup.sh /userscripts/
COPY ./docker-compose.yml /data/
COPY ./.env /foundry-aio-server/
COPY ./.env.example /foundry-aio-server/

# Run and show logs
CMD crontab -l | { cat; echo "0 ${BACKUP_START_HOUR} * * * bash /userscripts/backup.sh >> /var/log/cron.log 2>&1"; } | crontab - && \
    touch /var/log/cron.log && \
    cron && \
    tail -f /var/log/cron.log
