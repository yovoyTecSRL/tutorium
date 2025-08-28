# ═══════════════════════════════════════════════════════════════
# 🔍 ORBIX - Verificador de Estado SSL y Proyecto Tutorium
# ═══════════════════════════════════════════════════════════════

$DOMAIN = "tutorium.sistemasorbix.com"
$SERVER = "178.156.182.125"
$PROJECT_PATH = "D:\ORBIX\tutorium-sistemasorbix"

Write-Host "`n🔍 ORBIX - Verificador de Estado Tutorium" -ForegroundColor Green
Write-Host "════════════════════════════════════════════════" -ForegroundColor Gray

# 1. Verificar estructura de archivos locales
Write-Host "`n📁 VERIFICANDO ESTRUCTURA DE ARCHIVOS..." -ForegroundColor Cyan

$requiredFiles = @(
    "index.html",
    "cursos.html", 
    "registro.html",
    "css\style.css",
    "js\script.js",
    "ssl-manual.sh",
    "README-SSL.md"
)

$missingFiles = @()

foreach ($file in $requiredFiles) {
    $fullPath = Join-Path $PROJECT_PATH $file
    if (Test-Path $fullPath) {
        Write-Host "✅ $file" -ForegroundColor Green
    } else {
        Write-Host "❌ $file" -ForegroundColor Red
        $missingFiles += $file
    }
}

# 2. Verificar conectividad al servidor
Write-Host "`n🌐 VERIFICANDO CONECTIVIDAD AL SERVIDOR..." -ForegroundColor Cyan

try {
    $pingResult = Test-NetConnection -ComputerName $SERVER -Port 22 -InformationLevel Quiet
    if ($pingResult) {
        Write-Host "✅ Servidor accesible en puerto 22 (SSH)" -ForegroundColor Green
    } else {
        Write-Host "❌ Servidor no accesible en puerto 22" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Error de conectividad: $($_.Exception.Message)" -ForegroundColor Red
}

try {
    $httpTest = Test-NetConnection -ComputerName $SERVER -Port 80 -InformationLevel Quiet
    if ($httpTest) {
        Write-Host "✅ Servidor accesible en puerto 80 (HTTP)" -ForegroundColor Green
    } else {
        Write-Host "❌ Servidor no accesible en puerto 80" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Error conectando puerto 80" -ForegroundColor Red
}

try {
    $httpsTest = Test-NetConnection -ComputerName $SERVER -Port 443 -InformationLevel Quiet
    if ($httpsTest) {
        Write-Host "✅ Servidor accesible en puerto 443 (HTTPS)" -ForegroundColor Green
    } else {
        Write-Host "❌ Servidor no accesible en puerto 443" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Error conectando puerto 443" -ForegroundColor Red
}

# 3. Verificar SSL del dominio
Write-Host "`n🔒 VERIFICANDO SSL DEL DOMINIO..." -ForegroundColor Cyan

try {
    $response = Invoke-WebRequest -Uri "https://$DOMAIN" -UseBasicParsing -TimeoutSec 10
    
    if ($response.StatusCode -eq 200) {
        Write-Host "✅ SSL funcionando correctamente" -ForegroundColor Green
        Write-Host "  Estado: $($response.StatusCode)" -ForegroundColor White
        Write-Host "  Tamaño: $($response.Content.Length) bytes" -ForegroundColor White
    } else {
        Write-Host "⚠️ SSL responde pero con estado: $($response.StatusCode)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ SSL no funciona: $($_.Exception.Message)" -ForegroundColor Red
    
    # Intentar HTTP
    try {
        $httpResponse = Invoke-WebRequest -Uri "http://$DOMAIN" -UseBasicParsing -TimeoutSec 10
        Write-Host "ℹ️ HTTP funciona (estado: $($httpResponse.StatusCode))" -ForegroundColor Blue
    } catch {
        Write-Host "❌ HTTP tampoco funciona" -ForegroundColor Red
    }
}

# 4. Verificar DNS
Write-Host "`n🌐 VERIFICANDO DNS..." -ForegroundColor Cyan

try {
    $dnsResult = Resolve-DnsName -Name $DOMAIN -ErrorAction Stop
    $resolvedIP = $dnsResult | Where-Object { $_.Type -eq "A" } | Select-Object -First 1
    
    if ($resolvedIP) {
        $ip = $resolvedIP.IPAddress
        Write-Host "✅ DNS resuelve a: $ip" -ForegroundColor Green
        
        if ($ip -eq $SERVER) {
            Write-Host "✅ IP coincide con servidor configurado" -ForegroundColor Green
        } else {
            Write-Host "⚠️ IP no coincide. Esperado: $SERVER, Obtenido: $ip" -ForegroundColor Yellow
        }
    } else {
        Write-Host "❌ No se encontró registro A para el dominio" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Error resolviendo DNS: $($_.Exception.Message)" -ForegroundColor Red
}

# 5. Resumen y recomendaciones
Write-Host "`n📋 RESUMEN Y RECOMENDACIONES" -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════════" -ForegroundColor Gray

if ($missingFiles.Count -eq 0) {
    Write-Host "✅ Todos los archivos necesarios están presentes" -ForegroundColor Green
} else {
    Write-Host "❌ Faltan archivos:" -ForegroundColor Red
    foreach ($file in $missingFiles) {
        Write-Host "  - $file" -ForegroundColor Red
    }
}

Write-Host "`n🎯 PRÓXIMOS PASOS RECOMENDADOS:" -ForegroundColor Yellow
Write-Host "1. Si SSL no funciona, ejecutar: ssh root@$SERVER" -ForegroundColor White
Write-Host "2. Copiar y pegar contenido de ssl-manual.sh" -ForegroundColor White
Write-Host "3. Subir archivos HTML al servidor: /var/www/tutorium/" -ForegroundColor White
Write-Host "4. Verificar en navegador: https://$DOMAIN" -ForegroundColor White

Write-Host "`n🔧 COMANDOS ÚTILES:" -ForegroundColor Yellow
Write-Host "• Verificar SSL: curl -I https://$DOMAIN" -ForegroundColor White
Write-Host "• Conectar SSH: ssh root@$SERVER" -ForegroundColor White
Write-Host "• Ver logs: tail -f /var/log/nginx/tutorium.error.log" -ForegroundColor White

Write-Host "`n📁 ARCHIVOS IMPORTANTES:" -ForegroundColor Yellow
Write-Host "• ssl-manual.sh - Script completo SSL" -ForegroundColor White
Write-Host "• README-SSL.md - Instrucciones detalladas" -ForegroundColor White
Write-Host "• INSTRUCCIONES-FINALES.md - Guía paso a paso" -ForegroundColor White

Write-Host "`n🎉 Verificación completada!" -ForegroundColor Green
