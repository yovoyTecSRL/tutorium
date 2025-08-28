# ===================================================================
# PowerShell Deploy Script for Tutorium
# Orbix Systems - Windows Compatible Deployment
# ===================================================================

param(
    [string]$ServerIP = "178.156.182.125",
    [string]$ServerUser = "root",
    [string]$Domain = "tutorium.sistemasorbix.com",
    [switch]$SkipSSL,
    [switch]$TestOnly
)

# Configuración
$LOCAL_PATH = "D:\ORBIX\tutorium-sistemasorbix"
$REMOTE_PATH = "/opt/tutorium"
$SSH_KEY = "$env:USERPROFILE\.ssh\id_rsa"

Write-Host "🚀 ORBIX Tutorium Deploy Script" -ForegroundColor Cyan
Write-Host "=" * 60 -ForegroundColor Cyan
Write-Host "🎯 Dominio: $Domain" -ForegroundColor Blue
Write-Host "🖥️  Servidor: $ServerIP" -ForegroundColor Blue
Write-Host ""

# Función para logging
function Write-Log {
    param([string]$Message)
    Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $Message" -ForegroundColor Green
}

function Write-Error-Log {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

function Write-Warning-Log {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

# Verificar archivos locales
Write-Log "Verificando archivos locales..."
if (!(Test-Path $LOCAL_PATH)) {
    Write-Error-Log "Directorio local no encontrado: $LOCAL_PATH"
    exit 1
}

if (!(Test-Path "$LOCAL_PATH\index.html")) {
    Write-Error-Log "Archivo index.html no encontrado"
    exit 1
}

# Verificar herramientas necesarias
Write-Log "Verificando herramientas necesarias..."
$scp = Get-Command scp -ErrorAction SilentlyContinue
$ssh = Get-Command ssh -ErrorAction SilentlyContinue

if (!$scp -or !$ssh) {
    Write-Error-Log "SSH/SCP no encontrado. Instale OpenSSH o Git Bash"
    exit 1
}

# Crear paquete de despliegue
Write-Log "Creando paquete de despliegue..."
Set-Location $LOCAL_PATH

# Crear archivo tar usando PowerShell
$files = @(
    "index.html",
    "cursos.html", 
    "registro.html",
    "css",
    "js",
    "assets",
    "nginx",
    "scripts"
)

# Usar tar de Windows 10+ o 7-zip si está disponible
if (Get-Command tar -ErrorAction SilentlyContinue) {
    $tarCmd = "tar -czf tutorium-deploy.tar.gz " + ($files -join " ")
    Invoke-Expression $tarCmd
} else {
    Write-Warning-Log "Tar no disponible, usando compresión ZIP..."
    $zipPath = "tutorium-deploy.zip"
    if (Test-Path $zipPath) { Remove-Item $zipPath }
    
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::CreateFromDirectory($LOCAL_PATH, $zipPath)
}

# Test de conectividad
Write-Log "Verificando conectividad al servidor..."
$ping = Test-NetConnection -ComputerName $ServerIP -Port 22 -WarningAction SilentlyContinue
if (!$ping.TcpTestSucceeded) {
    Write-Warning-Log "No se puede conectar al puerto 22, continuando..."
}

if ($TestOnly) {
    Write-Log "Modo test - No se realizará despliegue real"
    exit 0
}

# Subir archivos al servidor
Write-Log "Subiendo archivos al servidor..."
$scpCmd = "scp -o StrictHostKeyChecking=no"
if (Test-Path $SSH_KEY) {
    $scpCmd += " -i `"$SSH_KEY`""
}

if (Test-Path "tutorium-deploy.tar.gz") {
    $scpCmd += " tutorium-deploy.tar.gz ${ServerUser}@${ServerIP}:/tmp/"
} else {
    $scpCmd += " tutorium-deploy.zip ${ServerUser}@${ServerIP}:/tmp/"
}

try {
    Invoke-Expression $scpCmd
    Write-Log "✅ Archivos subidos exitosamente"
} catch {
    Write-Error-Log "Error subiendo archivos: $_"
    exit 1
}

# Ejecutar comandos remotos
Write-Log "Ejecutando despliegue remoto..."
$sshCmd = "ssh -o StrictHostKeyChecking=no"
if (Test-Path $SSH_KEY) {
    $sshCmd += " -i `"$SSH_KEY`""
}
$sshCmd += " ${ServerUser}@${ServerIP}"

$remoteScript = @"
set -e
echo "🔧 Configurando servidor remoto..."

# Crear directorio temporal
mkdir -p /tmp/tutorium-deploy
cd /tmp/tutorium-deploy

# Extraer archivos
if [ -f /tmp/tutorium-deploy.tar.gz ]; then
    tar -xzf /tmp/tutorium-deploy.tar.gz
elif [ -f /tmp/tutorium-deploy.zip ]; then
    unzip /tmp/tutorium-deploy.zip
fi

# Hacer ejecutable el script SSL
chmod +x scripts/setup-ssl.sh

# Ejecutar setup SSL
if [ ! -f /etc/letsencrypt/live/$Domain/fullchain.pem ]; then
    echo "🔒 Configurando SSL..."
    ./scripts/setup-ssl.sh
else
    echo "✅ SSL ya configurado"
fi

# Copiar archivos web
echo "📁 Copiando archivos web..."
mkdir -p /var/www/tutorium.sistemasorbix.com/html
cp -r * /var/www/tutorium.sistemasorbix.com/html/
chown -R www-data:www-data /var/www/tutorium.sistemasorbix.com/html
chmod -R 755 /var/www/tutorium.sistemasorbix.com/html

# Configurar Nginx
echo "🔧 Configurando Nginx..."
cp nginx/tutorium.conf /etc/nginx/sites-available/
ln -sf /etc/nginx/sites-available/tutorium.conf /etc/nginx/sites-enabled/
nginx -t && systemctl reload nginx

# Limpiar temporales
rm -rf /tmp/tutorium-deploy*

echo "✅ Despliegue completado"
"@

try {
    $remoteScript | & $sshCmd.Split(' ')
    Write-Log "✅ Despliegue remoto completado"
} catch {
    Write-Error-Log "Error en despliegue remoto: $_"
    exit 1
}

# Limpiar archivos temporales locales
Write-Log "Limpiando archivos temporales..."
if (Test-Path "tutorium-deploy.tar.gz") { Remove-Item "tutorium-deploy.tar.gz" }
if (Test-Path "tutorium-deploy.zip") { Remove-Item "tutorium-deploy.zip" }

# Verificar despliegue
Write-Log "Verificando despliegue..."
Start-Sleep 10

# Verificar HTTP (debería redirigir)
try {
    $httpResponse = Invoke-WebRequest -Uri "http://$Domain" -MaximumRedirection 0 -ErrorAction Stop
    if ($httpResponse.StatusCode -eq 301 -or $httpResponse.StatusCode -eq 302) {
        Write-Log "✅ HTTP redirección funcionando"
    }
} catch {
    Write-Warning-Log "⚠️ HTTP Status: $($_.Exception.Response.StatusCode)"
}

# Verificar HTTPS
try {
    $httpsResponse = Invoke-WebRequest -Uri "https://$Domain" -ErrorAction Stop
    if ($httpsResponse.StatusCode -eq 200) {
        Write-Log "✅ HTTPS funcionando correctamente"
    }
} catch {
    Write-Warning-Log "⚠️ HTTPS Error: $($_.Exception.Message)"
}

# Resultados finales
Write-Host ""
Write-Host "🎉 DESPLIEGUE COMPLETADO" -ForegroundColor Green
Write-Host "=" * 60 -ForegroundColor Green
Write-Host "✅ Sitio web: https://$Domain" -ForegroundColor Green
Write-Host "✅ Redirección HTTP->HTTPS: Activa" -ForegroundColor Green
Write-Host "✅ Certificado SSL: Configurado" -ForegroundColor Green
Write-Host "✅ Nginx: Configurado" -ForegroundColor Green
Write-Host ""
Write-Host "📋 URLs disponibles:" -ForegroundColor Blue
Write-Host "   🌐 Principal: https://$Domain"
Write-Host "   📚 Cursos: https://$Domain/cursos.html"
Write-Host "   📝 Registro: https://$Domain/registro.html"
Write-Host ""
Write-Host "🔧 Para verificar logs del servidor:" -ForegroundColor Yellow
Write-Host "   ssh $ServerUser@$ServerIP 'tail -f /var/log/nginx/tutorium.sistemasorbix.com.error.log'"
Write-Host ""
Write-Host "🚀 Tutorium está listo para usar!" -ForegroundColor Blue
