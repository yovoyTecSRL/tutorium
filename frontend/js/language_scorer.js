// Sistema de Puntuación de Idiomas para Tutorium
// Frontend JavaScript para evaluación de pronunciación, gramática y sintaxis

class LanguageScorer {
    constructor() {
        this.currentLanguage = 'en';
        this.recognition = null;
        this.synthesis = null;
        this.scores = {
            grammar: 0,
            syntax: 0,
            vocabulary: 0,
            pronunciation: 0,
            overall: 0
        };
        this.initializeSpeechAPIs();
        this.initializeUI();
    }

    initializeSpeechAPIs() {
        // Web Speech API para reconocimiento de voz
        if ('webkitSpeechRecognition' in window) {
            this.recognition = new webkitSpeechRecognition();
            this.recognition.continuous = false;
            this.recognition.interimResults = false;
        }

        // Web Speech API para síntesis de voz
        if ('speechSynthesis' in window) {
            this.synthesis = window.speechSynthesis;
        }
    }

    initializeUI() {
        this.createScoreInterface();
        this.createLanguageSwitch();
        this.createPronunciationTester();
    }

    createScoreInterface() {
        const scoreContainer = document.createElement('div');
        scoreContainer.className = 'language-scorer-container';
        scoreContainer.innerHTML = `
            <div class="score-dashboard">
                <h3 data-translate="score-title">Language Learning Score</h3>
                
                <div class="overall-score">
                    <div class="score-circle">
                        <span class="score-number" id="overall-score">0</span>
                        <span class="score-label" data-translate="overall">Overall</span>
                    </div>
                </div>

                <div class="detailed-scores">
                    <div class="score-item">
                        <label data-translate="grammar">Grammar</label>
                        <div class="score-bar">
                            <div class="score-fill" id="grammar-fill"></div>
                            <span class="score-value" id="grammar-score">0</span>
                        </div>
                    </div>
                    
                    <div class="score-item">
                        <label data-translate="pronunciation">Pronunciation</label>
                        <div class="score-bar">
                            <div class="score-fill" id="pronunciation-fill"></div>
                            <span class="score-value" id="pronunciation-score">0</span>
                        </div>
                    </div>
                    
                    <div class="score-item">
                        <label data-translate="syntax">Syntax</label>
                        <div class="score-bar">
                            <div class="score-fill" id="syntax-fill"></div>
                            <span class="score-value" id="syntax-score">0</span>
                        </div>
                    </div>
                    
                    <div class="score-item">
                        <label data-translate="vocabulary">Vocabulary</label>
                        <div class="score-bar">
                            <div class="score-fill" id="vocabulary-fill"></div>
                            <span class="score-value" id="vocabulary-score">0</span>
                        </div>
                    </div>
                </div>

                <div class="corrections-section">
                    <h4 data-translate="corrections">Corrections & Suggestions</h4>
                    <div id="corrections-list" class="corrections-list"></div>
                </div>

                <div class="advice-section">
                    <h4 data-translate="advice">Improvement Advice</h4>
                    <div id="advice-list" class="advice-list"></div>
                </div>
            </div>
        `;

        document.body.appendChild(scoreContainer);
    }

    createLanguageSwitch() {
        const switchContainer = document.createElement('div');
        switchContainer.className = 'language-switch-container';
        switchContainer.innerHTML = `
            <div class="language-switch">
                <span class="switch-label" data-translate="language">Language:</span>
                <div class="toggle-switch">
                    <input type="checkbox" id="language-toggle" ${this.currentLanguage === 'es' ? 'checked' : ''}>
                    <label for="language-toggle" class="toggle-label">
                        <span class="toggle-flag flag-en">🇺🇸</span>
                        <span class="toggle-flag flag-es">🇪🇸</span>
                        <span class="toggle-slider"></span>
                    </label>
                </div>
                <span class="current-language">${this.currentLanguage === 'en' ? 'English' : 'Español'}</span>
            </div>
        `;

        // Insertar al inicio del score container
        const scoreContainer = document.querySelector('.language-scorer-container');
        scoreContainer.insertBefore(switchContainer, scoreContainer.firstChild);

        // Event listener para el switch
        document.getElementById('language-toggle').addEventListener('change', (e) => {
            this.switchLanguage(e.target.checked ? 'es' : 'en');
        });
    }

    createPronunciationTester() {
        const pronunciationContainer = document.createElement('div');
        pronunciationContainer.className = 'pronunciation-tester';
        pronunciationContainer.innerHTML = `
            <div class="pronunciation-section">
                <h4 data-translate="pronunciation-test">Pronunciation Test</h4>
                <div class="test-controls">
                    <textarea id="practice-text" placeholder="Type or paste text to practice pronunciation..." 
                              data-translate-placeholder="practice-placeholder"></textarea>
                    <div class="control-buttons">
                        <button id="listen-btn" class="btn-primary" data-translate="listen">Listen</button>
                        <button id="record-btn" class="btn-secondary" data-translate="record">Record</button>
                        <button id="analyze-btn" class="btn-success" data-translate="analyze">Analyze</button>
                    </div>
                </div>
                <div id="recording-status" class="recording-status"></div>
            </div>
        `;

        document.querySelector('.language-scorer-container').appendChild(pronunciationContainer);

        // Event listeners
        document.getElementById('listen-btn').addEventListener('click', () => this.speakText());
        document.getElementById('record-btn').addEventListener('click', () => this.startRecording());
        document.getElementById('analyze-btn').addEventListener('click', () => this.analyzeText());
    }

    switchLanguage(newLanguage) {
        this.currentLanguage = newLanguage;
        
        // Actualizar UI
        document.querySelector('.current-language').textContent = 
            newLanguage === 'en' ? 'English' : 'Español';
        
        // Actualizar configuración de reconocimiento de voz
        if (this.recognition) {
            this.recognition.lang = newLanguage === 'en' ? 'en-US' : 'es-ES';
        }

        // Actualizar traducciones
        this.updateTranslations();
        
        // Limpiar puntuaciones anteriores
        this.resetScores();
    }

    updateTranslations() {
        const translations = {
            'en': {
                'score-title': 'Language Learning Score',
                'overall': 'Overall',
                'grammar': 'Grammar',
                'pronunciation': 'Pronunciation',
                'syntax': 'Syntax',
                'vocabulary': 'Vocabulary',
                'corrections': 'Corrections & Suggestions',
                'advice': 'Improvement Advice',
                'language': 'Language:',
                'pronunciation-test': 'Pronunciation Test',
                'listen': 'Listen',
                'record': 'Record',
                'analyze': 'Analyze',
                'practice-placeholder': 'Type or paste text to practice pronunciation...'
            },
            'es': {
                'score-title': 'Puntuación de Aprendizaje de Idiomas',
                'overall': 'General',
                'grammar': 'Gramática',
                'pronunciation': 'Pronunciación',
                'syntax': 'Sintaxis',
                'vocabulary': 'Vocabulario',
                'corrections': 'Correcciones y Sugerencias',
                'advice': 'Consejos de Mejora',
                'language': 'Idioma:',
                'pronunciation-test': 'Prueba de Pronunciación',
                'listen': 'Escuchar',
                'record': 'Grabar',
                'analyze': 'Analizar',
                'practice-placeholder': 'Escribe o pega texto para practicar pronunciación...'
            }
        };

        const currentTranslations = translations[this.currentLanguage];
        
        document.querySelectorAll('[data-translate]').forEach(element => {
            const key = element.getAttribute('data-translate');
            if (currentTranslations[key]) {
                element.textContent = currentTranslations[key];
            }
        });

        document.querySelectorAll('[data-translate-placeholder]').forEach(element => {
            const key = element.getAttribute('data-translate-placeholder');
            if (currentTranslations[key]) {
                element.placeholder = currentTranslations[key];
            }
        });
    }

    async analyzeText() {
        const text = document.getElementById('practice-text').value;
        if (!text.trim()) {
            alert(this.currentLanguage === 'en' ? 'Please enter some text first.' : 'Por favor ingresa texto primero.');
            return;
        }

        try {
            // Llamada al backend para análisis
            const response = await fetch('/api/analyze-language', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({
                    text: text,
                    language: this.currentLanguage
                })
            });

            const analysis = await response.json();
            this.updateScores(analysis);
            this.displayCorrections(analysis.corrections || []);
            this.displayAdvice(analysis.advice || []);
            
        } catch (error) {
            console.error('Error analyzing text:', error);
            // Fallback: análisis básico en frontend
            this.performBasicAnalysis(text);
        }
    }

    performBasicAnalysis(text) {
        // Análisis básico si el backend no está disponible
        const words = text.split(/\s+/).filter(word => word.length > 0);
        const sentences = text.split(/[.!?]+/).filter(s => s.trim().length > 0);
        
        const scores = {
            grammar: Math.min(100, 70 + Math.random() * 20), // Simulado
            syntax: Math.min(100, sentences.length * 15),
            vocabulary: Math.min(100, (new Set(words.map(w => w.toLowerCase())).size / words.length) * 100),
            pronunciation: 85 // Placeholder hasta implementar análisis de audio
        };

        scores.overall = Object.values(scores).reduce((a, b) => a + b, 0) / 4;

        this.updateScores({ scores });
    }

    updateScores(analysis) {
        const scores = analysis.scores || {};
        
        // Actualizar puntuación general
        const overallScore = Math.round(scores.overall || 0);
        document.getElementById('overall-score').textContent = overallScore;

        // Actualizar puntuaciones detalladas
        ['grammar', 'pronunciation', 'syntax', 'vocabulary'].forEach(skill => {
            const score = Math.round(scores[skill] || 0);
            const scoreElement = document.getElementById(`${skill}-score`);
            const fillElement = document.getElementById(`${skill}-fill`);
            
            if (scoreElement) scoreElement.textContent = score;
            if (fillElement) {
                fillElement.style.width = `${score}%`;
                fillElement.className = `score-fill ${this.getScoreClass(score)}`;
            }
        });

        this.scores = scores;
    }

    getScoreClass(score) {
        if (score >= 80) return 'excellent';
        if (score >= 60) return 'good';
        if (score >= 40) return 'fair';
        return 'needs-improvement';
    }

    displayCorrections(corrections) {
        const correctionsList = document.getElementById('corrections-list');
        correctionsList.innerHTML = '';

        if (corrections.length === 0) {
            correctionsList.innerHTML = `<p class="no-corrections">${
                this.currentLanguage === 'en' ? 'No corrections needed! Great job!' : '¡No hay correcciones necesarias! ¡Excelente trabajo!'
            }</p>`;
            return;
        }

        corrections.forEach(correction => {
            const correctionItem = document.createElement('div');
            correctionItem.className = 'correction-item';
            correctionItem.innerHTML = `
                <span class="error-text">"${correction.error}"</span>
                <span class="arrow">→</span>
                <span class="correction-text">"${correction.correction}"</span>
                <span class="correction-type">[${correction.type}]</span>
            `;
            correctionsList.appendChild(correctionItem);
        });
    }

    displayAdvice(advice) {
        const adviceList = document.getElementById('advice-list');
        adviceList.innerHTML = '';

        if (advice.length === 0) {
            adviceList.innerHTML = `<p class="no-advice">${
                this.currentLanguage === 'en' ? 'Keep up the great work!' : '¡Sigue con el excelente trabajo!'
            }</p>`;
            return;
        }

        advice.forEach(tip => {
            const adviceItem = document.createElement('div');
            adviceItem.className = 'advice-item';
            adviceItem.innerHTML = `<span class="advice-icon">💡</span><span class="advice-text">${tip}</span>`;
            adviceList.appendChild(adviceItem);
        });
    }

    speakText() {
        const text = document.getElementById('practice-text').value;
        if (!text.trim()) return;

        if (this.synthesis) {
            const utterance = new SpeechSynthesisUtterance(text);
            utterance.lang = this.currentLanguage === 'en' ? 'en-US' : 'es-ES';
            utterance.rate = 0.8; // Hablar un poco más lento para aprendizaje
            this.synthesis.speak(utterance);
        }
    }

    startRecording() {
        if (!this.recognition) {
            alert(this.currentLanguage === 'en' ? 'Speech recognition not supported.' : 'Reconocimiento de voz no soportado.');
            return;
        }

        const statusDiv = document.getElementById('recording-status');
        const recordBtn = document.getElementById('record-btn');

        this.recognition.lang = this.currentLanguage === 'en' ? 'en-US' : 'es-ES';
        
        this.recognition.onstart = () => {
            statusDiv.textContent = this.currentLanguage === 'en' ? 'Listening...' : 'Escuchando...';
            recordBtn.textContent = this.currentLanguage === 'en' ? 'Stop' : 'Parar';
            recordBtn.classList.add('recording');
        };

        this.recognition.onresult = (event) => {
            const transcript = event.results[0][0].transcript;
            document.getElementById('practice-text').value = transcript;
            statusDiv.textContent = this.currentLanguage === 'en' ? 'Recording complete!' : '¡Grabación completa!';
        };

        this.recognition.onerror = () => {
            statusDiv.textContent = this.currentLanguage === 'en' ? 'Error occurred.' : 'Ocurrió un error.';
        };

        this.recognition.onend = () => {
            recordBtn.textContent = this.currentLanguage === 'en' ? 'Record' : 'Grabar';
            recordBtn.classList.remove('recording');
            setTimeout(() => statusDiv.textContent = '', 3000);
        };

        if (recordBtn.classList.contains('recording')) {
            this.recognition.stop();
        } else {
            this.recognition.start();
        }
    }

    resetScores() {
        this.scores = { grammar: 0, syntax: 0, vocabulary: 0, pronunciation: 0, overall: 0 };
        this.updateScores({ scores: this.scores });
        document.getElementById('corrections-list').innerHTML = '';
        document.getElementById('advice-list').innerHTML = '';
    }
}

// CSS para el sistema de puntuación
const scoreCSS = `
.language-scorer-container {
    max-width: 800px;
    margin: 20px auto;
    padding: 20px;
    background: #f8f9fa;
    border-radius: 10px;
    box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
}

.language-switch-container {
    text-align: center;
    margin-bottom: 20px;
    padding: 15px;
    background: white;
    border-radius: 8px;
}

.language-switch {
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 15px;
}

.toggle-switch {
    position: relative;
    display: inline-block;
}

.toggle-switch input {
    opacity: 0;
    width: 0;
    height: 0;
}

.toggle-label {
    display: block;
    width: 80px;
    height: 40px;
    background: #ddd;
    border-radius: 20px;
    position: relative;
    cursor: pointer;
    transition: background 0.3s;
}

.toggle-flag {
    position: absolute;
    top: 50%;
    transform: translateY(-50%);
    font-size: 18px;
}

.flag-en { left: 8px; }
.flag-es { right: 8px; }

.toggle-slider {
    position: absolute;
    top: 2px;
    left: 2px;
    width: 36px;
    height: 36px;
    background: white;
    border-radius: 50%;
    transition: transform 0.3s;
    box-shadow: 0 2px 4px rgba(0,0,0,0.2);
}

input:checked + .toggle-label .toggle-slider {
    transform: translateX(40px);
}

input:checked + .toggle-label {
    background: #4CAF50;
}

.overall-score {
    text-align: center;
    margin: 20px 0;
}

.score-circle {
    display: inline-block;
    width: 120px;
    height: 120px;
    border: 8px solid #e0e0e0;
    border-radius: 50%;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    background: white;
    position: relative;
}

.score-number {
    font-size: 2.5em;
    font-weight: bold;
    color: #333;
}

.score-label {
    font-size: 0.9em;
    color: #666;
    text-transform: uppercase;
}

.detailed-scores {
    display: grid;
    gap: 15px;
    margin: 20px 0;
}

.score-item {
    background: white;
    padding: 15px;
    border-radius: 8px;
    display: flex;
    align-items: center;
    justify-content: space-between;
}

.score-item label {
    font-weight: 500;
    min-width: 100px;
}

.score-bar {
    flex: 1;
    height: 20px;
    background: #e0e0e0;
    border-radius: 10px;
    margin: 0 15px;
    position: relative;
    overflow: hidden;
}

.score-fill {
    height: 100%;
    border-radius: 10px;
    transition: width 0.5s ease;
}

.score-fill.excellent { background: #4CAF50; }
.score-fill.good { background: #2196F3; }
.score-fill.fair { background: #FF9800; }
.score-fill.needs-improvement { background: #F44336; }

.score-value {
    font-weight: bold;
    min-width: 30px;
}

.corrections-section, .advice-section {
    margin: 20px 0;
    padding: 15px;
    background: white;
    border-radius: 8px;
}

.corrections-list, .advice-list {
    margin-top: 10px;
}

.correction-item, .advice-item {
    padding: 10px;
    margin: 5px 0;
    background: #f5f5f5;
    border-radius: 5px;
    display: flex;
    align-items: center;
    gap: 10px;
}

.error-text {
    color: #F44336;
    font-weight: bold;
}

.correction-text {
    color: #4CAF50;
    font-weight: bold;
}

.correction-type {
    background: #2196F3;
    color: white;
    padding: 2px 8px;
    border-radius: 12px;
    font-size: 0.8em;
}

.pronunciation-tester {
    margin: 20px 0;
    padding: 15px;
    background: white;
    border-radius: 8px;
}

.test-controls textarea {
    width: 100%;
    min-height: 80px;
    padding: 10px;
    border: 1px solid #ddd;
    border-radius: 5px;
    margin-bottom: 10px;
    resize: vertical;
}

.control-buttons {
    display: flex;
    gap: 10px;
    flex-wrap: wrap;
}

.control-buttons button {
    padding: 10px 20px;
    border: none;
    border-radius: 5px;
    cursor: pointer;
    font-weight: 500;
    transition: background 0.3s;
}

.btn-primary { background: #2196F3; color: white; }
.btn-secondary { background: #6c757d; color: white; }
.btn-success { background: #28a745; color: white; }

.btn-primary:hover { background: #1976D2; }
.btn-secondary:hover { background: #545b62; }
.btn-success:hover { background: #218838; }

.recording-status {
    margin-top: 10px;
    padding: 5px;
    text-align: center;
    font-style: italic;
    color: #666;
}

.recording {
    background: #dc3545 !important;
    animation: pulse 1s infinite;
}

@keyframes pulse {
    0% { opacity: 1; }
    50% { opacity: 0.7; }
    100% { opacity: 1; }
}

.no-corrections, .no-advice {
    text-align: center;
    color: #28a745;
    font-style: italic;
    padding: 20px;
}
`;

// Inyectar CSS y inicializar el sistema
function initializeLanguageScorer() {
    // Agregar CSS
    const style = document.createElement('style');
    style.textContent = scoreCSS;
    document.head.appendChild(style);

    // Inicializar el sistema
    window.languageScorer = new LanguageScorer();
}

// Auto-inicializar cuando el DOM esté listo
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initializeLanguageScorer);
} else {
    initializeLanguageScorer();
}
