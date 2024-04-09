FROM ubuntu:latest

RUN apt update && apt -y install zstd rclone gettext cron jq tzdata && \
    mkdir -p /root/.config/rclone /userdata /foundry-aio-server && \
    touch /var/log/cron.log

COPY ./etc/backup/crontask.template /userdata
COPY ./etc/backup/rclone.template.conf /userdata
COPY ./etc/backup/backup.sh /userdata
COPY ./etc/backup/run.sh /userdata

COPY ./.git /foundry-aio-server/.git
COPY ./.gitignore /foundry-aio-server/
COPY ./readme.md /foundry-aio-server/
COPY ./docker-compose.yml /foundry-aio-server/
COPY ./.env /foundry-aio-server/
COPY ./.env.example /foundry-aio-server/

ENTRYPOINT [ "bash", "/userdata/run.sh" ]