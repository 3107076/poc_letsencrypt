#!/bin/bash
set -eu

CERT_DIR=/certs/certificates
CERT="$CERT_DIR/poc.local.crt"
KEY="$CERT_DIR/poc.local.key"

mkdir -p "$CERT_DIR" /webroot

# --- Bootstrap chicken-and-egg ---
# Se lego non ha ancora emesso il certificato reale, generiamo un self-signed
# temporaneo così nginx riesce ad avviarsi. Verrà sostituito al primo rilascio.
if [ ! -f "$CERT" ] || [ ! -f "$KEY" ]; then
  echo "[nginx] Nessun certificato ACME presente: genero un self-signed temporaneo di bootstrap."
  openssl req -x509 -newkey rsa:2048 -nodes \
    -keyout "$KEY" -out "$CERT" -days 1 \
    -subj "/CN=poc.local" >/dev/null 2>&1
fi

# --- Watcher: reload a caldo quando il certificato cambia (zero downtime) ---
(
  while inotifywait -q -e close_write,move,create "$CERT_DIR" >/dev/null; do
    sleep 1   # piccolo debounce: lego scrive .key e .crt in sequenza
    echo "[nginx] Certificato aggiornato -> nginx -s reload"
    nginx -s reload 2>/dev/null || true
  done
) &

echo "[nginx] Avvio nginx."
exec nginx -g 'daemon off;'
