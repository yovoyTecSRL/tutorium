// Servidor principal de Tutorium - Sistemas Orbix
// ================================================

const express = require('express');
const path = require('path');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');
const rateLimit = require('express-rate-limit');
const { createServer } = require('http');
const { Server } = require('socket.io');
require('dotenv').config();

// Configuración del servidor
const app = express();
const server = createServer(app);
const io = new Server(server, {
  cors: {
    origin: process.env.BASE_URL || "*",
    methods: ["GET", "POST"]
  }
});

const PORT = process.env.PORT || 3000;
const HOST = process.env.HOST || '0.0.0.0';

// Middleware de seguridad
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'", "https://cdnjs.cloudflare.com"],
      scriptSrc: ["'self'", "'unsafe-inline'", "https://cdnjs.cloudflare.com"],
      imgSrc: ["'self'", "data:", "https:"],
      connectSrc: ["'self'", "https://api.openai.com"],
      fontSrc: ["'self'", "https://cdnjs.cloudflare.com"],
      objectSrc: ["'none'"],
      mediaSrc: ["'self'"],
      frameSrc: ["'none'"],
    },
  },
  crossOriginEmbedderPolicy: false
}));

// Middleware de compresión
app.use(compression());

// Middleware de CORS
app.use(cors({
  origin: process.env.BASE_URL || "*",
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With'],
  credentials: true
}));

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutos
  max: 100, // límite de 100 requests por ventana de tiempo
  message: 'Demasiadas solicitudes, intenta de nuevo más tarde.'
});

app.use('/api/', limiter);

// Middleware para parsear JSON
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Servir archivos estáticos
app.use(express.static(path.join(__dirname, 'assets')));
app.use('/css', express.static(path.join(__dirname, 'css')));
app.use('/js', express.static(path.join(__dirname, 'js')));
app.use('/img', express.static(path.join(__dirname, 'img')));
app.use('/pages', express.static(path.join(__dirname, 'pages')));

// Rutas principales
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'index.html'));
});

app.get('/login', (req, res) => {
  res.sendFile(path.join(__dirname, 'login.html'));
});

app.get('/registro', (req, res) => {
  res.sendFile(path.join(__dirname, 'registro.html'));
});

app.get('/cursos', (req, res) => {
  res.sendFile(path.join(__dirname, 'cursos.html'));
});

app.get('/certificaciones', (req, res) => {
  res.sendFile(path.join(__dirname, 'certificaciones.html'));
});

app.get('/tutores-ia', (req, res) => {
  res.sendFile(path.join(__dirname, 'tutores-ia.html'));
});

app.get('/panel-admin', (req, res) => {
  res.sendFile(path.join(__dirname, 'panel-admin.html'));
});

app.get('/progreso', (req, res) => {
  res.sendFile(path.join(__dirname, 'progreso.html'));
});

// API Routes
app.get('/api/health', (req, res) => {
  res.json({
    status: 'OK',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    environment: process.env.NODE_ENV || 'development',
    version: '1.0.0'
  });
});

// API para OpenAI (si se necesita)
app.post('/api/ai/chat', async (req, res) => {
  try {
    const { message, context } = req.body;
    
    // Aquí iría la lógica de OpenAI
    res.json({
      response: "Funcionalidad de AI disponible próximamente",
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('Error en AI chat:', error);
    res.status(500).json({
      error: 'Error interno del servidor',
      timestamp: new Date().toISOString()
    });
  }
});

// API para estadísticas del sistema
app.get('/api/stats', (req, res) => {
  res.json({
    users_online: io.sockets.sockets.size,
    server_uptime: process.uptime(),
    memory_usage: process.memoryUsage(),
    timestamp: new Date().toISOString()
  });
});

// Socket.IO para tiempo real
io.on('connection', (socket) => {
  console.log('🟢 Usuario conectado:', socket.id);
  
  socket.on('join-room', (room) => {
    socket.join(room);
    console.log(`Usuario ${socket.id} se unió a la sala ${room}`);
  });
  
  socket.on('chat-message', (data) => {
    socket.to(data.room).emit('chat-message', {
      message: data.message,
      user: data.user,
      timestamp: new Date().toISOString()
    });
  });
  
  socket.on('disconnect', () => {
    console.log('🔴 Usuario desconectado:', socket.id);
  });
});

// Middleware de manejo de errores
app.use((err, req, res, next) => {
  console.error('Error:', err.stack);
  res.status(500).json({
    error: 'Error interno del servidor',
    timestamp: new Date().toISOString()
  });
});

// Ruta 404
app.use((req, res) => {
  res.status(404).json({
    error: 'Ruta no encontrada',
    path: req.path,
    timestamp: new Date().toISOString()
  });
});

// Iniciar servidor
server.listen(PORT, HOST, () => {
  console.log(`
  🚀 Servidor Tutorium iniciado exitosamente!
  
  📍 URL: http://${HOST}:${PORT}
  🌍 Entorno: ${process.env.NODE_ENV || 'development'}
  📊 PID: ${process.pid}
  ⏰ Iniciado: ${new Date().toLocaleString()}
  
  🔗 Rutas disponibles:
  - GET / (Página principal)
  - GET /login (Login)
  - GET /registro (Registro)
  - GET /cursos (Cursos)
  - GET /certificaciones (Certificaciones)
  - GET /tutores-ia (Tutores IA)
  - GET /panel-admin (Panel administrativo)
  - GET /progreso (Progreso del estudiante)
  - GET /api/health (Estado del servidor)
  - GET /api/stats (Estadísticas)
  - POST /api/ai/chat (Chat con IA)
  
  ✨ Socket.IO habilitado para tiempo real
  🛡️ Seguridad y rate limiting activos
  `);
});

// Manejo de señales de terminación
process.on('SIGTERM', () => {
  console.log('🔄 Señal SIGTERM recibida, cerrando servidor...');
  server.close(() => {
    console.log('✅ Servidor cerrado correctamente');
    process.exit(0);
  });
});

process.on('SIGINT', () => {
  console.log('🔄 Señal SIGINT recibida, cerrando servidor...');
  server.close(() => {
    console.log('✅ Servidor cerrado correctamente');
    process.exit(0);
  });
});

module.exports = app;
