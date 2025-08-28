/* ============================================
   TUTORIUM - SISTEMAS ORBIX
   JavaScript común para todas las páginas
   ============================================ */

// Namespace global para la aplicación
window.Tutorium = window.Tutorium || {};

// === CONFIGURACIÓN GLOBAL ===
Tutorium.config = {
    animationDuration: 300,
    apiBaseUrl: '/api',
    version: '1.0.0'
};

// === UTILIDADES COMUNES ===
Tutorium.utils = {
    // Mostrar/ocultar elementos
    show: function(element) {
        if (typeof element === 'string') {
            element = document.querySelector(element);
        }
        if (element) {
            element.style.display = 'block';
        }
    },

    hide: function(element) {
        if (typeof element === 'string') {
            element = document.querySelector(element);
        }
        if (element) {
            element.style.display = 'none';
        }
    },

    // Alternar visibilidad
    toggle: function(element) {
        if (typeof element === 'string') {
            element = document.querySelector(element);
        }
        if (element) {
            element.style.display = element.style.display === 'none' ? 'block' : 'none';
        }
    },

    // Formatear números
    formatNumber: function(num) {
        return num.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
    },

    // Validar email
    validateEmail: function(email) {
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        return emailRegex.test(email);
    },

    // Generar ID único
    generateId: function() {
        return Date.now().toString(36) + Math.random().toString(36).substr(2);
    },

    // Debounce función
    debounce: function(func, wait) {
        let timeout;
        return function executedFunction(...args) {
            const later = () => {
                clearTimeout(timeout);
                func(...args);
            };
            clearTimeout(timeout);
            timeout = setTimeout(later, wait);
        };
    },

    // Throttle función
    throttle: function(func, limit) {
        let inThrottle;
        return function() {
            const args = arguments;
            const context = this;
            if (!inThrottle) {
                func.apply(context, args);
                inThrottle = true;
                setTimeout(() => inThrottle = false, limit);
            }
        };
    },

    // Copiar al portapapeles
    copyToClipboard: function(text) {
        navigator.clipboard.writeText(text).then(() => {
            Tutorium.notifications.show('Copiado al portapapeles', 'success');
        }).catch(err => {
            console.error('Error al copiar: ', err);
            Tutorium.notifications.show('Error al copiar', 'error');
        });
    }
};

// === SISTEMA DE NOTIFICACIONES ===
Tutorium.notifications = {
    show: function(message, type = 'info', duration = 3000) {
        const notification = document.createElement('div');
        notification.className = `notification notification-${type}`;
        notification.innerHTML = `
            <div class="notification-content">
                <i class="fas ${this.getIcon(type)}"></i>
                <span>${message}</span>
            </div>
            <button class="notification-close" onclick="this.parentElement.remove()">
                <i class="fas fa-times"></i>
            </button>
        `;

        // Estilos para la notificación
        notification.style.cssText = `
            position: fixed;
            top: 20px;
            right: 20px;
            z-index: 10000;
            background: rgba(255, 255, 255, 0.1);
            backdrop-filter: blur(20px);
            border-radius: 10px;
            padding: 15px 20px;
            color: white;
            border: 2px solid ${this.getColor(type)};
            box-shadow: 0 4px 20px rgba(0, 0, 0, 0.3);
            transform: translateX(400px);
            transition: transform 0.3s ease;
            max-width: 350px;
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 15px;
        `;

        document.body.appendChild(notification);

        // Animación de entrada
        setTimeout(() => {
            notification.style.transform = 'translateX(0)';
        }, 10);

        // Auto-remover después del duration
        setTimeout(() => {
            notification.style.transform = 'translateX(400px)';
            setTimeout(() => {
                if (notification.parentElement) {
                    notification.parentElement.removeChild(notification);
                }
            }, 300);
        }, duration);
    },

    getIcon: function(type) {
        const icons = {
            'success': 'fa-check-circle',
            'error': 'fa-times-circle',
            'warning': 'fa-exclamation-triangle',
            'info': 'fa-info-circle'
        };
        return icons[type] || icons.info;
    },

    getColor: function(type) {
        const colors = {
            'success': '#4CAF50',
            'error': '#f44336',
            'warning': '#FF9800',
            'info': '#2196F3'
        };
        return colors[type] || colors.info;
    }
};

// === CARGA Y ESTADO ===
Tutorium.loading = {
    show: function(element) {
        if (typeof element === 'string') {
            element = document.querySelector(element);
        }
        if (element) {
            element.innerHTML = '<div class="loading-spinner"></div>';
            element.classList.add('loading');
        }
    },

    hide: function(element) {
        if (typeof element === 'string') {
            element = document.querySelector(element);
        }
        if (element) {
            element.classList.remove('loading');
            const spinner = element.querySelector('.loading-spinner');
            if (spinner) {
                spinner.remove();
            }
        }
    }
};

// === ANIMACIONES COMUNES ===
Tutorium.animations = {
    fadeIn: function(element, duration = 300) {
        if (typeof element === 'string') {
            element = document.querySelector(element);
        }
        if (element) {
            element.style.opacity = '0';
            element.style.display = 'block';
            element.style.transition = `opacity ${duration}ms ease`;
            setTimeout(() => {
                element.style.opacity = '1';
            }, 10);
        }
    },

    fadeOut: function(element, duration = 300) {
        if (typeof element === 'string') {
            element = document.querySelector(element);
        }
        if (element) {
            element.style.transition = `opacity ${duration}ms ease`;
            element.style.opacity = '0';
            setTimeout(() => {
                element.style.display = 'none';
            }, duration);
        }
    },

    slideUp: function(element, duration = 300) {
        if (typeof element === 'string') {
            element = document.querySelector(element);
        }
        if (element) {
            element.style.transition = `transform ${duration}ms ease`;
            element.style.transform = 'translateY(-20px)';
            element.style.opacity = '0.8';
            setTimeout(() => {
                element.style.transform = 'translateY(0)';
                element.style.opacity = '1';
            }, 10);
        }
    },

    slideDown: function(element, duration = 300) {
        if (typeof element === 'string') {
            element = document.querySelector(element);
        }
        if (element) {
            element.style.transition = `transform ${duration}ms ease`;
            element.style.transform = 'translateY(0)';
            element.style.opacity = '1';
            setTimeout(() => {
                element.style.transform = 'translateY(20px)';
                element.style.opacity = '0.8';
            }, 10);
        }
    }
};

// === MANEJO DE FORMULARIOS ===
Tutorium.forms = {
    validate: function(form) {
        const errors = [];
        const inputs = form.querySelectorAll('input[required], select[required], textarea[required]');

        inputs.forEach(input => {
            if (!input.value.trim()) {
                errors.push(`${input.name || input.id} es requerido`);
                input.classList.add('error');
            } else {
                input.classList.remove('error');
            }

            // Validación específica para email
            if (input.type === 'email' && input.value && !Tutorium.utils.validateEmail(input.value)) {
                errors.push('Email no válido');
                input.classList.add('error');
            }
        });

        return errors;
    },

    serialize: function(form) {
        const formData = new FormData(form);
        const data = {};
        for (let [key, value] of formData.entries()) {
            data[key] = value;
        }
        return data;
    },

    reset: function(form) {
        form.reset();
        form.querySelectorAll('.error').forEach(input => {
            input.classList.remove('error');
        });
    }
};

// === MANEJO DE MODALES ===
Tutorium.modal = {
    show: function(modalId) {
        const modal = document.getElementById(modalId);
        if (modal) {
            modal.style.display = 'flex';
            setTimeout(() => {
                modal.classList.add('active');
            }, 10);
        }
    },

    hide: function(modalId) {
        const modal = document.getElementById(modalId);
        if (modal) {
            modal.classList.remove('active');
            setTimeout(() => {
                modal.style.display = 'none';
            }, 300);
        }
    },

    create: function(title, content, buttons = []) {
        const modalId = Tutorium.utils.generateId();
        const modalHTML = `
            <div id="${modalId}" class="modal">
                <div class="modal-content">
                    <div class="modal-header">
                        <h3>${title}</h3>
                        <button class="modal-close" onclick="Tutorium.modal.hide('${modalId}')">
                            <i class="fas fa-times"></i>
                        </button>
                    </div>
                    <div class="modal-body">
                        ${content}
                    </div>
                    <div class="modal-footer">
                        ${buttons.map(btn => `<button class="btn ${btn.class || 'btn-primary'}" onclick="${btn.onclick}">${btn.text}</button>`).join('')}
                    </div>
                </div>
            </div>
        `;

        document.body.insertAdjacentHTML('beforeend', modalHTML);
        this.show(modalId);
        return modalId;
    }
};

// === MANEJO DE AJAX ===
Tutorium.ajax = {
    get: async function(url) {
        try {
            const response = await fetch(url);
            return await response.json();
        } catch (error) {
            console.error('Error en GET:', error);
            throw error;
        }
    },

    post: async function(url, data) {
        try {
            const response = await fetch(url, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify(data)
            });
            return await response.json();
        } catch (error) {
            console.error('Error en POST:', error);
            throw error;
        }
    },

    put: async function(url, data) {
        try {
            const response = await fetch(url, {
                method: 'PUT',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify(data)
            });
            return await response.json();
        } catch (error) {
            console.error('Error en PUT:', error);
            throw error;
        }
    },

    delete: async function(url) {
        try {
            const response = await fetch(url, {
                method: 'DELETE'
            });
            return await response.json();
        } catch (error) {
            console.error('Error en DELETE:', error);
            throw error;
        }
    }
};

// === ALMACENAMIENTO LOCAL ===
Tutorium.storage = {
    set: function(key, value) {
        try {
            localStorage.setItem(key, JSON.stringify(value));
        } catch (error) {
            console.error('Error al guardar en localStorage:', error);
        }
    },

    get: function(key) {
        try {
            const item = localStorage.getItem(key);
            return item ? JSON.parse(item) : null;
        } catch (error) {
            console.error('Error al leer de localStorage:', error);
            return null;
        }
    },

    remove: function(key) {
        try {
            localStorage.removeItem(key);
        } catch (error) {
            console.error('Error al eliminar de localStorage:', error);
        }
    },

    clear: function() {
        try {
            localStorage.clear();
        } catch (error) {
            console.error('Error al limpiar localStorage:', error);
        }
    }
};

// === INICIALIZACIÓN COMÚN ===
Tutorium.init = function() {
    // Inicializar navegación móvil común
    this.initMobileNavigation();
    
    // Inicializar tooltips
    this.initTooltips();
    
    // Inicializar smooth scrolling
    this.initSmoothScrolling();
    
    // Inicializar manejo de errores
    this.initErrorHandling();
    
    console.log('✅ Tutorium Common inicializado');
};

Tutorium.initMobileNavigation = function() {
    const mobileToggle = document.querySelector('.mobile-menu-toggle');
    const navMenu = document.querySelector('.nav-menu');
    
    if (mobileToggle && navMenu) {
        mobileToggle.addEventListener('click', () => {
            navMenu.classList.toggle('active');
            mobileToggle.classList.toggle('active');
        });
    }
};

Tutorium.initTooltips = function() {
    const tooltipElements = document.querySelectorAll('[data-tooltip]');
    
    tooltipElements.forEach(element => {
        element.addEventListener('mouseenter', (e) => {
            const tooltip = document.createElement('div');
            tooltip.className = 'tooltip';
            tooltip.textContent = e.target.dataset.tooltip;
            tooltip.style.cssText = `
                position: absolute;
                background: rgba(0, 0, 0, 0.8);
                color: white;
                padding: 8px 12px;
                border-radius: 4px;
                font-size: 12px;
                z-index: 10000;
                pointer-events: none;
                white-space: nowrap;
            `;
            
            document.body.appendChild(tooltip);
            
            const rect = e.target.getBoundingClientRect();
            tooltip.style.left = rect.left + (rect.width / 2) - (tooltip.offsetWidth / 2) + 'px';
            tooltip.style.top = rect.top - tooltip.offsetHeight - 8 + 'px';
        });
        
        element.addEventListener('mouseleave', () => {
            const tooltip = document.querySelector('.tooltip');
            if (tooltip) {
                tooltip.remove();
            }
        });
    });
};

Tutorium.initSmoothScrolling = function() {
    document.querySelectorAll('a[href^="#"]').forEach(anchor => {
        anchor.addEventListener('click', function (e) {
            e.preventDefault();
            const target = document.querySelector(this.getAttribute('href'));
            if (target) {
                target.scrollIntoView({
                    behavior: 'smooth',
                    block: 'start'
                });
            }
        });
    });
};

Tutorium.initErrorHandling = function() {
    window.addEventListener('error', (e) => {
        console.error('Error global capturado:', e.error);
        Tutorium.notifications.show('Ha ocurrido un error inesperado', 'error');
    });
};

// === AUTO-INICIALIZACIÓN ===
document.addEventListener('DOMContentLoaded', () => {
    Tutorium.init();
});

// === ESTILOS CSS DINÁMICOS ===
const dynamicStyles = `
    .notification {
        animation: slideInRight 0.3s ease-out;
    }
    
    @keyframes slideInRight {
        from {
            transform: translateX(100%);
            opacity: 0;
        }
        to {
            transform: translateX(0);
            opacity: 1;
        }
    }
    
    .loading-spinner {
        width: 20px;
        height: 20px;
        border: 2px solid rgba(255, 255, 255, 0.3);
        border-top: 2px solid #ff6b6b;
        border-radius: 50%;
        animation: spin 1s linear infinite;
        margin: 0 auto;
    }
    
    @keyframes spin {
        0% { transform: rotate(0deg); }
        100% { transform: rotate(360deg); }
    }
    
    .modal {
        display: none;
        position: fixed;
        top: 0;
        left: 0;
        width: 100%;
        height: 100%;
        background: rgba(0, 0, 0, 0.8);
        z-index: 10000;
        align-items: center;
        justify-content: center;
        opacity: 0;
        transition: opacity 0.3s ease;
    }
    
    .modal.active {
        opacity: 1;
    }
    
    .modal-content {
        background: rgba(255, 255, 255, 0.1);
        backdrop-filter: blur(20px);
        border-radius: 15px;
        max-width: 500px;
        width: 90%;
        max-height: 80vh;
        overflow-y: auto;
        border: 2px solid rgba(255, 107, 107, 0.3);
        transform: scale(0.9);
        transition: transform 0.3s ease;
    }
    
    .modal.active .modal-content {
        transform: scale(1);
    }
    
    .modal-header {
        padding: 20px;
        border-bottom: 1px solid rgba(255, 107, 107, 0.2);
        display: flex;
        justify-content: space-between;
        align-items: center;
    }
    
    .modal-header h3 {
        color: #fff;
        margin: 0;
    }
    
    .modal-close {
        background: none;
        border: none;
        color: #fff;
        font-size: 1.2em;
        cursor: pointer;
        padding: 5px;
    }
    
    .modal-body {
        padding: 20px;
        color: #fff;
    }
    
    .modal-footer {
        padding: 20px;
        border-top: 1px solid rgba(255, 107, 107, 0.2);
        display: flex;
        gap: 10px;
        justify-content: flex-end;
    }
    
    .error {
        border-color: #f44336 !important;
        box-shadow: 0 0 10px rgba(244, 67, 54, 0.3) !important;
    }
`;

// Insertar estilos dinámicos
const styleSheet = document.createElement('style');
styleSheet.textContent = dynamicStyles;
document.head.appendChild(styleSheet);

console.log('🔧 Tutorium Common Library cargada');
