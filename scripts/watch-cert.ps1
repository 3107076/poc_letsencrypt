# Osserva in loop il certificato servito da nginx su poc.local:443.
# Mostra serial, fingerprint e scadenza: a ogni rotazione serial/fingerprint CAMBIANO
# mentre la connessione resta sempre servita -> prova del reload a caldo (zero downtime).
# openssl viene eseguito DENTRO il container acme, cosi' non serve openssl su Windows.
#
# Uso:  .\scripts\watch-cert.ps1  [-IntervalSeconds 5]
# (eseguire dalla cartella del progetto; Ctrl+C per uscire)

param([int]$IntervalSeconds = 5)

Write-Host "Osservo il certificato servito su poc.local:443 (Ctrl+C per uscire)..." -ForegroundColor Cyan
while ($true) {
    $out = & docker compose exec -T acme sh -c "echo | openssl s_client -connect poc.local:443 -servername poc.local 2>/dev/null | openssl x509 -noout -serial -fingerprint -enddate"
    $ts = Get-Date -Format 'HH:mm:ss'
    Write-Host "[$ts]" -ForegroundColor Yellow
    $out | ForEach-Object { "   $_" }
    Start-Sleep -Seconds $IntervalSeconds
}
