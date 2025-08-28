#!/bin/bash

# ═══════════════════════════════════════════════════════════════
# 🔧 SCRIPT DE REPARACIÓN COMPLETA PARA TUTORIUM
# Ejecutar desde la consola de Hetzner
# ═══════════════════════════════════════════════════════════════

echo "🔧 INICIANDO REPARACIÓN COMPLETA DE TUTORIUM"
echo "════════════════════════════════════════════════════════════"
echo "🌐 Dominio: tutorium.sistemasorbix.com"
echo "🔑 Servidor: $(hostname -I | awk '{print $1}')"
echo "📅 Fecha: $(date)"
echo ""

# ═══════════════════════════════════════════════════════════════
# 1. CONFIGURAR SSH CON CONTRASEÑA TEMPORAL
# ═══════════════════════════════════════════════════════════════

echo "🔐 PASO 1: Configurando SSH con contraseña temporal..."

# Crear contraseña temporal para root
echo "root:fTeRLCxfnaRL" | chpasswd

# Configurar SSH para permitir login con contraseña
sed -i 's/#PermitRootLogin yes/PermitRootLogin yes/' /etc/ssh/sshd_config
sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config

# Reiniciar SSH
systemctl restart sshd

echo "✅ SSH configurado. Contraseña temporal: fTeRLCxfnaRL"
echo "   Comando para conectar: ssh root@$(hostname -I | awk '{print $1}')"

# ═══════════════════════════════════════════════════════════════
# 2. ACTUALIZAR SISTEMA
# ═══════════════════════════════════════════════════════════════

echo ""
echo "🔄 PASO 2: Actualizando sistema..."
apt update -y
apt upgrade -y

echo "✅ Sistema actualizado"

# ═══════════════════════════════════════════════════════════════
# 3. INSTALAR PAQUETES NECESARIOS
# ═══════════════════════════════════════════════════════════════

echo ""
echo "📦 PASO 3: Instalando paquetes necesarios..."
apt install -y nginx certbot python3-certbot-nginx curl wget git nano vim ufw

echo "✅ Paquetes instalados"

# ═══════════════════════════════════════════════════════════════
# 4. CONFIGURAR FIREWALL
# ═══════════════════════════════════════════════════════════════

echo ""
echo "🔥 PASO 4: Configurando firewall..."
ufw --force enable
ufw allow ssh
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 22/tcp

echo "✅ Firewall configurado"

# ═══════════════════════════════════════════════════════════════
# 5. CREAR DIRECTORIO WEB
# ═══════════════════════════════════════════════════════════════

echo ""
echo "📁 PASO 5: Creando directorio web..."

# Crear directorio
mkdir -p /var/www/tutorium

# Crear página temporal con información completa
cat > /var/www/tutorium/index.html << 'EOF'
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Tutorium - Configuración SSL</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            margin: 0;
            padding: 50px;
            text-align: center;
        }
        .container {
            max-width: 600px;
            margin: 0 auto;
            background: rgba(255,255,255,0.1);
            padding: 40px;
            border-radius: 15px;
            backdrop-filter: blur(10px);
        }
        h1 { color: #fff; font-size: 2.5em; margin-bottom: 20px; }
        .status { font-size: 1.2em; margin: 20px 0; color: #00ff00; }
        .icon { font-size: 3em; margin-bottom: 20px; }
        .info { background: rgba(255,255,255,0.1); padding: 20px; border-radius: 10px; margin: 20px 0; }
        .command { background: #000; color: #00ff00; padding: 10px; border-radius: 5px; margin: 10px 0; font-family: monospace; }
    </style>
</head>
<body>
    <div class="container">
        <div class="icon">🔒</div>
        <h1>Tutorium SSL Setup</h1>
        <div class="status">Configurando certificados SSL...</div>
        <p>Dominio: tutorium.sistemasorbix.com</p>
        <p>Estado: Preparando servidor...</p>
        
        <div class="info">
            <h3>Información del Servidor</h3>
            <p>IP: $(hostname -I | awk '{print $1}')</p>
            <p>Fecha: $(date)</p>
            <p>Estado: Configurando SSL</p>
        </div>
        
        <div class="info">
            <h3>Acceso SSH</h3>
            <div class="command">ssh root@$(hostname -I | awk '{print $1}')</div>
            <p>Contraseña temporal: fTeRLCxfnaRL</p>
        </div>
    </div>
</body>
</html>
EOF

# Configurar permisos
chown -R www-data:www-data /var/www/tutorium
chmod -R 755 /var/www/tutorium

echo "✅ Directorio web creado con página temporal"

# ═══════════════════════════════════════════════════════════════
# 6. CONFIGURAR NGINX BÁSICO
# ═══════════════════════════════════════════════════════════════

echo ""
echo "⚙️ PASO 6: Configurando Nginx básico..."

# Remover configuración default
rm -f /etc/nginx/sites-enabled/default

# Crear configuración básica
cat > /etc/nginx/sites-available/tutorium << 'EOF'
server {
    listen 80;
    server_name tutorium.sistemasorbix.com www.tutorium.sistemasorbix.com;
    
    root /var/www/tutorium;
    index index.html;
    
    location / {
        try_files $uri $uri/ =404;
    }
    
    location /.well-known/acme-challenge/ {
        root /var/www/tutorium;
    }
    
    access_log /var/log/nginx/tutorium.access.log;
    error_log /var/log/nginx/tutorium.error.log;
}
EOF

# Habilitar sitio
ln -sf /etc/nginx/sites-available/tutorium /etc/nginx/sites-enabled/

# Probar configuración
nginx -t

if [ $? -eq 0 ]; then
    systemctl reload nginx
    echo "✅ Nginx configurado correctamente"
else
    echo "❌ Error en configuración de Nginx"
    exit 1
fi

# ═══════════════════════════════════════════════════════════════
# 7. OBTENER CERTIFICADO SSL
# ═══════════════════════════════════════════════════════════════

echo ""
echo "🔒 PASO 7: Obteniendo certificado SSL..."

# Obtener certificado SSL
certbot certonly \
    --webroot \
    --webroot-path=/var/www/tutorium \
    --email admin@sistemasorbix.com \
    --agree-tos \
    --no-eff-email \
    --domains tutorium.sistemasorbix.com,www.tutorium.sistemasorbix.com \
    --non-interactive

if [ $? -eq 0 ]; then
    echo "✅ Certificado SSL obtenido correctamente"
else
    echo "❌ Error obteniendo certificado SSL"
    echo "ℹ️ Continuando con configuración HTTP..."
fi

# ═══════════════════════════════════════════════════════════════
# 8. CONFIGURAR SSL EN NGINX
# ═══════════════════════════════════════════════════════════════

echo ""
echo "🔐 PASO 8: Configurando SSL en Nginx..."

# Verificar si el certificado existe
if [ -f "/etc/letsencrypt/live/tutorium.sistemasorbix.com/fullchain.pem" ]; then
    # Crear configuración con SSL
    cat > /etc/nginx/sites-available/tutorium << 'EOF'
server {
    listen 80;
    server_name tutorium.sistemasorbix.com www.tutorium.sistemasorbix.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name tutorium.sistemasorbix.com www.tutorium.sistemasorbix.com;
    
    root /var/www/tutorium;
    index index.html;
    
    ssl_certificate /etc/letsencrypt/live/tutorium.sistemasorbix.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/tutorium.sistemasorbix.com/privkey.pem;
    
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 1d;
    
    # Security headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
    add_header X-Frame-Options DENY always;
    add_header X-Content-Type-Options nosniff always;
    add_header X-XSS-Protection "1; mode=block" always;
    
    location / {
        try_files $uri $uri/ =404;
    }
    
    access_log /var/log/nginx/tutorium.access.log;
    error_log /var/log/nginx/tutorium.error.log;
}
EOF

    echo "✅ SSL configurado en Nginx"
else
    echo "⚠️ Certificado SSL no encontrado, manteniendo configuración HTTP"
fi

# Recargar Nginx
nginx -t && systemctl reload nginx

# ═══════════════════════════════════════════════════════════════
# 9. CONFIGURAR RENOVACIÓN AUTOMÁTICA
# ═══════════════════════════════════════════════════════════════

echo ""
echo "🔄 PASO 9: Configurando renovación automática..."

# Crear cron job para renovación
cat > /etc/cron.d/certbot-renew << 'EOF'
0 12 * * * root certbot renew --quiet --nginx --post-hook "systemctl reload nginx"
EOF

echo "✅ Renovación automática configurada"

# ═══════════════════════════════════════════════════════════════
# 10. CREAR SCRIPT DE ACCESO DIRECTO
# ═══════════════════════════════════════════════════════════════

echo ""
echo "🔑 PASO 10: Creando script de acceso directo..."

# Crear script para cambiar contraseña SSH
cat > /root/cambiar_ssh.sh << 'EOF'
#!/bin/bash
echo "🔐 Configurador de SSH para Tutorium"
echo "====================================="
echo ""
echo "Opciones:"
echo "1. Cambiar contraseña SSH"
echo "2. Generar clave SSH"
echo "3. Deshabilitar login con contraseña"
echo "4. Ver estado del servidor"
echo ""
read -p "Selecciona una opción (1-4): " option

case $option in
    1)
        echo "Cambiando contraseña SSH..."
        read -p "Nueva contraseña: " newpass
        echo "root:$newpass" | chpasswd
        echo "✅ Contraseña cambiada"
        ;;
    2)
        echo "Generando clave SSH..."
        ssh-keygen -t ed25519 -f /root/.ssh/id_ed25519 -N ""
        echo "✅ Clave generada en /root/.ssh/id_ed25519.pub"
        cat /root/.ssh/id_ed25519.pub
        ;;
    3)
        echo "Deshabilitando login con contraseña..."
        sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
        systemctl restart sshd
        echo "✅ Login con contraseña deshabilitado"
        ;;
    4)
        echo "Estado del servidor:"
        echo "IP: $(hostname -I | awk '{print $1}')"
        echo "Nginx: $(systemctl is-active nginx)"
        echo "SSH: $(systemctl is-active sshd)"
        echo "SSL: $(if [ -f /etc/letsencrypt/live/tutorium.sistemasorbix.com/fullchain.pem ]; then echo "Configurado"; else echo "No configurado"; fi)"
        ;;
    *)
        echo "Opción no válida"
        ;;
esac
EOF

chmod +x /root/cambiar_ssh.sh

echo "✅ Script de acceso creado en /root/cambiar_ssh.sh"

# ═══════════════════════════════════════════════════════════════
# 11. VERIFICACIÓN FINAL
# ═══════════════════════════════════════════════════════════════

echo ""
echo "🔍 PASO 11: Verificación final..."

# Verificar servicios
echo "Verificando servicios..."
systemctl status nginx --no-pager -l | grep -E "(Active|Main PID)"
systemctl status sshd --no-pager -l | grep -E "(Active|Main PID)"

# Verificar SSL
echo ""
echo "Verificando SSL..."
if [ -f "/etc/letsencrypt/live/tutorium.sistemasorbix.com/fullchain.pem" ]; then
    echo "✅ Certificado SSL presente"
    curl -I https://tutorium.sistemasorbix.com 2>/dev/null | head -1
else
    echo "⚠️ Certificado SSL no encontrado"
    curl -I http://tutorium.sistemasorbix.com 2>/dev/null | head -1
fi

# ═══════════════════════════════════════════════════════════════
# 12. RESUMEN FINAL
# ═══════════════════════════════════════════════════════════════

echo ""
echo "🎉 REPARACIÓN COMPLETADA!"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "📋 INFORMACIÓN DE ACCESO:"
echo "🌐 Dominio: tutorium.sistemasorbix.com"
echo "🔗 IP: $(hostname -I | awk '{print $1}')"
echo "👤 Usuario: root"
echo "🔑 Contraseña: fTeRLCxfnaRL"
echo ""
echo "📝 COMANDOS ÚTILES:"
echo "• Conectar SSH: ssh root@$(hostname -I | awk '{print $1}')"
echo "• Verificar SSL: curl -I https://tutorium.sistemasorbix.com"
echo "• Ver logs Nginx: tail -f /var/log/nginx/tutorium.error.log"
echo "• Configurar SSH: /root/cambiar_ssh.sh"
echo ""
echo "🔧 SERVICIOS ACTIVOS:"
echo "• Nginx: $(systemctl is-active nginx)"
echo "• SSH: $(systemctl is-active sshd)"
echo "• UFW: $(systemctl is-active ufw)"
echo ""
echo "📁 DIRECTORIOS IMPORTANTES:"
echo "• Web: /var/www/tutorium"
echo "• Nginx: /etc/nginx/sites-available/tutorium"
echo "• SSL: /etc/letsencrypt/live/tutorium.sistemasorbix.com/"
echo ""
echo "✅ ¡Todo listo! Puedes conectarte por SSH y verificar el sitio web."
echo "════════════════════════════════════════════════════════════"
