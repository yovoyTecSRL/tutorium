# ===================================================================
# INSTRUCCIONES FINALES - RESOLVER SSL MANUALMENTE
# ===================================================================

## 🚨 SITUACIÓN ACTUAL

Los scripts automáticos fallan por problemas de conexión SSH:
- Error: "getsockname failed: Not a socket"
- Error: "Read from remote host 178.156.182.125: Unknown error"

## 🛠️ SOLUCIÓN MANUAL

### OPCIÓN 1: Usar Terminal SSH Externo
1. Usa PuTTY, Terminal de Windows, o cualquier cliente SSH
2. Conecta: `ssh root@178.156.182.125`
3. Copia y pega el contenido de `ssl-manual.sh` bloque por bloque

### OPCIÓN 2: Usar Panel de Control Hetzner
1. Accede al panel de Hetzner Cloud
2. Usa la consola web del servidor
3. Ejecuta los comandos del archivo `ssl-manual.sh`

### OPCIÓN 3: Usar WinSCP + PuTTY
1. Conecta con WinSCP para subir archivos
2. Usa PuTTY para ejecutar comandos
3. Sigue las instrucciones paso a paso

## 📋 COMANDOS PRINCIPALES

```bash
# 1. Preparar sistema
apt update -y && apt install -y nginx certbot python3-certbot-nginx

# 2. Crear directorio
mkdir -p /var/www/tutorium

# 3. Configurar Nginx básico
rm -f /etc/nginx/sites-enabled/default
# [Crear configuración básica]

# 4. Obtener SSL
certbot certonly --webroot --webroot-path=/var/www/tutorium --email admin@sistemasorbix.com --agree-tos --no-eff-email --domains tutorium.sistemasorbix.com,www.tutorium.sistemasorbix.com --non-interactive

# 5. Configurar SSL en Nginx
# [Crear configuración SSL completa]

# 6. Recargar Nginx
nginx -t && systemctl reload nginx
```

## 🔧 ARCHIVOS DISPONIBLES

1. **ssl-manual.sh** - Script completo para copiar y pegar
2. **manual-ssl-setup.sh** - Script alternativo
3. **README-SSL.md** - Instrucciones detalladas

## 🎯 OBJETIVO

Lograr que `https://tutorium.sistemasorbix.com` funcione correctamente con SSL válido.

## 📞 SIGUIENTE PASO

¿Prefieres que te ayude con alguna de estas opciones específicas?
- Crear comandos individuales para copiar uno por uno
- Preparar archivos para subir con WinSCP
- Crear una versión más simple del sitio web

---

💡 **IMPORTANTE**: Los problemas de conexión SSH son de red/firewall, no del código. El SSL se puede configurar manualmente siguiendo los pasos del archivo `ssl-manual.sh`.
