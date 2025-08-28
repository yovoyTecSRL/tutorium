// ===================================================================
// Tutorium - JavaScript Functions
// Orbix Systems E-Learning Platform
// ===================================================================

// Configuración de OpenAI
const OPENAI_CONFIG = {
    apiKey: process.env.OPENAI_API_KEY || 'YOUR_OPENAI_API_KEY_HERE',
    projectId: 'proj_FqtYiqxNhqNwLXVlc2PUIIGe',
    baseUrl: 'https://api.openai.com/v1'
};

// Utilidades generales
const TutoriumUtils = {
    // Logging
    log: function(message, type = 'info') {
        const timestamp = new Date().toISOString();
        console.log(`[${timestamp}] [${type.toUpperCase()}] ${message}`);
    },
    
    // Almacenamiento local
    storage: {
        set: function(key, value) {
            try {
                localStorage.setItem(key, JSON.stringify(value));
                return true;
            } catch (e) {
                TutoriumUtils.log('Error saving to localStorage: ' + e.message, 'error');
                return false;
            }
        },
        
        get: function(key) {
            try {
                const item = localStorage.getItem(key);
                return item ? JSON.parse(item) : null;
            } catch (e) {
                TutoriumUtils.log('Error reading from localStorage: ' + e.message, 'error');
                return null;
            }
        },
        
        remove: function(key) {
            try {
                localStorage.removeItem(key);
                return true;
            } catch (e) {
                TutoriumUtils.log('Error removing from localStorage: ' + e.message, 'error');
                return false;
            }
        }
    },
    
    // Validación de formularios
    validateEmail: function(email) {
        const re = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        return re.test(email);
    },
    
    validatePassword: function(password) {
        return password.length >= 8;
    },
    
    // Efectos visuales
    showLoading: function(element) {
        element.innerHTML = '<div class="spinner"></div>';
    },
    
    hideLoading: function(element, originalContent) {
        element.innerHTML = originalContent;
    },
    
    // Notificaciones
    showNotification: function(message, type = 'info', duration = 3000) {
        const notification = document.createElement('div');
        notification.className = `notification notification-${type}`;
        notification.textContent = message;
        notification.style.cssText = `
            position: fixed;
            top: 20px;
            right: 20px;
            padding: 15px 20px;
            border-radius: 8px;
            color: white;
            font-weight: bold;
            z-index: 10000;
            animation: slideIn 0.3s ease-out;
        `;
        
        switch (type) {
            case 'success':
                notification.style.backgroundColor = '#4CAF50';
                break;
            case 'error':
                notification.style.backgroundColor = '#f44336';
                break;
            case 'warning':
                notification.style.backgroundColor = '#FF9800';
                break;
            default:
                notification.style.backgroundColor = '#00f7ff';
        }
        
        document.body.appendChild(notification);
        
        setTimeout(() => {
            notification.remove();
        }, duration);
    }
};

// Asistente IA
const AIAssistant = {
    isListening: false,
    recognition: null,
    
    init: function() {
        if ('webkitSpeechRecognition' in window || 'SpeechRecognition' in window) {
            const SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition;
            this.recognition = new SpeechRecognition();
            this.recognition.continuous = false;
            this.recognition.interimResults = false;
            this.recognition.lang = 'es-ES';
            
            this.recognition.onstart = () => {
                this.isListening = true;
                TutoriumUtils.log('Asistente IA: Escuchando...');
            };
            
            this.recognition.onresult = (event) => {
                const transcript = event.results[0][0].transcript;
                TutoriumUtils.log('Comando de voz: ' + transcript);
                this.processCommand(transcript);
            };
            
            this.recognition.onerror = (event) => {
                TutoriumUtils.log('Error de reconocimiento de voz: ' + event.error, 'error');
                this.isListening = false;
            };
            
            this.recognition.onend = () => {
                this.isListening = false;
            };
        }
    },
    
    startListening: function() {
        if (this.recognition && !this.isListening) {
            this.recognition.start();
        }
    },
    
    stopListening: function() {
        if (this.recognition && this.isListening) {
            this.recognition.stop();
        }
    },
    
    processCommand: function(command) {
        command = command.toLowerCase();
        
        if (command.includes('cursos') || command.includes('curso')) {
            window.location.href = 'cursos.html';
        } else if (command.includes('registro') || command.includes('registrar')) {
            window.location.href = 'registro.html';
        } else if (command.includes('ayuda') || command.includes('help')) {
            this.showHelp();
        } else {
            this.chatWithAI(command);
        }
    },
    
    chatWithAI: async function(message) {
        try {
            const response = await fetch(`${OPENAI_CONFIG.baseUrl}/chat/completions`, {
                method: 'POST',
                headers: {
                    'Authorization': `Bearer ${OPENAI_CONFIG.apiKey}`,
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    model: 'gpt-4',
                    messages: [
                        {
                            role: 'system',
                            content: 'Eres un asistente educativo para la plataforma Tutorium de Sistemas Orbix. Ayudas a los estudiantes con sus cursos de tecnología e IA.'
                        },
                        {
                            role: 'user',
                            content: message
                        }
                    ],
                    max_tokens: 150,
                    temperature: 0.7
                })
            });
            
            const data = await response.json();
            
            if (data.choices && data.choices[0]) {
                const aiResponse = data.choices[0].message.content;
                this.speak(aiResponse);
                TutoriumUtils.showNotification('IA: ' + aiResponse, 'info', 5000);
            }
        } catch (error) {
            TutoriumUtils.log('Error comunicándose con IA: ' + error.message, 'error');
            TutoriumUtils.showNotification('Error conectando con el asistente IA', 'error');
        }
    },
    
    speak: function(text) {
        if ('speechSynthesis' in window) {
            const utterance = new SpeechSynthesisUtterance(text);
            utterance.lang = 'es-ES';
            utterance.rate = 0.9;
            utterance.pitch = 1.1;
            speechSynthesis.speak(utterance);
        }
    },
    
    showHelp: function() {
        const helpText = `
        Comandos disponibles:
        - "Cursos" - Ver cursos disponibles
        - "Registro" - Registrarse en la plataforma
        - "Ayuda" - Mostrar esta ayuda
        - Cualquier pregunta sobre tecnología o programación
        `;
        
        TutoriumUtils.showNotification(helpText, 'info', 8000);
        this.speak('Puedes decir: cursos, registro, ayuda, o hacerme cualquier pregunta sobre tecnología.');
    }
};

// Sistema de progreso del usuario
const UserProgress = {
    currentUser: null,
    
    init: function() {
        this.currentUser = TutoriumUtils.storage.get('currentUser');
        if (this.currentUser) {
            this.updateUI();
        }
    },
    
    login: function(userData) {
        this.currentUser = userData;
        TutoriumUtils.storage.set('currentUser', userData);
        this.updateUI();
        TutoriumUtils.showNotification('¡Bienvenido, ' + userData.name + '!', 'success');
    },
    
    logout: function() {
        this.currentUser = null;
        TutoriumUtils.storage.remove('currentUser');
        this.updateUI();
        TutoriumUtils.showNotification('Sesión cerrada', 'info');
    },
    
    updateProgress: function(courseId, progress) {
        if (this.currentUser) {
            if (!this.currentUser.progress) {
                this.currentUser.progress = {};
            }
            this.currentUser.progress[courseId] = progress;
            TutoriumUtils.storage.set('currentUser', this.currentUser);
        }
    },
    
    getProgress: function(courseId) {
        if (this.currentUser && this.currentUser.progress) {
            return this.currentUser.progress[courseId] || 0;
        }
        return 0;
    },
    
    updateUI: function() {
        const loginLink = document.querySelector('a[href="#login"]');
        if (loginLink) {
            if (this.currentUser) {
                loginLink.innerHTML = `<i class="fas fa-user"></i> ${this.currentUser.name}`;
                loginLink.href = '#profile';
            } else {
                loginLink.innerHTML = '<i class="fas fa-sign-in-alt"></i> Login';
                loginLink.href = '#login';
            }
        }
    }
};

// Inicialización cuando el DOM esté listo
document.addEventListener('DOMContentLoaded', function() {
    TutoriumUtils.log('Iniciando Tutorium...');
    
    // Inicializar sistemas
    AIAssistant.init();
    UserProgress.init();
    
    // Configurar eventos
    const aiButton = document.querySelector('.ai-assistant');
    if (aiButton) {
        aiButton.addEventListener('click', function() {
            AIAssistant.startListening();
        });
    }
    
    // Configurar navegación suave
    document.querySelectorAll('a[href^="#"]').forEach(anchor => {
        anchor.addEventListener('click', function(e) {
            e.preventDefault();
            const target = document.querySelector(this.getAttribute('href'));
            if (target) {
                target.scrollIntoView({
                    behavior: 'smooth'
                });
            }
        });
    });
    
    TutoriumUtils.log('Tutorium inicializado correctamente');
});

// Exportar para uso global
window.TutoriumUtils = TutoriumUtils;
window.AIAssistant = AIAssistant;
window.UserProgress = UserProgress;
