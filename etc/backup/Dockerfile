FROM ubuntu:latest

RUN apt update && apt -y install zstd rclone cron jq tzdata curl && \
    curl -L https://github.com/a8m/envsubst/releases/download/v1.2.0/envsubst-`uname -s`-`uname -m` -o envsubst && \
    chmod +x envsubst && mv envsubst /usr/local/bin && \
    mkdir -p /root/.config/rclone /userdata /foundry-aio-server && \
    touch /var/log/cron.log

COPY ./etc/backup/crontask.template /userdata
COPY ./etc/backup/rclone.template.conf /userdata
COPY ./etc/backup/backup.sh /userdata
COPY ./etc/backup/run.sh /userdata

ENTRYPOINT [ "bash", "/userdata/run.sh" ]