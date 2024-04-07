FROM ubuntu:latest

# Устанавливаем необходимые пакеты
RUN apt update && apt -y install zstd rclone gettext cron jq

# Создаем необходимые директории
RUN mkdir -p /root/.config/rclone /userscripts /data

# Копируем файлы
COPY ./mount/backup/rclone.template.conf /root/.config/rclone/
COPY ./mount/backup/backup.sh /userscripts/
COPY ./mount/backup/backup-cron /etc/cron.d/
COPY ./docker-compose.yml /data/
COPY ./.env /data/
COPY ./.env.example /data/

# Запускаем cron и выводим логи
CMD touch /var/log/cron.log && cron && tail -f /var/log/cron.log
