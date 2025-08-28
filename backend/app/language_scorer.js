// language_scorer.js - Sistema de scoring integrado con FastAPI
class LanguageScorer {
    constructor() {
        this.API_BASE = window.API_BASE || 'http://127.0.0.1:8000';
        this.isProcessing = false;
        this.sessionHistory = [];
        this.duplicateBuffer = new Set();
        
        console.log('🎯 LanguageScorer initialized with API:', this.API_BASE);
    }

    // Analizar texto con el backend FastAPI
    async analyzeText(text, options = {}) {
        if (this.isProcessing) {
            console.log('⏳ Analysis already in progress, skipping...');
            return null;
        }

        if (!text || text.trim().length < 3) {
            console.log('❌ Text too short for analysis');
            return null;
        }

        // Anti-duplicate check
        const textHash = this.hashText(text);
        if (this.duplicateBuffer.has(textHash)) {
            console.log('🔄 Duplicate text detected, skipping analysis');
            return null;
        }

        try {
            this.isProcessing = true;
            this.duplicateBuffer.add(textHash);

            const response = await fetch(`${this.API_BASE}/analyze-language`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    text: text.trim(),
                    lang: options.lang || 'en',
                    metadata: {
                        timestamp: new Date().toISOString(),
                        source: 'web_interface',
                        ...options.metadata
                    }
                })
            });

            if (!response.ok) {
                throw new Error(`HTTP ${response.status}: ${response.statusText}`);
            }

            const result = await response.json();
            
            // Guardar en historial de sesión
            this.sessionHistory.push({
                text,
                result,
                timestamp: new Date().toISOString()
            });

            console.log('✅ Analysis completed:', result);
            return result;

        } catch (error) {
            console.error('❌ Error analyzing text:', error);
            return {
                scores: { pronunciation: 0, grammar: 0, syntax: 0, vocabulary: 0, overall: 0 },
                corrections: [`Error: ${error.message}`],
                advice: ['Please check your connection and try again.']
            };
        } finally {
            this.isProcessing = false;
            
            // Limpiar buffer después de 30 segundos
            setTimeout(() => {
                this.duplicateBuffer.delete(textHash);
            }, 30000);
        }
    }

    // Analizar entrada de voz específicamente
    async analyzeSpeech(text, speechMetadata = {}) {
        const metadata = {
            confidence: speechMetadata.confidence || 0.85,
            duration: speechMetadata.duration || 1.0,
            is_final: speechMetadata.isFinal || false,
            ...speechMetadata
        };

        try {
            const response = await fetch(`${this.API_BASE}/analyze-speech`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    text: text.trim(),
                    lang: 'en',
                    metadata
                })
            });

            if (!response.ok) {
                throw new Error(`HTTP ${response.status}`);
            }

            return await response.json();
        } catch (error) {
            console.error('❌ Error analyzing speech:', error);
            return await this.analyzeText(text, { metadata });
        }
    }

    // Renderizar scores en el widget
    renderScores(container, data) {
        if (!container || !data || !data.scores) {
            console.error('❌ Invalid data for rendering scores');
            return;
        }

        const { pronunciation, grammar, syntax, vocabulary, overall } = data.scores;

        try {
            // Score general
            const overallEl = container.querySelector('[data-score-overall]');
            if (overallEl) overallEl.textContent = overall;

            // Barras de progreso
            this.updateProgressBar(container, '[data-score-pron]', pronunciation);
            this.updateProgressBar(container, '[data-score-gram]', grammar);
            this.updateProgressBar(container, '[data-score-syn]', syntax);
            this.updateProgressBar(container, '[data-score-voc]', vocabulary);

            // Correcciones y consejos
            const correctionsEl = container.querySelector('[data-corrections]');
            if (correctionsEl && data.corrections) {
                correctionsEl.textContent = data.corrections[0] || 'Great job!';
            }

            const adviceEl = container.querySelector('[data-advice]');
            if (adviceEl && data.advice) {
                adviceEl.textContent = data.advice[0] || 'Keep practicing!';
            }

            // Actualizar badge de conexión
            this.updateConnectionBadge(container, true);

            console.log('✅ Scores rendered successfully');

        } catch (error) {
            console.error('❌ Error rendering scores:', error);
            this.updateConnectionBadge(container, false);
        }
    }

    // Actualizar barra de progreso individual
    updateProgressBar(container, selector, value) {
        const progressBar = container.querySelector(selector);
        if (progressBar) {
            progressBar.style.width = `${Math.max(0, Math.min(100, value))}%`;
            
            // Color dinámico basado en el score
            if (value >= 80) {
                progressBar.style.backgroundColor = '#22c55e'; // Verde
            } else if (value >= 60) {
                progressBar.style.backgroundColor = '#f59e0b'; // Amarillo
            } else {
                progressBar.style.backgroundColor = '#ef4444'; // Rojo
            }
        }
    }

    // Actualizar badge de estado de conexión
    updateConnectionBadge(container, isConnected) {
        const badge = container.querySelector('.badge-connection');
        if (badge) {
            badge.textContent = isConnected ? '🟢 Conectado' : '🔴 Desconectado';
            badge.className = `badge badge-connection ${isConnected ? 'bg-green-500' : 'bg-red-500'}`;
        }
    }

    // Obtener promedio de la sesión
    getSessionAverage() {
        if (this.sessionHistory.length === 0) return 0;
        
        const totalOverall = this.sessionHistory.reduce((sum, item) => {
            return sum + (item.result.scores?.overall || 0);
        }, 0);
        
        return Math.round(totalOverall / this.sessionHistory.length);
    }

    // Hash simple para detectar duplicados
    hashText(text) {
        let hash = 0;
        for (let i = 0; i < text.length; i++) {
            const char = text.charCodeAt(i);
            hash = ((hash << 5) - hash) + char;
            hash = hash & hash; // Convert to 32-bit integer
        }
        return hash.toString();
    }

    // Verificar estado de la API
    async checkAPIHealth() {
        try {
            const response = await fetch(`${this.API_BASE}/healthz`);
            return response.ok;
        } catch (error) {
            console.warn('⚠️ API health check failed:', error);
            return false;
        }
    }

    // Obtener historial de la sesión para la tabla
    getSessionHistory() {
        return this.sessionHistory.map((item, index) => ({
            attempt: index + 1,
            text: item.text.substring(0, 30) + (item.text.length > 30 ? '...' : ''),
            overall: item.result.scores?.overall || 0,
            timestamp: new Date(item.timestamp).toLocaleTimeString()
        }));
    }

    // Limpiar historial
    clearSession() {
        this.sessionHistory = [];
        this.duplicateBuffer.clear();
        console.log('🧹 Session cleared');
    }
}

// Función helper para analizar texto rápidamente
async function analyzeText(text, options = {}) {
    const scorer = new LanguageScorer();
    return await scorer.analyzeText(text, options);
}

// Función helper para renderizar scores
function renderScores(container, data) {
    const scorer = new LanguageScorer();
    return scorer.renderScores(container, data);
}

// Exportar para uso en módulos
if (typeof module !== 'undefined' && module.exports) {
    module.exports = { LanguageScorer, analyzeText, renderScores };
}

// Hacer disponible globalmente
window.LanguageScorer = LanguageScorer;
window.analyzeText = analyzeText;
window.renderScores = renderScores;
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify({text, lang, metadata: {duration_ms: durationMs, asr_confidence: asrConfidence}})
      });
      if (!res.ok) throw new Error('API error');
      const data = await res.json();
      if (this._isDuplicateFeedback(data.advice)) return;
      this.lastTranscript = text;
      this._bufferFeedback(data.advice);
      this._renderScores(data, text);
      this._persistAttempt(text, data);
    } catch (e) {
      this._setStatus(false);
      this._renderError('No se pudo analizar. Intenta de nuevo.');
    } finally {
      this.evaluating = false;
    }
  }

  _isDuplicateFeedback(advice) {
    if (!advice || !advice.length) return false;
    return this.lastFeedbacks.includes(advice[0]);
  }

  _bufferFeedback(advice) {
    if (!advice || !advice.length) return;
    this.lastFeedbacks.push(advice[0]);
    if (this.lastFeedbacks.length > this.maxFeedbackBuffer) this.lastFeedbacks.shift();
  }

  _persistAttempt(text, data) {
    const now = new Date();
    this.sessionAttempts.push({
      phrase: text,
      overall: data.scores?.overall || 0,
      date: now.toLocaleTimeString()
    });
    this._renderAttempts();
    this._renderSessionAvg();
  }

  _renderScores(data, text) {
    document.getElementById('scorePron').textContent = data.scores?.pronunciation ?? '-';
    document.getElementById('scoreGram').textContent = data.scores?.grammar ?? '-';
    document.getElementById('scoreSint').textContent = data.scores?.syntax ?? '-';
    document.getElementById('scoreVocab').textContent = data.scores?.vocabulary ?? '-';
    document.getElementById('scoreOverall').textContent = data.scores?.overall ?? '-';
    // Correcciones
    const corrEl = document.getElementById('scoreCorrections');
    corrEl.innerHTML = '';
    (data.corrections || []).forEach(c => {
      const li = document.createElement('li');
      li.textContent = c;
      corrEl.appendChild(li);
    });
    // Consejo
    document.getElementById('scoreAdvice').textContent = (data.advice && data.advice[0]) || '';
  }

  _renderAttempts() {
    if (!this.attemptsEl) return;
    this.attemptsEl.innerHTML = '';
    this.sessionAttempts.slice(-10).reverse().forEach((a, i) => {
      const tr = document.createElement('tr');
      tr.innerHTML = `<td>${this.sessionAttempts.length - i}</td><td>${a.phrase}</td><td>${a.overall}</td><td>${a.date}</td>`;
      this.attemptsEl.appendChild(tr);
    });
  }

  _renderSessionAvg() {
    if (!this.avgEl) return;
    if (!this.sessionAttempts.length) {
      this.avgEl.textContent = '-';
      return;
    }
    const avg = this.sessionAttempts.reduce((a, b) => a + (b.overall || 0), 0) / this.sessionAttempts.length;
    this.avgEl.textContent = avg.toFixed(1);
  }

  _renderError(msg) {
    document.getElementById('scoreAdvice').textContent = msg;
  }

  resetScores() {
    document.getElementById('scorePron').textContent = '-';
    document.getElementById('scoreGram').textContent = '-';
    document.getElementById('scoreSint').textContent = '-';
    document.getElementById('scoreVocab').textContent = '-';
    document.getElementById('scoreOverall').textContent = '-';
    document.getElementById('scoreCorrections').innerHTML = '';
    document.getElementById('scoreAdvice').textContent = '';
    this.sessionAttempts = [];
    this._renderAttempts();
    this._renderSessionAvg();
  }
}

// Export para uso global
window.LanguageScorer = LanguageScorer;
