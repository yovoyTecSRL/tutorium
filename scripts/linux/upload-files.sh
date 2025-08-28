# ===================================================================
# Upload de archivos a servidor después de SSL
# ===================================================================

# 1. Verificar que el SSL esté funcionando
echo "🔍 Verificando SSL..."
curl -I https://tutorium.sistemasorbix.com

# 2. Crear backup de archivos existentes
sudo cp -r /var/www/tutorium /var/www/tutorium.backup.$(date +%Y%m%d-%H%M%S)

# 3. Crear directorio para archivos estáticos
sudo mkdir -p /var/www/tutorium/{css,js,img,api}

# 4. Instalar Node.js para API (si no está instalado)
if ! command -v node &> /dev/null; then
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt-get install -y nodejs
fi

# 5. Configurar permisos
sudo chown -R www-data:www-data /var/www/tutorium
sudo chmod -R 755 /var/www/tutorium

# 6. Instalar PM2 para gestión de procesos
sudo npm install -g pm2

echo "✅ Servidor listo para recibir archivos"
echo "📁 Sube los archivos a: /var/www/tutorium/"
echo "🔧 Configuración completa en: /etc/nginx/sites-available/tutorium"
