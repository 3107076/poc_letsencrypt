# CLAUDE.md — PoC Rotazione automatica certificati SSL

> **PROTOCOLLO DI AUTO-AGGIORNAMENTO (per Claude)**
> Questo file è la **fonte di verità** del progetto e va mantenuto aggiornato.
> Dopo ogni modifica significativa — nuovi file o servizi, cambi di configurazione,
> nuove porte/volumi, nuovi comandi, decisioni architetturali — **aggiorna**:
> 1. la sezione **Stato corrente** (checklist ✅/⬜),
> 2. la sezione **Comandi rapidi** se cambiano i comandi,
> 3. le **Decisioni & convenzioni** se cambia una scelta.
> Mantieni le descrizioni sintetiche. Non serve chiedere il permesso per aggiornare questo file.

---

## 1. Scopo del PoC

Dimostrare, **in locale e senza un dominio pubblico**, il processo reale di
**rotazione automatica dei certificati TLS** come avviene con Let's Encrypt:

    richiesta → challenge HTTP-01 → emissione → rinnovo → reload di nginx senza downtime

Il vero Let's Encrypt richiede un dominio raggiungibile da internet, quindi non è
usabile in locale. Replichiamo lo **stesso protocollo (ACME)** con **Pebble**, il
server ACME di test ufficiale di Let's Encrypt, che gira in un container. Il flusso
è identico a quello di produzione; cambia solo che la CA è nostra.

## 2. Architettura

Tre container Docker sulla stessa rete (fake domain: **`poc.local`**):

| Servizio | Immagine | Ruolo |
|----------|----------|-------|
| **pebble** | `ghcr.io/letsencrypt/pebble` | CA/server ACME di test. Emette e valida i certificati. |
| **nginx**  | custom (`nginx:alpine` + inotify) | Serve la **dashboard** HTTPS su `:443` (+ `/api/`) con il cert emesso; serve la challenge su `:80`. Alias di rete `poc.local`. Si **auto-ricarica** quando il cert cambia. |
| **acme**   | custom (`alpine` + `lego`) | Client ACME. Emette il cert iniziale, poi lo ruota in loop; script per rinnovo manuale; scrive i dati della dashboard (`write-status.sh`). |

### Flusso di rotazione (il cuore del PoC)
1. `lego` (container **acme**) chiede/rinnova il cert a Pebble via challenge **HTTP-01 webroot**:
   scrive il token in `webroot/.well-known/acme-challenge/` (volume condiviso con nginx).
2. Pebble valida contattando `http://poc.local:80/.well-known/...` (risolto via DNS Docker sull'alias nginx).
3. `lego` scrive il nuovo `.crt`/`.key` nel volume `certs`.
4. `inotifywait` (container **nginx**) rileva il cambio → `nginx -s reload` → **sostituzione a caldo, zero downtime**.

È esattamente il pattern reale **certbot/lego + nginx**.

**Trigger della rotazione** (modalità realistica *expiry-driven*):
- **auto**: il loop `rotate-loop.sh` esegue `lego run` (senza forzare) ogni `CHECK_INTERVAL`s; lego rinnova **solo** quando il cert si avvicina alla scadenza (profilo Pebble a vita corta, ~5 min → rinnovo a ~½ vita). Un evento viene registrato solo se il serial cambia davvero.
- **manual**: `renew-once.sh` con `--renew-force` (bottone della dashboard via `/api/renew`, oppure `scripts/force-renew.ps1`). Un `mkdir`-lock condiviso serializza auto e manuale.

### Dashboard (interfaccia grafica del PoC)
- A ogni emissione/rinnovo, `acme` esegue `write-status.sh <trigger>`: parsa il cert con `openssl` e scrive **`/web/status.json`** (stato corrente) + append su **`/web/history.jsonl`** (storico eventi). `<trigger>` = `initial` | `auto` | `manual`.
- `nginx` serve una **dashboard statica** (`nginx/dashboard/index.html`, HTML/CSS/JS inline, zero dipendenze) su `:443` ed espone il volume `web` su **`/api/`**. La pagina fa polling di `/api/status.json` ogni 3s.
- **Taglio della pagina = divulgativo per pubblico non tecnico** (forma impersonale, tono "mini-corso" leggero). Struttura: **sticky header** (titolo `🔒 Rotazione automatica SSL` + check verde di stato live + pulsante "Vai alla demo") → **narrativa in atti** (hero "come un sito dimostra la propria identità"; cos'è un certificato con tooltip; "e se scade" con **3 card articoli reali** + bottone `expired.badssl.com`; **roadmap 398→200→100→47 giorni** CA/Browser Forum; il **"monopolio"** delle CA + origine VeriSign + contro di Let's Encrypt; **ACME con confronto prima/dopo** — flusso manuale con CSR vs automatico — e dialogo) → **diagramma del flusso** a 6 step come **timeline verticale** (spiegazioni sempre visibili) → **demo dal vivo** (countdown, vita cert, emissioni, cert corrente, grafico intervalli SVG, timeline ultimi 10) → **schema infrastrutturale interattivo** (cornici "PC locale"/"rete Docker" con frecce etichettate, 10 componenti cliccabili) → **glossario** → **dipendenze del progetto**. Si mostra **sempre tutto** (niente modalità tecnica). Guard: `html/body` **senza** `overflow-x:hidden` (romperebbe la sticky).
- **Bottone "Forza rinnovo"**: `fetch('/api/renew', POST)` → nginx fa da reverse proxy verso un listener `socat` nel container `acme` (`renew-http.sh` → `renew-once.sh`). Solo POST; nessuna auth (PoC, porta 8080 non esposta sull'host).
- `status.json` include: `mode` (`expiry`), `cert_lifetime` (s), `current.not_after_epoch`, oltre a serial/issuer/san/date/fingerprint/key_type/trigger e `history` (ultimi 10).
- Colori trigger validati per lo sfondo scuro (skill dataviz): `initial #2563eb`, `auto #16a34a`, `manual #d97706`. Accent brand: `#38bdf8` (distinto dai categorici).
- Volume condiviso **`web`**: scritto da `acme` (rw), servito da `nginx` (ro).
- URL: `https://poc.local/` (porte host standard 80/443; richiede `127.0.0.1 poc.local` nel file hosts). Anche `https://localhost/`.

## 3. Struttura file

```
ssl-rotation-poc/
├── CLAUDE.md                 # questo file (memoria di progetto)
├── docker-compose.yml        # orchestrazione 3 servizi + volumi
├── pebble/
│   └── pebble-config.json    # httpPort 80, tlsPort 443, profilo default validityPeriod 300s
├── nginx/
│   ├── Dockerfile            # nginx:alpine + inotify-tools + openssl
│   ├── default.conf          # :80 (challenge) + :443 (dashboard, /api/, /api/renew proxy)
│   ├── dashboard/index.html  # UI divulgativa del PoC (narrativa ad atti + demo live + schemi interattivi)
│   └── entrypoint.sh         # bootstrap self-signed + watch-and-reload
├── acme/
│   ├── Dockerfile            # alpine + lego + socat + pebble.minica.pem
│   ├── pebble.minica.pem     # CA per fidarsi dell'API TLS di Pebble
│   ├── entrypoint.sh         # attende pebble+nginx, emette cert, avvia listener + loop
│   ├── rotate-loop.sh        # loop realistico: lego run non forzato ogni CHECK_INTERVAL
│   ├── renew-once.sh         # rinnovo FORZATO (--renew-force): bottone + force-renew.ps1
│   ├── renew-http.sh         # handler HTTP (socat) per il bottone -> renew-once.sh
│   └── write-status.sh       # scrive status.json/history.jsonl per la dashboard
├── scripts/
│   ├── watch-cert.ps1        # osserva serial/fingerprint del cert servito
│   ├── force-renew.ps1       # forza un rinnovo on-demand
│   ├── trust-pebble-root.ps1 # installa la root CA corrente di Pebble (togli l'alert browser)
│   └── untrust-pebble-root.ps1 # rimuove le root Pebble dallo store utente
└── README.md
```

## 4. Comandi rapidi

Prerequisito: **Docker Desktop avviato** (verifica: `docker version` mostra anche `Server`).

```powershell
cd path\to\ssl-rotation-poc

docker compose build          # costruisce le immagini nginx e acme
docker compose up -d          # avvia lo stack
docker compose logs -f acme   # segue emissione + rotazioni
docker compose logs -f pebble # segue le challenge validate da Pebble
docker compose logs -f nginx  # segue i reload di nginx

# Verifica endpoint HTTPS (CA di test => serve -k finche' non installi la root):
curl.exe -vk https://poc.local/

# Osserva la rotazione dal vivo (serial/fingerprint cambiano a ogni ciclo):
scripts\watch-cert.ps1

# Trigger manuale di rinnovo:
scripts\force-renew.ps1

docker compose down -v        # ferma tutto e cancella i volumi (Pebble è stateless)
```

## 5. Decisioni & convenzioni

- **Fake domain**: `poc.local` — è un alias di rete Docker sul container nginx; Pebble lo risolve via DNS embedded di Docker (`127.0.0.11:53`).
- **Porte host**: `443→443` (HTTPS, URL pulito `https://poc.local/`), `80→80` (challenge/redirect), `14000/15000` (API/management Pebble; `:15000/roots/0` espone la root CA corrente).
- **Volumi condivisi**: `webroot` (acme↔nginx, token challenge), `certs` (output lego ↔ cert usati da nginx), `web` (acme→nginx, `status.json`/`history.jsonl` per la dashboard).
- **Dashboard**: statica servita da nginx; il solo "backend" è un listener `socat` in acme per il bottone (nessun servizio extra). I dati vengono dal container acme che parsa il cert con `openssl` a ogni rinnovo. Trigger tracciati: `initial`/`auto`/`manual`.
- **Client ACME**: `lego` (binario Go, semplice per CA custom e webroot). Preso da `goacme/lego` (binario in `/lego`, entrypoint `["/lego"]`) e copiato in `/usr/bin/lego` nell'immagine finale (così è nel PATH).
- **Trust del server ACME**: `LEGO_CA_CERTIFICATES=/pebble.minica.pem`. Il cert API di Pebble ha SAN `pebble` (verificato), quindi `https://pebble:14000/dir` non dà errori di hostname.
- **Sintassi lego v5**: in lego 5.x **non esiste più il comando `renew`** — `run` fa "get *or* renew"; inoltre i flag (`--server`, `--email`, `--http`, `--path`, …) sono **opzioni del sottocomando** e vanno messi **dopo** `run`, non prima.
- **Modalità rotazione (realistica, expiry-driven)**: il profilo Pebble emette cert a **vita corta (300s)**; il loop fa `lego run` non forzato con `--ari-disable` ogni `CHECK_INTERVAL`s → lego rinnova a ~½ vita residua. Il **rinnovo forzato** (`--renew-force`) resta solo come **override manuale** (bottone / `force-renew.ps1`).
- **Immagine Pebble**: `ghcr.io/letsencrypt/pebble` (GitHub Container Registry — non più su Docker Hub). L'entrypoint dell'immagine **è già il binario** Pebble, quindi in `command:` si passano solo gli argomenti (`-config … -dnsserver …`), senza ripetere `pebble`.
- **Reload senza downtime**: `inotifywait` nel container nginx → `nginx -s reload`. Nessun docker socket esposto.
- **Bootstrap chicken-and-egg**: al primo avvio nginx genera un self-signed temporaneo così parte prima che lego abbia emesso il cert reale.
- **CHECK_INTERVAL**: `30`s (env acme) = ogni quanto il loop controlla se rinnovare. La **vita del cert** (300s) sta in `pebble/pebble-config.json` (`profiles.default.validityPeriod`) e determina la cadenza naturale.

## 6. Caveat noti

- La CA è **Pebble (test)** → browser/OS non si fidano: usare `-k`/`--insecure`, **oppure** installare la root CA di Pebble (`scripts/trust-pebble-root.ps1`, store utente, no admin) per avere il lucchetto verde su `https://poc.local/`.
- Pebble è **stateless**: a ogni riavvio rigenera CA e chiavi. Conseguenza sul trust: la root installata **smette di combaciare** dopo un restart di pebble → ri-eseguire `trust-pebble-root.ps1` (e `untrust` per pulire). Firefox usa uno store proprio (import manuale).
- File su filesystem Windows: i bind mount verso container Linux passano da Docker Desktop (lieve overhead, irrilevante).

## 7. Stato corrente

- ✅ Scaffolding progetto (tutti i file creati)
- ✅ `pebble.minica.pem` vendorizzato (verificato: firma il cert API dell'immagine ghcr, nessun errore TLS)
- ✅ Docker Desktop avviato e `docker version` OK (daemon)
- ✅ `docker compose build` eseguito con successo
- ✅ `docker compose up -d` → cert iniziale emesso via ACME, HTTPS su porte standard 80/443 (`https://poc.local/`)
- ✅ **Rotazione automatica guidata dalla scadenza** verificata (evento `auto` a ~½ vita, senza intervento)
- ✅ Trigger manuale verificato (bottone dashboard `/api/renew` + `force-renew.ps1` → nuovo serial)
- ✅ Dashboard su `https://poc.local/`: countdown alla scadenza, grafico intervalli, storico ultimi 10, sezione didattica + diagramma flusso, bottone Forza rinnovo
- ✅ Porte host standard 80/443; trust opzionale via `trust-pebble-root.ps1`
- ✅ **Dashboard divulgativa** (2026-07-17): riscrittura per pubblico non tecnico (narrativa ad atti, sticky header, modalità tecnica, card articoli reali, roadmap 398→47, **schema infrastrutturale interattivo**). Ricostruita `nginx` + verificata servita (HTTP 200) con stato live fresco.

**PoC completo e funzionante (2026-07-17).** Modalità attuale: **realistica (expiry-driven)** — cert a vita 5 min, rinnovo automatico alla scadenza + override manuale. Dashboard in taglio divulgativo per presentazione a pubblico non tecnico.

### Idee future / in piano (non ancora fatte)
- **Wow dal vivo** (step 2): feed eventi in italiano, contatore "0s di disservizio su N rinnovi", diagramma di flusso che si illumina in tempo reale durante la rotazione.
- **Rompi e guarisci** (step 3): bottone "Simula guasto" → cert scaduto sul sito della demo → avviso rosso del browser → auto-riparazione.
- **Esempio Windows/IIS** (in valutazione): win-acme contro lo stesso Pebble; nota: container Windows/IIS non convivono col Linux stack sullo stesso Docker Desktop (modalità unica) → serve host/VM Windows.
