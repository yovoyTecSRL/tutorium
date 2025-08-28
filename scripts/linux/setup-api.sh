# ===================================================================
# Configuración de API OpenAI en servidor
# ===================================================================

# 1. Crear directorio para API
sudo mkdir -p /var/www/tutorium/api

# 2. Crear package.json
sudo tee /var/www/tutorium/api/package.json > /dev/null << 'EOF'
{
  "name": "tutorium-api",
  "version": "1.0.0",
  "description": "API para Tutorium",
  "main": "server.js",
  "scripts": {
    "start": "node server.js",
    "dev": "nodemon server.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "cors": "^2.8.5",
    "helmet": "^7.0.0",
    "dotenv": "^16.3.1",
    "express-rate-limit": "^6.8.1",
    "openai": "^4.0.0"
  }
}
EOF

# 3. Crear servidor Express
sudo tee /var/www/tutorium/api/server.js > /dev/null << 'EOF'
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3001;

// Middleware
app.use(helmet());
app.use(cors());
app.use(express.json());

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutos
  max: 100 // límite de 100 requests por IP
});
app.use('/api/', limiter);

// OpenAI configuration
const OpenAI = require('openai');
const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY
});

// API Routes
app.post('/api/chat', async (req, res) => {
  try {
    const { message } = req.body;
    
    if (!message) {
      return res.status(400).json({ error: 'Mensaje requerido' });
    }
    
    const completion = await openai.chat.completions.create({
      model: "gpt-4",
      messages: [
        {
          role: "system",
          content: "Eres un asistente educativo para Tutorium. Ayudas a estudiantes con sus cursos y dudas académicas. Responde en español de forma clara y educativa."
        },
        {
          role: "user",
          content: message
        }
      ],
      max_tokens: 500,
      temperature: 0.7
    });
    
    res.json({
      response: completion.choices[0].message.content,
      timestamp: new Date().toISOString()
    });
    
  } catch (error) {
    console.error('Error OpenAI:', error);
    res.status(500).json({ error: 'Error procesando consulta' });
  }
});

// Health check
app.get('/api/health', (req, res) => {
  res.json({ 
    status: 'OK', 
    timestamp: new Date().toISOString(),
    service: 'Tutorium API'
  });
});

// Start server
app.listen(PORT, () => {
  console.log(`🚀 Tutorium API corriendo en puerto ${PORT}`);
});
EOF

# 4. Crear archivo de environment
sudo tee /var/www/tutorium/api/.env > /dev/null << 'EOF'
PORT=3001
OPENAI_API_KEY=<REDACTED>"YOUR_OPENAI_API_KEY_HERE"}
NODE_ENV=production
EOF

# 5. Instalar dependencias
cd /var/www/tutorium/api
sudo npm install

# 6. Configurar PM2
sudo tee /var/www/tutorium/api/ecosystem.config.js > /dev/null << 'EOF'
module.exports = {
  apps: [{
    name: 'tutorium-api',
    script: 'server.js',
    instances: 1,
    autorestart: true,
    watch: false,
    max_memory_restart: '1G',
    env: {
      NODE_ENV: 'production',
      PORT: 3001
    }
  }]
};
EOF

# 7. Iniciar API con PM2
sudo pm2 start ecosystem.config.js
sudo pm2 startup
sudo pm2 save

# 8. Actualizar configuración Nginx para proxy API
sudo tee /etc/nginx/sites-available/tutorium > /dev/null << 'EOF'
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
    
    # Proxy API requests
    location /api/ {
        proxy_pass http://localhost:3001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
    
    # Static files
    location / {
        try_files $uri $uri/ =404;
        add_header Cache-Control "public, max-age=31536000";
    }
    
    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;
    
    access_log /var/log/nginx/tutorium.access.log;
    error_log /var/log/nginx/tutorium.error.log;
}
EOF

# 9. Reiniciar Nginx
sudo nginx -t && sudo systemctl reload nginx

# 10. Configurar permisos finales
sudo chown -R www-data:www-data /var/www/tutorium
sudo chmod -R 755 /var/www/tutorium

echo "✅ API configurada correctamente"
echo "🌐 Endpoint: https://tutorium.sistemasorbix.com/api/health"
echo "💬 Chat API: https://tutorium.sistemasorbix.com/api/chat"
echo "📋 PM2 status: pm2 status"
