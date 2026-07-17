#!/bin/bash
# Loop di rotazione REALISTICO (guidato dalla scadenza).
# Ogni CHECK_INTERVAL secondi esegue `lego run` SENZA forzare: lego rinnova solo se il
# certificato e' vicino alla scadenza (di default a ~1/2 o 1/3 della vita residua).
# Registriamo un evento solo quando il certificato cambia davvero (serial diverso).
set -uo pipefail

: "${DOMAIN:=poc.local}"
: "${ACME_SERVER:=https://pebble:14000/dir}"
: "${EMAIL:=poc@example.com}"
: "${CHECK_INTERVAL:=30}"
export LEGO_CA_CERTIFICATES="${LEGO_CA_CERTIFICATES:-/pebble.minica.pem}"

CRT="/certs/certificates/${DOMAIN}.crt"
serial_of(){ openssl x509 -in "$CRT" -noout -serial 2>/dev/null | sed 's/^serial=//'; }

echo "[acme] Loop realistico attivo: controllo ogni ${CHECK_INTERVAL}s; lego rinnova alla scadenza."
while true; do
  sleep "$CHECK_INTERVAL"
  before=$(serial_of)

  # Lock condiviso col rinnovo manuale: mai due `lego` in contemporanea.
  if ! mkdir /tmp/renew.lock 2>/dev/null; then
    echo "[acme] rinnovo manuale in corso, salto questo controllo."
    continue
  fi
  # --ari-disable: niente endpoint ARI, cosi' la soglia e' deterministica (frazione di vita).
  lego run --server "$ACME_SERVER" --email "$EMAIL" --accept-tos \
       --http --http.webroot /webroot \
       --domains "$DOMAIN" --path /certs \
       --ari-disable --no-random-sleep >/tmp/lego-check.log 2>&1
  rmdir /tmp/renew.lock 2>/dev/null

  after=$(serial_of)
  if [ -n "$after" ] && [ "$before" != "$after" ]; then
    echo "[acme] === Rotazione: certificato rinnovato in prossimita' della scadenza (serial ${after}) ==="
    /write-status.sh auto
  fi
done
