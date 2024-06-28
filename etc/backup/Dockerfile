FROM ubuntu:latest

RUN apt update && apt -y install zstd rclone gettext cron jq tzdata && \
    mkdir -p /root/.config/rclone /userdata /foundry-aio-server && \
    touch /var/log/cron.log

COPY ./etc/backup/crontask.template /userdata
COPY ./etc/backup/rclone.template.conf /userdata
COPY ./etc/backup/backup.sh /userdata
COPY ./etc/backup/run.sh /userdata

ENTRYPOINT [ "bash", "/userdata/run.sh" ]