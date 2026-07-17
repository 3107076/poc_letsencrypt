# Trigger manuale: forza un rinnovo immediato del certificato.
# nginx si ricarica da solo grazie al watcher inotify nel suo container.
#
# Uso:  .\scripts\force-renew.ps1
# (eseguire dalla cartella del progetto)

Write-Host "Forzo un rinnovo immediato del certificato..." -ForegroundColor Cyan
docker compose exec -T acme /renew-once.sh
if ($LASTEXITCODE -eq 0) {
    Write-Host "Fatto. nginx si ricarica da solo. Verifica con: .\scripts\watch-cert.ps1" -ForegroundColor Green
} else {
    Write-Host "Rinnovo fallito (exit $LASTEXITCODE). Controlla: docker compose logs acme" -ForegroundColor Red
}
