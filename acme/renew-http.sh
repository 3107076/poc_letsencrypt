#!/bin/bash
# Handler HTTP minimale invocato da socat (un processo per connessione).
# Legge e scarta la richiesta, forza un rinnovo del certificato e risponde in JSON.
# NOTA: e' un PoC -> nessuna autenticazione. Raggiungibile solo dalla rete Docker
# interna (nginx fa da reverse proxy su /api/renew); la porta non e' esposta sull'host.
set -uo pipefail

# Consuma la request line + gli header fino alla riga vuota (stdin = socket).
read -r _reqline
while IFS= read -r line; do
  line=${line%$'\r'}
  [ -z "$line" ] && break
done

# Forza il rinnovo (output tenuto fuori dal socket, altrimenti sporca la risposta HTTP).
if TRIGGER=manual /renew-once.sh >/tmp/renew-http.log 2>&1; then
  body='{"ok":true,"message":"Rinnovo forzato completato"}'
  code='200 OK'
else
  body='{"ok":false,"message":"Rinnovo fallito - vedi i log di acme"}'
  code='500 Internal Server Error'
fi

printf 'HTTP/1.1 %s\r\nContent-Type: application/json\r\nContent-Length: %s\r\nConnection: close\r\n\r\n%s' \
  "$code" "${#body}" "$body"
