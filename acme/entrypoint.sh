#!/bin/bash
set -uo pipefail

: "${DOMAIN:=poc.local}"
: "${ACME_SERVER:=https://pebble:14000/dir}"
: "${EMAIL:=poc@example.com}"
: "${CHECK_INTERVAL:=30}"
export LEGO_CA_CERTIFICATES="${LEGO_CA_CERTIFICATES:-/pebble.minica.pem}"

echo "[acme] Attendo che il server ACME (Pebble) sia raggiungibile su ${ACME_SERVER} ..."
until curl -fsS --cacert "$LEGO_CA_CERTIFICATES" "$ACME_SERVER" >/dev/null 2>&1; do
  sleep 2
done
echo "[acme] Pebble raggiungibile."

echo "[acme] Attendo che nginx risponda su http://${DOMAIN}/ (necessario per la challenge) ..."
until curl -fsS "http://${DOMAIN}/" -o /dev/null 2>&1; do
  sleep 2
done
echo "[acme] nginx raggiungibile."

# Listener HTTP per il bottone "Forza rinnovo" della dashboard (nginx fa da proxy su /api/renew).
echo "[acme] Avvio il listener del trigger manuale su :8080."
socat -T60 TCP-LISTEN:8080,reuseaddr,fork EXEC:/renew-http.sh &

echo "[acme] Emissione del certificato iniziale per ${DOMAIN} ..."
until lego run --server "$ACME_SERVER" --email "$EMAIL" --accept-tos \
      --http --http.webroot /webroot \
      --domains "$DOMAIN" --path /certs; do
  echo "[acme] Emissione fallita, riprovo tra 5s ..."
  sleep 5
done

echo "[acme] Certificato iniziale emesso."
/write-status.sh initial

echo "[acme] Avvio il loop di rotazione (controllo ogni ${CHECK_INTERVAL}s)."
exec /rotate-loop.sh
