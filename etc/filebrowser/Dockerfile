FROM alpine:latest

RUN apk update && \
  apk upgrade && \
  apk add curl gettext bash && \
  curl -fsSL https://raw.githubusercontent.com/filebrowser/get/master/get.sh | bash && \
  apk del bash && \
  mkdir /cfg

COPY ./etc/filebrowser/config/config.template.json /cfg/config.template.json

ENTRYPOINT envsubst < /cfg/config.template.json > /config.json && filebrowser -c /config.json