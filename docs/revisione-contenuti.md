# Revisione contenuti dashboard — versione "spiegata ai non tecnici"

> ⚠️ **Nota.** Questo è il **documento di progettazione iniziale** dei contenuti. La pagina finale
> (`nginx/dashboard/index.html`) è stata poi rifinita e diverge in alcuni punti — es. niente
> "modalità tecnica" (si mostra sempre tutto), «**monopolio**» al posto di «racket», aggiunta del
> confronto **prima/dopo con la CSR**, della sezione **dipendenze**, e header con pulsante demo +
> check verde di stato. In caso di dubbio, **fa fede il codice della pagina**.

> **A cosa serve questo file.** Qui ci sono *tutti i testi* che finiranno nella pagina, da
> rivedere **prima** che si tocchi il codice. Sono i contenuti veri (copy), non un riassunto: se
> una frase non va, si corregge qui e finisce in pagina pari pari.
>
> **Pubblico**: colleghi non-IT, partono da zero. **Tono**: mini-corso, ma leggero e con qualche
> battuta — se diventa un muro tecnico ci si addormenta. La pagina fa da supporto a chi presenta:
> testi brevi, un concetto per blocco, tante analogie.
>
> **Forma impersonale** in tutto il copy di pagina (niente "tu"/"tua", niente rivolgersi diretto):
> si presenta meglio dal vivo.
>
> **Nota sull'ordine di lavoro.** Questo file copre lo step 1 concordato — *Comprensione per
> non-tecnici* (contenuti + struttura narrativa). Gli step 2 (*Wow dal vivo*: feed eventi,
> contatore "0s di downtime", diagramma che si illumina) e 3 (*Rompi e guarisci*) arrivano dopo,
> come modifiche separate. Qui sotto è indicato solo dove si aggancieranno.

---

## Come sarà strutturata la pagina (dall'alto in basso)

Idea di fondo: la pagina racconta una **storia in atti**, poi mostra la **demo dal vivo**. Chi
presenta accompagna dall'alto verso il basso come un'unica slide scrollabile.

1. **Apertura** — "cosa sto guardando" in una frase
2. **Cos'è un certificato** — l'analogia
3. **Perché conta** — cosa succede se manca/scade
4. **Il problema che si aggrava** — i certificati durano sempre meno (398 → 47 giorni)
5. **Il "racket" e la rivoluzione gratis** — le CA a pagamento vs Let's Encrypt
6. **La soluzione: l'automazione** — il robot che rinnova da solo (aggancio al diagramma)
7. **La demo dal vivo** — le sezioni tecniche che già esistono, con testi rivisti
8. **Glossario** — i termini che compaiono, spiegati in una riga

### Sticky header (barra fissa in alto)

Barra **fissa** che resta visibile durante lo scroll (ottima per presentare — lo stato "vivo" è
sempre sott'occhio anche mentre si spiega la teoria). Contenuto, **neutro senza nome/marchio**:

- **Sinistra** — titolo compatto: `🔒 Rotazione automatica dei certificati TLS` + un **pallino
  verde "sistema attivo"** che pulsa.
- **Centro** — mini-stato dal vivo: *"Certificato valido · scade tra 02:14"* con countdown, così
  durante tutta la spiegazione resta visibile il timer che scorre.
- **Destra** — interruttore **"🤓 Modalità tecnica"** (default OFF: pagina semplice; ON: compaiono
  serial, fingerprint, log ACME grezzi) + link **"↓ Vai alla demo"** che scrolla alle sezioni vive.
- *(Predisposto ma per dopo: interruttore lingua **IT / EN**.)*

Le chicche più ingombranti (contatore *0s di disservizio*, feed eventi) restano nel corpo pagina,
non nell'header, per non affollarlo. Una pagina sola, due pubblici.

---

## ATTO 1 — Apertura (hero)

**Titolo grande:**
> # Come un sito si rinnova la "patente" da solo

**Sottotitolo:**
> Ogni sito sicuro (quello col lucchetto 🔒) ha un documento d'identità digitale che **scade**.
> Questa demo mostra, dal vivo, come quel documento venga **rinnovato in automatico** prima della
> scadenza — senza che nessuno debba ricordarsene e **senza mai spegnere il sito**.

**Riquadro "Cosa sto guardando?" (call-out chiaro, sfondo tenue):**
> 👀 **In parole povere:** qui sotto c'è un sito finto che si rifà il certificato di sicurezza
> ogni pochi minuti, da solo. Normalmente succede ogni pochi mesi e non lo si vede mai; qui è
> stato accelerato apposta, per mostrarlo in diretta.

**Ponte verso l'atto 2 (due parole su HTTPS):**
> La **"s" di HTTP*s*** — e il lucchetto accanto all'indirizzo — segna la differenza tra un sito
> "normale" e un sito **sicuro**. Ma cosa la rende possibile, tecnicamente? Un unico oggetto, che
> lavora dietro le quinte di ogni sito sicuro: il **certificato**. Vale la pena vedere cos'è. 👇

---

## ATTO 2 — Cos'è un certificato SSL/TLS?

**Titolo:** 🪪 Cos'è un certificato (e perché c'entra il lucchetto)

**Testo:**
> Il **lucchetto** 🔒 vicino all'indirizzo del sito indica due cose:
>
> 1. **"Si sta parlando davvero con chi si crede"** — non con un impostore messo in mezzo.
> 2. **"Quello che ci si dice è in una busta sigillata"** — password, numeri di carta, messaggi:
>    nessuno può leggerli lungo il tragitto.
>
> A rendere possibile tutto questo è un **certificato**: in pratica la **carta d'identità del
> sito**. Come una carta d'identità, è rilasciato da un ente di cui ci si fida, riporta un "nome"
> (l'indirizzo del sito) e — dettaglio importante — **ha una data di scadenza**.

**Analogia da tenere a mente (riquadro):**
> 🪪 **Certificato = carta d'identità del sito.** Rilasciato da un ente fidato, con nome e
> scadenza. Se è valido, il browser mostra il lucchetto. Se scade, iniziano i guai (atto 3).

*(Tooltip sul termine "certificato" ovunque compaia: «Il documento d'identità digitale del sito,
con scadenza. Prova che il sito è chi dice di essere e permette la connessione cifrata.»)*

---

## ATTO 3 — Perché è importante? (cosa succede se scade)

**Titolo:** 💥 E se scade? (spoiler: succede un casino)

**Testo:**
> Una carta d'identità scaduta, all'aeroporto, blocca al gate. Un **certificato scaduto** fa di
> peggio: il browser di **ogni singolo visitatore** mostra una pagina rossa spaventosa —
> *"La connessione non è privata"*, *"Sito non sicuro"* — e la maggior parte delle persone
> scappa. Per un'azienda significa **sito di fatto irraggiungibile**, vendite perse e figuraccia.

**Riquadro "storie vere":**
> 😬 **Non succede solo ai piccoli.** Colossi come Microsoft, grandi operatori telefonici e
> Spotify sono finiti offline **per un certificato dimenticato e scaduto**. Un post-it non
> ricordato al momento giusto, e mezzo mondo resta fuori. Capita. Ed è esattamente ciò che
> l'automazione elimina.

**Preview articoli (3 "ritagli di giornale" affiancati).** Card statiche in stile notizia —
titolo + testata + data + una riga di estratto + **link reale** all'articolo. *Niente immagini
esterne hotlinkate*: le card sono disegnate in CSS, così restano leggibili anche offline in
presentazione (coerente col fatto che tutta la demo gira in locale). Il link apre l'articolo vero
in una nuova scheda per chi vuole approfondire. Contenuti (verificati):

> 📰 **Microsoft Teams KO in tutto il mondo per un certificato scaduto**
> — *Engadget · 3 febbraio 2020*
> Microsoft dimentica di rinnovare un certificato: Teams giù per ore, circa **20 milioni di
> utenti** tagliati fuori in pieno smart working.
> 🔗 https://www.engadget.com/2020/02/03/microsoft-teams-expired-certificate/
>
> 📰 **Un certificato scaduto lascia offline milioni di telefoni**
> — *TechCrunch · 7 dicembre 2018*
> Un certificato scaduto nel software Ericsson blocca le reti mobili: **~32 milioni di utenti O2**
> nel Regno Unito e decine di milioni di SoftBank in Giappone senza dati per un giorno.
> 🔗 https://techcrunch.com/2018/12/07/heres-what-caused-yesterdays-o2-and-softbank-outages/
>
> 📰 **The Day the Music Died: Spotify ko per un certificato scaduto**
> — *The SSL Store · agosto 2020*
> Un certificato *wildcard* dimenticato mette fuori uso lo streaming per circa un'ora:
> **#spotifydown** finisce in tendenza.
> 🔗 https://www.thesslstore.com/blog/the-day-the-music-died-certificate-expiration-takes-down-spotify/

**Pulsante "Mostra com'è fatto un avviso ↗"** (in pagina, accanto alle card):
> Apre in una nuova scheda **https://expired.badssl.com** — un sito nato apposta con un
> certificato scaduto: mostra dal vivo la pagina rossa del browser.
> *(Più avanti, nello step "Rompi e guarisci", lo stesso avviso comparirà sul sito della demo,
> non su un sito esterno.)*

---

## ATTO 4 — Il problema che si aggrava: durano sempre meno

**Titolo:** ⏳ E adesso scadono sempre più in fretta

**Testo:**
> Ecco il colpo di scena. Per motivi di sicurezza (un documento rubato che dura poco fa meno
> danni), l'industria ha deciso di **accorciare drasticamente** la vita dei certificati. Non è
> un'ipotesi: è già deciso e in calendario.

**Timeline visiva (grafico/righe, numeri esatti):**

| Quando | Durata massima di un certificato |
|---|---|
| Fino a poco fa | **398 giorni** (~13 mesi) |
| **Da marzo 2026** | **200 giorni** ← *già in vigore* |
| Da marzo 2027 | **100 giorni** |
| **Da marzo 2029** | **47 giorni** (poco più di un mese!) |

> Fonte: **CA/Browser Forum** (ballot SC-081v3, 2025), l'organismo — browser + autorità di
> certificazione — che detta le regole. Decisione approvata all'unanimità.

**La morale (riquadro, è il cuore del "perché lo facciamo"):**
> 🤖 **Ecco perché serve l'automazione.** Rinnovare a mano un documento ogni ~13 mesi era
> fastidioso ma gestibile. Farlo **ogni 47 giorni, su decine o centinaia di siti**, a mano, è
> semplicemente impossibile senza sbagliare. L'automazione smette di essere una comodità e
> diventa **l'unico modo per sopravvivere**. Questa demo mostra proprio quel meccanismo.

---

## ATTO 5 — Il "racket" delle CA e la rivoluzione gratis

**Titolo:** 💸 Piccola parentesi: perché una volta era pure un salasso

**Testo (tono ironico, impersonale):**
> Fino a non molti anni fa quel documento d'identità andava **comprato**, ogni anno, da aziende
> chiamate **Autorità di Certificazione** (CA). Il modello era delizioso: *"Bel sito… sarebbe un
> peccato se mostrasse un avviso rosso a tutti i visitatori. Con una modica cifra annuale, si può
> evitare."* 😏 Un pizzo digitale, praticamente — solo con la fattura.

**Da dove nasce il potere delle CA (il cuore della battuta):**
> Ma perché proprio *loro* potevano incassare? La chiave è un dettaglio di come funzionano i
> browser. Negli anni '90, quando nasce il lucchetto, i browser (all'epoca Netscape) si trovavano
> davanti un problema: *di chi fidarsi?* La soluzione fu semplice e definitiva: **incollare dentro
> il browser una lista di "enti fidati"** — poche aziende, scelte a mano. La prima e più famosa fu
> **VeriSign**. Da quel momento la regola diventò: *un certificato vale solo se è firmato da uno di
> quelli già nella lista del browser.*
>
> Tradotto: quelle poche aziende erano diventate i **caselli autostradali obbligati** di tutta
> Internet. Per avere il lucchetto, bisognava passare da una di loro. E, guarda caso, entrare in
> quella lista era difficilissimo. Risultato: **oligopolio**, certificati a centinaia di dollari
> l'anno, per un file che a produrlo costa… zero. **Questo** è il "racket": non una truffa, ma una
> posizione di controllo comodissima, garantita dall'essere già dentro la fiducia del browser.

**Segue:**
> Poi nel 2015 è arrivata **Let's Encrypt**, un'organizzazione no-profit con un'idea
> rivoluzionaria: **certificati gratis per tutti**, rilasciati **da un robot in pochi secondi**.
> Niente più abbonamenti, niente più telefonate al commerciale. Oggi Let's Encrypt protegge
> **centinaia di milioni di siti**, gratis.

**Il pezzo forte (riquadro):**
> 🎩 **E il trucco qual è?** Che per essere gratis e automatico, il rilascio doveva essere fatto
> **da una macchina, non da un umano**. Così è nato un linguaggio con cui il server e l'autorità
> "si parlano" da soli per ottenere e rinnovare i certificati. Si chiama **ACME**, ed è esattamente
> il protagonista di questa demo.

*(Tooltip su "CA / Autorità di Certificazione": «L'ente fidato che rilascia i certificati, come
la questura per le carte d'identità. Es. Let's Encrypt, gratuita.»)*

---

## ATTO 6 — La soluzione: l'automazione (ACME)

**Titolo:** 🤝 Come fa un sito a rinnovarsi da solo: il protocollo ACME

**Testo:**
> ACME è semplicemente le **regole della conversazione** tra il server e l'autorità. Tolta ogni
> sigla, il dialogo è questo:
>
> - **Server:** «Vorrei un certificato per *trenord.it*.»
> - **Autorità:** «Dimostra che il sito è davvero tuo: metti questo codice in un punto preciso.»
> - **Server:** *(mette il codice)* «Fatto.»
> - **Autorità:** *(va a controllare)* «Confermo, è tuo. Ecco il certificato, valido X tempo.»
>
> Tutto qui. E siccome lo fa un programma, può **rifarlo da solo** poco prima di ogni scadenza,
> all'infinito, giorno e notte. **Questo** è ciò che rende sostenibile il mondo dei 47 giorni.

**Aggancio al diagramma interattivo (che già esiste):**
> 👇 Qui sotto si può cliccare ogni passo di questa conversazione e vedere cosa succede davvero.

*(Il diagramma interattivo attuale resta; se ne rivedono solo i testi degli step per allinearli a
questo tono più semplice e impersonale. Nello step 2 — "Wow dal vivo" — questo diagramma si
illuminerà in tempo reale mentre la rotazione accade.)*

---

## ATTO 7 — La demo dal vivo (sezioni già esistenti, testi rivisti)

Qui vivono le parti "tecniche" già presenti. Non cambiano nella sostanza, ma ogni sezione prende
una **riga di spiegazione in linguaggio umano** sopra, così anche chi non sa cosa guarda capisce.

- **Countdown "Il certificato scade tra…"**
  > ⏱️ Il conto alla rovescia qui sotto: quando sta per finire, il sistema **non aspetta** — ne
  > ottiene già uno nuovo. Nel mondo reale la barra durerebbe mesi; qui pochi minuti.

- **"Vita del certificato" + "Emissioni totali"**
  > 🔁 Ogni rinnovo produce un certificato **completamente nuovo** (numero di serie diverso). Il
  > contatore sale da solo, senza che nessuno tocchi niente.

- **Grafico degli intervalli**
  > 📊 Ogni barra è un rinnovo. Colore diverso a seconda del motivo: primo rilascio, rinnovo
  > automatico, o rinnovo forzato col pulsante.

- **Storico ultimi 10 eventi**
  > 📜 La cronologia dei rinnovi. Gli orari ravvicinati mostrano il sistema che lavora da solo.

- **Bottone "Forza rinnovo"**
  > 🔘 Un click sul pulsante fa accadere il rinnovo subito, senza aspettare la scadenza.

*(Qui, nello step 2, si aggiungeranno il **feed eventi in italiano** e il contatore
**"0 secondi di disservizio su N rinnovi"** — la frase che riassume tutto il valore. Nello step 3
il bottone **"Simula guasto"** per far vedere l'avviso rosso del browser e poi l'auto-riparazione.)*

---

## ATTO 7-bis — Schema infrastrutturale ("Sotto il cofano") 🆕 DA RIVEDERE

> **Nuova sezione proposta.** Spiega *com'è fatta* la demo (l'architettura), mentre il diagramma
> dell'Atto 6 spiega *come funziona il processo* (il dialogo ACME). Due cose diverse e
> complementari. Stesso schema di interazione del diagramma di flusso già esistente: si clicca un
> pezzo e sotto compare una spiegazione breve. **Posizione proposta:** dopo la demo dal vivo (prima
> si vede funzionare, poi si apre il cofano), prima del glossario.

**Titolo:** 🧩 Sotto il cofano: com'è fatta questa demo

**Introduzione (una riga):**
> Tutta la demo gira sul PC, dentro **Docker**, senza bisogno di Internet. Ecco i pezzi e come si
> parlano. Cliccare un componente per la spiegazione.

**Diagramma (bozza; in pagina diventa un disegno HTML/SVG con i box cliccabili):**

```
╔══════════════════════════════════════════════════════════════════════╗
║  🖥️  IL TUO PC  —  Windows + Docker Desktop                            ║
║                                                                        ║
║   🌐 Browser ──── https://poc.local ─────────────────┐                 ║
║        ▲          (🗂️ file hosts: poc.local → 127.0.0.1)               ║
║        │                                             │                 ║
║        │                             🔌 porte 80/443 pubblicate        ║
║        │   ┌───────────────────────────────────────  ▼ ────────────┐   ║
║        │   │  🕸️ RETE DOCKER (privata) · DNS interno 127.0.0.11    │   ║
║        │   │                                                       │   ║
║        │   │   ┌─────────┐      ┌─────────┐      ┌─────────────┐   │   ║
║        └───┼─► │ 🌍 nginx│◄────►│ 🤖 acme │◄───► │ 🏛️ pebble   │   │   ║
║            │   │ web+TLS │      │ (lego)  │ ACME │ finta L.E.  │   │   ║
║            │   └────┬────┘      └────┬────┘      └─────────────┘   │   ║
║            │        │  📁 volumi condivisi │                       │   ║
║            │        ▼                      ▼                       │   ║
║            │     📁 certs      📁 webroot      📁 web               │   ║
║            └───────────────────────────────────────────────────────┘   ║
╚══════════════════════════════════════════════════════════════════════╝
```

**Legenda delle frecce (le connessioni):**
- **Browser → nginx** — la visita al sito (HTTPS sulla porta 443).
- **acme ↔ pebble** — il dialogo ACME: richiesta e rilascio del certificato.
- **pebble → nginx** — la verifica della challenge (l'autorità va a controllare la "prova").
- **acme → volumi → nginx** — consegna di token, certificato e dati della dashboard.

### Pezzi cliccabili (testo che compare sotto il diagramma)

1. **🖥️ Il tuo PC (host + Docker Desktop)**
   > La macchina che ospita tutto. **Docker Desktop** è il programma che fa girare i container.
   > Nella demo il PC fa anche da visitatore, aprendo il sito nel browser. In un caso reale host e
   > visitatore sarebbero macchine diverse; qui coincidono per comodità.

2. **🌐 Browser**
   > Il visitatore del sito. Si collega a `https://poc.local`, riceve il certificato e lo controlla:
   > se è valido e firmato da un'autorità fidata, mostra il lucchetto 🔒.

3. **🗂️ File hosts — il DNS locale fatto a mano**
   > Su Internet un indirizzo (`trenord.it`) viene tradotto in un numero (IP) dai server **DNS**.
   > Qui non c'è Internet: una riga nel file `hosts` del PC dice «`poc.local` = questo computer».
   > È un DNS in miniatura, scritto a mano, che permette di usare un nome di dominio senza
   > possederne uno vero.

4. **🔌 Port mapping (porte 80 / 443)**
   > Di default un container è chiuso verso l'esterno. Il *port mapping* apre una finestra precisa:
   > le porte **80** (HTTP) e **443** (HTTPS) del container nginx vengono "pubblicate" sul PC, così
   > il browser può raggiungerle. È l'unico punto di contatto tra il mondo esterno e la rete interna.

5. **📦 Container Docker**
   > Una scatola isolata che racchiude un programma e tutto ciò che gli serve per funzionare, senza
   > interferire col resto del computer. Si accende, si spegne e si butta senza lasciare tracce.
   > Questa demo è fatta di **3 container**, uno per ruolo.

6. **🕸️ Rete Docker + DNS interno (127.0.0.11)**
   > I 3 container dialogano su una rete privata, invisibile da fuori. Dentro c'è un **mini-DNS**
   > (indirizzo `127.0.0.11`) che li fa chiamare per nome — «nginx», «acme», «pebble» — invece che
   > per numero. Stesso meccanismo dei DNS di Internet, ma tutto interno.

7. **🌍 nginx — il web server**
   > Mostra il sito e gestisce la connessione sicura (HTTPS). Fa tre lavori: serve la dashboard,
   > espone la "prova" della challenge sulla porta 80, e — appena il robot deposita un certificato
   > nuovo — lo adotta al volo **senza spegnersi** nemmeno un istante (*reload a caldo*). Sulla rete
   > interna risponde anche al nome `poc.local`.

8. **🤖 acme — il robot (lego)**
   > Il protagonista dell'automazione. Con lo strumento **lego** parla ACME con l'autorità: chiede
   > il certificato, supera la challenge e lo rinnova da solo poco prima di ogni scadenza. Non ha
   > porte aperte verso l'esterno: lavora silenzioso in sottofondo.

9. **🏛️ pebble — la finta Let's Encrypt**
   > Una copia "da laboratorio" di Let's Encrypt che gira in locale. Fa esattamente ciò che farebbe
   > l'autorità vera — riceve la richiesta, verifica il controllo del dominio, emette il certificato
   > — ma senza Internet né un dominio pubblico. *(Curiosità: ad ogni riavvio rigenera le proprie
   > chiavi da zero.)*

10. **📁 Volumi condivisi (certs · webroot · web)**
    > Cartelle condivise tra i container, come una chiavetta USB comune: si passano i file senza
    > cablare connessioni dirette. **webroot** per la prova della challenge (acme scrive, nginx
    > mostra), **certs** per i certificati emessi (acme scrive, nginx legge e ricarica), **web** per
    > i dati della dashboard (acme scrive, nginx serve).

> **Nota tecnica (compare solo in "modalità tecnica"):** pebble espone anche le porte 14000
> (directory ACME) e 15000 (management/root CA) per ispezione; acme ha un piccolo listener interno
> (`socat` su :8080, non pubblicato) che riceve il comando del bottone "Forza rinnovo" inoltrato da
> nginx. Dettagli utili a chi vuole smontare la demo, superflui per il racconto.

---

## ATTO 8 — Glossario (in fondo, "modalità tecnica")

Riquadro finale, un termine per riga, per chi vuole i nomi veri delle cose:

- **Certificato SSL/TLS** — la carta d'identità digitale del sito, con scadenza.
- **CA (Autorità di Certificazione)** — chi rilascia i certificati (es. Let's Encrypt).
- **ACME** — il "linguaggio" con cui server e autorità si parlano per rilasciare/rinnovare.
- **Let's Encrypt** — l'autorità no-profit che ha reso i certificati gratis e automatici.
- **Pebble** — la versione "da laboratorio" di Let's Encrypt usata in questa demo, tutta in
  locale (così non serve un sito pubblico su internet).
- **Rinnovo / rotazione** — sostituire il certificato con uno nuovo prima che scada.
- **Serial / impronta (fingerprint)** — il "codice univoco" di ogni certificato: se cambia,
  è la prova che il certificato è davvero nuovo.
- **Reload a caldo** — il sito adotta il nuovo certificato **senza spegnersi** nemmeno un istante.

---

## Note di stile / decisioni — STATO

1. ✅ **Nome del sito demo nei testi**: `trenord.it` (la demo tecnica resta su `poc.local`).
2. ✅ **Emoji**: sì, come segnaletica leggera.
3. ✅ **Pezzo "racket"**: confermato, + aggiunta l'origine delle CA (VeriSign / lista fidata nel
   browser / oligopolio) come cuore dell'affermazione. *(Atto 5)*
4. ✅ **Storie vere (Atto 3)**: **articoli reali linkati** con estratto breve (Teams/Engadget 2020,
   O2-SoftBank/TechCrunch 2018, Spotify/The SSL Store 2020) + pulsante che apre **expired.badssl.com**
   dal vivo. Fonti verificate con ricerca. *(Atto 3)*
5. ✅ **Modalità tecnica**: confermata, dentro uno **sticky header** — **neutro, senza nome/marchio**
   (`🔒 Rotazione automatica dei certificati TLS`) + pallino "sistema attivo" + mini-countdown +
   link "vai alla demo"; predisposto (per dopo) l'interruttore lingua IT/EN.
6. ✅ **Forma impersonale**: applicata a tutto il copy di pagina.
7. ✅ **Lingua**: tutto in italiano; interruttore IT/EN agganciato più avanti.

**Tutte le decisioni sono chiuse.** Prossimo passo: portare questi contenuti nella pagina
(`nginx/dashboard/index.html`) con la nuova struttura + sticky header + card articoli + tooltip +
modalità tecnica, mantenendo intatte le sezioni vive e il diagramma interattivo.
