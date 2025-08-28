# Auditoría y Limpieza de Páginas Tutorium

Se realizó una auditoría y limpieza en las páginas principales de Tutorium para garantizar que:

- No exista texto, CSS ni bloques de debug visibles después del `<footer>`.
- Todas las etiquetas HTML estén correctamente cerradas.
- Se agregó un bloque `<style>` defensivo en `<head>` para ocultar posibles dumps o residuos.
- Se mantiene la coherencia visual y de estilos (azul/blanco) en todas las vistas.

Páginas auditadas y protegidas:
- `frontend/pages/index.html`
- `frontend/pages/profedeingles.html`
- `frontend/pages/tutores-ia.html`

Puedes validar visualmente y con el script `scripts/assert-no-dump.js` que no hay texto basura bajo el footer.
# 🎓 Tutorium - Sistema Educativo Inteligente con IA

## 📋 Descripción

Tutorium es una plataforma educativa web moderna que utiliza inteligencia artificial para crear experiencias de aprendizaje personalizadas. La plataforma se especializa en tutorías interactivas, análisis de idiomas con puntuación automática, seguimiento del progreso del estudiante y contenido adaptativo.

## ✨ Características Principales

- **🤖 Tutores con IA**: Asistentes virtuales especializados en diferentes materias
- **🗣️ Análisis de Idiomas**: Sistema avanzado de puntuación de pronunciación, gramática y sintaxis
- **📊 Seguimiento de Progreso**: Dashboard detallado del avance del estudiante con métricas inteligentes
- **🎯 Personalización**: Contenido adaptado al nivel y estilo de aprendizaje
- **📚 Múltiples Cursos**: Variedad de materias y niveles disponibles
- **🔐 Sistema de Usuarios**: Registro, login y perfiles personalizados
- **📱 Responsive**: Funciona en dispositivos móviles y desktop
- **🌐 Multiidioma**: Soporte completo para español e inglés con detección automática
- **🎙️ Reconocimiento de Voz**: Análisis de pronunciación en tiempo real
- **📝 Corrección Automática**: Detección y corrección de errores gramaticales y sintácticos

## � Tecnologías Utilizadas

- **Frontend**: HTML5, CSS3, JavaScript (ES6+), Web Speech API
- **Backend**: Python 3.11, Flask, CORS
- **IA/ML**: 
  - NLTK para análisis de texto
  - TextBlob para procesamiento de lenguaje natural
  - Modelos personalizados para puntuación de idiomas
- **Análisis de Audio**: Librosa, SoundFile
- **Servidor Web**: Apache/Nginx
- **Base de Datos**: SQLite/MySQL
- **Testing**: Pytest, unittest
- **Despliegue**: VPS con Ubuntu/CentOS

## 🧠 Sistema de Puntuación de Idiomas

### Componentes del Sistema

1. **Backend (Python)**
   - `language_scoring_system.py`: Motor de análisis principal
   - `language_api.py`: API REST para análisis
   - `config.py`: Configuración del sistema

2. **Frontend (JavaScript)**
   - `language_scorer.js`: Interfaz de puntuación
   - Integración con Web Speech API
   - UI bilingüe con cambio dinámico

### Métricas de Evaluación

- **Pronunciación (40%)**: Análisis fonético y claridad
- **Gramática (30%)**: Detección de errores gramaticales
- **Sintaxis (20%)**: Complejidad y estructura de oraciones
- **Vocabulario (10%)**: Riqueza y nivel de vocabulario

### Idiomas Soportados

- **🇺🇸 Inglés**: Detección completa de errores comunes
- **🇪🇸 Español**: Análisis de ser/estar, subjuntivo, concordancia

## 📁 Estructura del Proyecto

```
tutorium.sistemasorbix.com/
├── 📄 index.html                    # Página principal
├── 📁 assets/                       # Recursos multimedia
├── 📁 css/                          # Estilos CSS
│   ├── main.css
│   ├── common.css
│   └── pages/
├── 📁 js/                           # JavaScript Frontend
│   ├── app.js
│   ├── common.js
│   ├── index.js
│   └── language_scorer.js           # 🆕 Sistema de puntuación
├── 📁 html/                         # Páginas HTML
│   ├── login.html
│   ├── registro.html
│   ├── cursos.html
│   └── progreso.html
├── 📁 tools/                        # 🆕 Herramientas Backend
│   ├── language_scoring_system.py   # Motor de análisis
│   ├── language_api.py              # API REST
│   ├── config.py                    # Configuración
│   ├── test_language_system.py      # Tests unitarios
│   └── start.py                     # Script de inicio
├── 📁 scripts/                      # Scripts de automatización
├── 📄 server.js                     # Servidor Node.js
├── 📄 requirements.txt              # 🆕 Dependencias Python
├── 📄 package-api.json              # 🆕 Config API
└── 📄 TAREAS-PENDIENTES.md          # 🆕 Backlog detallado
```

## 🛠️ Instalación y Configuración

### Requisitos Previos

- Python 3.8 o superior
- Node.js 16 o superior (opcional)
- Servidor web (Apache/Nginx)
- Git

### Instalación Rápida

1. **Clonar el repositorio**
   ```bash
   git clone https://github.com/tu-usuario/tutorium.sistemasorbix.com.git
   cd tutorium.sistemasorbix.com
   ```

2. **Configurar entorno automáticamente**
   ```bash
   python tools/start.py setup
   ```

3. **Ejecutar tests**
   ```bash
   python tools/start.py test
   ```

4. **Iniciar servidor de desarrollo**
   ```bash
   python tools/start.py serve
   ```

5. **Modo desarrollo completo**
   ```bash
   python tools/start.py dev
   ```

### Instalación Manual

1. **Instalar dependencias Python**
   ```bash
   pip install -r requirements.txt
   ```

2. **Configurar variables de entorno**
   ```bash
   cp .env.example .env
   # Editar .env con tus configuraciones
   ```

3. **Iniciar API**
   ```bash
   python tools/language_api.py
   ```

4. **Abrir navegador**
   - Frontend: `http://localhost:3000`
   - API: `http://localhost:5000`

## 🔧 Configuración del Servidor

### Apache Configuration

```apache
<VirtualHost *:80>
    ServerName tutorium.sistemasorbix.com
    DocumentRoot /var/www/tutorium
    
    <Directory /var/www/tutorium>
        AllowOverride All
        Require all granted
    </Directory>
    
    # Proxy para API Python
    ProxyPass /api/ http://127.0.0.1:5000/api/
    ProxyPassReverse /api/ http://127.0.0.1:5000/api/
    
    ErrorLog ${APACHE_LOG_DIR}/tutorium_error.log
    CustomLog ${APACHE_LOG_DIR}/tutorium_access.log combined
</VirtualHost>
```

### Nginx Configuration

```nginx
server {
    listen 80;
    server_name tutorium.sistemasorbix.com;
    root /var/www/tutorium;
    index index.html;
    
    location / {
        try_files $uri $uri/ =404;
    }
    
    # API Backend Python
    location /api/ {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
    
    # WebSocket para tiempo real
    location /ws/ {
        proxy_pass http://127.0.0.1:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

## 🧪 Testing

### Tests Automáticos
```bash
# Ejecutar todos los tests
python tools/start.py test

# Solo tests del sistema de puntuación
python tools/test_language_system.py

# Verificación de producción
python tools/start.py check
```

### Tests Manuales
```bash
# Test de API
curl -X POST http://localhost:5000/api/analyze-language \
  -H "Content-Type: application/json" \
  -d '{"text": "He are good student", "language": "en"}'

# Health check
curl http://localhost:5000/api/health
```

## 📊 API Endpoints

### Sistema de Puntuación
- `POST /api/analyze-language` - Analizar texto y obtener puntuaciones
- `GET /api/student-progress/:id` - Progreso del estudiante
- `POST /api/save-analysis` - Guardar análisis
- `GET /api/supported-languages` - Idiomas soportados
- `GET /api/health` - Health check

### Autenticación (Pendiente)
- `POST /api/auth/login` - Iniciar sesión
- `POST /api/auth/register` - Registrar usuario
- `POST /api/auth/logout` - Cerrar sesión

### Cursos (Pendiente)
- `GET /api/courses` - Listar cursos
- `GET /api/courses/:id` - Obtener curso específico
- `POST /api/courses/:id/enroll` - Inscribirse en curso

## � Despliegue

### Despliegue con Scripts Automáticos

```bash
# Usar tasks predefinidas
python tools/start.py check              # Verificar sistema
./deploy-simple.bat                      # Deploy básico
./ssl-simple.ps1                         # Configurar SSL
```

### Despliegue Manual

1. **Preparar archivos**
   ```bash
   python tools/start.py check
   ```

2. **Subir al servidor**
   ```bash
   scp -r . usuario@servidor:/var/www/tutorium/
   ```

3. **Configurar en servidor**
   ```bash
   ssh usuario@servidor
   cd /var/www/tutorium
   python tools/start.py setup
   python tools/start.py serve &
   ```

## 🎯 Uso del Sistema de Puntuación

### Desde JavaScript (Frontend)

```javascript
// Inicializar sistema
const scorer = new LanguageScorer('language-scoring-container');

// Analizar texto
scorer.analyzeText("Hello world", "en").then(result => {
    console.log('Puntuaciones:', result.scores);
    console.log('Correcciones:', result.corrections);
});

// Cambiar idioma
scorer.switchLanguage('es');
```

### Desde Python (Backend)

```python
from tools.language_scoring_system import LanguageScoringSystem

# Crear instancia
scorer = LanguageScoringSystem()

# Analizar texto
result = scorer.analyze_text("He are good student", "en")
print(f"Puntuación general: {result['scores']['overall']}")

# Obtener consejos
advice = scorer.get_improvement_advice(result)
for tip in advice:
    print(f"💡 {tip}")
```

## 📋 Tareas Pendientes

Ver [TAREAS-PENDIENTES.md](TAREAS-PENDIENTES.md) para la lista completa de tareas organizadas por prioridad.

### ✅ Completadas Recientemente
- [x] Sistema de puntuación de idiomas
- [x] API REST con Flask
- [x] Tests unitarios completos
- [x] Configuración del proyecto
- [x] Scripts de automatización

### 🚀 Prioridades Inmediatas
- [ ] Integración completa frontend-backend
- [ ] Sistema de autenticación
- [ ] Dashboard de progreso con métricas
- [ ] Base de datos para persistencia
- [ ] Configurar SSL/HTTPS

## 🤝 Contribución

1. Fork del proyecto
2. Crear rama para feature (`git checkout -b feature/LanguageScoring`)
3. Commit cambios (`git commit -m 'Add language scoring system'`)
4. Push a la rama (`git push origin feature/LanguageScoring`)
5. Abrir Pull Request

### Estándares de Código

- **Python**: PEP 8, usar `black` para formato
- **JavaScript**: ES6+, usar `prettier` para formato
- **Tests**: Cobertura mínima 80%
- **Documentación**: Docstrings en español

## � Licencia

Este proyecto está bajo la Licencia MIT - ver [LICENSE](LICENSE) para más detalles.

## 📞 Contacto

- **Proyecto**: [https://github.com/tu-usuario/tutorium.sistemasorbix.com](https://github.com/tu-usuario/tutorium.sistemasorbix.com)
- **Website**: [https://tutorium.sistemasorbix.com](https://tutorium.sistemasorbix.com)
- **Email**: contacto@sistemasorbix.com
- **API Docs**: [https://tutorium.sistemasorbix.com/api/docs](https://tutorium.sistemasorbix.com/api/docs)

## � Reconocimientos

- **OpenAI** por los modelos de IA y APIs
- **NLTK Team** por las herramientas de procesamiento de lenguaje
- **Flask Community** por el framework web
- **Comunidad open source** por las librerías utilizadas
- **Contribuidores del proyecto** por hacer esto posible

## 🎉 Características Destacadas

### 🏆 Sistema de Puntuación Inteligente
- Análisis en tiempo real de texto y voz
- Algoritmos adaptativos de machine learning
- Feedback personalizado según el nivel del estudiante

### 🌍 Soporte Multilingüe Avanzado
- Detección automática de idioma
- Reglas gramaticales específicas por idioma
- Errores comunes culturalmente relevantes

### 📈 Analytics y Progreso
- Tracking detallado del progreso
- Identificación de patrones de mejora
- Reportes de tendencias de aprendizaje

---

⭐ **¡Dale una estrella al proyecto si te gusta!** ⭐

🚀 **Únete a nosotros en la revolución del aprendizaje de idiomas con IA** 🚀
