FROM nginx:alpine

# inotify-tools: per il watch del certificato; openssl: per il self-signed di bootstrap; bash: per l'entrypoint
RUN apk add --no-cache inotify-tools openssl bash

COPY default.conf /etc/nginx/conf.d/default.conf
COPY dashboard/index.html /usr/share/nginx/html/index.html
COPY entrypoint.sh /entrypoint.sh
# Normalizza eventuali CRLF (file editati su Windows) e rende eseguibile
RUN sed -i 's/\r$//' /entrypoint.sh && chmod +x /entrypoint.sh

EXPOSE 80 443
ENTRYPOINT ["/entrypoint.sh"]
