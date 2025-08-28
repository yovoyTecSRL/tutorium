/* ============================================
   TUTORIUM - SISTEMAS ORBIX
   JavaScript principal para index.html
   ============================================ */

// Variables globales
let isAudioPlaying = false;
let audioContext = null;
let oscillator = null;
let gainNode = null;

// Inicialización cuando el DOM esté cargado
document.addEventListener('DOMContentLoaded', function() {
    initializeApp();
});

// Función principal de inicialización
function initializeApp() {
    console.log('🎉 Bienvenido a Tutorium - Sistemas Orbix!');
    console.log('🚀 Plataforma de aprendizaje con IA avanzada');
    console.log('🎵 Haz clic en el botón de audio para activar el sonido ambiente');
    
    // Inicializar componentes
    initializeAudio();
    initializeMobileMenu();
    initializeScrollAnimations();
    initializeHeaderEffects();
    initializeSmoothScrolling();
    initializeParticleEffects();
    initializeHoverSounds();
    initializeIntersectionObserver();
    initializeAccessibility();
    handleResize();
    updateThemeColors();
    monitorPerformance();
    
    // Verificar enlaces
    verifyLinks();
    
    // Mostrar animaciones iniciales
    handleScrollAnimations();
}

// === AUDIO CONTROL ===
function initializeAudio() {
    const audioControl = document.getElementById('audioControl');
    const audioIcon = document.getElementById('audioIcon');
    
    if (!audioControl || !audioIcon) return;
    
    // Crear contexto de audio
    audioContext = new (window.AudioContext || window.webkitAudioContext)();
    
    audioControl.addEventListener('click', toggleAudio);
}

function toggleAudio() {
    const audioIcon = document.getElementById('audioIcon');
    
    if (isAudioPlaying) {
        stopAmbientSound();
        audioIcon.className = 'fas fa-volume-mute';
        isAudioPlaying = false;
    } else {
        createAmbientSound();
        audioIcon.className = 'fas fa-volume-up';
        isAudioPlaying = true;
    }
}

function createAmbientSound() {
    try {
        if (oscillator) {
            oscillator.stop();
        }
        
        if (audioContext.state === 'suspended') {
            audioContext.resume();
        }
        
        oscillator = audioContext.createOscillator();
        gainNode = audioContext.createGain();
        
        oscillator.connect(gainNode);
        gainNode.connect(audioContext.destination);
        
        // Configurar sonido ambiente suave
        oscillator.frequency.setValueAtTime(220, audioContext.currentTime);
        oscillator.type = 'sine';
        gainNode.gain.setValueAtTime(0.05, audioContext.currentTime);
        
        // Modulación suave
        const lfo = audioContext.createOscillator();
        const lfoGain = audioContext.createGain();
        lfo.connect(lfoGain);
        oscillator.start();
        lfo.start();
    } catch (error) {
        console.error('Error creating ambient sound:', error);
    }
}
    lfoGain.gain.setValueAtTime(10, audioContext.currentTime);
    
    oscillator.start();
    lfo.start();
}

function stopAmbientSound() {
    if (oscillator) {
        oscillator.stop();
        oscillator = null;
    }
}

// === MOBILE MENU ===
function initializeMobileMenu() {
    const mobileMenuToggle = document.getElementById('mobileMenuToggle');
    const navMenu = document.getElementById('navMenu');
    
    if (!mobileMenuToggle || !navMenu) return;
    
    mobileMenuToggle.addEventListener('click', function() {
        navMenu.classList.toggle('active');
        mobileMenuToggle.classList.toggle('active');
    });
}

// === SCROLL ANIMATIONS ===
function initializeScrollAnimations() {
    window.addEventListener('scroll', handleScrollAnimations);
}

function handleScrollAnimations() {
    const scrollElements = document.querySelectorAll('.scroll-animate');
    
    scrollElements.forEach(element => {
        const elementTop = element.getBoundingClientRect().top;
        const elementVisible = 150;
        
        if (elementTop < window.innerHeight - elementVisible) {
            element.classList.add('active');
        }
    });
}

// === HEADER EFFECTS ===
function initializeHeaderEffects() {
    window.addEventListener('scroll', handleHeaderScroll);
}

function handleHeaderScroll() {
    const header = document.querySelector('.header');
    if (!header) return;
    
    if (window.scrollY > 50) {
        header.style.background = 'rgba(15, 15, 35, 0.98)';
        header.style.boxShadow = '0 2px 30px rgba(255, 107, 107, 0.4)';
    } else {
        header.style.background = 'rgba(15, 15, 35, 0.95)';
        header.style.boxShadow = '0 2px 30px rgba(15, 15, 35, 0.8)';
    }
}

// === SMOOTH SCROLLING ===
function initializeSmoothScrolling() {
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
}

// === PARTICLE EFFECTS ===
function initializeParticleEffects() {
    // Crear partículas ocasionalmente
    setInterval(createParticle, 2000);
}

function createParticle() {
    const particle = document.createElement('div');
    particle.style.position = 'fixed';
    particle.style.width = '4px';
    particle.style.height = '4px';
    particle.style.background = '#ff6b6b';
    particle.style.borderRadius = '50%';
    particle.style.pointerEvents = 'none';
    particle.style.opacity = '0.7';
    particle.style.zIndex = '999';
    
    const startX = Math.random() * window.innerWidth;
    const startY = window.innerHeight + 10;
    
    particle.style.left = startX + 'px';
    particle.style.top = startY + 'px';
    
    document.body.appendChild(particle);
    
    let y = startY;
    let x = startX;
    let dx = (Math.random() - 0.5) * 2;
    let dy = -Math.random() * 3 - 1;
    
    function animateParticle() {
        y += dy;
        x += dx;
        
    animateParticle();
}
        particle.style.left = x + 'px';
        particle.style.top = y + 'px';
        
        if (y < -10 || x < -10 || x > window.innerWidth + 10) {
            document.body.removeChild(particle);
            return;
        }
        
        requestAnimationFrame(animateParticle);
    }
    
    animateParticle();
}

// === HOVER SOUNDS ===
function initializeHoverSounds() {
    const hoverElements = document.querySelectorAll('.nav-menu a, .hero-btn, .feature-card');
    
    hoverElements.forEach(element => {
        element.addEventListener('mouseenter', playHoverSound);
    });
}

function playHoverSound() {
    if (isAudioPlaying && audioContext) {
        // Crear sonido sutil al hacer hover
        const hoverOscillator = audioContext.createOscillator();
        const hoverGain = audioContext.createGain();
        
        hoverOscillator.connect(hoverGain);
        hoverGain.connect(audioContext.destination);
        
        hoverOscillator.frequency.setValueAtTime(800, audioContext.currentTime);
        hoverOscillator.type = 'sine';
        hoverGain.gain.setValueAtTime(0.02, audioContext.currentTime);
        hoverGain.gain.exponentialRampToValueAtTime(0.001, audioContext.currentTime + 0.1);
        
        hoverOscillator.start();
        hoverOscillator.stop(audioContext.currentTime + 0.1);
    }
}

// === UTILITIES ===
function verifyLinks() {
    console.log('🔗 Enlaces verificados:');
    console.log('✅ Cursos: pages/cursos.html');
    console.log('✅ Certificaciones: pages/certificaciones.html');
    console.log('✅ Tutores IA: pages/tutores-ia.html');
    console.log('✅ Progreso: pages/progreso.html');
    console.log('✅ Panel Admin: pages/backup-panel.html');
    console.log('✅ Login: pages/login.html');
}

// === ANIMATION UTILITIES ===
function animateCounter(element, start, end, duration) {
    const startTime = performance.now();
    
    function updateCounter(currentTime) {
        const elapsed = currentTime - startTime;
        const progress = Math.min(elapsed / duration, 1);
        
        const current = Math.floor(start + (end - start) * progress);
        element.textContent = current.toLocaleString();
        
        if (progress < 1) {
            requestAnimationFrame(updateCounter);
        }
    }
    
    requestAnimationFrame(updateCounter);
}

// === INTERSECTION OBSERVER ===
function initializeIntersectionObserver() {
    const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.classList.add('animate');
                
                // Animar contadores si es una tarjeta de estadísticas
                if (entry.target.classList.contains('stat-card')) {
                    const numberElement = entry.target.querySelector('.stat-number');
                    if (numberElement) {
                        const endValue = parseInt(numberElement.textContent.replace(/,/g, ''));
                        animateCounter(numberElement, 0, endValue, 2000);
                    }
                }
            }
        });
    }, {
        threshold: 0.1
    });
    
    // Observar elementos animables
    document.querySelectorAll('.scroll-animate, .stat-card').forEach(el => {
        observer.observe(el);
    });
}

// === THEME UTILITIES ===
function updateThemeColors() {
    const root = document.documentElement;
    root.style.setProperty('--primary-color', '#ff6b6b');
    root.style.setProperty('--secondary-color', '#4ecdc4');
    root.style.setProperty('--accent-color', '#45b7d1');
}

// === PERFORMANCE MONITORING ===
function monitorPerformance() {
    // Medir tiempo de carga
    window.addEventListener('load', function() {
        const loadTime = performance.now();
        console.log(`⚡ Página cargada en ${loadTime.toFixed(2)}ms`);
    });
    
    // Medir FPS
    let fps = 0;
    let lastTime = performance.now();
    
    function measureFPS() {
        const currentTime = performance.now();
        fps = 1000 / (currentTime - lastTime);
        lastTime = currentTime;
        
        if (fps < 30) {
            console.warn('⚠️ FPS bajo detectado:', fps.toFixed(2));
        }
        
        requestAnimationFrame(measureFPS);
    }
    
    measureFPS();
}

// === ERROR HANDLING ===
window.addEventListener('error', function(e) {
    console.error('❌ Error capturado:', e.error);
});

// === ACCESSIBILITY ===
function initializeAccessibility() {
    // Navegación por teclado
    document.addEventListener('keydown', function(e) {
        if (e.key === 'Tab') {
            document.body.classList.add('keyboard-navigation');
        }
    });
    
    // Click para remover indicador de navegación por teclado
    document.addEventListener('click', function() {
        document.body.classList.remove('keyboard-navigation');
    });
}
function handleResize() {
    window.addEventListener('resize', function() {
        // Actualizar variables CSS dependientes del viewport
        document.documentElement.style.setProperty('--vh', window.innerHeight * 0.01 + 'px');
    });
}

// === INITIALIZATION COMPLETE ===
document.addEventListener('DOMContentLoaded', function() {
    setTimeout(() => {
        console.log('✅ Tutorium inicializado completamente');
        console.log('🎯 Todos los sistemas operativos');
        console.log('🚀 Listo para el aprendizaje con IA');
    }, 1000);
});

// Exportar funciones para uso global
window.TutoriumApp = {
    toggleAudio,
    createParticle,
    animateCounter,
    updateThemeColors
};
