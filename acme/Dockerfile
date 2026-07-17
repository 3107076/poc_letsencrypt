# Prendiamo il binario lego dall'immagine ufficiale
FROM goacme/lego:latest AS lego

FROM alpine:latest
RUN apk add --no-cache bash openssl curl ca-certificates socat

COPY --from=lego /lego /usr/bin/lego
# CA che firma il certificato TLS dell'API di Pebble (per fidarsi del server ACME)
COPY pebble.minica.pem /pebble.minica.pem
COPY entrypoint.sh rotate-loop.sh renew-once.sh write-status.sh renew-http.sh /
# Normalizza eventuali CRLF (file editati su Windows) e rende eseguibili
RUN sed -i 's/\r$//' /entrypoint.sh /rotate-loop.sh /renew-once.sh /write-status.sh /renew-http.sh \
    && chmod +x /entrypoint.sh /rotate-loop.sh /renew-once.sh /write-status.sh /renew-http.sh

ENTRYPOINT ["/entrypoint.sh"]
