#!/bin/bash
# Rinnovo FORZATO singolo (override manuale on-demand: bottone dashboard o force-renew.ps1).
# Usa --renew-force: emette un nuovo certificato anche se quello attuale non e' in scadenza.
set -uo pipefail

: "${DOMAIN:=poc.local}"
: "${ACME_SERVER:=https://pebble:14000/dir}"
: "${EMAIL:=poc@example.com}"
: "${TRIGGER:=manual}"
export LEGO_CA_CERTIFICATES="${LEGO_CA_CERTIFICATES:-/pebble.minica.pem}"

# Lock condiviso col loop di controllo: mai due `lego` in contemporanea.
if ! mkdir /tmp/renew.lock 2>/dev/null; then
  echo "[acme] rinnovo gia' in corso, salto."
  exit 0
fi
trap 'rmdir /tmp/renew.lock 2>/dev/null' EXIT

if lego run --server "$ACME_SERVER" --email "$EMAIL" --accept-tos \
     --http --http.webroot /webroot \
     --domains "$DOMAIN" --path /certs \
     --renew-force --no-random-sleep; then
  # Aggiorna i dati della dashboard solo se il rinnovo e' andato a buon fine.
  /write-status.sh "$TRIGGER"
else
  exit 1
fi
