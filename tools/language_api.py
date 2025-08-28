#!/usr/bin/env python3
"""
API Backend para el Sistema de Puntuación de Idiomas - Tutorium
Endpoint para análisis de texto y puntuación de habilidades lingüísticas.
"""

from flask import Flask, request, jsonify
from flask_cors import CORS
import sys
import os

# Agregar el directorio tools al path para importar el sistema de puntuación
sys.path.append(os.path.join(os.path.dirname(__file__), '..', 'tools'))

try:
    from language_scoring_system import LanguageScoringSystem
except ImportError:
    print("Error: No se pudo importar el sistema de puntuación")
    print("Asegúrate de que language_scoring_system.py esté en la carpeta tools/")
    sys.exit(1)

app = Flask(__name__)
CORS(app)  # Permitir requests desde el frontend

# Instancia global del sistema de puntuación
scorer = LanguageScoringSystem()

@app.route('/api/analyze-language', methods=['POST'])
def analyze_language():
    """
    Endpoint para analizar texto y retornar puntuaciones y correcciones.
    
    Request body:
    {
        "text": "The text to analyze",
        "language": "en" | "es"
    }
    
    Response:
    {
        "scores": {
            "grammar": 85,
            "syntax": 75,
            "vocabulary": 90,
            "pronunciation": 80,
            "overall": 82
        },
        "corrections": [
            {
                "type": "grammar",
                "error": "he are",
                "correction": "he is",
                "position": [0, 6]
            }
        ],
        "suggestions": [...],
        "advice": [
            "Focus on subject-verb agreement",
            "Practice with more complex sentences"
        ]
    }
    """
    try:
        # Validar request
        data = request.get_json()
        if not data:
            return jsonify({'error': 'No JSON data provided'}), 400
        
        text = data.get('text', '').strip()
        language = data.get('language', 'en')
        
        if not text:
            return jsonify({'error': 'Text is required'}), 400
        
        if language not in ['en', 'es']:
            return jsonify({'error': 'Language must be "en" or "es"'}), 400
        
        # Analizar el texto
        analysis = scorer.analyze_text(text, language)
        
        # Generar consejos de mejora
        advice = scorer.get_improvement_advice(analysis)
        analysis['advice'] = advice
        
        # Limpiar datos sensibles del timestamp
        if 'timestamp' in analysis:
            del analysis['timestamp']
        
        return jsonify(analysis), 200
        
    except Exception as e:
        app.logger.error(f"Error analyzing language: {str(e)}")
        return jsonify({'error': 'Internal server error'}), 500


@app.route('/api/student-progress/<student_id>', methods=['GET'])
def get_student_progress(student_id):
    """
    Endpoint para obtener el progreso histórico de un estudiante.
    
    Response:
    {
        "student_id": "123",
        "total_sessions": 25,
        "average_scores": {
            "grammar": 78.5,
            "syntax": 82.1,
            "vocabulary": 85.0,
            "pronunciation": 75.3
        },
        "trends": {
            "grammar": +5.2,
            "syntax": +1.8,
            "vocabulary": -2.1,
            "pronunciation": +8.7
        },
        "current_level": "Intermediate (B1)",
        "recent_sessions": [...]
    }
    """
    try:
        # Aquí normalmente consultarías la base de datos
        # Por ahora, datos de ejemplo
        
        # TODO: Implementar persistencia de datos
        # analyses = get_student_analyses_from_db(student_id)
        
        # Datos de ejemplo para demostración
        example_analyses = []
        
        if not example_analyses:
            return jsonify({
                'student_id': student_id,
                'message': 'No data found for this student',
                'total_sessions': 0
            }), 404
        
        # Generar reporte de progreso
        progress_report = scorer.export_progress_report(example_analyses)
        progress_report['student_id'] = student_id
        
        return jsonify(progress_report), 200
        
    except Exception as e:
        app.logger.error(f"Error getting student progress: {str(e)}")
        return jsonify({'error': 'Internal server error'}), 500


@app.route('/api/save-analysis', methods=['POST'])
def save_analysis():
    """
    Endpoint para guardar análisis de un estudiante.
    
    Request body:
    {
        "student_id": "123",
        "analysis": { ... },
        "session_data": { ... }
    }
    """
    try:
        data = request.get_json()
        if not data:
            return jsonify({'error': 'No JSON data provided'}), 400
        
        student_id = data.get('student_id')
        analysis = data.get('analysis')
        
        if not student_id or not analysis:
            return jsonify({'error': 'student_id and analysis are required'}), 400
        
        # TODO: Implementar guardado en base de datos
        # save_analysis_to_db(student_id, analysis)
        
        return jsonify({
            'message': 'Analysis saved successfully',
            'student_id': student_id
        }), 200
        
    except Exception as e:
        app.logger.error(f"Error saving analysis: {str(e)}")
        return jsonify({'error': 'Internal server error'}), 500


@app.route('/api/health', methods=['GET'])
def health_check():
    """Health check endpoint."""
    return jsonify({
        'status': 'healthy',
        'service': 'Language Scoring API',
        'version': '1.0.0'
    }), 200


@app.route('/api/supported-languages', methods=['GET'])
def supported_languages():
    """Retorna los idiomas soportados."""
    return jsonify({
        'languages': [
            {'code': 'en', 'name': 'English', 'flag': '🇺🇸'},
            {'code': 'es', 'name': 'Español', 'flag': '🇪🇸'}
        ]
    }), 200


# Manejo de errores
@app.errorhandler(404)
def not_found(error):
    return jsonify({'error': 'Endpoint not found'}), 404


@app.errorhandler(405)
def method_not_allowed(error):
    return jsonify({'error': 'Method not allowed'}), 405


@app.errorhandler(500)
def internal_error(error):
    return jsonify({'error': 'Internal server error'}), 500


if __name__ == '__main__':
    # Configuración para desarrollo
    app.run(
        host='127.0.0.1',
        port=5000,
        debug=True
    )
