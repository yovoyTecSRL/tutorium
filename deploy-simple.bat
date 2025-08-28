@echo off
echo 🚀 Tutorium Deploy Script
echo ========================

REM Configuración
set SERVER_IP=178.156.182.125
set SERVER_USER=root
set DOMAIN=tutorium.sistemasorbix.com

echo 📦 Creando paquete de archivos...
tar -czf tutorium-files.tar.gz index.html cursos.html registro.html css js assets simple-deploy.sh

echo 📤 Subiendo archivos al servidor...
scp -o StrictHostKeyChecking=no tutorium-files.tar.gz %SERVER_USER%@%SERVER_IP%:/tmp/

echo 🔧 Ejecutando despliegue remoto...
ssh -o StrictHostKeyChecking=no %SERVER_USER%@%SERVER_IP% "cd /tmp && tar -xzf tutorium-files.tar.gz && chmod +x simple-deploy.sh && ./simple-deploy.sh"

echo ✅ Despliegue completado!
echo 🌐 Sitio: https://%DOMAIN%
echo 🔒 SSL: Configurado automáticamente

pause
