# Rimuove le root "Pebble Root CA" installate nello store radici attendibili dell'utente.
# Utile dopo un riavvio di Pebble (che rigenera la root) o per fare pulizia a fine PoC.
#
# Uso:  .\scripts\untrust-pebble-root.ps1

$ErrorActionPreference = 'Stop'
$found = Get-ChildItem Cert:\CurrentUser\Root | Where-Object { $_.Subject -like '*Pebble Root CA*' }
if (-not $found) {
    Write-Host "Nessuna 'Pebble Root CA' presente nello store dell'utente." -ForegroundColor Yellow
    exit 0
}
$found | ForEach-Object {
    Write-Host ("Rimuovo: {0}  (serial {1})" -f $_.Subject, $_.SerialNumber) -ForegroundColor Cyan
    Remove-Item -Path ("Cert:\CurrentUser\Root\{0}" -f $_.Thumbprint) -Force
}
Write-Host "Fatto." -ForegroundColor Green
