# FoundryVTT All-in-One

![foundryvtt community content](github/fvtt-cc-text.png)

## Description

This repository contains a [Docker Compose](https://docs.docker.com/compose/) project with all the necessary services for comfortable use of [FoundryVTT](https://foundryvtt.com/).

## Services

1. [felddy/foundryvtt](https://github.com/felddy/foundryvtt-docker)  
   Used for hosting FoundryVTT. This package requires [FoundryVTT](https://foundryvtt.com/) account credentials for authorization and to download the FoundryVTT application.
2. [filebrowser/filebrowser](https://filebrowser.org/installation)  
   Used to manage files via a web interface.
3. [jonasal/nginx-certbot](https://github.com/JonasAlfredsson/docker-nginx-certbot/tree/master)  
   Used for hosting the application and for creating and renewing SSL certificates via [Certbot](https://certbot.eff.org/).
4. [backup](https://github.com/yanodincov/foundry-aio-server/blob/main/etc/backup/Dockerfile)  
   A self-written service for creating backups of this project and uploading them via [rclone](https://rclone.org/) every day.

This project does not store or share your data with third parties, but the services it uses may do so. The author of the project is not responsible for the safety of the data entered by you into this project.

## File Structure

* ``data`` - The folder where data is stored as you work.
* ``etc`` - Auxiliary files for running Docker services.

## Environments

* ``COMPOSE_PROJECT_NAME`` - Prefix for Docker Compose containers.
* ``FOUNDRY_IMAGE_VERSION`` - Version of [felddy/foundryvtt](https://github.com/felddy/foundryvtt-docker) image.
* ``FOUNDRY_ADMIN_PASSWORD`` - Administrator password for the Foundry application.
* ``FOUNDRY_USERNAME`` - Username for your [FoundryVTT](https://foundryvtt.com/) account.
* ``FOUNDRY_PASSWORD`` - Password for your [FoundryVTT](https://foundryvtt.com/) account.
* ``FOUNDRY_STORE_CONFIG`` - Save settings changed in the web interface, but disable auto-fill settings from your Foundry](https://foundryvtt.com/) account. It's recommended to set it to ``false`` for the first run, but after initial use, it's highly recommended to set it to ``true`` to save settings changes.
* ``NGINX_DOMAIN`` - Domain of the server, e.g., example.com.
* ``BACKUP_ENABLED`` - Flag for enabled bakcup process. By default is ``false``.
* ``NGINX_DOMAIN_EMAIL`` - Email for registering SSL certificates using Certbot.
* ``BACKUP_START_HOUR`` - Hour of the day when the project will create and upload backups.
* ``BACKUP_START_MINUTE`` - Minute of selected hour of the day when the project will create and upload backups.
* ``BACKUP_STORAGE_FOLDER`` - Path to storage disk folder to store backups.
* ``BACKUP_TIMEZONE`` - [Ubuntu timezone](https://manpages.ubuntu.com/manpages/trusty/man3/DateTime::TimeZone::Catalog.3pm.html) for backup service.
* ``BACKUP_BUFFER_SIZE`` - Buffer size of rclone in [copy command](https://rclone.org/commands/rclone_copy/)
* ``BACKUP_COMPRESSION_LEVEL`` - Compression level of zstd compression command.
* ``RCLONE_JSON_CONFIG`` - Json config for the rclone. You can make it via a [script](scripts/json-rclone-config.sh) from your local rclone config.

## Before You Start

1. Buy a server and register a domain on this server.
2. Prepare your server to run this project:
   3.1. Obtain SSH access to the server.
   3.2. Install [Docker](https://docs.docker.com/engine/install/).
3. Make json rclone config:
   3.1 Install [rclone](https://rclone.org/install/) to your device and connect a storag wich you want to use to backup your foundry project.
   3.2 Make json config using that [script](scripts/json-rclone-config.sh).
   3.3 Place maked json config to yout `.env`

## How to Start

1. Clone this project on your server:
   ```bash
   git clone https://github.com/yanodincov/foundry-aio-server.git
   ```

2. Create and fill in the `.env` file:
    ```bash
    cp .env.example .env
    ```

3. Run the project using [Docker Compose](https://docs.docker.com/compose/):
    ```bash
    docker-compose up -d
    ```

4. After successfully building and running Foundry, it's highly recommended to enable the ``FOUNDRY_STORE_CONFIG`` flag to preserve the configured Foundry settings via the web interface after restarting the service.
