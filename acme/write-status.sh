#!/bin/bash
# Produce i dati per la dashboard: parsa il certificato corrente con openssl e scrive
# /web/status.json (stato attuale) + append su /web/history.jsonl (uno storico di eventi).
# Argomento $1 = trigger dell'evento: "initial" | "auto" | "manual".
set -uo pipefail

TRIGGER="${1:-auto}"
: "${DOMAIN:=poc.local}"

CRT="/certs/certificates/${DOMAIN}.crt"
WEB="/web"
HIST="$WEB/history.jsonl"

mkdir -p "$WEB"
[ -f "$CRT" ] || { echo "[status] certificato assente, skip"; exit 0; }

# --- Campi estratti dal certificato ---
serial=$(openssl x509 -in "$CRT" -noout -serial 2>/dev/null | sed 's/^serial=//')
issuer=$(openssl x509 -in "$CRT" -noout -issuer 2>/dev/null | sed 's/^issuer=//')
nb=$(openssl x509 -in "$CRT" -noout -startdate 2>/dev/null | sed 's/^notBefore=//')
na=$(openssl x509 -in "$CRT" -noout -enddate  2>/dev/null | sed 's/^notAfter=//')
fp=$(openssl x509 -in "$CRT" -noout -fingerprint -sha256 2>/dev/null | sed 's/^.*=//')
san=$(openssl x509 -in "$CRT" -noout -ext subjectAltName 2>/dev/null \
        | grep -oE 'DNS:[^,]+' | sed 's/DNS://' | tr '\n' ',' | sed 's/,$//')
keybits=$(openssl x509 -in "$CRT" -noout -text 2>/dev/null | grep -m1 -oE 'Public-Key: \([0-9]+ bit\)' | grep -oE '[0-9]+')
if openssl x509 -in "$CRT" -noout -text 2>/dev/null | grep -qi 'id-ecPublicKey'; then
  keytype="EC ${keybits:-?}"
else
  keytype="RSA ${keybits:-?}"
fi
ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# Converte una data openssl ("Jul 16 13:02:00 2026 GMT") in epoch UTC.
to_epoch(){
  local s="${1% GMT}" mon day tm year mm d2
  mon=$(echo "$s" | awk '{print $1}'); day=$(echo "$s" | awk '{print $2}')
  tm=$(echo "$s" | awk '{print $3}'); year=$(echo "$s" | awk '{print $4}')
  case "$mon" in Jan)mm=01;;Feb)mm=02;;Mar)mm=03;;Apr)mm=04;;May)mm=05;;Jun)mm=06;;
                 Jul)mm=07;;Aug)mm=08;;Sep)mm=09;;Oct)mm=10;;Nov)mm=11;;Dec)mm=12;;*)mm=01;;esac
  d2=$(printf '%02d' "$day" 2>/dev/null || echo "$day")
  date -u -d "${year}-${mm}-${d2} ${tm}" +%s 2>/dev/null
}
nb_epoch=$(to_epoch "$nb"); na_epoch=$(to_epoch "$na")
lifetime=0
[ -n "$nb_epoch" ] && [ -n "$na_epoch" ] && lifetime=$((na_epoch - nb_epoch))
[ -z "$na_epoch" ] && na_epoch=0

# --- Storico: una riga JSON per evento (append) ---
printf '{"ts":"%s","serial":"%s","trigger":"%s","not_after":"%s"}\n' \
  "$ts" "$serial" "$TRIGGER" "$na" >> "$HIST"

issuances=$(wc -l < "$HIST" | tr -d ' ')
# Ultimi 10 eventi, dal piu' recente al piu' vecchio, uniti in un array JSON.
hist=$(tail -n 10 "$HIST" | awk '{a[NR]=$0} END{for(i=NR;i>=1;i--) printf "%s%s",(i<NR?",":""),a[i]}')

# --- status.json (scrittura atomica via file temporaneo) ---
cat > "$WEB/status.json.tmp" <<EOF
{
  "domain": "$DOMAIN",
  "mode": "expiry",
  "updated": "$ts",
  "cert_lifetime": $lifetime,
  "issuances": $issuances,
  "current": {
    "serial": "$serial",
    "issuer": "$issuer",
    "san": "$san",
    "not_before": "$nb",
    "not_after": "$na",
    "not_after_epoch": $na_epoch,
    "fingerprint_sha256": "$fp",
    "key_type": "$keytype",
    "trigger": "$TRIGGER"
  },
  "history": [ $hist ]
}
EOF
mv "$WEB/status.json.tmp" "$WEB/status.json"
echo "[status] aggiornato ($TRIGGER): serial=$serial lifetime=${lifetime}s issuances=$issuances"
