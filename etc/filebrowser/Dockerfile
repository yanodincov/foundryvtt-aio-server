FROM alpine:latest

RUN apk update && \
  apk upgrade && \
  apk add curl bash && \
  curl -fsSL https://raw.githubusercontent.com/filebrowser/get/master/get.sh | bash && \
  apk del bash curl

ENTRYPOINT filebrowser -d /db/filebrowser.db -c /config/config.json