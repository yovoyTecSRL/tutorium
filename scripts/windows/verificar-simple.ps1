# Verificador de estado simple para Tutorium
$DOMAIN = "tutorium.sistemasorbix.com"
$SERVER = "178.156.182.125"

Write-Host "VERIFICADOR DE ESTADO TUTORIUM" -ForegroundColor Green
Write-Host "Dominio: $DOMAIN" -ForegroundColor White
Write-Host "Servidor: $SERVER" -ForegroundColor White

# Verificar archivos locales
Write-Host "`nVerificando archivos locales..." -ForegroundColor Cyan

$files = @("index.html", "cursos.html", "registro.html", "ssl-manual.sh")
foreach ($file in $files) {
    if (Test-Path $file) {
        Write-Host "OK: $file" -ForegroundColor Green
    } else {
        Write-Host "FALTA: $file" -ForegroundColor Red
    }
}

# Verificar conectividad
Write-Host "`nVerificando conectividad..." -ForegroundColor Cyan

try {
    $ping = Test-NetConnection -ComputerName $SERVER -Port 22 -InformationLevel Quiet
    if ($ping) {
        Write-Host "OK: Puerto 22 (SSH) accesible" -ForegroundColor Green
    } else {
        Write-Host "ERROR: Puerto 22 no accesible" -ForegroundColor Red
    }
} catch {
    Write-Host "ERROR: No se puede conectar al servidor" -ForegroundColor Red
}

# Verificar SSL
Write-Host "`nVerificando SSL..." -ForegroundColor Cyan

try {
    $response = Invoke-WebRequest -Uri "https://$DOMAIN" -UseBasicParsing -TimeoutSec 10
    Write-Host "OK: SSL funciona (Status: $($response.StatusCode))" -ForegroundColor Green
} catch {
    Write-Host "ERROR: SSL no funciona" -ForegroundColor Red
    Write-Host "Detalle: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Verificar DNS
Write-Host "`nVerificando DNS..." -ForegroundColor Cyan

try {
    $dns = Resolve-DnsName -Name $DOMAIN -ErrorAction Stop
    $ip = ($dns | Where-Object { $_.Type -eq "A" } | Select-Object -First 1).IPAddress
    Write-Host "OK: DNS resuelve a $ip" -ForegroundColor Green
    
    if ($ip -eq $SERVER) {
        Write-Host "OK: IP coincide con servidor configurado" -ForegroundColor Green
    } else {
        Write-Host "ADVERTENCIA: IP no coincide" -ForegroundColor Yellow
    }
} catch {
    Write-Host "ERROR: No se puede resolver DNS" -ForegroundColor Red
}

Write-Host "`nRESUMEN:" -ForegroundColor Cyan
Write-Host "Para configurar SSL manualmente:" -ForegroundColor White
Write-Host "1. ssh root@$SERVER" -ForegroundColor Gray
Write-Host "2. Copiar contenido de ssl-manual.sh" -ForegroundColor Gray
Write-Host "3. Verificar: https://$DOMAIN" -ForegroundColor Gray

Write-Host "`nVerificacion completada!" -ForegroundColor Green
