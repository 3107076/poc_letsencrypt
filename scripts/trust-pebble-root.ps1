# Scarica la root CA CORRENTE di Pebble e la installa fra le "Autorita' di
# certificazione radice attendibili" dell'UTENTE (nessun admin richiesto).
# Dopo l'import, riavvia il browser e apri https://poc.local/ : niente piu' alert.
#
# ATTENZIONE (caveat Pebble): Pebble e' stateless e RIGENERA la root a ogni riavvio
# (docker compose down/up o restart del container pebble). Dopo un riavvio questa
# root non combacia piu': ri-esegui questo script (installa la nuova) ed elimina la
# vecchia con .\scripts\untrust-pebble-root.ps1.
#
# Uso:  .\scripts\trust-pebble-root.ps1

$ErrorActionPreference = 'Stop'
$pem = Join-Path $env:TEMP 'pebble-root.pem'

Write-Host "Scarico la root CA corrente da Pebble (https://localhost:15000/roots/0)..." -ForegroundColor Cyan
curl.exe -sk https://localhost:15000/roots/0 -o $pem
if (-not (Test-Path $pem) -or (Get-Item $pem).Length -eq 0) {
    Write-Host "Impossibile scaricare la root. Pebble e' avviato? (docker compose ps)" -ForegroundColor Red
    exit 1
}

$c = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($pem)
Write-Host ("Root: {0}  (serial {1})" -f $c.Subject, $c.SerialNumber) -ForegroundColor Yellow

Import-Certificate -FilePath $pem -CertStoreLocation Cert:\CurrentUser\Root | Out-Null
Write-Host "OK: root installata nello store 'Radici attendibili' dell'utente." -ForegroundColor Green
Write-Host "Riavvia il browser e apri https://poc.local/ (Firefox usa uno store proprio: vedi README)." -ForegroundColor Green
