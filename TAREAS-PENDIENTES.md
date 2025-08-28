# 📌 Tareas Pendientes de Tutorium

## 1. Estructura de la Plataforma

- [ ] Replicar eLearning de Odoo Community 16 como base.
	- [ ] Analizar los módulos clave de eLearning en Odoo Community 16 (cursos, lecciones, quizzes, progreso, certificados).
	- [ ] Definir la estructura de datos mínima (cursos, lecciones, usuarios, progreso, certificados).
	- [ ] Crear modelos y migraciones iniciales en el backend (sin Odoo, solo Python/SQL).
	- [ ] Implementar endpoints REST para gestión de cursos, lecciones y progreso.
	- [ ] Crear interfaz web básica para visualizar cursos y lecciones.
	- [ ] Agregar soporte para quizzes y autoevaluaciones.
	- [ ] Implementar lógica de emisión de certificados al completar cursos.
	- [ ] Documentar endpoints y estructura de datos.
				- [ ] Integrar videollamadas en tiempo real (Zoom + lógica IA/humano).
					- [ ] Investigar e integrar Zoom API/SDK para reuniones embebidas.
					- [ ] Definir estructura de datos para identificar tipo de tutor (IA: codemaster, mathgenius, etc. / Humano).
					- [ ] Al iniciar la videollamada:
							- [ ] Si el tutor es IA (ej: codemaster, mathgenius):
									- [ ] Mostrar imagen/avatar representativo del tutor IA en vez de video.
									- [ ] Deshabilitar opción de cámara para el “tutor IA”.
									- [ ] Permitir solo audio y chat para el tutor IA.
							- [ ] Si el tutor es humano:
									- [ ] Solicitar acceso a cámara (opcional) y audio (obligatorio).
									- [ ] Permitir que el profesor humano elija si activa cámara o solo audio.
									- [ ] Si el profesor no activa cámara, mostrar su avatar o iniciales.
					- [ ] Implementar lógica frontend para mostrar el estado (IA/avatar, humano/cámara, humano/audio).
					- [ ] Integrar autenticación y control de acceso a salas.
					- [ ] Añadir chat y compartición de pantalla (si es posible).
					- [ ] Pruebas de calidad de audio/video y experiencia de usuario.
					- [ ] Documentar el flujo de conexión y reglas de visualización.
- [ ] Sincronización con Moodle.
- [ ] Backend administrativo conectado a Odoo.

## 2. IA y Personalización

- [ ] Tutor IA que asigne tareas y formule preguntas diarias (ejemplo: para Galilea y compañeros).
  - [ ] Implementar sistema de puntuación para estudiantes (pronunciación, sintaxis, gramática).
    - [ ] Backend: Crear API `/api/analyze-language` para análisis de texto.
    - [ ] Backend: Sistema de detección de errores gramaticales por idioma.
    - [ ] Backend: Algoritmo de puntuación ponderada (pronunciación 40%, gramática 30%, sintaxis 20%, vocabulario 10%).
    - [ ] Frontend: Interfaz de puntuación con barras de progreso y círculo de puntuación general.
    - [ ] Frontend: Sistema de correcciones en tiempo real con sugerencias.
  - [ ] Agregar corrección automática de pronunciación usando Web Speech API.
    - [ ] Integrar reconocimiento de voz para captura de audio del estudiante.
    - [ ] Comparar pronunciación con síntesis de voz nativa.
    - [ ] Análisis de precisión fonética básica.
  - [ ] Implementar corrección de sintaxis y gramática en tiempo real.
    - [ ] Patrones de errores comunes en inglés y español.
    - [ ] Sugerencias contextuales para mejora de estructura.
    - [ ] Validación de concordancia y tiempos verbales.
  - [ ] Crear switch de idioma (Inglés/Español) para ejercicios y correcciones.
    - [ ] Toggle animado con banderas de países.
    - [ ] Cambio dinámico de idioma para reconocimiento de voz.
    - [ ] Traducciones automáticas de interfaz.
  - [ ] Sistema de indicadores de progreso por área (pronunciación, gramática, vocabulario).
    - [ ] Tracking histórico de puntuaciones por sesión.
    - [ ] Tendencias de mejora a lo largo del tiempo.
    - [ ] Niveles de competencia (A1, A2, B1, B2, C1, C2).
  - [ ] Generar consejos personalizados para mejorar el nivel del idioma seleccionado.
    - [ ] Consejos específicos basados en puntuaciones bajas.
    - [ ] Recomendaciones de ejercicios complementarios.
    - [ ] Seguimiento de áreas de mejora prioritarias.
  - [ ] Dashboard de progreso con métricas detalladas por habilidad lingüística.
    - [ ] Reportes exportables de progreso del estudiante.
    - [ ] Comparativas entre sesiones de práctica.
    - [ ] Alertas automáticas para profesores sobre estudiantes que necesitan ayuda.
- [ ] Emisión automática de certificados al completar cursos.
- [ ] Matching inteligente de estudiantes con tutores.

## 3. Dashboard y Métricas

- [ ] Seguimiento de progreso individual y grupal.
- [ ] Estadísticas detalladas de rendimiento.
- [ ] Panel interactivo para docentes y padres.

## 4. Automatización y Pruebas

- [ ] Tareas programadas por día con argumentos y documentación (para que Copilot las ejecute solo).
- [ ] Integrar pruebas automatizadas (Playwright) para validar UX y performance.
- [ ] Reportes de seguridad y estabilidad.

## 5. Experiencia de Usuario

- [ ] Interfaz visual moderna, clara y motivacional.
- [ ] Espacios de colaboración entre estudiantes.
- [ ] Opciones de gamificación para aumentar el engagement.
