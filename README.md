# PoC — Rotazione automatica dei certificati SSL (ACME + nginx + Docker)

Piccolo proof-of-concept che replica **in locale, senza un dominio pubblico**, il
processo reale di rotazione automatica dei certificati TLS di Let's Encrypt:

```
richiesta → challenge HTTP-01 → emissione → rinnovo → reload di nginx senza downtime
```

La "finta Let's Encrypt" è **[Pebble](https://github.com/letsencrypt/pebble)**, il server
ACME di test ufficiale di Let's Encrypt: parla lo **stesso protocollo (ACME)** ma la CA
gira in un container. Il client ACME è **[lego](https://go-acme.github.io/lego/)**.

## Componenti

| Servizio | Ruolo |
|----------|-------|
| **pebble** | CA / server ACME di test |
| **nginx**  | Espone la **dashboard** HTTPS su `:443` (+ `/api/`), serve la challenge su `:80`, si **auto-ricarica** quando il certificato cambia |
| **acme**   | `lego`: emette il certificato iniziale e poi lo **ruota in loop** |

Dominio del PoC: **`poc.local`** (alias di rete Docker sul container nginx).

## Prerequisiti

- **Docker Desktop** installato e **avviato** (`docker version` deve mostrare anche `Server`).

## Avvio

```powershell
cd path\to\ssl-rotation-poc

docker compose build
docker compose up -d

# Segui l'emissione e le rotazioni:
docker compose logs -f acme
```

## Dashboard

Apri **https://poc.local/** (o **https://localhost/**) nel browser. Mostra dal vivo il
certificato servito, il countdown alla prossima rotazione, il contatore delle emissioni, il
grafico degli intervalli di rotazione, la timeline degli eventi e una sezione che spiega il PoC.

> **Dominio locale**: aggiungi `127.0.0.1 poc.local` al file
> `C:\Windows\System32\drivers\etc\hosts` (richiede admin). nginx è mappato sulle porte
> standard **80/443**, quindi l'URL è pulito: `https://poc.local/`.

### Certificato attendibile (togliere l'alert del browser)

Il certificato è firmato dalla CA di test **Pebble**, che il sistema non conosce: per questo il
browser mostra l'avviso. Per farlo diventare "verde", installa la **root CA di Pebble**:

```powershell
.\scripts\trust-pebble-root.ps1      # scarica la root corrente e la installa (store utente)
# poi riavvia il browser e apri https://poc.local/
.\scripts\untrust-pebble-root.ps1    # per rimuoverla
```

> ⚠️ **Pebble rigenera la root a ogni riavvio** (è stateless): dopo un `docker compose down/up`
> o un restart di `pebble`, la root cambia. Ri-esegui `trust-pebble-root.ps1` (e `untrust` per
> pulire la vecchia). Firefox usa un proprio store: vai su *Impostazioni → Privacy → Certificati
> → Autorità → Importa* e seleziona il file scaricato in `%TEMP%\pebble-root.pem`.

## Verifica

```powershell
# 1) Endpoint HTTPS attivo (CA di test => serve -k finché non installi la root):
curl.exe -vk https://poc.local/

# 2) Rotazione dal vivo: serial e fingerprint cambiano a ogni ciclo (~60s),
#    ma la connessione resta sempre servita (reload a caldo, zero downtime):
.\scripts\watch-cert.ps1

# 3) Rinnovo manuale on-demand:
.\scripts\force-renew.ps1
```

Log utili:

```powershell
docker compose logs -f pebble   # challenge validate dalla CA
docker compose logs -f nginx    # reload a caldo di nginx
```

## Stop

```powershell
docker compose down -v          # ferma e cancella i volumi (Pebble è stateless)
```

## Note

- I certificati sono emessi da una CA di **test** (Pebble): browser e OS non li considerano
  validi. È atteso — si usa `-k` / `--insecure`.
- Il rinnovo è **forzato a ogni ciclo** (`lego run --renew-force`) solo per rendere la
  rotazione osservabile in secondi. In produzione si ometterebbe `--renew-force` e si
  lascerebbe a lego decidere in base alla finestra di scadenza (`--renew-days` / ARI).
- La configurazione è documentata in dettaglio in [`CLAUDE.md`](./CLAUDE.md).
